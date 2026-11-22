#!/usr/bin/env python3
"""Run matugen for a colour scheme: the accent seeds the tonal colours (primary, containers),
while the scheme's own background, text and outline colours replace matugen's accent-tinted neutrals.

Optionally a third argument (json list of hex colours: the scheme's primary, secondary, tertiary,
error and accents) is classified into the red/orange/yellow/green/cyan/blue/purple custom colours,
so templates that use them (e.g. the nvim palette) get the scheme's real hues instead of fixed ones.

usage: matugen-scheme.py <accent hex> <json {matugen role: hex}> [json [hex, ...]]
"""
import colorsys
import json
import os
import subprocess
import sys
import tempfile

# canonical hues (degrees) of the custom colour slots
SLOTS = {"red": 355, "orange": 28, "yellow": 50, "green": 100, "cyan": 182, "blue": 215, "purple": 285}
MATCH_RANGE = 36  # max hue distance for a scheme colour to claim a slot
MIN_SAT = 0.15  # below this a colour is grey and carries no hue


def hsl(hex_):
    r, g, b = (int(hex_[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h * 360, s, l


def to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360) / 360, l, s)
    return "#%02x%02x%02x" % tuple(round(c * 255) for c in (r, g, b))


def hue_dist(a, b):
    return abs((a - b + 180) % 360 - 180)


def classify(colors, error=None):
    """Map each slot to a hex: scheme colours where one is close in hue (closest pairs first, one
    slot per colour), otherwise a colour at the canonical hue with the matched colours' average
    saturation and lightness, so the palette stays coherent (and grey schemes stay grey)."""
    cands = []
    for c in colors:
        c = c.lower()
        if len(c) == 7 and c[0] == "#" and c not in (x[0] for x in cands):
            cands.append((c, *hsl(c)))
    if not cands:
        return {}
    coloured = [c for c in cands if c[2] >= MIN_SAT] or cands
    pairs = sorted(
        (hue_dist(c[1], hue), c[0], slot)
        for c in coloured for slot, hue in SLOTS.items()
        if hue_dist(c[1], hue) <= MATCH_RANGE
    )
    out, used = {}, set()
    # the scheme's error colour is its red, even when another colour is a hair closer
    if error and error.lower() in (c[0] for c in coloured):
        e = next(c for c in coloured if c[0] == error.lower())
        if hue_dist(e[1], SLOTS["red"]) <= MATCH_RANGE:
            used.add(e[0])
            out["red"] = e[0]
    for _, hex_, slot in pairs:
        if hex_ not in used and slot not in out:
            used.add(hex_)
            out[slot] = hex_
    ref = [hsl(h) for h in out.values()] or [c[1:] for c in coloured]
    sat = sum(c[1] for c in ref) / len(ref)
    lig = sum(c[2] for c in ref) / len(ref)
    for slot, hue in SLOTS.items():
        out.setdefault(slot, to_hex(hue, sat, lig))
    return out


accent, overrides = sys.argv[1], json.loads(sys.argv[2])
hues = json.loads(sys.argv[3]) if len(sys.argv) > 3 else []
palette = classify(hues, hues[0] if hues else None)
overrides.update(palette)
dump = subprocess.run(
    ["matugen", "color", "hex", accent, "-m", "dark", "--dry-run", "-j", "hex", "-q"],
    capture_output=True, text=True, check=True,
).stdout
data = json.loads(dump[dump.index("{"):])
for role, hex_ in overrides.items():
    data["colors"][role] = {m: {"color": hex_} for m in ("dark", "default", "light")}
with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
    json.dump(data, f)
try:
    subprocess.run(["matugen", "json", f.name, "-m", "dark"], check=True)
finally:
    os.unlink(f.name)
