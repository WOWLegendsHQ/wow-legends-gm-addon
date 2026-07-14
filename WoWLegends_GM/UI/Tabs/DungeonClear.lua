-- WoWLegends_GM/UI/Tabs/DungeonClear.lua
-- Dungeon Clear (mod-dungeon-clear, v1.4.0): a TANK BOT runs the dungeon for
-- the group while the players play followers. All commands are player-level
-- (.dc ..., in-game only) and act on the group's elected leader tank bot.
-- Authored from GM_COMMANDS.md section 1.8.

local addonName, WLGM = ...

-- ─── Hidden-channel listener ────────────────────────────────────────────────
-- All non-error DC announcements are sent as LANG_ADDON party messages with
-- payload "DC\tCHAT\t<text>" — invisible on a stock client (only error refusals
-- arrive as normal whispers). The wire payload splits at the first tab, so the
-- event delivers prefix="DC", message="CHAT\t<text>". Print those to chat so
-- the tank's progress is actually visible. Registered at file level: it works
-- whether or not the panel is ever opened.
local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:SetScript("OnEvent", function(_, _, prefix, message, _, sender)
    if prefix ~= "DC" or type(message) ~= "string" then return end
    local text = message:match("^CHAT\t(.+)$")
    if text then
        DEFAULT_CHAT_FRAME:AddMessage(WLGM.colors.accent .. "[Dungeon Clear]" .. WLGM.colors.reset
            .. (sender and sender ~= "" and (" " .. WLGM.colors.brand .. sender .. WLGM.colors.reset .. ":") or "")
            .. " " .. text)
    end
end)

-- ─── Command rows (all SEC_PLAYER; the server enforces the rest) ────────────
local RunControl = {
    { id="dc_on", label="Start clear", format=".dc on", level=0, group="DungeonClear",
      tooltip="Start the autonomous clear. The tank announces 'Dungeon clear enabled. Heading to <boss>.'\nRefusals are whispered: not in a dungeon / no boss table for this map / '<Name> is dead - rez and try again.'" },
    { id="dc_off", label="Stop clear", format=".dc off", level=0, group="DungeonClear",
      tooltip="Full stop + teardown. The tank halts instantly; followers revert to following you." },
    { id="dc_pause", label="Pause / resume", format=".dc pause", level=0, group="DungeonClear",
      tooltip="Toggle. Pause holds everyone in place with progress preserved (mid-combat: the current fight finishes first). The same command resumes; resume refuses while anyone is dead.\nA run auto-paused at a closed door resumes itself when a player opens the door." },
    { id="dc_skip", label="Skip objective", format=".dc skip", level=0, group="DungeonClear",
      tooltip="Skip the current objective. If a lever/prisoner-style gating event is due it retires THAT first; otherwise skips the boss and re-routes (auto-disables when nothing is left)." },
    { id="dc_pull", label="Pull mode", format=".dc pull %s", level=0, group="DungeonClear",
      args={ { key="mode", placeholder="mode (opt)", choices={"dynamic","on","off"}, optional=true, width=110 } },
      tooltip="Trash pull mode: on = Advanced (camp-pull every pack), off = Leeroy (walk in, fight in place), dynamic = per-pack auto (recommended).\nLeave unset to cycle Off -> On -> Dynamic. Works BEFORE starting too (pre-sets the mode for the next run)." },
    { id="dc_go", label="Go to boss", format=".dc go %s", level=0, group="DungeonClear",
      args={ { key="boss", placeholder="name or entry", width=140 } },
      tooltip="Route the tank straight to that boss - name substring or creature entry, e.g. '.dc go herod' or '.dc go 3975'.\nUn-skips it, clears pause, re-routes, announces 'Targeting boss: <name>. Navigating...'.\nDot-command/addon only - there is no $dc go chat form." },
}

local Info = {
    { id="dc_status", label="Status", format=".dc status", level=0, group="DungeonClear",
      tooltip="One-liner: 'Dungeon clear: on/off. Next boss: <name>. Skipped: <n>.' (+ ' Stalled: <reason>' when stuck).\nWorks while the run is off. ('.dc status addon' suppresses the chat line for addons.)" },
    { id="dc_bosses", label="List bosses", format=".dc bosses", level=0, group="DungeonClear",
      tooltip="Full roster for the dungeon: every boss/objective/event with position and live state (alive / dead / skipped), wing-aware and faction-filtered.\nWorks while the run is off." },
    { id="dc_config", label="Show config", format=".dc config", level=0, group="DungeonClear",
      tooltip="Dump every DungeonClear.* tunable as the module reads it THIS tick; '*' marks a live per-run addon override.\nConfirms conf edits without .reload config." },
}

local Spectate = {
    { id="dc_spectate", label="Spectate toggle", format=".dc spectate", level=0, group="DungeonClear",
      tooltip="Free-fly spectator camera on YOURSELF while your character keeps playing under bot AI. In-dungeon only; the same command toggles it off; auto-teardown on death, teleport or logout.\nServer gates: DungeonClear.SpectateEnable (default 1), DungeonClear.SpectateSpeed 0.5-8 (default 2.5)." },
}

WLGM.RegisterTab({
    id = "dungeonclear", label = "Dungeon Clear",
    builder = function(parent)
        WLGM.BuildScrollSections(parent, {
            { title = "Run control", rows = RunControl },
            { title = "Info & status", rows = Info },
            { title = "Spectate", rows = Spectate },
        },
        "A TANK BOT runs the dungeon for the group while you play a follower. Commands act on the group's elected leader tank bot "
        .. "(lowest-GUID tank bot in a party; Main Tank / best-geared tank bot in a raid; a real-player tank is never eligible) - "
        .. "ANY real player in that bot's group may issue them. No tank bot in the group -> 'No tank bot found in your group.'\n"
        .. "Chat works too while INSIDE the dungeon: whisper the tank (or /party) $dc on/off/pause/skip/pull/status/bosses. "
        .. "The tank's progress announcements ride a hidden addon channel - this addon prints them to your chat as [Dungeon Clear] lines automatically.\n"
        .. "Server master switch: DungeonClear.Enable in mod_dungeon_clear.conf (default on).")
    end,
})
