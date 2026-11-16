"""Makes test/fixtures/reference.json with Swiss Ephemeris (pyswisseph) as the reference.

    python -I tool/make_reference.py

Needs `pip install pyswisseph`. Uses the built-in Moshier ephemeris (no data files needed).

Day conventions (the same as in the Dart code and the tests):
  Sun   - the solar day of the UTC calendar date at the given longitude: the 24 h window
          centred on the mean solar noon, i.e. [JD(date 12:00 UTC) - lng/360 - 0.5 d, +1 d).
          Dart call: sunTimes(DateTime.utc(y, m, d, 12), lat, lng).
          The first sunrise and the first sunset inside the window are stored.
  Moon  - the UTC day [date 00:00 UTC, +24 h). Dart call: moonTimes(DateTime.utc(y, m, d), lat, lng).
          The first moonrise and the first moonset inside the window are stored.
  Illumination - illuminated fraction of the Moon at date 12:00 UTC (swe.pheno_ut, attr[1]).
Events are stored as Unix milliseconds (UTC); null = no event in the window.
Rise/set = upper limb at the horizon, standard refraction (pressure 1013.25 hPa, 15 C), observer at sea level.
"""
import json
from pathlib import Path

import swisseph as swe

FLAGS = swe.FLG_MOSEPH
CITIES = [
    # name, latitude, longitude (east positive)
    ("Warsaw", 52.2297, 21.0122),
    ("Minsk", 53.9006, 27.5590),
    ("New York", 40.7128, -74.0060),
    ("Sydney", -33.8688, 151.2093),
    ("Quito", -0.1807, -78.4678),
    ("Singapore", 1.3521, 103.8198),
    ("Buenos Aires", -34.6037, -58.3816),
    ("Reykjavik", 64.1466, -21.9426),
    ("Fairbanks", 64.8378, -147.7164),
    ("Tromso", 69.6492, 18.9553),
    ("Murmansk", 68.9585, 33.0827),
    ("Longyearbyen", 78.2232, 15.6267),
]
# 24 dates between January 2026 and December 2028: every 45 days from 2026-01-10 plus the four
# solstices/equinoxes of 2027 so that the polar transitions are covered.
import datetime as dt

DATES = sorted({dt.date(2026, 1, 10) + dt.timedelta(days=45 * k) for k in range(22)} |
               {dt.date(2027, 3, 20), dt.date(2027, 6, 21)})
ATPRESS, ATTEMP = 1013.25, 15.0
UNIX_JD = 2440587.5


def to_ms(jd):
    return None if jd is None else int(round((jd - UNIX_JD) * 86400000))


def first_event(jd_start, body, which, lat, lng):
    """First rise/set after jd_start and strictly inside the 24 h window, else None."""
    flag, tret = swe.rise_trans(jd_start, body, which, (lng, lat, 0.0), ATPRESS, ATTEMP, FLAGS)
    if flag == -2:  # circumpolar: no event
        return None
    if flag < 0:
        raise RuntimeError(f"rise_trans failed {flag}")
    t = tret[0]
    return t if t < jd_start + 1.0 else None


rows = []
for name, lat, lng in CITIES:
    for d in DATES:
        jd_noon = swe.julday(d.year, d.month, d.day, 12.0)
        sun_start = jd_noon - lng / 360.0 - 0.5
        moon_start = swe.julday(d.year, d.month, d.day, 0.0)
        row = {
            "city": name, "lat": lat, "lng": lng, "date": d.isoformat(),
            "sunRise": to_ms(first_event(sun_start, swe.SUN, swe.CALC_RISE, lat, lng)),
            "sunSet": to_ms(first_event(sun_start, swe.SUN, swe.CALC_SET, lat, lng)),
            "moonRise": to_ms(first_event(moon_start, swe.MOON, swe.CALC_RISE, lat, lng)),
            "moonSet": to_ms(first_event(moon_start, swe.MOON, swe.CALC_SET, lat, lng)),
            "illumination": swe.pheno_ut(jd_noon, swe.MOON, FLAGS)[1],
            "sunWindowStart": to_ms(sun_start), "moonWindowStart": to_ms(moon_start),
        }
        rows.append(row)

out = Path(__file__).resolve().parent.parent / "test" / "fixtures" / "reference.json"
out.parent.mkdir(parents=True, exist_ok=True)
meta = {"generator": "tool/make_reference.py", "pyswisseph": str(swe.__version__), "swisseph_lib": swe.version, "ephemeris": "Moshier (built in)",
        "cities": len(CITIES), "dates": len(DATES), "rows": rows}
out.write_text(json.dumps(meta, indent=0, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
print(len(rows), "rows ->", out)
