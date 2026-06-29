-- WoWLegends_GM/UI/Tabs/General.lua
-- GM quality-of-life: state toggles (GM mode, cheats), self-modification
-- (morph, scale, speed) and assorted utility commands. Authored from the
-- General command slice. The Search tab covers the long tail.

local addonName, WLGM = ...

-- ─── Toggles: GM mode + cheats ─────────────────────────────────────────────
local GMmode = {
    { id="gm_on", label="GM mode on", format=".gm on", level=1, group="General",
      tooltip="Turn on the GM flag." },
    { id="gm_off", label="GM mode off", format=".gm off", level=1, group="General",
      tooltip="Turn off the GM flag." },
    { id="gm_fly", label="GM fly", format=".gm fly %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70} }, tooltip="Enable or disable GM fly mode." },
    { id="gm_visible", label="GM visible", format=".gm visible %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70} },
      tooltip="Make yourself visible (on) or invisible (off) to other players." },
    { id="gm_chat", label="GM chat badge", format=".gm chat %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Show/hide the GM badge in your chat messages. Blank = show current state." },
    { id="gm_ingame", label="GMs in game", format=".gm ingame", level=0, group="General",
      tooltip="List the Game Masters currently online." },
    { id="gm_list", label="List GM accounts", format=".gm list", level=3, group="General",
      tooltip="List all Game Master accounts and their security levels." },
}

local Cheats = {
    { id="cheat_god", label="God mode", format=".cheat god %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Make yourself invulnerable. Blank = toggle/show state." },
    { id="cheat_power", label="No power cost", format=".cheat power %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Remove spell costs (mana, energy, rage...)." },
    { id="cheat_cooldown", label="No cooldown", format=".cheat cooldown %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Disable spell cooldowns." },
    { id="cheat_casttime", label="No cast time", format=".cheat casttime %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Remove spell casting times (instant cast)." },
    { id="cheat_waterwalk", label="Water walk", format=".cheat waterwalk %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70} },
      tooltip="Walk on water (self or selected character)." },
    { id="cheat_taxi", label="All taxi routes", format=".cheat taxi %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70} },
      tooltip="Temporarily grant access to all flight paths for the selected character (self if none)." },
    { id="cheat_explore", label="Explore maps", format=".cheat explore %s", level=2, group="General",
      args={ {key="flag",placeholder="1=reveal 0=hide",numeric=true,width=110} },
      tooltip="Reveal (1) or hide (0) all maps for the selected character, or yourself if none." },
    { id="cheat_status", label="Cheat status", format=".cheat status", level=2, group="General",
      tooltip="Show which cheats you currently have enabled." },
}

local function togglesBuilder(parent)
    WLGM.BuildScrollSections(parent, {
        { title = "GM mode", rows = GMmode },
        { title = "Cheats",  rows = Cheats },
    })
end

-- ─── Modify Self: morph, mount, scale, speed ───────────────────────────────
local Appearance = {
    { id="morph_target", label="Morph target", format=".morph target %s", level=1, group="General",
      args={ {key="displayid",placeholder="displayId",numeric=true,width=100} },
      tooltip="Change the selected target's model to the given display ID (self if none)." },
    { id="morph_reset", label="Demorph", format=".morph reset", level=1, group="General",
      tooltip="Reset the selected target's model back to normal." },
    { id="morph_mount", label="Morph mount", format=".morph mount %s", level=1, group="General",
      args={ {key="displayid",placeholder="displayId",numeric=true,width=100} },
      tooltip="Change the selected target's mount model to the given display ID." },
    { id="dismount", label="Dismount", format=".dismount", level=0, group="General",
      tooltip="Dismount yourself if you are mounted." },
    { id="modify_scale", label="Scale", format=".modify scale %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 10",numeric=true,width=90} },
      tooltip="Resize the selected player/creature (self if none). Rate 0.1 to 10; 1 = normal." },
}

