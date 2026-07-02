#!/usr/bin/env python3
"""Regenerate WoWLegends_GM/Data/Catalog.lua from the WoW Legends command list.

Fetches https://wow-legends.eu/assets/data/commands.js (the same data the site's
/commands page uses), or reads a local commands.js if you pass one. This powers
the addon's Search tab.

    python tools/gen_catalog.py                 # fetch live
    python tools/gen_catalog.py commands.js     # use a local copy
"""
import json, re, sys, os, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "WoWLegends_GM", "Data", "Catalog.lua")
URL = "https://wow-legends.eu/assets/data/commands.js"

src = sys.argv[1] if len(sys.argv) > 1 else None
if src and os.path.exists(src):
    txt = open(src, "r", encoding="utf-8").read()
else:
    print("fetching", URL)
    req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
    txt = urllib.request.urlopen(req).read().decode("utf-8")

arr = json.loads(re.search(r"const DATA\s*=\s*(\[.*\])\s*;?\s*$", txt, re.S).group(1))


def esc(s):
    if s is None:
        return ""
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\r", " ").replace("\n", " ")
    return re.sub(r"\s+", " ", s).strip()


lines = [
    "-- WoWLegends_GM/Data/Catalog.lua",
    "-- AUTO-GENERATED from wow-legends.eu/commands (do not hand-edit; run tools/gen_catalog.py).",
    "-- Full command reference powering the Search tab. %d commands." % len(arr),
    "-- Fields: n=name  l=accessLevel(0-5)  g=group  u=usage  d=description  w=WLonly(0/1)",
    "-- Access tiers: 0 Player | 1 Moderator | 2 Game Master | 3 Administrator | 4 Console | 5 Bot",
    "",
    "local _, WLGM = ...",
    "WLGM.Catalog = {",
]
for x in sorted(arr, key=lambda r: (r.get("g") or "", r.get("n") or "")):
    lines.append('  {n="%s",l=%d,g="%s",u="%s",d="%s",w=%d},' % (
        esc(x.get("n")), int(x.get("l") or 0), esc(x.get("g")),
        esc(x.get("u")), esc(x.get("d")), int(x.get("w") or 0)))
lines.append("}")
lines.append("")

open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("wrote", os.path.normpath(OUT), "-", len(arr), "commands")
