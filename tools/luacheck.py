#!/usr/bin/env python3
"""Validate every addon Lua file parses as Lua 5.1 (WoW's version).

    pip install luaparser
    python tools/luacheck.py            # checks ../WoWLegends_GM
    python tools/luacheck.py <dir>      # checks a specific directory
"""
import sys, glob, os
from luaparser import ast

HERE = os.path.dirname(os.path.abspath(__file__))
root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "WoWLegends_GM")

files = sorted(glob.glob(os.path.join(root, "**", "*.lua"), recursive=True))
bad = 0
for f in files:
    try:
        ast.parse(open(f, "r", encoding="utf-8").read())
        print("OK   " + os.path.relpath(f, root))
    except Exception as e:
        bad += 1
        print("FAIL " + os.path.relpath(f, root) + "  -> " + (str(e).splitlines() or [""])[0])
print("\n%d file(s), %d failed" % (len(files), bad))
sys.exit(1 if bad else 0)
