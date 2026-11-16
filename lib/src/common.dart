// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'dart:math' as math;

const double pi = math.pi;
const double rad = pi / 180;
const double deg = 180 / pi;
const double msDay = 86400000.0;
const double earthRadiusKm = 6378.14;
const double auKm = 149597870.7;

/// Julian day of a UTC instant.
double julianDay(DateTime t) => t.millisecondsSinceEpoch / msDay + 2440587.5;

DateTime fromJulianDay(double jd) => DateTime.fromMillisecondsSinceEpoch(
  ((jd - 2440587.5) * msDay).round(),
  isUtc: true,
);

/// Julian centuries since J2000.0.
double centuries(double jd) => (jd - 2451545.0) / 36525.0;

double norm360(double x) {
  final r = x % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Mean obliquity of the ecliptic in degrees.
double meanObliquity(double t) =>
    23.0 +
    (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) /
        60.0;

/// Throws [ArgumentError] for coordinates outside the valid range (or NaN).
void checkCoordinates(double lat, double lng) {
  if (!(lat >= -90 && lat <= 90)) {
    throw ArgumentError.value(lat, 'lat', 'must be within -90..90 degrees');
  }
  if (!(lng >= -180 && lng <= 180)) {
    throw ArgumentError.value(lng, 'lng', 'must be within -180..180 degrees');
  }
}
