// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'dart:math' as math;

import 'common.dart';
import 'sun.dart';

// Multipliers of the arguments D, M, M', F and the coefficient (1e-6 degree
// for longitude and latitude, 1e-3 km for distance).
const List<List<int>> _lonTerms = [
  [0, 0, 1, 0, 6288774],
  [2, 0, -1, 0, 1274027],
  [2, 0, 0, 0, 658314],
  [0, 0, 2, 0, 213618],
  [0, 1, 0, 0, -185116],
  [0, 0, 0, 2, -114332],
  [2, 0, -2, 0, 58793],
  [2, -1, -1, 0, 57066],
  [2, 0, 1, 0, 53322],
  [2, -1, 0, 0, 45758],
  [0, 1, -1, 0, -40923],
  [1, 0, 0, 0, -34720],
  [0, 1, 1, 0, -30383],
  [2, 0, 0, -2, 15327],
  [0, 0, 1, 2, -12528],
  [0, 0, 1, -2, 10980],
  [4, 0, -1, 0, 10675],
  [0, 0, 3, 0, 10034],
  [4, 0, -2, 0, 8548],
  [2, 1, -1, 0, -7888],
  [2, 1, 0, 0, -6766],
  [1, 0, -1, 0, -5163],
  [1, 1, 0, 0, 4987],
  [2, -1, 1, 0, 4036],
  [2, 0, 2, 0, 3994],
  [4, 0, 0, 0, 3861],
  [2, 0, -3, 0, 3665],
  [0, 1, -2, 0, -2689],
  [2, 0, -1, 2, -2602],
  [2, -1, -2, 0, 2390],
  [1, 0, 1, 0, -2348],
  [2, -2, 0, 0, 2236],
  [0, 1, 2, 0, -2120],
  [0, 2, 0, 0, -2069],
  [2, -2, -1, 0, 2048],
];

const List<List<int>> _latTerms = [
  [0, 0, 0, 1, 5128122],
  [0, 0, 1, 1, 280602],
  [0, 0, 1, -1, 277693],
  [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413],
  [2, 0, -1, -1, 46271],
  [2, 0, 0, 1, 32573],
  [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266],
  [0, 0, 2, -1, 8822],
  [2, -1, 0, -1, 8216],
  [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200],
  [2, 1, 0, -1, -3359],
];

const List<List<int>> _distTerms = [
  [0, 0, 1, 0, -20905355],
  [2, 0, -1, 0, -3699111],
  [2, 0, 0, 0, -2955968],
  [0, 0, 2, 0, -569925],
  [0, 1, 0, 0, 48888],
  [0, 0, 0, 2, -3149],
  [2, 0, -2, 0, 246158],
  [2, -1, -1, 0, -152138],
  [2, 0, 1, 0, -170733],
  [2, -1, 0, 0, -204586],
  [0, 1, -1, 0, -129620],
  [1, 0, 0, 0, 108743],
  [0, 1, 1, 0, 104755],
  [4, 0, -1, 0, 79661],
];

/// Moon state at one instant. Internal: not exported by the package.
///
/// Main periodic terms of the lunar longitude, latitude and distance series
/// (Meeus, "Astronomical Algorithms", ch. 47).
class MoonPosition {
  MoonPosition(this.lambda, this.beta, this.distKm, this.ra, this.dec);

  /// Ecliptic longitude and latitude (radians), distance (km), equatorial coordinates (radians).
  final double lambda, beta, distKm, ra, dec;
}

