-- WoWLegends_GM/UI/Tabs/World.lua
-- Living World (repack v1.8.0): Most Wanted bounties, Nemesis bots, Bot life,
-- Innkeepers who know you and the duel crowd. Every row was read from the
-- command tables and handlers in mod-wowlegends (wowlegends_bounty.cpp,
-- _nemesis, _botlife, _innkeepers, _makgora_crowd); see GM_COMMANDS.md 1.12.
-- Town raids and the Terminator are v1.9.0 and deliberately absent.

local addonName, WLGM = ...

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

-- Most bounty/nemesis commands take a character NAME, not a selection; leaving
-- the box blank fills in your current target.
local function who(placeholder, opt)
    return { key="name", placeholder=placeholder or "character", fallback="target", optional=opt, width=130 }
end

local WANTED = { "1", "2", "3", "5", "8", "10", "15", "20" }

-- --- Most Wanted (bounties) ------------------------------------------------
local Bounty = {
    { id="bty_mine", label="My bounty", format=".bounty", level=0, wl=true, group="World",
      tooltip="Your own price, wanted level and Bounty Coins." },
    { id="bty_top", label="Most wanted", format=".bounty top", level=0, wl=true, group="World",
      tooltip="The realm's most-wanted list (a player command too)." },
    { id="bty_status", label="System status", format=".bounty status", level=2, wl=true, group="World",
      tooltip="GM overview of the bounty system and its live settings." },
    { id="bty_set", label="Set bounty", format=".bounty set %s %s", level=2, wl=true, group="World",
      args={ who("online char"), {key="amount",placeholder="amount",numeric=true,width=80} },
      tooltip="Set a character's bounty exactly. Wanted level = floor(sqrt(amount / 10)):\n250 = W5, 1000 = W10, 4000 = W20. The character must be online." },
    { id="bty_coins", label="Set coins", format=".bounty coins %s %s", level=2, wl=true, group="World",
      args={ who("online char"), {key="amount",placeholder="coins",numeric=true,width=80} },
      tooltip="Set a character's Bounty Coins to exactly this number. Online only." },
    { id="bty_addcoins", label="Add coins", format=".bounty addcoins %s %s", level=2, wl=true, group="World",
      args={ who("char"), {key="amount",placeholder="coins",numeric=true,width=80} },
      tooltip="Add Bounty Coins to a character. Works offline too." },
    { id="bty_hunter", label="Send a hunter now", format=".bounty hunter %s", level=2, wl=true, group="World",
      args={ {key="name",placeholder="online char (blank = you)",optional=true,width=170} },
      tooltip="Force a bounty hunt on an online character right now, ignoring a smoke bomb. Blank = yourself. The hunter arrives in about 3 seconds." },
    { id="bty_hitman", label="Hitman contract", format=".bounty hitman %s %s %s %s", level=2, wl=true, group="World", danger=true,
      args={ who("target"), {key="w",placeholder="W",choices=WANTED,width=60},
             {key="delay",placeholder="delay s",numeric=true,width=70}, {key="buyer",placeholder="buyer",width=110} },
      tooltip="Put a hitman on a character as if the buyer paid for it: wanted level W, sent after the delay (seconds).\nTarget and buyer are character names (offline is fine). Refused if a hitman is already hunting the target." },
    { id="bty_reset", label="Wipe bounty record", format=".bounty reset %s", level=2, wl=true, group="World", danger=true,
      args={ who("online char") },
      tooltip="Delete the character's whole bounty record: price, wanted level and coins. Online only." },
}

