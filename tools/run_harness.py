#!/usr/bin/env python3
"""Headless smoke test: run harness.lua (a stub WoW API) against the addon.

Loads every file in TOC order, fires PLAYER_LOGIN (which builds every tab over
every command def), dry-runs BuildLine on each command, and fuzz-clicks every
control. Prints PASS/FAIL. Catches runtime errors a syntax check can't.

    pip install lupa
    python tools/run_harness.py
"""
import os
from lupa import LuaRuntime

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.abspath(os.path.join(HERE, "..", "WoWLegends_GM")).replace("\\", "/")

lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().BASE = BASE
lua.execute(open(os.path.join(HERE, "harness.lua"), "r", encoding="utf-8").read())
R = lua.globals().RESULT


def tolist(t):
    out = []
    if t is None:
        return out
    try:
        for i in range(1, len(t) + 1):
            if t[i] is not None:
                out.append(t[i])
    except Exception:
        pass
    return out


print("tabs registered :", R["tabs"])
print("catalog entries :", R["catalog"])
print("teleports       :", R["teleports"])

errors = tolist(R["errors"])
fmt = tolist(R["fmt_errors"])
clicks = tolist(R["click_errors"])
chat = tolist(R["chat"])

print("\n=== load/run/event ERRORS (%d) ===" % len(errors))
for e in errors:
    print("  " + str(e))
print("\n=== BuildLine format errors (%d) ===" % len(fmt))
for e in fmt:
    print("  " + str(e))
print("\n=== click-path errors (%d) ===" % len(clicks))
for e in clicks[:20]:
    print("  " + str(e))

bad = [c for c in chat if any(k in str(c) for k in ("error", "ERROR", "MISSING", "Error"))]
print("\n=== addon chat error lines (%d) ===" % len(bad))
for c in bad:
    print("  " + str(c))

ok = not errors and not fmt and not clicks and not bad
print("\nRESULT:", "PASS" if ok else "FAIL")
raise SystemExit(0 if ok else 1)
