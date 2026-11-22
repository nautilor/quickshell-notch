#!/usr/bin/env python3
"""Print the colours matugen would generate for a colour scheme (+ optional accent). Writes nothing.

usage: show-scheme.py <scheme name | path to .json> [accent hex]
       show-scheme.py --list

Mirrors Colorschemes.build() and Matugen.schemeRoles, then runs matugen with --dry-run.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DIRS = [
    os.path.join(os.path.dirname(HERE), "colorschemes"),
    os.path.expanduser("~/.config/quickshell-notch/colorschemes"),
]


def rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def hexs(c):
    return "#" + "".join("%02x" % round(max(0, min(1, v)) * 255) for v in c)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def build(j, accent=None):
    bg, fg = rgb(j["background"]), rgb(j["foreground"])
    primary = rgb(accent) if accent else rgb(j["primary"])
    secondary = rgb(j["secondary"]) if j.get("secondary") else mix(primary, fg, 0.5)
    tertiary = rgb(j["tertiary"]) if j.get("tertiary") else mix(primary, secondary, 0.5)
    error = rgb(j["error"]) if j.get("error") else rgb("#f2b8b5")
    on = lambda c: bg if lum(c) > 0.5 else fg
    p = {
        "notch": bg,
        "surfaceContainerLow": mix(bg, fg, 0.04),
        "surfaceContainer": mix(bg, fg, 0.07),
        "surfaceContainerHigh": mix(bg, fg, 0.11),
        "surfaceContainerHighest": mix(bg, fg, 0.15),
        "primary": primary,
        "secondaryContainer": mix(bg, secondary, 0.22),
        "secondaryContainerFg": mix(secondary, fg, 0.75),
        "tertiary": tertiary,
        "tertiaryFg": on(tertiary),
        "tertiaryContainer": mix(bg, tertiary, 0.28),
        "tertiaryContainerFg": mix(tertiary, fg, 0.75),
        "error": error,
        "errorFg": on(error),
        "surfaceFg": fg,
        "surfaceVariantFg": mix(fg, bg, 0.25),
        "outline": mix(bg, fg, 0.4),
        "outlineVariant": mix(bg, fg, 0.18),
    }
    for k in list(p):
        if accent and k == "primary":
            continue
        if isinstance(j.get(k), str):
            p[k] = rgb(j[k])
    return p


def roles(p):
    m = {
        "background": p["notch"],
        "surface": p["notch"],
        "surface_dim": p["notch"],
        "surface_container_lowest": p["notch"],
        "surface_container_low": p["surfaceContainerLow"],
        "surface_container": p["surfaceContainer"],
        "surface_container_high": p["surfaceContainerHigh"],
        "surface_container_highest": p["surfaceContainerHighest"],
        "surface_bright": p["surfaceContainerHighest"],
        "surface_variant": p["surfaceContainerHigh"],
        "on_background": p["surfaceFg"],
        "on_surface": p["surfaceFg"],
        "on_surface_variant": p["surfaceVariantFg"],
        "outline": p["outline"],
        "outline_variant": p["outlineVariant"],
        "secondary": p["secondaryContainerFg"],
        "secondary_container": p["secondaryContainer"],
        "on_secondary_container": p["secondaryContainerFg"],
        "tertiary": p["tertiary"],
        "on_tertiary": p["tertiaryFg"],
        "tertiary_container": p["tertiaryContainer"],
        "on_tertiary_container": p["tertiaryContainerFg"],
        "error": p["error"],
        "on_error": p["errorFg"],
    }
    return {k: hexs(v) for k, v in m.items()}


def find(name):
    if os.path.isfile(name):
        return name
    for d in reversed(DIRS):  # user dir wins
        f = os.path.join(d, name if name.endswith(".json") else name + ".json")
        if os.path.isfile(f):
            return f
    sys.exit("scheme not found: " + name)


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args[0] == "--list":
        names = {f[:-5] for d in DIRS if os.path.isdir(d) for f in os.listdir(d) if f.endswith(".json") and not f.startswith("_")}
        print("\n".join(sorted(names)))
        return
    with open(find(args[0])) as f:
        j = json.load(f)
    accent = args[1] if len(args) > 1 else None
    p = build(j, accent)
    seed = hexs(p["primary"])
    dump = subprocess.run(
        ["matugen", "color", "hex", seed, "-m", "dark", "--dry-run", "-j", "hex", "-q"],
        capture_output=True, text=True, check=True,
    ).stdout
    colors = {k: v["dark"]["color"] for k, v in json.loads(dump[dump.index("{"):])["colors"].items()}
    over = roles(p)
    colors.update(over)
    w = max(map(len, colors))
    tty = sys.stdout.isatty() and "NO_COLOR" not in os.environ

    def paint(h):
        if not tty:
            return h
        r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
        # swatch (background) + hex in the colour itself
        return f"\x1b[48;2;{r};{g};{b}m    \x1b[0m \x1b[38;2;{r};{g};{b}m{h}\x1b[0m"

    print("seed accent:", paint(seed))
    for k in sorted(colors):
        print(f"{k:<{w}}  {paint(colors[k])}" + ("   (scheme)" if k in over else ""))


main()
