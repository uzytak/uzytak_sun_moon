// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'package:test/test.dart';

import '../tool/accuracy.dart';

/// Comparison with Swiss Ephemeris (test/fixtures/reference.json, made by
/// tool/make_reference.py): 12 places, including polar ones, x 24 dates in 2026-2028.
void main() {
  final report = measure();

  test('the fixture is complete', () {
    expect(report.cities, 12);
    expect(report.dates, 24);
    expect(report.rows, 288);
  });

  test(
    'sunrise and sunset: within 1 minute, within 2 minutes above 65 degrees',
    () {
      expect(report.sunLow.n, greaterThan(400));
      expect(report.sunLow.max, lessThanOrEqualTo(1.0));
      expect(report.sunHigh.n, greaterThan(50));
      expect(report.sunHigh.max, lessThanOrEqualTo(2.0));
    },
  );

  test('moonrise and moonset: within 2 minutes', () {
    expect(report.moonLow.n, greaterThan(350));
    expect(report.moonLow.max, lessThanOrEqualTo(2.0));
    expect(report.moonHigh.n, greaterThan(50));
    expect(report.moonHigh.max, lessThanOrEqualTo(2.0));
  });

  test('Moon illumination: within 0.5 percentage points', () {
    expect(report.illumination.n, 288);
    expect(report.illumination.max, lessThanOrEqualTo(0.5));
  });

  test(
    'polar day, polar night and days without an event agree with the reference',
    () {
      expect(report.problems, isEmpty);
    },
  );
}
