#!/usr/bin/env python3
"""Regenerate WoWLegends_GM/Data/Teleports.lua from the realm's game_tele table.

Reads every .teleport destination from the world DB so the Teleport tab's
destination browser matches your realm exactly. Needs the local repack DB
running. Connection is via WL_DB_* env vars (defaults = repack local dev DB;
override if yours differs). No credentials are stored in this file.

    pip install pymysql
    python tools/gen_teleports.py
    # or:  WL_DB_HOST=... WL_DB_USER=... WL_DB_PASS=... WL_DB_NAME=... python tools/gen_teleports.py
"""
import os, sys, pymysql

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "WoWLegends_GM", "Data", "Teleports.lua")

HOST = os.environ.get("WL_DB_HOST", "127.0.0.1")
PORT = int(os.environ.get("WL_DB_PORT", "3306"))
USER = os.environ.get("WL_DB_USER", "root")
PASS = os.environ.get("WL_DB_PASS", "")
NAME = os.environ.get("WL_DB_NAME", "wl_world")

# WotLK map ids -> friendly continent / instance name for the destination browser.
MAPS = {
    0: "Eastern Kingdoms", 1: "Kalimdor", 530: "Outland", 571: "Northrend",
    33: "Shadowfang Keep", 34: "Stockades", 36: "Deadmines", 43: "Wailing Caverns",
    47: "Razorfen Kraul", 48: "Blackfathom", 70: "Uldaman", 90: "Gnomeregan",
    109: "Sunken Temple", 129: "Razorfen Downs", 189: "Scarlet Monastery",
    209: "Zul'Farrak", 229: "Blackrock Spire", 230: "Blackrock Depths",
    249: "Onyxia", 269: "CoT Dark Portal", 289: "Scholomance", 309: "Zul'Gurub",
    329: "Stratholme", 349: "Maraudon", 369: "Deeprun Tram", 389: "Ragefire Chasm",
    409: "Molten Core", 429: "Dire Maul", 449: "Alliance Vault", 450: "Horde Vault",
    469: "Blackwing Lair", 489: "Warsong Gulch",
    509: "Ahn'Qiraj", 529: "Arathi Basin", 531: "Temple of Ahn'Qiraj", 532: "Karazhan",
    533: "Naxxramas", 534: "Hyjal", 540: "Shattered Halls", 542: "Blood Furnace",
    543: "Hellfire Ramparts", 544: "Magtheridon", 545: "Steamvault", 546: "Underbog",
    547: "Slave Pens", 548: "Serpentshrine", 550: "Tempest Keep", 552: "Arcatraz",
    553: "Botanica", 554: "Mechanar", 555: "Shadow Labyrinth", 556: "Sethekk Halls",
    557: "Mana-Tombs", 558: "Auchenai Crypts", 559: "Nagrand Arena", 560: "Old Hillsbrad",
    562: "Blade's Edge Arena", 564: "Black Temple",
    565: "Gruul's Lair", 566: "Eye of the Storm", 568: "Zul'Aman",
    572: "Ruins of Lordaeron", 574: "Utgarde Keep",
    575: "Utgarde Pinnacle", 576: "Nexus", 578: "Oculus", 580: "Sunwell",
    585: "Magisters' Terrace", 595: "CoT Stratholme", 599: "Halls of Stone",
    600: "Drak'Tharon", 601: "Azjol-Nerub", 602: "Halls of Lightning", 603: "Ulduar",
    604: "Gundrak", 607: "Strand of the Ancients", 608: "Violet Hold",
    615: "Obsidian Sanctum", 616: "Eye of Eternity", 617: "Dalaran Arena",
    618: "Ring of Valor", 619: "Ahn'kahet", 624: "Vault of Archavon",
    628: "Isle of Conquest", 631: "Icecrown Citadel", 632: "Forge of Souls",
    649: "Trial of the Crusader", 650: "Trial of the Champion", 658: "Pit of Saron",
    668: "Halls of Reflection", 724: "Ruby Sanctum",
}


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


try:
    conn = pymysql.connect(host=HOST, port=PORT, user=USER, password=PASS, database=NAME)
except Exception as e:
    sys.exit("DB connect failed (%s@%s:%d/%s): %s\nSet WL_DB_* env vars if your DB differs."
             % (USER, HOST, PORT, NAME, e))

cur = conn.cursor()
cur.execute("SELECT name, map FROM game_tele ORDER BY map, name")
rows = cur.fetchall()
conn.close()

lines = [
    "-- WoWLegends_GM/Data/Teleports.lua",
    "-- AUTO-GENERATED from world.game_tele (%d destinations; run tools/gen_teleports.py)." % len(rows),
    "-- Each entry: { name, map = friendly continent/zone }. Use with .tele <name>.",
    "",
    "local _, WLGM = ...",
    "WLGM.Teleports = {",
]
for name, m in rows:
    lines.append('  {n="%s",m="%s"},' % (esc(name), esc(MAPS.get(m, "Map %d" % m))))
lines.append("}")
lines.append("")

open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print("wrote", os.path.normpath(OUT), "-", len(rows), "destinations")