local Speed = {
    { id="speed_all", label="Speed: all", format=".modify speed all %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set all movement speeds (run, swim, back) of the selected player (self if none). 1 = normal." },
    { id="speed_run", label="Speed: run", format=".modify speed %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set running speed of the selected player (self if none). 1 = normal." },
    { id="speed_walk", label="Speed: walk", format=".modify speed walk %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set walk speed of the selected player (self if none). 1 = normal." },
    { id="speed_backwalk", label="Speed: backwalk", format=".modify speed backwalk %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set backward-running speed of the selected player (self if none). 1 = normal." },
    { id="speed_swim", label="Speed: swim", format=".modify speed swim %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set swim speed of the selected player (self if none). 1 = normal." },
    { id="speed_fly", label="Speed: fly", format=".modify speed fly %s", level=2, group="General",
      args={ {key="rate",placeholder="0.1 - 50",numeric=true,width=90} },
      tooltip="Set flying speed of the selected player (self if none). 1 = normal." },
}

local function modifyBuilder(parent)
    WLGM.BuildScrollSections(parent, {
        { title = "Appearance", rows = Appearance },
        { title = "Speed",      rows = Speed },
    })
end

-- ─── Utility ───────────────────────────────────────────────────────────────
local Info = {
    { id="gps", label="GPS", format=".gps %s", level=1, group="General",
      args={ {key="name",placeholder="player (opt)",fallback="target",optional=true,width=130} },
      tooltip="Show position (X, Y, Z, orientation, map, zone) for the selected unit or named player." },
    { id="commands", label="Commands", format=".commands", level=0, group="General",
      tooltip="List the commands available for your account level." },
    { id="possess", label="Possess", format=".possess", level=2, group="General",
      tooltip="Possess the selected creature indefinitely." },
    { id="unpossess", label="Unpossess", format=".unpossess", level=2, group="General",
      tooltip="Stop possessing: release yourself or the current possessed target." },
    { id="bindsight", label="Bind sight", format=".bindsight", level=3, group="General",
      tooltip="Bind your vision to the selected unit indefinitely. Cannot be used while possessing." },
    { id="unbindsight", label="Unbind sight", format=".unbindsight", level=3, group="General",
      tooltip="Remove bound vision. Cannot be used while possessing." },
}

local Tags = {
    { id="bm", label="Beastmaster", format=".bm %s", level=2, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Enable/disable in-game Beastmaster mode. Blank = show current state." },
    { id="commentator", label="Commentator", format=".commentator %s", level=1, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Enable/disable the in-game Commentator tag. Blank = show current state." },
    { id="dev", label="Dev tag", format=".dev %s", level=3, group="General",
      args={ {key="state",placeholder="on/off",width=70,optional=true} },
      tooltip="Enable/disable the in-game Dev tag. Blank = show current state." },
    { id="settings_announcer", label="Announcer", format=".settings announcer %s %s", level=1, group="General",
      args={ {key="type",placeholder="autobroadcast/arena/bg",width=170}, {key="state",placeholder="on/off",width=70} },
      tooltip="Toggle announcements. Types: autobroadcast, arena, bg." },
    { id="wchange", label="Weather", format=".wchange %s %s", level=3, group="General",
      args={ {key="type",placeholder="0fine 1rain 2snow 3storm",numeric=true,width=150}, {key="grade",placeholder="0.0 - 1.0",numeric=true,width=90} },
      tooltip="Set weather. Type: 0 fine, 1 rain, 2 snow, 3 storm, 86 thunder, 90 blackrain. Grade 0.0-1.0." },
    { id="unstuck", label="Unstuck", format=".unstuck %s %s", level=2, group="General",
      args={ {key="name",placeholder="player",fallback="target",width=130}, {key="loc",placeholder="inn/graveyard/startzone",width=170,optional=true} },
      tooltip="Teleport a player to inn / graveyard / startzone. Default = their hearth location." },
    { id="hidearea", label="Hide area", format=".hidearea %s", level=3, group="General",
      args={ {key="areaid",placeholder="areaId",numeric=true,width=100} },
      tooltip="Hide the given area ID from the selected character (self if none)." },
    { id="showarea", label="Show area", format=".showarea %s", level=2, group="General",
      args={ {key="areaid",placeholder="areaId",numeric=true,width=100} },
      tooltip="Reveal the given area ID to the selected character (self if none)." },
}

local function utilityBuilder(parent)
    WLGM.BuildScrollSections(parent, {
        { title = "Info & vision", rows = Info },
        { title = "Tags & world",  rows = Tags },
    })
end

WLGM.RegisterTab({
    id = "general", label = "General",
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Toggles",     builder = togglesBuilder },
            { label = "Modify Self", builder = modifyBuilder },
            { label = "Utility",     builder = utilityBuilder },
        }, "general")
    end,
})
