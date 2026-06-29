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

Source-verified against the v1.1.0 build (2026-06-29). This is the authoritative list for building the GM addon: every WL custom command, every playerbot command, the bot chat (`$`) commands, World PvP, World Events (with zones), and XP — plus the option lists for dropdowns.

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

---

## 2. Playerbot management (dot-commands, `.playerbots ...`)
There is **no bare `.bot` alias** — always `.playerbots bot ...`. [P] unless noted.

### 2.1 Build / manage your party (`.playerbots bot ...`)
| Command | What it does |
|---|---|
| `.playerbots bot list` | Your bots: online (`+`), your offline alts (`-`), randoms in group. |
| `.playerbots bot add <Name[,Name2,...]>` | Log the named char(s) in as **your** bot (you become master). No name = current target. Cap `MaxAddedBots` (40). |
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
| `$talents` | Report current spec + help. |
| `$talents spec list` | List the class's premade specs with point spreads. |
| `$talents spec <name>` | Switch to a named spec (must match the list). **This is how you set tank/heal/dps.** Specs in §5.2. |
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

> **Not active in this build:** `hire` (trigger disabled — would crash), `logout` / `wait <sec>` as chat commands (commented out). Plain (non-`$`) whispers feed the AI chat / small-talk, not commands.

---

## 5. Option reference (for dropdowns)

### 5.1 Classes — `addclass` and `.companion create`
`warrior` · `paladin` · `hunter` · `rogue` · `priest` · `dk` *(also `deathknight`)* · `shaman` · `mage` · `warlock` · `druid`

### 5.2 Specs per class — `$talents spec <name>`
| Class | Specs |
|---|---|
| Warrior | arms, fury, protection |
| Paladin | holy, protection, retribution |
| Hunter | beast mastery, marksmanship, survival |
| Rogue | assasination *(one 's' in-engine)*, combat, subtlety |
| Priest | discipline, holy, shadow |
| Death Knight | blood, frost, unholy |
| Shaman | elemental, enhancement, restoration |
| Mage | arcane, fire, frost |
| Warlock | affliction, demonology, destruction |
| Druid | balance, feral combat, restoration |

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
- **Realm MOTD** — NOT a config: it's the `motd` table in the auth DB; change with `.server set motd enUS <text>` (core command).

---

## 7. Addon-builder notes
- Send **dot-commands** to the chat edit box verbatim (`.worldpvp start 10`).
- Send **bot orders** as `$<command>` to **whisper** (one bot) or **PARTY/RAID chat** (all your bots). Never send a bot order without the `$` — it'd post as normal chat / AI-chat.
- A GM sees/uses everything; gate **[GM]** buttons behind the player's GM status (the server still enforces it).
- Good panels: **Party builder** (addclass per class + "Summon all" → party `$summon`), **Role setter** (`$talents spec <name>` per bot, auto-pick by class via §3 mapping), **Combat bar** (`$attack`/`$tank attack`/`$pull`/`$max dps`/`$flee`/`$focus heal`), **GM Events** (`.worldpvp start/stop/status`, `.wlevent start <zone>/stop/status` with the §5.5 zone dropdown), **Companion** (`.companion create/summon/dismiss/forget`).
- Core/standard AzerothCore GM commands (`.tele`, `.go`, `.modify`, `.npc`, `.lookup`, `.ban`, `.account`, `.server`, …) are unchanged from AzerothCore — pull those from the AC wiki; this doc covers only WL-custom + playerbot + the `$` bot orders.
