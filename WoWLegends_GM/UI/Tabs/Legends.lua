-- WoWLegends_GM/UI/Tabs/Legends.lua
-- ★ The headline tab: WoW Legends-exclusive commands.
-- Companion · Hardcore + Mak'gora · custom XP rate · instant Gear ·
-- World PvP · Faction Battlefronts. Authored from GM_COMMANDS.md (v1.1.0).

local addonName, WLGM = ...

local CLASSES = "warrior  paladin  hunter  rogue  priest  dk  shaman  mage  warlock  druid"
local RACES = {
    Alliance = "human  dwarf  nightelf  gnome  draenei",
    Horde    = "orc  undead  tauren  troll  bloodelf",
}
-- List forms for the dropdowns (race is filtered by the player's faction).
local CLASS_LIST = { "warrior", "paladin", "hunter", "rogue", "priest", "dk", "shaman", "mage", "warlock", "druid" }
local RACE_LIST = {
    Alliance = { "human", "dwarf", "nightelf", "gnome", "draenei" },
    Horde    = { "orc", "undead", "tauren", "troll", "bloodelf" },
}

-- §5.5 fixed battlefront spots: zone name + the admin .go to that zone's banner.
local ZONES = {
    { "Westfall",            ".go xyz -10235.2 1222.5 43.6 0" },
    { "Redridge Mountains",  ".go xyz -9266.6 -2188.8 64.1 0" },
    { "Duskwood",            ".go xyz -10573.0 -1182.5 28.0 0" },
    { "Arathi Highlands",    ".go xyz -1508.5 -2732.1 32.5 0" },
    { "Hillsbrad Foothills", ".go xyz -853.2 -533.5 10.0 0" },
    { "The Hinterlands",     ".go xyz 119.4 -3190.4 117.3 0" },
    { "Stranglethorn Vale",  ".go xyz -12388.9 172.6 2.8 0" },
    { "Eastern Plaguelands", ".go xyz 2301.0 -4613.4 73.6 0" },
    { "The Barrens",         ".go xyz -452.8 -2650.8 95.5 1" },
    { "Ashenvale",           ".go xyz 1928.3 -2165.9 93.8 1" },
    { "Stonetalon Mountains",".go xyz 1570.9 1031.5 138.0 1" },
    { "Desolace",            ".go xyz -606.4 2211.8 93.0 1" },
    { "Thousand Needles",    ".go xyz -4969.0 -1726.9 -62.1 1" },
    { "Feralas",             ".go xyz -4841.2 1309.4 81.4 1" },
    { "Tanaris",             ".go xyz -7177.1 -3785.3 8.4 1" },
    { "Dustwallow Marsh",    ".go xyz -4043.6 -2991.3 36.4 1" },
}

-- Zone dropdown options: text "N Name", value "N" (1-based index).
local ZONE_CHOICES = {}
for i, z in ipairs(ZONES) do ZONE_CHOICES[i] = { text = i .. "  " .. z[1], value = tostring(i) } end

-- intro paragraph + a list of command rows.
local function section(info, rows, opts)
    return function(parent)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
        fs:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -8)
        fs:SetJustifyH("LEFT")
        fs:SetText(WLGM.colors.muted .. info .. WLGM.colors.reset)
        local lo = opts or {}
        lo.yTop = 8 + fs:GetStringHeight() + 14
        WLGM.LayoutRows(parent, rows, lo)
    end
end

