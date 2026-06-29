-- WoWLegends_GM/UI/Tabs/Server.lua
-- Server operations: broadcasts & notifications, world status, lifecycle
-- (shutdown/restart), DB hot-reloads, game events, and character/world saves.
-- The Search tab covers the full .reload table list; this is the curated set.

local addonName, WLGM = ...

-- intro paragraph + a list of command rows, auto-columned inside a scroll.
local function section(info, rows)
    return function(parent)
        WLGM.BuildScrollSections(parent, { { rows = rows } }, info)
    end
end

-- ─── Announce / notify ─────────────────────────────────────────────────────
local Announce = {
    { id="announce", label="Announce (chat)", format=".announce %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Send a global message to every online player's chat log." },
    { id="nameannounce", label="Announce w/ name", format=".nameannounce %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Global chat announcement that also shows the sender's name." },
    { id="notify", label="Notify (on-screen)", format=".notify %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Flash a global message on the middle of every player's screen." },
    { id="gmannounce", label="GM announce", format=".gmannounce %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Send an announcement to online Game Masters only." },
    { id="gmnameannounce", label="GM announce w/ name", format=".gmnameannounce %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Announce to online GMs, displaying the sender's name." },
    { id="gmnotify", label="GM notify (on-screen)", format=".gmnotify %s", level=2, group="Server",
      args={ {key="msg",placeholder="message",width=260} },
      tooltip="Flash an on-screen notification to all online GMs." },
    { id="ab_add", label="Autobroadcast add", format=".autobroadcast add %s %s", level=3, group="Server",
      args={ {key="weight",placeholder="weight",numeric=true,width=80}, {key="text",placeholder="text",width=200} },
      tooltip="Add a recurring autobroadcast line with the given weight (relative frequency) and text." },
    { id="ab_list", label="Autobroadcast list", format=".autobroadcast list", level=2, group="Server",
      tooltip="List all configured autobroadcast entries with their IDs." },
    { id="ab_remove", label="Autobroadcast remove", format=".autobroadcast remove %s", level=3, group="Server", danger=true,
      args={ {key="id",placeholder="id",numeric=true,width=80} },
      tooltip="Remove the autobroadcast entry with the given ID (and its locale rows)." },
}

-- ─── Status / world settings ───────────────────────────────────────────────
local Status = {
    { id="srv_info", label="Server info", format=".server info", level=0, group="Server",
      tooltip="Show the server version and the current number of connected players." },
    { id="srv_motd", label="Show MOTD", format=".server motd", level=0, group="Server",
      tooltip="Display the realm's current Message of the Day." },
    { id="srv_setmotd", label="Set MOTD", format=".server set motd %s", level=3, group="Server",
      args={ {key="motd",placeholder="message of the day",width=260} },
      tooltip="Set the realm's Message of the Day for the current realm (enUS).\nFull syntax: .server set motd [realmId] [locale] <MOTD>  (realmId -1 = all realms)." },
    { id="srv_setclosed", label="Set world closed", format=".server set closed %s", level=4, group="Server", danger=true,
      args={ {key="state",placeholder="on / off",width=90} },
      tooltip="Open or close the world to new client connections. 'on' blocks new logins; 'off' reopens." },
    { id="srv_loglevel", label="Set log level", format=".server set loglevel %s %s %s", level=4, group="Server",
      args={ {key="facility",placeholder="appender|logger",width=130}, {key="name",placeholder="name",width=110}, {key="level",placeholder="0-6",numeric=true,width=60} },
      tooltip="Change a log facility's verbosity at runtime.\nfacility: appender (a) or logger (l).\nlevel: 0 disabled, 1 trace, 2 debug, 3 info, 4 warn, 5 error, 6 fatal." },
    { id="srv_corpses", label="Expire corpses", format=".server corpses", level=2, group="Server",
      tooltip="Trigger an immediate corpse-expiry check across the world." },
    { id="srv_debug", label="Server debug info", format=".server debug", level=3, group="Server",
      tooltip="Show detailed server setup info (build, paths, threads) - handy for bug reports." },
}

