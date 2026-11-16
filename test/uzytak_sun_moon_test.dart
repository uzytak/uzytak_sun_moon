// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'package:test/test.dart';
import 'package:uzytak_sun_moon/uzytak_sun_moon.dart';

void main() {
  group('sunTimes', () {
    test(
      'Warsaw, 15 November 2026: sunrise before sunset, noon between them',
      () {
        final t = sunTimes(DateTime.utc(2026, 11, 15, 12), 52.2297, 21.0122);
        expect(t.polar, isFalse);
        expect(t.rise!.isUtc, isTrue);
        expect(t.rise!.isBefore(t.noon), isTrue);
        expect(t.noon.isBefore(t.set!), isTrue);
        // about 8 h 50 min of daylight in mid November
        expect(t.dayLength!.inMinutes, inInclusiveRange(520, 540));
      },
    );

    test('the equator has about 12 hours of daylight all year', () {
      for (final m in [3, 6, 9, 12]) {
        final t = sunTimes(DateTime.utc(2027, m, 15, 12), 0, 0);
        expect(
          t.dayLength!.inMinutes,
          inInclusiveRange(715, 735),
          reason: 'month $m',
        );
      }
    });

    test('Tromso: polar night at the winter solstice, midnight sun at the summer solstice', () {
      final winter = sunTimes(DateTime.utc(2026, 12, 21, 12), 69.65, 18.96);
      expect(winter.polar, isTrue);
      expect(winter.rise, isNull);
      expect(winter.set, isNull);
      expect(winter.dayLength, isNull);
      final summer = sunTimes(DateTime.utc(2027, 6, 21, 12), 69.65, 18.96);
      expect(summer.polar, isTrue);
    });

    test('rejects coordinates out of range', () {
      expect(
        () => sunTimes(DateTime.utc(2027, 1, 1), 91, 0),
        throwsArgumentError,
      );
      expect(
        () => sunTimes(DateTime.utc(2027, 1, 1), 0, 181),
        throwsArgumentError,
      );
      expect(
        () => sunTimes(DateTime.utc(2027, 1, 1), double.nan, 0),
        throwsArgumentError,
      );
    });
  });

  group('moonIllumination', () {
    test('new moon 9 November 2026 (about 07:02 UTC) is dark, full moon 24 November (about 14:53 UTC) is bright', () {
      final nm = moonIllumination(DateTime.utc(2026, 11, 9, 7, 2));
      final fm = moonIllumination(DateTime.utc(2026, 11, 24, 14, 53));
      expect(nm.fraction, lessThan(0.005));
      expect(fm.fraction, greaterThan(0.995));
      expect((nm.phase > 0.5 ? 1 - nm.phase : nm.phase), lessThan(0.01));
      expect((fm.phase - 0.5).abs(), lessThan(0.01));
    });

    test('the phase grows from 0 to 1 over one lunar month', () {
      var last = -1.0;
      for (var day = 0; day < 29; day += 4) {
        final p = moonIllumination(
          DateTime.utc(2026, 11, 10).add(Duration(days: day)),
        ).phase;
        expect(p, greaterThan(last));
        last = p;
      }
    });

    test('fraction is always within 0..1', () {
      for (var i = 0; i < 400; i++) {
        final f = moonIllumination(
          DateTime.utc(2026, 1, 1).add(Duration(hours: i * 37)),
        ).fraction;
        expect(f, inInclusiveRange(0, 1));
      }
    });
  });

  group('moonTimes', () {
    test('a day can have no moonrise: some days of a month have none, none has two', () {
      var withoutRise = 0;
      for (var day = 1; day <= 30; day++) {
        final t = moonTimes(DateTime.utc(2026, 11, day), 52.2297, 21.0122);
        if (t.rise == null) withoutRise++;
        if (t.rise != null) {
          final start = DateTime.utc(2026, 11, day);
          expect(
            t.rise!.isAfter(start) || t.rise!.isAtSameMomentAs(start),
            isTrue,
          );
          expect(
            t.rise!.isBefore(start.add(const Duration(hours: 24, minutes: 1))),
            isTrue,
          );
        }
      }
      expect(withoutRise, inInclusiveRange(0, 3));
    });

    test('far north the Moon can stay above or below the horizon for the whole day', () {
      var up = 0, down = 0;
      for (var day = 1; day <= 30; day++) {
        final t = moonTimes(DateTime.utc(2026, 12, day), 78.22, 15.63);
        if (t.alwaysUp) up++;
        if (t.alwaysDown) down++;
        if (t.alwaysUp || t.alwaysDown) {
          expect(t.rise, isNull);
          expect(t.set, isNull);
        }
      }
      expect(up, greaterThan(0));
      expect(down, greaterThan(0));
    });

    test('rejects coordinates out of range', () {
      expect(
        () => moonTimes(DateTime.utc(2027, 1, 1), -91, 0),
        throwsArgumentError,
      );
      expect(
        () => moonTimes(DateTime.utc(2027, 1, 1), 0, -181),
        throwsArgumentError,
      );
    });
  });
}