-- ─── Companion (faction-aware create tooltip) ──────────────────────────────
local function companionBuilder(parent)
    local faction = UnitFactionGroup("player") or "Alliance"
    local raceList = RACES[faction] or (RACES.Alliance .. "  /  " .. RACES.Horde)
    local raceChoices = RACE_LIST[faction] or RACE_LIST.Alliance

    local rows = {
        { id="comp_show", label="My companion", format=".companion", level=0, wl=true, group="Legends",
          tooltip="Show your companion (name, race, class), or how to create one if you have none yet." },
        { id="comp_create", label="Create companion", format=".companion create %s %s %s", level=0, wl=true, group="Legends",
          args={ {key="race",placeholder="race",choices=raceChoices,width=110}, {key="class",placeholder="class",choices=CLASS_LIST,width=100}, {key="name",placeholder="name",width=120} },
          tooltip="Claim your ONE permanent battle companion - a bot that fights at your side, chats, and remembers you.\n"
              .. "Your faction (" .. faction .. ") races: " .. raceList .. "\nClasses: " .. CLASSES
              .. "\nName: 2-12 letters, unique.   e.g.  .companion create orc warrior Grommash" },
        { id="comp_summon", label="Summon companion", format=".companion summon", level=0, wl=true, group="Legends",
          tooltip="Recall your companion to your side (auto-joins your group and fights with you)." },
        { id="comp_dismiss", label="Dismiss companion", format=".companion dismiss", level=0, wl=true, group="Legends",
          tooltip="Send your companion away temporarily. Recall any time with Summon." },
        { id="comp_forget", label="Forget companion", format=".companion forget", level=0, wl=true, group="Legends", danger=true,
          tooltip="Permanently release your companion: the bond and its memory are wiped and the pool character is freed, so you can create a new one." },
    }
    return section(
        "Your ONE permanent battle companion - a bound bot that fights at your side, chats, and remembers you. "
        .. "Drive it like any bot from the Bots tab ($follow, $attack, $talents spec ...). Available to every player.",
        rows)(parent)
end

-- ─── Hardcore + Mak'gora ───────────────────────────────────────────────────
local Hardcore = {
    { id="hc_on", label="Enable Hardcore", format=".hardcore on", level=0, wl=true, group="Legends", danger=true,
      tooltip="Opt this character into PERMADEATH. LEVEL 1 ONLY and irreversible - fall once and the hero is gone for good.\nConfirm by running it TWICE within 30s (or use the Herald of the Fallen NPC). Blocked if realm-wide HC is on, opt-in is disabled, you are not level 1, or already hardcore/fallen." },
    { id="hc_status", label="Hardcore status", format=".hardcore status", level=0, wl=true, group="Legends",
      tooltip="Show your state: FALLEN / ACTIVE (hardcore) / normal." },
    { id="makgora", label="Mak'gora challenge", format=".makgora", level=0, wl=true, group="Legends", danger=true,
      tooltip="Arm a duel to the death with your TARGETED player. Both must be hardcore, target each other, and both run .makgora; the next normal duel within 30s becomes lethal for the loser." },
}

-- ─── Custom XP rate ────────────────────────────────────────────────────────
local XP = {
    { id="xp_view", label="View XP rate", format=".xp view", level=0, wl=true, group="Legends",
      tooltip="Show your current XP rate and the maximum the server allows (default cap 10)." },
    { id="xp_set", label="Set XP rate", format=".xp set %s", level=0, wl=true, group="Legends",
      args={ {key="rate",placeholder="rate (1=blizzlike)",numeric=true} }, tooltip="Set your personal XP rate. 1 = blizzlike, up to the server cap (default 10)." },
    { id="xp_enable", label="Enable XP rate", format=".xp enable", level=0, wl=true, group="Legends",
      tooltip="Enable the individual-XP modifier for you." },
    { id="xp_disable", label="Disable XP rate", format=".xp disable", level=0, wl=true, group="Legends",
      tooltip="Disable it (back to the realm's default rate)." },
    { id="xp_default", label="Reset to default", format=".xp default", level=0, wl=true, group="Legends",
      tooltip="Reset your XP rate to the configured default." },
}

-- ─── Gear (GM) ─────────────────────────────────────────────────────────────
local Gear = {
    { id="gear_max", label="Gear: best", format=".gear max", level=2, wl=true, group="Legends",
      tooltip="Gear the targeted bot/player (or yourself) with the best available items for their level." },
    { id="gear_epic", label="Gear: epic", format=".gear epic", level=2, wl=true, group="Legends",
      tooltip="Full EPIC (purple) set for the current level." },
    { id="gear_rare", label="Gear: rare", format=".gear rare", level=2, wl=true, group="Legends",
      tooltip="Full RARE (blue) set for the current level." },
    { id="gear_level", label="Gear: leveling", format=".gear level", level=2, wl=true, group="Legends",
      tooltip="Level-appropriate quest/dungeon-grade gear. Spec-aware." },
    { id="gear_undress", label="Undress", format=".gear undress", level=2, wl=true, group="Legends", danger=true,
      tooltip="Strip all equipped items from the target into their bags." },
}