MoonPosition moonPosition(double jd) {
  final t = centuries(jd);
  final lm = norm360(218.3164477 + 481267.88123421 * t); // mean longitude
  final d = norm360(297.8501921 + 445267.1114034 * t) * rad; // mean elongation
  final ms =
      norm360(357.5291092 + 35999.0502909 * t) * rad; // Sun's mean anomaly
  final mm =
      norm360(134.9633964 + 477198.8675055 * t) * rad; // Moon's mean anomaly
  final f =
      norm360(93.2720950 + 483202.0175233 * t) * rad; // argument of latitude
  final e = 1 - 0.002516 * t - 0.0000074 * t * t;

  double series(List<List<int>> terms, double Function(double) fn) {
    var s = 0.0;
    for (final r in terms) {
      final arg = r[0] * d + r[1] * ms + r[2] * mm + r[3] * f;
      final k = r[1].abs() == 1 ? e : (r[1].abs() == 2 ? e * e : 1.0);
      s += r[4] * k * fn(arg);
    }
    return s;
  }

  var sl = series(_lonTerms, math.sin);
  var sb = series(_latTerms, math.sin);
  final sr = series(_distTerms, math.cos);

  final a1 = (119.75 + 131.849 * t) * rad;
  final a2 = (53.09 + 479264.290 * t) * rad;
  final a3 = (313.45 + 481266.484 * t) * rad;
  final lmr = lm * rad;
  sl += 3958 * math.sin(a1) + 1962 * math.sin(lmr - f) + 318 * math.sin(a2);
  sb +=
      -2235 * math.sin(lmr) +
      382 * math.sin(a3) +
      175 * math.sin(a1 - f) +
      175 * math.sin(a1 + f) +
      127 * math.sin(lmr - mm) -
      115 * math.sin(lmr + mm);

  final lambda = (lm + sl / 1e6) * rad;
  final beta = (sb / 1e6) * rad;
  final dist = 385000.56 + sr / 1000.0;
  final eps = meanObliquity(t) * rad;
  final ra = math.atan2(
    math.sin(lambda) * math.cos(eps) - math.tan(beta) * math.sin(eps),
    math.cos(lambda),
  );
  final dec = math.asin(
    math.sin(beta) * math.cos(eps) +
        math.cos(beta) * math.sin(eps) * math.sin(lambda),
  );
  return MoonPosition(lambda, beta, dist, ra, dec);
}

/// Greenwich mean sidereal time in radians.
double _gmst(double jd) {
  final t = centuries(jd);
  final g =
      280.46061837 +
      360.98564736629 * (jd - 2451545.0) +
      0.000387933 * t * t -
      t * t * t / 38710000.0;
  return norm360(g) * rad;
}

/// Rise/set test of the Moon (radians): positive while the upper limb is above
/// the horizon. Topocentric altitude of the centre (parallax removed), plus the
/// semi-diameter 0.2725·π and the horizontal refraction 34′.
double _moonRiseMargin(double jd, double lat, double lng) {
  final m = moonPosition(jd);
  final phi = lat * rad;
  final h = _gmst(jd) + lng * rad - m.ra; // local hour angle
  final alt = math.asin(
    math.sin(phi) * math.sin(m.dec) +
        math.cos(phi) * math.cos(m.dec) * math.cos(h),
  );
  final parallax = math.asin(earthRadiusKm / m.distKm);
  final topo = alt - parallax * math.cos(alt);
  return topo + 0.2725 * parallax + 0.5667 * rad;
}

/// Illumination of the Moon at one instant, as returned by [moonIllumination].
class MoonIllumination {
  /// Creates a result. Normally you get one from [moonIllumination].
  const MoonIllumination(this.fraction, this.phase, this.angle);

  /// Illuminated fraction 0..1.
  final double fraction;

  /// 0 new moon, 0.25 first quarter, 0.5 full moon, 0.75 last quarter
  /// (elongation of the Moon from the Sun along the ecliptic, divided by 360°).
  final double phase;

  /// Position angle of the bright limb (radians).
  final double angle;
}

