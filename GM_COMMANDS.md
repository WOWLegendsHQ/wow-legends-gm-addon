# WoW Legends — Complete Command Reference (for the GM Addon)

## ▶ Start here — prompt for the addon build

**Read this whole file, then build the _WoW Legends GM Addon_.**

**What it is:** an in-game admin panel for **World of Warcraft 3.3.5a (WotLK)** that gives GMs/admins one-click control over the WoW Legends custom systems and the playerbots *without typing commands* — start/stop **World PvP** and **World Events** (with a zone picker + teleport-to-battlefront), build & command bot parties, set roles, quick-gear targets, manage XP, and more.

**Your goal:** the **nicest, cleanest, best-organized** GM addon you can make — fast, clear, WoW-native. Every control sends one of the commands documented below (the server still enforces GM rank).

**Design principles:**
- A tidy, tabbed/sectioned window organized by task: **Events (World PvP / World Events + zone TP) · Bots · Roles · Gear · XP · Utility**.
- Show GM-only controls only to GMs — gate by the player's GM level (see the GM-levels note in §0). Tags below: **[P]** any player, **[GM]** GameMaster.
- Clear icons, helpful tooltips; **confirm disruptive actions** (starting World PvP, spawning an event, etc.).
- Target **WoW 3.3.5a (WotLK) — client build 12340**: `.toc` header `## Interface: 30300`, Lua 5.1 + XML, the WotLK FrameXML API only.
- Implementation is just chat: **dot-commands** (`.worldpvp start`, `.wlevent start <zone>`) go to the server; **bot orders** (`$follow`, `$summon`) go to **whisper** or **party/raid** chat.
- **Testing the commands:** the live realm's Remote Access is wired to the **wow-legends MCP** — use `ra_command` to run dot-commands against the running server and verify their behaviour/output (e.g. `.worldpvp status`, `.wlevent zones`, `.xp view`). The `$` bot orders are in-world chat, so test those on a character in-game.

The complete, source-verified spec follows — including permission tags and the per-zone World Events teleport coordinates (§5.5). The "Addon-builder notes" (§7) suggest a panel layout.

---

Source-verified against the v1.4.0 build (2026-07-14; §§1.1–1.6 originally verified on v1.1.0, §1.7 on v1.3.0 — all unchanged since). This is the authoritative list for building the GM addon: every WL custom command, every playerbot command, the bot chat (`$`) commands, Dungeon Clear, World PvP, World Events (with zones), XP and Legend Roads — plus the option lists for dropdowns.

---

## 0. The TWO command types (read this first — it drives everything)

| Type | Prefix | Where typed | Example |
|------|--------|-------------|---------|
| **Dot-command** | `.` | any chat box (like a slash command) | `.worldpvp status`, `.companion create ...` |
| **Bot chat command** | **`$`** | **whisper a bot**, or **say in party/raid chat** | `$follow`, `$summon`, `$talents spec arms` |

**⚠️ The `$` prefix is mandatory for bot orders on this build.** WL sets `AiPlayerbot.CommandPrefix = "$"`:
- A **plain whisper** to a bot (no `$`) → goes to **AI chat** (the bot talks back in character), it is **NOT** an order.
- A **`$`-prefixed** message (whisper or party/raid) → is an **order** (the `$` is stripped, the rest runs as a command).
- `$` was chosen because the core reserves `!` and `.` as GM-command prefixes.
- **Chaining:** multiple commands in one message separated by the configured command separator (`AiPlayerbot.CommandSeparator`).
- **Reply-channel prefixes** (after the `$`): `#w #p #r #a #g` force the bot to reply via whisper/party/raid/addon/guild.

So: **the addon sends `.` commands to the chat edit box as-is, and bot orders as `$<command>` to whisper or PARTY chat.** Tables in §4 list the bare word — send it as `$word`.

Permission tags below: **[P]** = any player (`SEC_PLAYER`), **[GM]** = GameMaster (`SEC_GAMEMASTER`).

**GM levels (AzerothCore — max is 3):** `0` player · `1` moderator · `2` **GameMaster** · `3` **administrator** (highest account level) · `4` console/RA (not assignable to a player account). WL `[GM]` commands require level **2+**; the repack's `admin` account is level **3**. Set with `.account set gmlevel <account> <0-3> <realmID|-1>` (relog to apply). *(This is the AzerothCore scale — not the 0–9 of other cores.)*

---

## 1. WoW Legends custom commands (dot-commands)

### 1.1 `.worldpvp` — all-zones World PvP control **[GM]** *(v1.1, RA/console too)*
Open-world PvP everywhere: enemy-faction players **and** the AI bots become attackable. Modes are set in `mod_wowlegends.conf` (`WorldPvP.Mode` = `always` | `timed`); these commands drive the **timed** mode.

