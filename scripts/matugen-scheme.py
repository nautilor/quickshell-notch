#!/usr/bin/env python3
"""Run matugen for a colour scheme: the accent seeds the tonal colours (primary, containers),
while the scheme's own background, text and outline colours replace matugen's accent-tinted neutrals.

usage: matugen-scheme.py <accent hex> <json {matugen role: hex}>
"""
import json
import os
import subprocess
import sys
import tempfile

accent, overrides = sys.argv[1], json.loads(sys.argv[2])
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