/// Illuminated fraction, phase and bright-limb angle of the Moon at the
/// instant [date] (any time zone; only the instant matters).
MoonIllumination moonIllumination(DateTime date) {
  final jd = julianDay(date);
  final s = sunPosition(jd);
  final m = moonPosition(jd);
  final dl = m.lambda - s.lambda;
  final cosPsi =
      math.cos(m.beta) *
      math.cos(dl); // elongation from the ecliptic coordinates
  final psi = math.acos(cosPsi.clamp(-1.0, 1.0));
  final sunKm = s.distAu * auKm;
  final inc = math.atan2(
    sunKm * math.sin(psi),
    m.distKm - sunKm * cosPsi,
  ); // phase angle
  final fraction = (1 + math.cos(inc)) / 2;
  final phase = norm360(dl * deg) / 360.0;
  final angle = math.atan2(
    math.cos(s.dec) * math.sin(s.ra - m.ra),
    math.sin(s.dec) * math.cos(m.dec) -
        math.cos(s.dec) * math.sin(m.dec) * math.cos(s.ra - m.ra),
  );
  return MoonIllumination(fraction, phase, angle);
}

/// Moon events of one 24-hour window, as returned by [moonTimes].
class MoonTimes {
  /// Creates a result. Normally you get one from [moonTimes].
  const MoonTimes({
    this.rise,
    this.set,
    this.alwaysUp = false,
    this.alwaysDown = false,
  });

  /// First moonrise inside the window as a UTC instant, or `null` when the
  /// Moon does not rise in it.
  final DateTime? rise;

  /// First moonset inside the window as a UTC instant, or `null` when the
  /// Moon does not set in it.
  final DateTime? set;

  /// `true` when the Moon neither rises nor sets in the window and stays
  /// above the horizon for most of it.
  final bool alwaysUp;

  /// `true` when the Moon neither rises nor sets in the window and stays
  /// below the horizon for most of it.
  final bool alwaysDown;
}

/// Moonrise and moonset inside the 24 hours that start at [dayStart].
///
/// [dayStart] is the UTC instant of the wanted day's local midnight (for a
/// UTC day: `DateTime.utc(y, m, d)`). [lat] is the latitude in degrees (north
/// positive), [lng] the longitude in degrees (east positive).
///
/// The Moon rises about 50 minutes later every day, so a window can contain no
/// rise or no set: then [MoonTimes.rise] or [MoonTimes.set] is `null`. That is
/// normal and not an error. Near the poles the Moon can stay up or down for the
/// whole window; see [MoonTimes.alwaysUp] and [MoonTimes.alwaysDown].
///
/// The event is the upper limb of the Moon at the horizon with the standard
/// refraction (34′) and with the topocentric parallax of the observer.
/// Results are UTC instants.
///
/// Throws [ArgumentError] when [lat] is outside −90..90 or [lng] outside −180..180.
MoonTimes moonTimes(DateTime dayStart, double lat, double lng) {
  checkCoordinates(lat, lng);
  final jd0 = julianDay(dayStart);
  const stepMin = 20;
  const steps = 24 * 60 ~/ stepMin;
  const step = stepMin / 1440.0;
  double f(double jd) => _moonRiseMargin(jd, lat, lng);

  double? rise, set;
  var prevJd = jd0;
  var prev = f(prevJd);
  var upSamples = prev > 0 ? 1 : 0;
  for (var i = 1; i <= steps; i++) {
    final jd = jd0 + i * step;
    final cur = f(jd);
    if (cur > 0) upSamples++;
    if ((prev < 0) != (cur < 0)) {
      // sign change inside this step: refine by the secant / false-position method
      var a = prevJd, b = jd, fa = prev, fb = cur;
      for (var k = 0; k < 6; k++) {
        final x = a + (b - a) * fa / (fa - fb);
        final fx = f(x);
        if ((fx < 0) == (fa < 0)) {
          a = x;
          fa = fx;
        } else {
          b = x;
          fb = fx;
        }
      }
      final root = a + (b - a) * fa / (fa - fb);
      if (cur > prev) {
        rise ??= root;
      } else {
        set ??= root;
      }
    }
    prevJd = jd;
    prev = cur;
  }
  final none = rise == null && set == null;
  return MoonTimes(
    rise: rise == null ? null : fromJulianDay(rise),
    set: set == null ? null : fromJulianDay(set),
    alwaysUp: none && upSamples > steps ~/ 2,
    alwaysDown: none && upSamples <= steps ~/ 2,
  );
}