-- ─── World PvP (GM) ────────────────────────────────────────────────────────
local WorldPvP = {
    { id="wpvp_start", label="Open World PvP", format=".worldpvp start %s", level=2, wl=true, group="Legends", danger=true,
      args={ {key="minutes",placeholder="minutes (opt)",numeric=true,optional=true} },
      tooltip="Open an all-zones World PvP window now (timed mode). Optional duration in minutes; omit for the configured default. While open, enemy players AND bots are attackable everywhere; same-faction, GMs, cities and sanctuaries stay safe." },
    { id="wpvp_status", label="World PvP status", format=".worldpvp status", level=2, wl=true, group="Legends",
      tooltip="Report mode (off / always / timed), whether a window is active, and time remaining / time to next." },
    { id="wpvp_stop", label="Close World PvP", format=".worldpvp stop", level=2, wl=true, group="Legends", danger=true,
      tooltip="Close the current World PvP window." },
}

-- ─── Battlefronts (GM) + per-zone teleport ─────────────────────────────────
local function battlefrontBuilder(parent)
    local info = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    info:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -8)
    info:SetJustifyH("LEFT")
    info:SetText(WLGM.colors.muted .. "Faction Battlefronts - a contested capture point where players and bots wage a tug-of-war over a war banner. "
        .. "Auto-spawns on a timer when enabled, or start one manually here." .. WLGM.colors.reset)

    local rows = {
        { id="wle_start", label="Start battlefront", format=".wlevent start %s", level=2, wl=true, group="Legends",
          args={ {key="zone",placeholder="random zone",optional=true,choices=ZONE_CHOICES,width=150} },
          tooltip="Start a battlefront. Leave the zone unset for a random one, or pick a specific zone." },
        { id="wle_status", label="Battlefront status", format=".wlevent status", level=2, wl=true, group="Legends",
          tooltip="Report the active battlefront: Alliance% / Horde%, time left, and a .go line to the banner." },
        { id="wle_stop", label="Stop battlefront", format=".wlevent stop", level=2, wl=true, group="Legends", danger=true,
          tooltip="End the active battlefront." },
        { id="wle_zones", label="List zones in chat", format=".wlevent zones", level=2, wl=true, group="Legends",
          tooltip="Print the 16 curated zones with indices to chat." },
    }
    local used = WLGM.LayoutRows(parent, rows, { yTop = 8 + info:GetStringHeight() + 14 })

    -- Teleport-to-zone mini control (uses the fixed §5.5 spots).
    local y = -(used + 10)
    local tpHdr = WLGM.CreateSectionHeader(parent, "Teleport to a zone battlefront (admin)")
    tpHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    y = y - tpHdr:GetHeight() - 6

    local dd = WLGM.CreateChoice(parent, 180, 22, ZONE_CHOICES, "choose zone...")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)

    local function tp()
        local i = tonumber(dd.GetValue())
        if not i or not ZONES[i] then WLGM.Warn("pick a zone from the list first."); return end
        WLGM.RunCommand(ZONES[i][2])
    end

    local goBtn = WLGM.MakeFlatButton(parent, 90, 22, "Teleport", { justify = "CENTER" })
    goBtn:SetPoint("LEFT", dd, "RIGHT", 8, 0)
    goBtn:SetScript("OnClick", tp)

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", goBtn, "RIGHT", 12, 0)
    hint:SetText("Jumps you to the selected zone's battlefront spot.")
end

WLGM.RegisterTab({
    id = "legends", label = "Legends", wl = true,
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Companion",    builder = companionBuilder },
            { label = "Hardcore",     builder = section("Permadeath at level 1 - fall once and the hero is gone for good. Challenge other hardcore players to a lethal Mak'gora duel.", Hardcore) },
            { label = "XP Rate",      builder = section("Set your own leveling pace. Each player controls a personal XP multiplier (1 = blizzlike, up to the server cap).", XP) },
            { label = "Gear",         builder = section("GM tool: instantly gear the targeted bot/player (or yourself). Spec-aware. Players gear up via Companion + bot init tiers instead.", Gear) },
            { label = "World PvP",    builder = section("Open a server-wide World PvP window: everyone is flagged everywhere. Same-faction players, GMs, cities and sanctuaries stay safe.", WorldPvP) },
            { label = "Battlefronts", builder = battlefrontBuilder },
        }, "legends")
    end,
})