| Command | Args | What it does |
|---|---|---|
| `.worldpvp start` | `[minutes]` | Open a PvP window now. Optional duration; omit = `Timed.DurationMinutes`. Only meaningful in `timed` mode. Saves nothing — runtime window. |
| `.worldpvp stop` | — | Close the current window. |
| `.worldpvp status` | — | Report: mode (off/always/timed), whether active, and time remaining / time to next window. |

### 1.2 `.wlevent` — World Events / Faction Battlefront control **[GM]** *(v1.1, RA/console too)*
A contested capture point in a curated zone; both factions fight over a war banner (tug-of-war), hold it to win. Auto-spawns on a timer when `WorldEvents.Enabled=1`, or start manually here.

| Command | Args | What it does |
|---|---|---|
| `.wlevent start` | `[zone\|index]` | Start a battlefront. No arg = random zone; or a zone **name** (keyword) / **1-based index** (see §5.5). |
| `.wlevent stop` | — | End the active battlefront. |
| `.wlevent status` | — | Report the active battlefront: Alliance%/Horde%, time left, and a `.go xyz` line to the banner. |
| `.wlevent zones` | — | List the 16 curated zones with their indices. |

**TP to a battlefront (admin):** `.wlevent status` prints a live `.go xyz` line to the current banner; to jump to any zone's fixed battlefront spot, use the per-zone `.go xyz` coordinates in **§5.5**.

### 1.3 `.xp` — per-character XP rate (mod-individual-xp) **[P]**
Each player controls their own XP rate, capped by the server max (default cap 10).

| Command | Args | What it does |
|---|---|---|
| `.xp view` | — | Show your current XP rate + the max allowed. |
| `.xp set` | `<rate>` | Set your XP rate (1 = blizzlike; up to the server cap). |
| `.xp enable` | — | Enable the individual-XP modifier for you. |
| `.xp disable` | — | Disable it (back to the realm default rate). |
| `.xp default` | — | Reset to the configured default. |

### 1.4 `.companion` — personal permanent battle-companion **[P]**
One companion per player; a bound bot that fights with you and remembers you in AI chat. Drive it like any bot (`$follow`, `$attack`, `$talents spec <name>`).

| Command | Args | What it does |
|---|---|---|
| `.companion` | — | Show your companion's status (or the help line if you have none). |
| `.companion create` | `<race> <class> <name>` | Claim your one companion. Race must match your faction; name 2–12 letters, unique. Auto-joins/follows/fights. e.g. `.companion create orc warrior Grommash`. Races/classes in §5.1/§5.4. |
| `.companion summon` | — | Recall it to your side. |
| `.companion dismiss` | — | Send it away temporarily (recall with `summon`). |
| `.companion forget` | — | Permanently release it (wipes memory, frees the pool char) so you can create a new one. |

### 1.5 `.gear` — quick-gear the target **[GM]**
Operates on a targeted bot/player (GM tool; players use `.companion` + addclass `init` tiers instead).

| Command | What it does |
|---|---|
| `.gear level` | Gear to the target's level (quest/dungeon-grade). |
| `.gear rare` | Full rare (blue) set. |
| `.gear epic` | Full epic (purple) set. |
| `.gear max` | Best available for the level. |
| `.gear undress` | Strip all gear. |

### 1.6 `.hardcore` + `.makgora` — permadeath **[P]**
| Command | What it does |
|---|---|
| `.hardcore on` | Opt this char into permadeath. **Level 1 only, irreversible.** Confirm by typing it **twice within 30s** (or use the Herald of the Fallen NPC). Blocked if realm-wide HC is on, opt-in disabled, already fallen/hardcore, or not level 1. |
| `.hardcore status` | Show your state: FALLEN / ACTIVE / normal. |
| `.makgora` | Arm a duel-to-the-death with your **targeted player**. Both must be hardcore, target each other, and **both type `.makgora`**; the next normal duel within 30s becomes lethal. Disabled if `Hardcore.Makgora=0`. |

### 1.7 `.path` — Paths of Legends **[P]/[GM]**

Opt-in, per-character challenge Paths sworn at the Herald of the Fallen NPC (every starting zone). A Path binds only the character that swears it. Players swear/forsake **at the Herald**; the command below is player STATUS plus three self-only GM test tools.

| Command | Tier | What it does |
|---|---|---|
| `.path` | [P] | Show every Path you've sworn and its status (`sworn` / `FULFILLED` / `WALKED` / `forsaken`; Long Road boss progress included). Example: `.path` |
| `.path swear <long/iron/pilgrim/slow>` | [GM] | TEST tool. Force-swears a Path on **yourself**, bypassing all guards (level, starting gear) and skipping the realm announce. Default `long`. Run `.path reset` before re-swearing the same Path. Example: `.path swear iron` |
| `.path credit` | [GM] | TEST tool. Quietly credits your next missing Long Road boss (whisper only). Requires an active Long Road on yourself. Example: `.path credit` |
| `.path reset` | [GM] | TEST tool. Wipes ALL of your own Path records (cache + database). Example: `.path reset` |

