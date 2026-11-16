# uzytak_sun_moon

Sunrise, sunset, solar noon, moonrise, moonset, Moon phase and illumination for any place on Earth.
Pure Dart, no dependencies, works in Flutter and in command-line Dart.

It is our own implementation of public astronomical formulas (NOAA solar equations and the Meeus
low-precision lunar theory with topocentric parallax), checked against Swiss Ephemeris.

* Project page: https://calendar.uzytak.com/astro/
* Licence: MIT, Copyright (c) 2026 UZYTAK

## Install

```yaml
dependencies:
  uzytak_sun_moon: ^1.0.0
```

```sh
dart pub add uzytak_sun_moon
```

## Example

```dart
import 'package:uzytak_sun_moon/uzytak_sun_moon.dart';

void main() {
  const lat = 52.2297, lng = 21.0122; // Warsaw: north and east are positive

  // Sun: pass any instant near the middle of the wanted day (UTC noon of the date is fine).
  final sun = sunTimes(DateTime.utc(2026, 11, 15, 12), lat, lng);
  if (!sun.polar) {
    print('rise ${sun.rise}, set ${sun.set}, day ${sun.dayLength!.inMinutes} min'); // UTC instants
  }

  // Moon: pass the start of the 24-hour window.
  final moon = moonTimes(DateTime.utc(2026, 11, 15), lat, lng);
  print('moonrise ${moon.rise}, moonset ${moon.set}'); // either can be null

  // Phase and illumination at one instant.
  final ill = moonIllumination(DateTime.utc(2026, 11, 15, 12));
  print('${(ill.fraction * 100).toStringAsFixed(1)} % lit, phase ${ill.phase}');
}
```

See `example/example.dart` for a version that prints local times.

## API

| Function | Result |
| --- | --- |
| `sunTimes(date, lat, lng)` | `SunTimes`: `rise`, `set`, `noon`, `polar`, `dayLength` |
| `moonTimes(dayStart, lat, lng)` | `MoonTimes`: `rise`, `set`, `alwaysUp`, `alwaysDown` |
| `moonIllumination(date)` | `MoonIllumination`: `fraction` (0..1), `phase` (0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter), `angle` of the bright limb in radians |

## Accuracy

Compared with Swiss Ephemeris 2.10.03 (through pyswisseph, Moshier ephemeris): 12 places (Warsaw, Minsk,
New York, Sydney, Quito, Singapore, Buenos Aires, Reykjavik, Fairbanks, Tromsø, Murmansk, Longyearbyen) on
24 dates between January 2026 and August 2028, 288 place-days. Rise and set are the upper limb at the
horizon with standard refraction (34′), observer at sea level. The numbers below are measured by
`dart run tool/accuracy.dart`; the reference is made by `tool/make_reference.py`.

| Quantity | Compared values | Mean error | 95th percentile | Maximum error |
| --- | ---: | ---: | ---: | ---: |
| Sunrise and sunset, latitude up to 65° | 432 | 0.08 min | 0.21 min | 0.62 min |
| Sunrise and sunset, latitude above 65° | 78 | 0.19 min | 0.45 min | 1.27 min |
| Moonrise and moonset, latitude up to 65° | 400 | 0.07 min | 0.16 min | 0.57 min |
| Moonrise and moonset, latitude above 65° | 73 | 0.19 min | 0.61 min | 0.81 min |
| Moon illuminated fraction | 288 | 0.009 pp | 0.018 pp | 0.019 pp |

Events that fall within 3 minutes of the edge of the compared 24-hour window are left out (2 moon events, no sun events),
because the same event can land on either side of the edge. In every other case the Sun and the Moon
agree with Swiss Ephemeris on whether an event exists at all (polar day, polar night, days without a moonrise).

The accuracy is a measured property of these formulas for the years 2026-2028 and the places above,
not a guarantee for every place and date. It is not meant for navigation, only for calendars,
planners and apps that show times to the minute.

## Notes

* **Time zones.** All results are UTC instants (`DateTime.isUtc == true`). Convert them to a local time
  zone yourself, for example with `package:timezone`. The package does not know about time zones or summer time.
* **Which day.** `sunTimes` returns the solar day whose mean solar noon is nearest to the instant you pass:
  `DateTime.utc(y, m, d, 12)` gives the calendar date `y-m-d` at any longitude, and local noon converted to UTC
  works too. `moonTimes` looks at the 24 hours that start at the instant you pass (the UTC instant of the local midnight).
* **Polar day and night.** Inside the polar circles `SunTimes.polar` is `true` and `rise`, `set` and `dayLength`
  are `null`.
* **The Moon can have no rise or no set on a day.** It rises about 50 minutes later every day, so about once a
  month a day has no moonrise and another day has no moonset. `MoonTimes.rise` or `set` is then `null`;
  this is correct, not an error. Near the poles the Moon can stay above or below the horizon for the whole day
  (`alwaysUp` or `alwaysDown`). If a window holds two events of the same kind, the first one is returned.
* **Altitude.** The observer is at sea level, there is no correction for a high horizon (mountains) or
  for the height of the observer.
* **Coordinates.** `lat` is -90..90 (north positive), `lng` is -180..180 (east positive);
  other values throw `ArgumentError`.

## Tests

```sh
dart test
python -I tool/make_reference.py   # optional: remakes the reference (needs pip install pyswisseph)
dart run tool/accuracy.dart        # prints the accuracy table
```

The tests assert sunrise and sunset within 1 minute (2 minutes above 65° latitude), moonrise and moonset
within 2 minutes, and the illuminated fraction within 0.5 percentage points of the reference.

## Made by UZYTAK

https://uzytak.com · used in the Belarusian tear-off calendar https://calendar.uzytak.com/by/

Licensed under the MIT License, see `LICENSE`.
