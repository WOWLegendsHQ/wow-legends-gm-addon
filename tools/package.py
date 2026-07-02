#!/usr/bin/env python3
"""Build WoWLegends_GM.zip for a GitHub release.

Writes ZIP entries with FORWARD-SLASH paths (WoWLegends_GM/...). Do NOT use
PowerShell's Compress-Archive on Windows: it writes backslash separators that
some extractors turn into broken flat filenames instead of folders.

    python tools/package.py
"""
import zipfile, os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, ".."))
root = os.path.join(REPO, "WoWLegends_GM")
out = os.path.join(REPO, "WoWLegends_GM.zip")

if os.path.exists(out):
    os.remove(out)

n = 0
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for dp, _, fs in os.walk(root):
        for fn in fs:
            full = os.path.join(dp, fn)
            z.write(full, os.path.relpath(full, REPO).replace(os.sep, "/"))
            n += 1

with zipfile.ZipFile(out) as z:
    names = z.namelist()
    ver = [l for l in z.read("WoWLegends_GM/WoWLegends_GM.toc").decode().splitlines()
           if l.startswith("## Version")]
    print("entries:", n,
          "| forward-slash only:", all(chr(92) not in x for x in names),
          "|", ver[0] if ver else "(no version)")
    print("output:", out, "(%.1f KB)" % (os.path.getsize(out) / 1024))