*In-game only (`Console::No`) — these do not run over RA/console.*

### 1.8 `.dc` — Dungeon Clear **[P]** *(v1.4.0, bundled mod-dungeon-clear; in-game only)*

A TANK BOT autonomously runs the dungeon for the group. Every command acts on the group's **elected leader tank bot** (lowest-GUID tank bot in a party; Main Tank / best-geared tank bot in a raid; a real-player tank is never eligible), and **any real player in that bot's group** may issue them — not master-only. No tank bot in the group → `No tank bot found in your group.`

**WL master gate:** `DungeonClear.Enable = 0` (in `mod_dungeon_clear.conf`) makes every dispatch subcommand refuse with `Dungeon clear is disabled on this server (DungeonClear.Enable).` — `.dc config` and `.dc spectate` have their own handlers (spectate has its own gate).

| Command | Params | What it does |
|---|---|---|
| `.dc on` | — | Start the autonomous clear. Tank announces `Dungeon clear enabled. Heading to <boss>.` Refusals (whispered): not in a dungeon / no boss table / `<Name> is dead — rez and try again.` |
| `.dc off` | — | Full stop + teardown; tank halts instantly; followers revert to following the player. |
| `.dc skip` | — | Skip the current objective. If a lever/prisoner-style gating event is due it retires THAT first; otherwise skips the boss and re-routes (auto-disables when nothing is left). |
| `.dc pause` | — | Toggle. Pause holds everyone in place, progress preserved (mid-combat: current fight finishes first). Same command resumes; resume refuses while anyone is dead. A run auto-paused at a closed door auto-resumes when a player opens it. |
| `.dc pull` | `[on\|off\|dynamic\|dyn]` | Trash pull mode: `on` = Advanced (camp-pull every pack), `off` = Leeroy (walk in, fight in place), `dynamic` = per-pack auto (recommended). No param = cycle Off → On → Dynamic. Works BEFORE `.dc on` too (pre-sets the mode; reply appends `(applies when dungeon clear starts)`). Example: `.dc pull dynamic` |
| `.dc status` | `[addon\|silent]` | One-liner: `Dungeon clear: on/off. Next boss: <name>. Skipped: <n>.` (+ ` Stalled: <reason>` when stuck). Works while the run is off. `addon`/`silent` suppresses the chat line. |
| `.dc bosses` | `[addon\|silent]` | Full roster for the dungeon: every boss/objective/event with position and live state (alive / dead / skipped), wing-aware, faction-filtered. Works while the run is off. |
| `.dc go <boss>` | name substring or creature entry (REQUIRED) | Route the tank straight to that boss: `.dc go herod`, `.dc go 3975`. Un-skips it, clears pause, re-routes, announces `Targeting boss: <name>. Navigating...`. **Dot-command/addon only — there is NO `$dc go` chat form.** |
| `.dc config` | — | Dumps every `DungeonClear.*` tunable as the module reads it THIS tick; `*` marks a live per-run addon override. Confirms conf edits without `.reload config`. |
| `.dc spectate` | — | Free-fly spectator camera on the ISSUER (possession dummy; character keeps playing under bot AI). In-dungeon only. Gate: `DungeonClear.SpectateEnable` (default 1); speed: `DungeonClear.SpectateSpeed` (0.5–8, default 2.5). Toggle off with the same command; auto-teardown on death/teleport/logout. |

**Chat forms** (`$dc ...`, whisper the tank or /party — only live while the bot is INSIDE a dungeon; the dot-commands work anywhere): `$dc on` (`$dungeon clear on`) · `$dc off` (`$dungeon clear off`) · `$dc skip` · `$dc pause` (`$dungeon clear pause`) · `$dc pull [on|off|dynamic|dyn]` · `$dc status [addon|silent]` · `$dc bosses [addon|silent]`. There is **no** `$dc go` / `$dc config` / `$dc spectate`, and do NOT document a `dungeon clear pull` long alias (registered upstream but inert).

**⚠️ Hidden-channel display note:** all non-error DC announcements are sent on the hidden addon channel (`LANG_ADDON` party messages, payload `DC\tCHAT\t<text>`) — on a stock client the tank appears silent; only error refusals arrive as visible whispers. The addon listens for the `DC` prefix and prints `CHAT` payloads to the chat frame as `[Dungeon Clear]` lines.

### 1.9 `.wlpaths` — Legend Roads + AI telemetry **[GM/ADMIN]** *(v1.4.0, console OK)*

Legend Roads is the world-wide road/path graph the bots walk (`BotPathways.*` conf keys, §6). The four world maps ship pre-built.