-- ─── Lifecycle (all destructive) ───────────────────────────────────────────
local Lifecycle = {
    { id="srv_shutdown", label="Shutdown", format=".server shutdown %s %s", level=3, group="Server", danger=true,
      args={ {key="delay",placeholder="e.g. 1h15m30s",width=120}, {key="code",placeholder="exit code (opt)",numeric=true,optional=true,width=110} },
      tooltip="Shut the world server down after <delay>. Delay is a timestring like 1h15m30s. Optional exit code (default 0)." },
    { id="srv_shutdown_cancel", label="Cancel shutdown", format=".server shutdown cancel", level=3, group="Server",
      tooltip="Cancel a pending shutdown/restart timer." },
    { id="srv_restart", label="Restart", format=".server restart %s", level=3, group="Server", danger=true,
      args={ {key="delay",placeholder="e.g. 1h15m30s",width=120} },
      tooltip="Restart the world server after <delay> (timestring, e.g. 5m). Exit code 2." },
    { id="srv_restart_cancel", label="Cancel restart", format=".server restart cancel", level=3, group="Server",
      tooltip="Cancel a pending shutdown/restart timer." },
    { id="srv_idleshutdown", label="Idle shutdown", format=".server idleshutdown %s %s", level=4, group="Server", danger=true,
      args={ {key="delay",placeholder="e.g. 1h15m30s",width=120}, {key="code",placeholder="exit code (opt)",numeric=true,optional=true,width=110} },
      tooltip="Shut down after <delay> only if no players are connected. Delay is a timestring; optional exit code (default 0)." },
    { id="srv_idleshutdown_cancel", label="Cancel idle shutdown", format=".server idleshutdown cancel", level=3, group="Server",
      tooltip="Cancel a pending idle shutdown/restart timer." },
    { id="srv_idlerestart", label="Idle restart", format=".server idlerestart %s", level=4, group="Server", danger=true,
      args={ {key="delay",placeholder="e.g. 1h15m30s",width=120} },
      tooltip="Restart after <delay> only if no players are connected. Delay is a timestring. Exit code 2." },
    { id="srv_idlerestart_cancel", label="Cancel idle restart", format=".server idlerestart cancel", level=3, group="Server",
      tooltip="Cancel a pending idle restart/shutdown timer." },
    { id="srv_exit", label="Exit NOW", format=".server exit", level=4, group="Server", danger=true,
      tooltip="Terminate the server IMMEDIATELY with exit code 0. No delay, no warning - use with care." },
}

-- ─── Reload (curated common DB hot-reloads) ────────────────────────────────
local Reload = {
    { id="rl_config", label="config", format=".reload config", level=3, group="Server", danger=true,
      tooltip="Re-read worldserver.conf. Note: many settings only apply at restart; some are ignored or rejected on reload." },
    { id="rl_creature_template", label="creature_template", format=".reload creature_template %s", level=3, group="Server", danger=true,
      args={ {key="entry",placeholder="entry",numeric=true,width=90} },
      tooltip="Reload a single creature's template by entry from the database." },
    { id="rl_item_template", label="item_template", format=".reload item_template_locale", level=3, group="Server", danger=true,
      tooltip="Reload item template locale data from the database." },
    { id="rl_quest_template", label="quest_template", format=".reload quest_template", level=3, group="Server", danger=true,
      tooltip="Reload the quest_template table from the database." },
    { id="rl_gobject_template", label="gameobject_template", format=".reload gameobject_template_locale", level=3, group="Server", danger=true,
      tooltip="Reload gameobject template locale data from the database." },
    { id="rl_smart_scripts", label="smart_scripts", format=".reload smart_scripts", level=3, group="Server", danger=true,
      tooltip="Reload the smart_scripts table - apply SmartAI changes without a restart." },
    { id="rl_creature_text", label="creature_text", format=".reload creature_text", level=3, group="Server", danger=true,
      tooltip="Reload the creature_text table (NPC say/yell/emote lines)." },
    { id="rl_conditions", label="conditions", format=".reload conditions", level=3, group="Server", danger=true,
      tooltip="Reload the conditions table." },
    { id="rl_gossip_menu", label="gossip_menu", format=".reload gossip_menu", level=3, group="Server", danger=true,
      tooltip="Reload the gossip_menu table." },
    { id="rl_gossip_option", label="gossip_menu_option", format=".reload gossip_menu_option", level=3, group="Server", danger=true,
      tooltip="Reload the gossip_menu_option table." },
    { id="rl_npc_vendor", label="npc_vendor", format=".reload npc_vendor", level=3, group="Server", danger=true,
      tooltip="Reload the npc_vendor table (vendor inventories)." },
    { id="rl_creature_loot", label="creature_loot_template", format=".reload creature_loot_template", level=3, group="Server", danger=true,
      tooltip="Reload the creature_loot_template table." },
    { id="rl_all_spell", label="all spell_*", format=".reload all spell", level=3, group="Server", danger=true,
      tooltip="Reload all reload-safe spell_* tables in one go." },
    { id="rl_smart_note", label="Need another table?", format=".reload", level=3, group="Server",
      tooltip="Type .reload on its own (or use the Search tab) to see the full list of reloadable tables - dozens more loot/locale/script tables are supported." },
}

