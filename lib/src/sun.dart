// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'dart:math' as math;

import 'common.dart';

/// Sun state at one instant. Internal: not exported by the package.
///
/// Based on the NOAA "General Solar Position Calculations" (Julian century,
/// mean anomaly, equation of centre, apparent longitude, equation of time).
class SunPosition {
  SunPosition(this.lambda, this.ra, this.dec, this.eqTime, this.distAu);

  /// Apparent ecliptic longitude, right ascension, declination (radians).
  final double lambda, ra, dec;

  /// Equation of time in minutes.
  final double eqTime;
  final double distAu;
}

SunPosition sunPosition(double jd) {
  final t = centuries(jd);
  final l0 = norm360(
    280.46646 + t * (36000.76983 + t * 0.0003032),
  ); // geometric mean longitude
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t); // mean anomaly
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final mr = m * rad;
  final c =
      math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * mr) * (0.019993 - 0.000101 * t) +
      math.sin(3 * mr) * 0.000289;
  final trueLong = l0 + c;
  final trueAnom = (m + c) * rad;
  final dist = 1.000001018 * (1 - e * e) / (1 + e * math.cos(trueAnom));
  final omega = (125.04 - 1934.136 * t) * rad;
  final lambda = (trueLong - 0.00569 - 0.00478 * math.sin(omega)) * rad;
  final eps = (meanObliquity(t) + 0.00256 * math.cos(omega)) * rad;
  final ra = math.atan2(math.cos(eps) * math.sin(lambda), math.cos(lambda));
  final dec = math.asin(math.sin(eps) * math.sin(lambda));
  final y = math.tan(eps / 2) * math.tan(eps / 2);
  final l0r = l0 * rad;
  final eqt =
      4 *
      deg *
      (y * math.sin(2 * l0r) -
          2 * e * math.sin(mr) +
          4 * e * y * math.sin(mr) * math.cos(2 * l0r) -
          0.5 * y * y * math.sin(4 * l0r) -
          1.25 * e * e * math.sin(2 * mr));
  return SunPosition(lambda, ra, dec, eqt, dist);
}

/// Sun events of one solar day, as returned by [sunTimes].
class SunTimes {
  /// Creates a result. Normally you get one from [sunTimes].
  const SunTimes({
    this.rise,
    this.set,
    required this.noon,
    required this.polar,
  });

  /// Sunrise as a UTC instant; `null` in polar day and polar night.
  final DateTime? rise;

  /// Sunset as a UTC instant; `null` in polar day and polar night.
  final DateTime? set;

  /// Solar noon (the Sun crosses the meridian) as a UTC instant.
  final DateTime noon;

  /// `true` when the Sun neither rises nor sets on this day (polar day or
  /// polar night). Then [rise], [set] and [dayLength] are `null`.
  final bool polar;

  /// Time between sunrise and sunset, or `null` in polar day/night.
  Duration? get dayLength =>
      rise != null && set != null ? set!.difference(rise!) : null;
}

/// Sunrise, sunset and solar noon for the solar day around [date].
///
/// [lat] is the latitude in degrees (north positive), [lng] the longitude in
/// degrees (east positive). Sunrise and sunset are the moments when the centre
/// of the Sun is 0.833° below the horizon (upper limb on the horizon with the
/// standard refraction).
///
/// Day convention: the result belongs to the solar day whose mean solar noon is
/// nearest to [date]. Pass any instant near the middle of the wanted local day,
/// for example local noon converted to UTC, or simply `DateTime.utc(y, m, d, 12)`
/// for the calendar date `y-m-d` at any longitude. All results are UTC instants;
/// convert them to a local time zone yourself.
///
/// In polar day or polar night [SunTimes.polar] is `true` and
/// [SunTimes.rise] and [SunTimes.set] are `null`.
///
/// Throws [ArgumentError] when [lat] is outside −90..90 or [lng] outside −180..180.
SunTimes sunTimes(DateTime date, double lat, double lng) {
  checkCoordinates(lat, lng);
  // Mean solar noon at this longitude is 12:00 UTC − lng/360 days; take the day nearest to [date].
  final n = (julianDay(date) + lng / 360.0).roundToDouble();
  final base = n - lng / 360.0; // JD of mean solar noon

  var jdNoon = base;
  for (var i = 0; i < 3; i++) {
    jdNoon = base - sunPosition(jdNoon).eqTime / 1440.0;
  }
  final noon = fromJulianDay(jdNoon);

  final phi = lat * rad;
  final cosZenith = math.cos(90.833 * rad);
  // Hour angle of the Sun's rise/set in degrees at the instant [at]; null when it does not rise or set.
  double? hourAngle(double at) {
    final dec = sunPosition(at).dec;
    final x =
        cosZenith / (math.cos(phi) * math.cos(dec)) -
        math.tan(phi) * math.tan(dec);
    if (x.isNaN || x < -1 || x > 1) return null;
    return math.acos(x) * deg;
  }

  // Event time = mean noon ∓ hour angle − equation of time, iterated with the Sun's state at that moment.
  double? event(int sign) {
    var x = jdNoon;
    for (var i = 0; i < 4; i++) {
      final ha = hourAngle(x);
      if (ha == null) return null;
      x = base + sign * ha / 360.0 - sunPosition(x).eqTime / 1440.0;
    }
    return x;
  }

  final rise = event(-1);
  final set = event(1);
  if (rise == null || set == null) return SunTimes(noon: noon, polar: true);
  return SunTimes(
    rise: fromJulianDay(rise),
    set: fromJulianDay(set),
    noon: noon,
    polar: false,
  );
}