| Command | Security | What it does |
|---|---|---|
| `.wlpaths build <mapId>` | Administrator (3), console OK | Builds the Legend Roads graph for a WORLD map (0/1/530/571) as a chunked background job (~30 ms/tick — the server stays responsive; the conf.dist "freezes the world" comment is stale). Saves `<DataDir>/pathways/map<id>.wlp`, goes live immediately; restart later to release terrain grids. One job at a time. Example: `.wlpaths build 571` |
| `.wlpaths status` | Administrator (3), console OK | Prints `Pathways ON/OFF (all bots: yes/no), comfort N deg, climb xN, water xN`, build-job progress if running, and every loaded graph (`map 1: 205302 nodes, 615645 edges`). |
| `.aichat stats` | GameMaster (2), console OK | Pre-existing (v1.2.0) AI-chat telemetry. Since v1.4.0 the Today/Since-start lines also append `orders N / parse-miss N` when talk-and-command is on. |

---

## 2. Playerbot management (dot-commands, `.playerbots ...`)
There is **no bare `.bot` alias** — always `.playerbots bot ...`. [P] unless noted.

### 2.1 Build / manage your party (`.playerbots bot ...`)
| Command | What it does |
|---|---|
| `.playerbots bot list` | Your bots: online (`+`), your offline alts (`-`), randoms in group. |
| `.playerbots bot add <Name[,Name2,...]>` | Log the named char(s) in as **your** bot (you become master). No name = current target. Names are case-insensitive (since v1.4.0). Cap `MaxAddedBots` (40). |
| `.playerbots bot addaccount <Account\|CharName>` | Add **all** chars on that account as bots at once. |
| `.playerbots bot login <Name>` | Same path as `add`. |
| `.playerbots bot remove <Name>` | Remove/log out one of your bots. Aliases: `logout`, `rm`. |
| `.playerbots bot addclass <class> [male\|female\|0\|1]` | Summon a fresh pre-geared **disposable** class bot of your faction. Gated by `AddClassCommand=1` (default on) else [GM]. Classes in §5.1. |
| `.playerbots bot lookup` | List classes available for `addclass`. |
| `.playerbots bot init[=<tier>] <Name\|*\|!>` | **(addclass bots only)** Regear to a tier (§5.3). `*` = all in group, `!` = all (GM). Non-GM master + `AutoInitOnly=1` → only `init=auto`. |
| `.playerbots bot levelup` / `level` | Re-randomize at current level. |
| `.playerbots bot refresh` | Re-roll consumables/gear (`refresh=raid` unbinds instances). |
| `.playerbots bot random` | Full re-randomize. |
| `.playerbots bot quests` | Initialize instance quests. |
| `.playerbots bot initself[=<tier>]` | Regear **your own** char — **[GM]** only (players use `.gear`). |

### 2.2 Account linking (control a trusted friend's chars) — `.playerbots account ...`
The **only** legitimate way to command someone else's characters (NOT friending). Needs `AllowTrustedAccountBots=1`.
| Command | What it does |
|---|---|
| `.playerbots account setKey <key>` | Set a security key on your account so others can link. |
| `.playerbots account link <account> <key>` | Link to another account using its key → you can add its chars as bots. |
| `.playerbots account linkedAccounts` | List linked accounts. |
| `.playerbots account unlink <account>` | Remove a link. |

> **Control model (important for the addon):** a bot obeys only its **master** (whoever `add`ed it) or a **GM**. Friending a bot does NOT grant control (only the `BotActiveAloneForceWhenIsFriend` liveliness toggle). A GM can command **any** bot. "Unsecured" commands any nearby player may issue to any bot: `$who $wts $sendmail $invite $leave $lfg $pvp stats $rpg status`.

---

## 3. Roles & specs (bot chat — `$talents ...`)
A bot's **dungeon role (tank/heal/dps) = its spec.** Set roles by changing spec.