-- ─── Events ────────────────────────────────────────────────────────────────
local Events = {
    { id="ev_activelist", label="Active events", format=".event activelist", level=2, group="Server",
      tooltip="List the game events currently active in the world." },
    { id="ev_info", label="Event info", format=".event info %s", level=2, group="Server",
      args={ {key="id",placeholder="event id (opt)",numeric=true,optional=true,width=110} },
      tooltip="Show information about a game event by ID (or all events if blank)." },
    { id="ev_start", label="Start event", format=".event start %s", level=2, group="Server",
      args={ {key="id",placeholder="event id",numeric=true,width=100} },
      tooltip="Start event #id now (not saved to DB - reverts on restart)." },
    { id="ev_stop", label="Stop event", format=".event stop %s", level=2, group="Server",
      args={ {key="id",placeholder="event id",numeric=true,width=100} },
      tooltip="Stop event #id now (not saved to DB - reverts on restart)." },
}

-- ─── Save ──────────────────────────────────────────────────────────────────
local Save = {
    { id="saveall", label="Save all characters", format=".saveall", level=2, group="Server",
      tooltip="Force-save every online character to the database immediately." },
    { id="pdump_write", label="pdump write", format=".pdump write %s %s", level=3, group="Server",
      args={ {key="file",placeholder="filename",width=150}, {key="who",placeholder="name or GUID",width=150} },
      tooltip="Export a character to a dump file. .pdump write <filename> <playerNameOrGUID>" },
    { id="pdump_load", label="pdump load", format=".pdump load %s %s %s %s", level=3, group="Server", danger=true,
      args={ {key="file",placeholder="filename",width=140}, {key="acct",placeholder="account",width=120},
             {key="newname",placeholder="new name (opt)",optional=true,width=120}, {key="newguid",placeholder="new GUID (opt)",numeric=true,optional=true,width=110} },
      tooltip="Import a character from a dump file into an account. .pdump load <filename> <account> [newname] [newguid]" },
    { id="pdump_copy", label="pdump copy", format=".pdump copy %s %s %s %s", level=3, group="Server", danger=true,
      args={ {key="who",placeholder="name or GUID",width=140}, {key="acct",placeholder="account",width=120},
             {key="newname",placeholder="new name (opt)",optional=true,width=120}, {key="newguid",placeholder="new GUID (opt)",numeric=true,optional=true,width=110} },
      tooltip="Copy an existing character into another account. .pdump copy <playerNameOrGUID> <account> [newname] [newguid]" },
}

WLGM.RegisterTab({
    id = "server", label = "Server",
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Announce",  builder = section(
                "Broadcast to players or GMs - global chat, on-screen flash, or recurring autobroadcasts.",
                Announce, { rowsPerColumn = 6, columnWidth = 430 }) },
            { label = "Status",    builder = section(
                "Inspect and tune the running world: version/player count, MOTD, log level, and the open/closed gate.",
                Status) },
            { label = "Lifecycle", builder = section(
                "Schedule or cancel shutdowns and restarts - every command here stops or interrupts the world. Delays are timestrings like 1h15m30s.",
                Lifecycle, { rowsPerColumn = 8, columnWidth = 430 }) },
            { label = "Reload",    builder = section(
                "Hot-reload DB tables so edits apply without a restart. Curated common tables below; .reload on its own lists them all.",
                Reload, { rowsPerColumn = 7, columnWidth = 430 }) },
            { label = "Events",    builder = section(
                "Control game events at runtime. Start/stop are live-only and revert on restart (not saved to the DB).",
                Events) },
            { label = "Save",      builder = section(
                "Persist characters: force-save everyone online, or export/import individual characters via pdump.",
                Save) },
        }, "server")
    end,
})
