// Copyright (c) 2026 UZYTAK. Licensed under the MIT License.
// See the LICENSE file in the package root.

/// Compares the package with the Swiss Ephemeris reference (test/fixtures/reference.json,
/// made by tool/make_reference.py) and prints the accuracy table.
///
///     dart run tool/accuracy.dart
///
/// Day conventions are documented in tool/make_reference.py.
library;

import 'dart:convert';
import 'dart:io';

import 'package:uzytak_sun_moon/uzytak_sun_moon.dart';

/// Events whose reference time is closer than this to the edge of the day window are not compared:
/// the same event can fall on either side of the edge.
const edgeMinutes = 3.0;

/// Statistics of absolute errors in one group.
class Stat {
  final List<double> errors = [];
  int skipped = 0;
  int presenceMismatch = 0;

  void add(double e) => errors.add(e);

  int get n => errors.length;
  double get max => errors.isEmpty ? 0 : errors.reduce((a, b) => a > b ? a : b);
  double get mean =>
      errors.isEmpty ? 0 : errors.reduce((a, b) => a + b) / errors.length;
  double get p95 {
    if (errors.isEmpty) return 0;
    final s = [...errors]..sort();
    return s[((s.length - 1) * 0.95).round()];
  }
}

/// Result of one run over the whole fixture.
class Report {
  Report(this.cities, this.dates, this.rows);
  final int cities, dates, rows;
  final sunLow = Stat(); // |lat| <= 65
  final sunHigh = Stat(); // |lat| > 65
  final moonLow = Stat();
  final moonHigh = Stat();
  final illumination = Stat(); // percentage points
  final problems = <String>[];
  String pyswisseph = '';
}

Report measure([String path = 'test/fixtures/reference.json']) {
  final data =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
  final rep = Report(data['cities'] as int, data['dates'] as int, rows.length)
    ..pyswisseph = data['swisseph_lib'] as String;

  double minutes(DateTime a, int b) =>
      (a.millisecondsSinceEpoch - b).abs() / 60000.0;

  // Compares one event; [edge] = distance in minutes of the reference to the window edge when the
  // reference has an event, and of our result when it does not.
  void compare(
    Stat st,
    String tag,
    DateTime? ours,
    int? ref,
    int winStart,
    String what,
  ) {
    final lo = winStart.toDouble(), hi = winStart + 86400000.0;
    double edge(int ms) =>
        ((ms - lo).abs() < (hi - ms).abs()
            ? (ms - lo).abs()
            : (hi - ms).abs()) /
        60000.0;
    if (ours == null && ref == null) return;
    if (ours == null || ref == null) {
      final t = (ref ?? ours!.millisecondsSinceEpoch);
      if (edge(t) <= edgeMinutes) {
        st.skipped++;
        return;
      }
      st.presenceMismatch++;
      rep.problems.add(
        '$tag $what: ${ours == null ? 'we have none, reference has one' : 'we have one, reference has none'}',
      );
      return;
    }
    if (edge(ref) <= edgeMinutes) {
      st.skipped++;
      return;
    }
    st.add(minutes(ours, ref));
  }

  for (final r in rows) {
    final lat = (r['lat'] as num).toDouble(),
        lng = (r['lng'] as num).toDouble();
    final d = DateTime.parse('${r['date']}T00:00:00Z');
    final tag = '${r['city']} ${r['date']}';
    final high = lat.abs() > 65;

    final st = sunTimes(DateTime.utc(d.year, d.month, d.day, 12), lat, lng);
    final sunStat = high ? rep.sunHigh : rep.sunLow;
    final sw = r['sunWindowStart'] as int;
    compare(sunStat, tag, st.rise, r['sunRise'] as int?, sw, 'sunrise');
    compare(sunStat, tag, st.set, r['sunSet'] as int?, sw, 'sunset');

    final mt = moonTimes(DateTime.utc(d.year, d.month, d.day), lat, lng);
    final moonStat = high ? rep.moonHigh : rep.moonLow;
    final mw = r['moonWindowStart'] as int;
    compare(moonStat, tag, mt.rise, r['moonRise'] as int?, mw, 'moonrise');
    compare(moonStat, tag, mt.set, r['moonSet'] as int?, mw, 'moonset');

    final ill = moonIllumination(DateTime.utc(d.year, d.month, d.day, 12))
        .fraction;
    rep.illumination.add(
      (ill - (r['illumination'] as num).toDouble()).abs() * 100,
    );
  }
  return rep;
}

String _f(double v, int digits) => v.toStringAsFixed(digits);

/// Markdown table used in README.md and on the web page.
String table(Report r) {
  String row(String label, Stat s, {bool pp = false}) {
    final u = pp ? ' pp' : ' min';
    final dg = pp ? 3 : 2;
    return '| $label | ${s.n} | ${_f(s.mean, dg)}$u | ${_f(s.p95, dg)}$u | ${_f(s.max, dg)}$u |';
  }

  return [
    '| Quantity | Compared values | Mean error | 95th percentile | Maximum error |',
    '| --- | ---: | ---: | ---: | ---: |',
    row('Sunrise and sunset, latitude up to 65°', r.sunLow),
    row('Sunrise and sunset, latitude above 65°', r.sunHigh),
    row('Moonrise and moonset, latitude up to 65°', r.moonLow),
    row('Moonrise and moonset, latitude above 65°', r.moonHigh),
    row('Moon illuminated fraction', r.illumination, pp: true),
  ].join('\n');
}

void main() {
  final r = measure();
  stdout.writeln(
    'Reference: Swiss Ephemeris ${r.pyswisseph} (pyswisseph), ${r.cities} places x ${r.dates} dates = ${r.rows} place-days',
  );
  stdout.writeln(table(r));
  stdout.writeln(
    'skipped near window edge: sun ${r.sunLow.skipped + r.sunHigh.skipped}, moon ${r.moonLow.skipped + r.moonHigh.skipped}',
  );
  stdout.writeln('presence mismatches: ${r.problems.length}');
  for (final p in r.problems) {
    stdout.writeln('  $p');
  }
}
