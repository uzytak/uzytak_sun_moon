// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

import 'package:uzytak_sun_moon/uzytak_sun_moon.dart';

String hhmm(DateTime utc, Duration offset) {
  final t = utc.add(offset);
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

void main() {
  // Warsaw. Results are UTC instants; here we add the local offset (CET = UTC+1) by hand.
  const lat = 52.2297, lng = 21.0122;
  const cet = Duration(hours: 1);

  // Sun: pass any instant near the middle of the wanted day (UTC noon of the date is fine).
  final sun = sunTimes(DateTime.utc(2026, 11, 15, 12), lat, lng);
  if (sun.polar) {
    print('The Sun does not rise or set on this day.');
  } else {
    print(
      'Sunrise ${hhmm(sun.rise!, cet)}, sunset ${hhmm(sun.set!, cet)}, '
      'day length ${sun.dayLength!.inMinutes} min',
    );
  }

  // Moon: pass the start of the 24-hour window (here the UTC day).
  final moon = moonTimes(DateTime.utc(2026, 11, 15), lat, lng);
  print(
    'Moonrise ${moon.rise == null ? 'none today' : hhmm(moon.rise!, cet)}, '
    'moonset ${moon.set == null ? 'none today' : hhmm(moon.set!, cet)}',
  );

  // Phase and illumination at one instant.
  final ill = moonIllumination(DateTime.utc(2026, 11, 15, 12));
  print(
    'Moon: ${(ill.fraction * 100).toStringAsFixed(1)} % lit, '
    'phase ${ill.phase.toStringAsFixed(3)} (0 new, 0.5 full)',
  );
}
