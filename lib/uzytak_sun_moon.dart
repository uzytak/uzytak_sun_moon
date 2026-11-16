// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

/// Sunrise, sunset, moonrise, moonset, Moon phase and illumination.
///
/// Own UZYTAK implementation of public astronomical formulas (NOAA solar
/// equations, Meeus low-precision lunar theory). Pure Dart, no dependencies,
/// works in Flutter and in command-line Dart. Made by UZYTAK, https://uzytak.com
library;

export 'src/moon.dart'
    show MoonIllumination, MoonTimes, moonIllumination, moonTimes;
export 'src/sun.dart' show SunTimes, sunTimes;
