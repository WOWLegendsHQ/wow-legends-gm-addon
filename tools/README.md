# Build & test tooling

Scripts for maintaining and releasing the addon from a clean clone. All paths are
relative to the repo, so `git clone` + these run anywhere.

## Requirements
- Python 3
- `pip install luaparser lupa pymysql`
  - `luaparser` — Lua syntax check
  - `lupa` — embedded Lua for the headless test
  - `pymysql` — only for `gen_teleports.py`

## Scripts

| Script | What it does | Run |
|---|---|---|
| `luacheck.py` | Parse every addon `.lua` (Lua 5.1) and report syntax errors. | `python tools/luacheck.py` |
| `run_harness.py` (+ `harness.lua`) | Headless smoke test: stubs the WoW 3.3.5a API, loads the addon in TOC order, fires `PLAYER_LOGIN` (builds every tab over every command), dry-runs `BuildLine` on each command, and fuzz-clicks every control. Prints `PASS`/`FAIL`. | `python tools/run_harness.py` |
| `gen_catalog.py` | Regenerate `WoWLegends_GM/Data/Catalog.lua` (the 869-command Search index) from `wow-legends.eu/assets/data/commands.js`. | `python tools/gen_catalog.py` |
| `gen_teleports.py` | Regenerate `WoWLegends_GM/Data/Teleports.lua` (the `.teleport` destination browser) from the realm's `game_tele` table. Needs the local DB; override with `WL_DB_HOST/PORT/USER/PASS/NAME`. | `python tools/gen_teleports.py` |
| `package.py` | Build `WoWLegends_GM.zip` with correct forward-slash entries. **Do not** use PowerShell `Compress-Archive` — it writes backslash paths some extractors turn into broken files. | `python tools/package.py` |

## Release checklist
1. Make your changes under `WoWLegends_GM/`.
2. (If commands/teleports changed) `python tools/gen_catalog.py` / `gen_teleports.py`.
3. Bump `## Version` in `WoWLegends_GM/WoWLegends_GM.toc`.
4. `python tools/luacheck.py` and `python tools/run_harness.py` — both must pass.
5. `python tools/package.py`.
6. Commit + push, then create a GitHub release for the new tag and attach `WoWLegends_GM.zip`.