-- --- Nemesis bots -----------------------------------------------------------
local Nemesis = {
    { id="nem_status", label="Nemesis status", format=".nemesis status %s", level=2, wl=true, group="World",
      args={ who("online player") },
      tooltip="Show an online player's nemesis: the bot, wins on each side, its rank and when it last hunted." },
    { id="nem_set", label="Set nemesis", format=".nemesis set %s %s", level=2, wl=true, group="World",
      args={ who("online player"), {key="bot",placeholder="online bot",width=120} },
      tooltip="Make this bot the player's nemesis. Both must be online." },
    { id="nem_test", label="Send it now", format=".nemesis test %s", level=2, wl=true, group="World",
      args={ who("online player") },
      tooltip="Send the player's nemesis after them right now. Only where they can be attacked (World PvP or flagged), never in towns or instances." },
    { id="nem_clear", label="Clear nemesis", format=".nemesis clear %s", level=2, wl=true, group="World", danger=true,
      args={ who("online player") },
      tooltip="Remove the player's nemesis. The player must be online." },
}

-- --- Bot life (day rhythm) ------------------------------------------------------
local HOURS = { "auto" }
for h = 0, 23 do HOURS[#HOURS + 1] = tostring(h) end

local BotLife = {
    { id="bl_status", label="Status", format=".botlife status", level=2, wl=true, group="World",
      tooltip="Is Bot life on, which hour it is following and which phase of the day that is." },
    { id="bl_census", label="Census", format=".botlife census", level=2, wl=true, group="World",
      tooltip="Count the bots: how many are in town and inns, how many out in the world." },
    { id="bl_on", label="Turn on", format=".botlife on", level=2, wl=true, group="World",
      tooltip="Switch Bot life on (until restart - WowLegends.BotLife.Enabled in the conf is the default)." },
    { id="bl_off", label="Turn off", format=".botlife off", level=2, wl=true, group="World",
      tooltip="Switch Bot life off (until restart)." },
    { id="bl_hour", label="Force hour", format=".botlife hour %s", level=2, wl=true, group="World",
      args={ {key="hour",placeholder="0-23 / auto",choices=HOURS,width=90} },
      tooltip="Pretend it is this hour of the day (0-23) to see the bots move into that phase. auto = follow the realm clock again." },
}

-- --- Innkeepers who know you ---------------------------------------------------
local DEEDS = { "raid", "dungeon", "worldboss", "loot", "level", "pvp", "death", "quest" }

local Innkeepers = {
    { id="inn_status", label="Status", format=".innkeeper status", level=2, wl=true, group="World",
      tooltip="Feature on/off, the current shift (day or night, and whether it is forced), the night hours and each inn's keepers." },
    { id="inn_shift", label="Set shift", format=".innkeeper shift %s", level=2, wl=true, group="World",
      args={ {key="mode",placeholder="auto",choices={"auto","day","night"},optional=true,width=80} },
      tooltip="Force the day or the night keeper on duty in every inn, or auto to follow the clock." },
    { id="inn_deeds", label="Player's deeds", format=".innkeeper deeds %s", level=2, wl=true, group="World",
      args={ who("online player") },
      tooltip="List what the server remembers an online player did (the last 20 deeds) - what the keepers talk about." },
    { id="inn_deed", label="Add a deed", format=".innkeeper deed %s %s %s", level=2, wl=true, group="World",
      args={ who("online player"), {key="kind",placeholder="kind",choices=DEEDS,width=90},
             {key="what",placeholder="what [| where]",width=170} },
      tooltip="Record a deed by hand for testing, e.g. kind raid, what: Onyxia | Onyxia's Lair." },
    { id="inn_test", label="Test a greeting", format=".innkeeper test %s %s %s", level=2, wl=true, group="World",
      args={ {key="inn",placeholder="inn",choices={"sw","org","dal-a","dal-h"},width=80}, who("online player"),
             {key="say",placeholder="say (optional)",optional=true,width=150} },
      tooltip="Have the keeper on duty at that inn greet the player (sw = Stormwind, org = Orgrimmar, dal-a / dal-h = Dalaran) - or, with a line, answer it as if the player had said it.\nThe reply is written by the AI and queued, so it needs AI chat; a refusal means AI off, budget spent or queue full." },
}

-- --- Duel crowd ----------------------------------------------------------------
local Crowd = {
    { id="crowd_status", label="Status", format=".crowd", level=2, wl=true, group="World",
      tooltip="Show the duel crowd settings now in force." },
    { id="crowd_on", label="Turn on", format=".crowd on", level=2, wl=true, group="World",
      tooltip="Crowds gather at duels (until restart - WowLegends.DuelCrowd.* in the conf are the defaults)." },
    { id="crowd_off", label="Turn off", format=".crowd off", level=2, wl=true, group="World",
      tooltip="No more crowds (until restart)." },
    { id="crowd_duels", label="Which duels", format=".crowd duels %s", level=2, wl=true, group="World",
      args={ {key="which",placeholder="duels",choices={"makgora","all"},width=90} },
      tooltip="makgora = only Mak'gora duels get a crowd, all = every duel." },
    { id="crowd_count", label="Spectators", format=".crowd count %s", level=2, wl=true, group="World",
      args={ {key="n",placeholder="4-160 / auto",width=90} },
      tooltip="How many guards watch (4-160), or auto to fill the ring for its radius." },
    { id="crowd_radius", label="Ring size", format=".crowd radius %s", level=2, wl=true, group="World",
      args={ {key="yd",placeholder="4-30 yd",numeric=true,width=70} },
      tooltip="Radius of the ring in yards (4-30)." },
    { id="crowd_props", label="Props", format=".crowd props %s", level=2, wl=true, group="World",
      args={ {key="v",placeholder="on/off",choices={"on","off"},width=70} },
      tooltip="Torches, faction banners and braziers around the ring." },
    { id="crowd_walls", label="Walls", format=".crowd walls %s", level=2, wl=true, group="World",
      args={ {key="v",placeholder="on/off",choices={"on","off"},width=70} },
      tooltip="The guards shove a fighter who tries to leave back into the ring." },
    { id="crowd_pillars", label="Pillars", format=".crowd pillars %s", level=2, wl=true, group="World",
      args={ {key="n",placeholder="0-4",choices={"0","1","2","3","4"},width=60} },
      tooltip="Up to four arena pillars inside the ring." },
    { id="crowd_test", label="Test around me", format=".crowd test %s", level=2, wl=true, group="World",
      args={ {key="s",placeholder="seconds (opt)",numeric=true,optional=true,width=90} },
      tooltip="Raise the ring around yourself for the given seconds - for screenshots and video. In game only." },
    { id="crowd_clear", label="Clear test crowd", format=".crowd clear", level=2, wl=true, group="World",
      tooltip="Remove a test crowd. In game only." },
}

WLGM.RegisterTab({
    id = "world", label = "Living World", wl = true,
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Most Wanted", builder = section("Bounties (repack v1.8.0, created and designed by Cazius). Kill the other faction and your price climbs; masked bounty hunters come to collect, a smoke bomb throws them off, hitmen can be bought. On by default: WowLegends.Bounty.Enabled.", Bounty) },
            { label = "Nemesis",     builder = section("Nemesis bots (v1.8.0): a bot you killed holds a grudge and now comes looking for you out in the world. Beat it five times and it gives up. On by default: WowLegends.Nemesis.Enabled.", Nemesis) },
            { label = "Bot life",    builder = section("Bot life (v1.8.0, idea: DeewaTT): bots follow the realm clock - town in the morning, questing by day, inns in the evening, rest at night. Off by default: WowLegends.BotLife.Enabled.", BotLife) },
            { label = "Innkeepers",  builder = section("Innkeepers who know you (v1.8.0): the keepers of Stormwind, Orgrimmar and Dalaran greet players by name, know their latest deeds and can be talked to. Off by default: WowLegends.Innkeepers.Enabled.", Innkeepers) },
            { label = "Duel crowd",  builder = section("Duels get a crowd (v1.8.0, idea: Cazius): the duelists' city guards form a cheering ring. On by default, for every duel. Changes here last until a restart; WowLegends.DuelCrowd.* in the conf are the defaults.", Crowd) },
        }, "world")
    end,
})