| Command | What it does |
|---|---|
| `$talents` | Report current spec + help. **The tree name it reports is NOT the name the set-command takes** (see below). |
| `$talents spec list` | List the bot's valid **premade** spec names, live from the server config. These exact strings are what `spec <name>` accepts. |
| `$talents spec <premadeName>` | Switch to a premade spec (**this is how you set tank/heal/dps**). `<premadeName>` is matched **exactly, case-sensitive, spaces included** against the `AiPlayerbot.PremadeSpecName.*` config names — e.g. `talents spec prot pve`. The friendly tree name fails: `talents spec protection` → *"Spec protection not found."* Full name map in §5.2. ⚠️ A spec change does NOT re-gear — follow with `$autogear` (the addon's Roles dropdown does both automatically). |
| `$talents switch <1\|2>` | Activate primary/secondary dual-spec (auto-trains dual spec for `2` if eligible). |
| `$talents autopick` | Auto-pick a full tree for the level. |
| `$talents apply <link>` | Apply a specific talent link. |

**Spec → role mapping** (tank/heal by class; everything else = DPS):
| Class | Tank spec | Heal spec |
|---|---|---|
| Warrior | Protection | — |
| Paladin | Protection | Holy |
| Death Knight | Blood | — |
| Druid | Feral *(needs Thick Hide)* | Restoration |
| Priest | — | Discipline / Holy |
| Shaman | — | Restoration |
| Hunter / Rogue / Mage / Warlock | — | — (always DPS) |

### Strategy toggles (advanced, bot chat)
| Command | What it does |
|---|---|
| `$co <list>` | Edit the **combat** strategy set. |
| `$nc <list>` | Edit the **non-combat** strategy set. |
| `$de <list>` | Edit the **dead-state** strategy set. |
`<list>` = comma-separated `+name` (add) / `-name` (remove) / `~name` (toggle) / `?` (list) / `!` (reset). e.g. `$co +heal,-flee`. `$cs <name> <idx> <command>` creates/edits a persisted custom strategy.

---

## 4. Bot chat commands (`$` — whisper a bot or say in party/raid)
**Prefix every command below with `$`.** Tables show the bare word; send `$word`. Whisper → that bot; party/raid → all your bots (they obey silently).

### Movement & positioning
| Cmd | Effect | | Cmd | Effect |
|---|---|---|---|---|
| `follow` | follow you | | `stay` | hold position |
| `flee` | fall back / flee | | `runaway` | run from the group |
| `grind` | resume roaming/grinding | | `move from group` | spread away |
| `disperse` | spread out | | `summon` | pull bot(s) to you (dungeons) |
| `home` | set/return home | | `go <where>` | travel to place/coords |
| `position [set]` | report/set formation pos | | `formation <name>` | set group formation |
| `taxi` | take a flight path | | `teleport` | teleport (e.g. to master) |
| `enter vehicle` / `leave vehicle` | mount/dismount vehicle | | | |

### Travel & guide *(v1.4.0)*
| Cmd | Effect |
|---|---|
| `hearthstone` | The bot really USES its Hearthstone (real, interruptible cast). In /party it's the whole squad's "everyone hearth" button. Silent if the stone is on cooldown or missing (the spoken `go home` order pre-checks and answers `My hearthstone is still cooling down.` instead). Skipped in battlegrounds. Distinct from the old `home` (which only SETS the hearth at an innkeeper). |
| `wl guide stop` | Cancel an active guide escort (`Alright, staying with you.`). `follow`, `stay` and `reset botAI` also cancel it. |
| `wl guide <mapId> <x> <y> <z> <zTol> [label...]` | The RAW escort command (internal/advanced — players never type this; the spoken Guide phrases in the Talk & Command section build it). |

### Dungeon Clear (`$dc ...`) *(v1.4.0)*
Whisper the tank or /party; only live while the bot is INSIDE a dungeon. Full behaviour, refusals and the hidden-channel note: **§1.8**.
`$dc on` (`$dungeon clear on`) · `$dc off` (`$dungeon clear off`) · `$dc skip` · `$dc pause` (`$dungeon clear pause`) · `$dc pull [on|off|dynamic|dyn]` · `$dc status [addon|silent]` · `$dc bosses [addon|silent]` — no `$dc go`/`config`/`spectate` (dot-command only).

### Combat
| Cmd | Effect |
|---|---|
| `attack` | attack current target |
| `pull` | pull target (`pull back`, `pull rti` variants) |
| `tank attack` | tank engages your target |
| `max dps` | maximum-DPS posture |
| `cast <spell> [target]` | cast a spell (`castnc <spell>` = non-combat) |
| `focus heal [targets]` | tell a healer which target(s) to prioritize |
| `save mana` / `drink` | conserve / restore mana |
| `rti [icon]` | set/report the focused raid-target icon |
| `rtsc` | real-time click control |
| `stance <name>` | warrior/druid stance or form |
| `cancel <form>` | druid: drop a form (tree/travel/bear/dire bear/cat/moonkin/aquatic) |
| `naxx` / `bwl` | apply a Naxx / BWL raid combat preset |
| *(info, whisper)* | `dps`, `target`, `attackers`, `spell [name]`, `spells`, `ss` |

### Pets
`tame [pet]` (hunter) · `pet` (manage/summon) · `pet attack`

### Gear & items (whisper)
| Cmd | Effect | | Cmd | Effect |
|---|---|---|---|---|
| `equip <item>` / `e` | equip linked item | | `unequip <item>` / `ue` | take off |
| `autogear` | best available | | `autogear bis` | best-in-slot |
| `equip upgrade` | equip inventory upgrades | | `use <item>` / `u` | use/consume |
| `open items` / `unlock items` | open lockboxes | | `destroy <item>` | destroy |
| `repair` | repair gear | | `craft <recipe>` | craft |
| `c [item]` / `items` / `inv` | report inventory | | `maintenance` | repair/sell housekeeping |

### Loot, trade, money, mail
| Cmd | Effect | | Cmd | Effect |
|---|---|---|---|---|
| `add all loot` / `loot all` | loot nearby (party ok) | | `ll` | loot strategy/list |
| `roll <pass\|need\|greed>` | loot-roll behaviour (party ok) | | `trade [item]` / `t` | trade |
| `nt [item]` | exclude from auto-trade | | `sell <item>` / `s` | sell to vendor |
| `buy <item>` / `b` | buy | | `reward <quest>` / `r` | choose quest reward |
| `wts [item]` | "want to sell" *(unsecured)* | | `bank` | bank |
| `gb` / `gbank` | guild bank | | `mail` / `sendmail <x>` | read / send mail *(sendmail unsecured)* |
| `emblems` | report badge currency | | | |

### Quests
`accept [quest]` · `talk` (turn in) · `quests` · `q [item/quest]` · `qi [item]` · `drop [quest]` · `share [quest]` · `clean quest log` · `rpg status` / `rpg do quest`

### Info & buffs (whisper)
`stats` · `who` · `rep`/`reputation` · `pvp stats` · `los` · `aura` · `range [v]`/`ra` · `buff [class]` · `glyphs` / `glyph equip` / `remove glyph`

### Group & guild
`invite` *(unsec)* · `join` · `leave` *(unsec)* · `give leader` · `lfg` *(unsec)* · `ginvite` · `guild promote`/`demote`/`remove`/`leave`

### Death & recovery
`release` (corpse run) · `revive` (spirit healer)

### Utility
`help` (bot whispers its full list) · `reset` / `reset botAI` · `chat` · `emote` · `calc <item>` · `wipe` / `ready` · `trainer` · `cheat <flags>` / `debug <sub>` / `log <level>` *(GM/debug)*

### Talk & Command — plain English, no `$` *(v1.4.0)*
Gate: `WowLegends.AiCommand.Enabled = 1` (**ships default 0**; ON on the PTR). The exact phrases below are deterministic — they work with NO AI backend configured; free-form sentences go through the LLM (order-vs-chat) only when a backend is set up. `$` commands always work regardless.

- **Whisper your own bot (no `$`):** `follow` / `stay` / `attack` / `flee` / `drink` / `eat` / `come here` / `go home` (pre-checks hearthstone CD) / `attack the <mob name>` (resolves against live enemies within 60 yds of YOU; sets your target). One whispered ack (`On it - right behind you.`) or an honest refusal (`Pulling is a tank's job - I'm not built for it.`).
- **Group-addressed (party/raid/say/yell):** `everyone follow me` · `all of you attack the kobold miner` · `bots go home` · `you guys stay here`. The group answers with ONE voice. Party-wide `home` and `grind` ask to be repeated within 45 s before obeying (drastic-order confirm). Gate: `WowLegends.AiCommand.PartyOrders.Enabled` (1).
- **The Guide (spoken escort):** `take me to / lead me to / guide me to / show me the way to <place>`. Destinations: teleport-catalog places (`booty bay`), dungeon entrances on the map, `my quest`, role NPCs (`an innkeeper`, `my trainer`, `a repair vendor`, `the auction house`, `a flight master`, `the bank`, `a stable master`), starting zones (`the troll starting zone`). Walks you there by road, yells if you fall behind, comes back for you. Same continent only (`That's beyond this land - we'd need a ship or zeppelin.`). Gates: `WowLegends.BotGuide.Enabled` (1) + AiCommand on. Zero LLM cost — fully deterministic.
- **The Sage (data-grounded answers):** plain whispers that are question-shaped and name a game entity — `who sells Refreshing Spring Water?` · `where is Mankrik?` · `price of the Bronze Tube?` · `what does [linked quest] reward?` — answered from real server data: items (prices, vendors + nearest one with direction), quests (giver, objective, rewards), NPCs (roles, nearest spawn). Gate: `WowLegends.AiChat.Sage.Enabled` (1); rides AI chat.

> **Not active in this build:** `hire` (trigger disabled — would crash), `logout` / `wait <sec>` as chat commands (commented out). Plain (non-`$`) whispers feed the AI chat / small-talk — unless they match a Talk & Command pattern above (with `AiCommand.Enabled=1`), in which case they are orders.

---

## 5. Option reference (for dropdowns)

### 5.1 Classes — `addclass` and `.companion create`
`warrior` · `paladin` · `hunter` · `rogue` · `priest` · `dk` *(also `deathknight`)* · `shaman` · `mage` · `warlock` · `druid`

### 5.2 Specs per class — `$talents spec <premadeName>` *(corrected 2026-07-15)*

**The command takes the PREMADE config name (send-as column), matched exactly — lowercase, spaces included.** The friendly tree names the bot *reports* (`protection`, `restoration`, …) are **not** accepted (`Spec protection not found`). Verified verbatim against the live PTR `playerbots.conf` (`AiPlayerbot.PremadeSpecName.<class>.<n>`); the conf is authoritative if a name ever changes — `$talents spec list` prints a bot's own live list. ⚠️ Spec change alone does NOT re-gear — follow with `$autogear`.

| Class | Send-as (label · role) |
|---|---|
| Warrior | `arms pve` (Arms · DPS) · `fury pve` (Fury · DPS) · `prot pve` (Protection · **Tank**) · `arms pvp` · `fury pvp` · `prot pvp` |
| Paladin | `holy pve` (Holy · **Healer**) · `prot pve` (Protection · **Tank**) · `ret pve` (Retribution · DPS) · `holy pvp` · `prot pvp` · `ret pvp` |
| Hunter *(all DPS)* | `bm pve` (Beast Mastery) · `mm pve` (Marksmanship) · `surv pve` (Survival) · `bm pvp` · `mm pvp` · `surv pvp` |
| Rogue *(all DPS)* | `as pve` (Assassination) · `combat pve` (Combat) · `subtlety pve` (Subtlety) · `as pvp` · `combat pvp` · `subtlety pvp` |
| Priest | `disc pve` (Discipline · **Healer**) · `holy pve` (Holy · **Healer**) · `shadow pve` (Shadow · DPS) · `disc pvp` · `holy pvp` · `shadow pvp` |
| Death Knight | `blood pve` · `frost pve` · `unholy pve` · `double aura blood pve` (Double Aura) · `blood pvp` · `frost pvp` · `unholy pvp` — *DKs tank in ANY tree (Frost Presence + gear), so no tank/dps tags here* |
| Shaman | `ele pve` (Elemental · DPS) · `enh pve` (Enhancement · DPS) · `resto pve` (Restoration · **Healer**) · `ele pvp` · `enh pvp` · `resto pvp` |
| Mage *(all DPS)* | `arcane pve` (Arcane) · `fire pve` (Fire) · `frost pve` (Frost) · `frostfire pve` (Frostfire, PvE only) · `arcane pvp` · `fire pvp` · `frost pvp` |
| Warlock *(all DPS)* | `affli pve` (Affliction) · `demo pve` (Demonology) · `destro pve` (Destruction) · `affli pvp` · `demo pvp` · `destro pvp` |
| Druid | `balance pve` (Balance · DPS) · `bear pve` (Feral Bear · **Tank**) · `cat pve` (Feral Cat · DPS) · `resto pve` (Restoration · **Healer**) · `balance pvp` · `cat pvp` · `resto pvp` — *no bear pvp* |

The addon's **Bots → Roles** dropdown drives all of this: pick a friendly label, it whispers the exact premade name and auto-runs `$autogear`.

### 5.3 `init=` tiers — `.playerbots bot init=<tier> <target>`
`auto` (scale to your gear) · `white`/`common` · `green`/`uncommon` · `blue`/`rare` · `purple`/`epic` · `legendary` · or a numeric **gearscore**. Target: a bot name, `*` (your group), `!` (all bots, GM).

### 5.4 Companion races — must match faction
- **Alliance:** human · dwarf · nightelf · gnome · draenei
- **Horde:** orc · undead · tauren · troll · bloodelf

### 5.5 World Events zones — `.wlevent start <zone|index>` + admin TP coords
Pass the zone **name** (keyword) or its **1-based index**; no arg = random. The TP column is the exact `.go xyz <x> <y> <z> <map>` to teleport an admin to that zone's battlefront spot.

| # | Zone | Map | TP (admin) |
|---|------|-----|------------|
| 1 | Westfall | 0 (EK) | `.go xyz -10235.2 1222.5 43.6 0` |
| 2 | Redridge Mountains | 0 | `.go xyz -9266.6 -2188.8 64.1 0` |
| 3 | Duskwood | 0 | `.go xyz -10573.0 -1182.5 28.0 0` |
| 4 | Arathi Highlands | 0 | `.go xyz -1508.5 -2732.1 32.5 0` |
| 5 | Hillsbrad Foothills | 0 | `.go xyz -853.2 -533.5 10.0 0` |
| 6 | The Hinterlands | 0 | `.go xyz 119.4 -3190.4 117.3 0` |
| 7 | Stranglethorn Vale | 0 | `.go xyz -12388.9 172.6 2.8 0` |
| 8 | Eastern Plaguelands | 0 | `.go xyz 2301.0 -4613.4 73.6 0` |
| 9 | The Barrens | 1 (Kalimdor) | `.go xyz -452.8 -2650.8 95.5 1` |
| 10 | Ashenvale | 1 | `.go xyz 1928.3 -2165.9 93.8 1` |
| 11 | Stonetalon Mountains | 1 | `.go xyz 1570.9 1031.5 138.0 1` |
| 12 | Desolace | 1 | `.go xyz -606.4 2211.8 93.0 1` |
| 13 | Thousand Needles | 1 | `.go xyz -4969.0 -1726.9 -62.1 1` |
| 14 | Feralas | 1 | `.go xyz -4841.2 1309.4 81.4 1` |
| 15 | Tanaris | 1 | `.go xyz -7177.1 -3785.3 8.4 1` |
| 16 | Dustwallow Marsh | 1 | `.go xyz -4043.6 -2991.3 36.4 1` |

*(These are the fixed zone spots the event uses; a live battlefront's exact banner location is also reported by `.wlevent status`.)*

---

## 6. Config-only features (no command — surface as info, not buttons)
These have **no in-game command**; they're `mod_wowlegends.conf` toggles (apply on restart / `.reload config`). Listed so the addon can show their state, not trigger them:
- **Auto-summon into dungeons** — `AutoSummonBots.Enabled` (1), `.DelayMs` (4000). Group bots auto-summon when the leader zones into a dungeon/raid.
- **Bot faction taunts** — `BotTaunts.Enabled` (0).
- **Smarter PvP targeting** (healers first) — `SmartPvpTargeting.Enabled` (1).
- **World PvP mode/schedule** — `WorldPvP.Enabled` (0), `.Mode` (always/timed), `.Timed.IntervalMinutes/DurationMinutes/Announce`.
- **World Events schedule/tuning** — `WorldEvents.Enabled` (0) + interval/radius/weights/rewards/zone-spawn knobs.
- **Paths of Legends** — sworn at the Herald NPC (§1.7): `WowLegends.Paths.Enabled` (1), `.MaxLevelToSwear` (4), `.Announce` (1), `.AllowAbandon` (1), `.Trophies.Enabled` (1), `.HeraldHonors.Enabled` (1); per-Path `.LongRoad/.IronOath/.PilgrimsWay/.SlowBurn.Enabled` (1).
- **Talk-and-command** (plain-English orders, §4) — `WowLegends.AiCommand.Enabled` (**0 — ships OFF**; ON on the PTR), `WowLegends.AiCommand.PartyOrders.Enabled` (1), `WowLegends.BotGuide.Enabled` (1, the Guide), `WowLegends.AiChat.Sage.Enabled` (1, the Sage).
- **Legend Roads** (bot road-walking, §1.9) — `BotPathways.Enabled` (1), `.AllBots` (1), `.MaxSlopeDegrees` (20, range 5–45, baked into built data), `.ClimbWeight` (10, 0–100, baked), `.WaterCostFactor` (5, 1–50, live).
- **Bot behaviour polish (v1.4.0, zero commands)** — `TriageHealer.Enabled` (1, healers prioritize real players), `VoiceCards.Enabled` (1, per-bot personalities), `SpeechGovernor.Enabled` (1, anti chat-spam), `AiChat.NoTrailingQuestions` (1).
- **Dungeon Clear** — `mod_dungeon_clear.conf` (NEW FILE): `DungeonClear.Enable` (1, WL master switch) + ~30 upstream keys (pull tuning, rest targets, loot floor, `SpectateEnable`, `SpectateSpeed`…). Inspect live values with `.dc config` (§1.8).
- **Realm MOTD** — NOT a config: it's the `motd` table in the auth DB; change with `.server set motd enUS <text>` (core command).

---

## 7. Addon-builder notes
- Send **dot-commands** to the chat edit box verbatim (`.worldpvp start 10`).
- Send **bot orders** as `$<command>` to **whisper** (one bot) or **PARTY/RAID chat** (all your bots). Never send a bot order without the `$` — it'd post as normal chat / AI-chat.
- A GM sees/uses everything; gate **[GM]** buttons behind the player's GM status (the server still enforces it).
- **Dungeon Clear announcements are invisible without a listener** (§1.8): register for `CHAT_MSG_ADDON` prefix `DC` and print `CHAT\t<text>` payloads to the chat frame (errors already arrive as normal whispers). Richer payloads (`STATUS\t…`, `BOSS\t…`) exist on the same prefix for a future status panel.
- Good panels: **Party builder** (addclass per class + "Summon all" → party `$summon`), **Role setter** (`$talents spec <name>` per bot, auto-pick by class via §3 mapping), **Combat bar** (`$attack`/`$tank attack`/`$pull`/`$max dps`/`$flee`/`$focus heal`), **GM Events** (`.worldpvp start/stop/status`, `.wlevent start <zone>/stop/status` with the §5.5 zone dropdown), **Companion** (`.companion create/summon/dismiss/forget`).
- Core/standard AzerothCore GM commands (`.tele`, `.go`, `.modify`, `.npc`, `.lookup`, `.ban`, `.account`, `.server`, …) are unchanged from AzerothCore — pull those from the AC wiki; this doc covers only WL-custom + playerbot + the `$` bot orders.
