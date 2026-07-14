-- WoWLegends_GM/UI/Tabs/Bots.lua
-- The PlayerBot command center. Two command types (per GM_COMMANDS.md):
--   • dot-commands  .playerbots ...   (manage who your bots are)
--   • bot orders    $word             (tell your bots what to do)
-- The scope selector at the top decides where $ orders go: PARTY (all your
-- bots) or WHISPER (just the targeted bot).

local addonName, WLGM = ...

-- Shared order scope for every bot-order ($) row in this tab.
local botScope = "party"
local function getScope() return botScope end

-- Helpers --------------------------------------------------------------------
local function order(id, label, word, tooltip, args, danger)
    return { id = id, label = label, format = word, send = "bot", getScope = getScope,
             group = "Bots", tooltip = tooltip, args = args, danger = danger }
end
local function pb(id, label, fmt, tooltip, args, level, danger)
    return { id = id, label = label, format = fmt, group = "Bots",
             tooltip = tooltip, args = args, level = level or 0, danger = danger }
end

-- Dropdown option lists.
local CLASS_LIST = { "warrior", "paladin", "hunter", "rogue", "priest", "dk", "shaman", "mage", "warlock", "druid" }
local GENDERS    = { "male", "female" }
local TIERS      = { "auto", "white", "green", "blue", "purple", "legendary" }

-- ─── Party builder (.playerbots dot-commands) ──────────────────────────────
local Party = {
    pb("pb_list",     "List my bots",    ".playerbots bot list",
        "Show your bots: online (+), your offline alts (-), and randoms in your group."),
    pb("pb_addclass", "Add class bot",   ".playerbots bot addclass %s %s",
        "Summon a fresh pre-geared DISPOSABLE class bot of your faction. Gender optional (male/female).\nClasses: warrior paladin hunter rogue priest dk shaman mage warlock druid.",
        { {key="class",placeholder="class",choices=CLASS_LIST}, {key="gender",placeholder="gender (opt)",optional=true,choices=GENDERS,width=90} }),
    pb("pb_lookup",   "Classes available", ".playerbots bot lookup",
        "List the classes you can summon with Add class bot."),
    pb("pb_add",      "Add bot by name", ".playerbots bot add %s",
        "Log the named character(s) in as YOUR bot (you become master). Comma-separate several. Blank = current target. Names are case-insensitive.",
        { {key="name",placeholder="Name[,Name2]",fallback="target",width=150} }),
    pb("pb_addacct",  "Add whole account", ".playerbots bot addaccount %s",
        "Add ALL characters on that account/charname as bots at once.",
        { {key="acct",placeholder="account / char",width=150} }),
    pb("pb_remove",   "Remove bot",      ".playerbots bot remove %s",
        "Remove / log out one of your bots (alias: logout, rm). Blank = current target.",
        { {key="name",placeholder="Name",fallback="target",width=150} }),
    pb("pb_remall",   "Remove ALL bots", ".playerbots bot remove *",
        "Log out every bot you currently control.", nil, 0, true),
}

-- ─── Init / regear (.playerbots dot-commands) ──────────────────────────────
local Manage = {
    pb("pb_init",   "Regear bot to tier", ".playerbots bot init=%s %s",
        "Regear an addclass bot to a tier. Tiers: auto white green blue purple legendary, or a gearscore number.\nTarget: a bot name, * (your group), ! (all bots, GM).",
        { {key="tier",placeholder="tier",choices=TIERS,width=100}, {key="name",placeholder="name / * / !",fallback="target",width=120} }),
    pb("pb_levelup","Re-roll at level",  ".playerbots bot levelup",
        "Re-randomize your bots at their current level."),
    pb("pb_refresh","Refresh gear/consumes", ".playerbots bot refresh",
        "Re-roll consumables and gear on your bots."),
    pb("pb_random", "Full re-randomize", ".playerbots bot random",
        "Completely re-randomize your bots.", nil, 0, true),
    pb("pb_quests", "Init instance quests", ".playerbots bot quests",
        "Initialize instance quests for your bots."),
    pb("pb_initself","Regear MYSELF (GM)", ".playerbots bot initself",
        "Regear your OWN character to a bot tier. GM only - players use the Gear panel in Legends.", nil, 2),
    pb("pb_setkey", "Set account key",  ".playerbots account setKey %s",
        "Set a security key on your account so a trusted friend can link and command your characters.",
        { {key="key",placeholder="key",width=120} }),
    pb("pb_link",   "Link to account",  ".playerbots account link %s %s",
        "Link to another account using its key, so you can add its characters as bots.",
        { {key="acct",placeholder="account",width=110}, {key="key",placeholder="key",width=90} }),
    pb("pb_linked", "Linked accounts",  ".playerbots account linkedAccounts",
        "List the accounts you are linked to."),
    pb("pb_unlink", "Unlink account",   ".playerbots account unlink %s",
        "Remove a link.", { {key="acct",placeholder="account",width=120} }),
}

-- ─── Orders ($ bot-chat) — movement & combat ───────────────────────────────
local Movement = {
    order("o_follow",   "Follow",     "follow",   "Follow you."),
    order("o_stay",     "Stay",       "stay",     "Hold current position."),
    order("o_summon",   "Summon",     "summon",   "Pull the bot(s) to you (dungeons)."),
    order("o_flee",     "Flee",       "flee",     "Fall back / flee."),
    order("o_runaway",  "Run away",   "runaway",  "Run away from the group."),
    order("o_grind",    "Grind",      "grind",    "Resume roaming / grinding."),
    order("o_disperse", "Disperse",   "disperse", "Spread out."),
    order("o_home",     "Home",       "home",     "Set / return to home."),
    order("o_taxi",     "Take taxi",  "taxi",     "Take a flight path."),
    order("o_tele",     "Teleport",   "teleport", "Teleport (e.g. to master)."),
    order("o_go",       "Go to",      "go %s",    "Travel to a place or coords.", { {key="where",placeholder="place/coords",width=140} }),
}
local Combat = {
    order("o_attack",   "Attack",       "attack",      "Attack your current target."),
    order("o_tankatk",  "Tank attack",  "tank attack", "Tank engages your target."),
    order("o_pull",     "Pull",         "pull",        "Pull the target."),
    order("o_maxdps",   "Max DPS",      "max dps",     "Maximum-DPS posture."),
    order("o_focus",    "Focus heal",   "focus heal %s","Tell healers which target(s) to prioritize. Blank = your target.", { {key="who",placeholder="player (opt)",optional=true,width=120} }),
    order("o_cast",     "Cast spell",   "cast %s",     "Cast a spell (optionally on a target).", { {key="spell",placeholder="spell [target]",width=150} }),
    order("o_savemana", "Save mana",    "save mana",   "Conserve mana."),
    order("o_drink",    "Drink",        "drink",       "Restore mana / health."),
    order("o_rti",      "Set raid icon","rti %s",      "Set / report the focused raid-target icon.", { {key="icon",placeholder="icon (opt)",optional=true,width=90} }),
    order("o_release",  "Release",      "release",     "Corpse run after death."),
    order("o_revive",   "Revive",       "revive",      "Resurrect at the spirit healer."),
    order("o_reset",    "Reset AI",     "reset botAI", "Reset the bot's AI state.", nil, true),
    order("o_help",     "Bot: help",    "help",        "Bot whispers you its full command list."),
}

-- ─── Travel & Guide ($ bot-chat, v1.4.0) ───────────────────────────────────
local Travel = {
    order("t_hearth", "Use hearthstone", "hearthstone",
        "The bot really casts its Hearthstone (interruptible cast). In party scope this is the whole squad's 'everyone hearth' button.\nSilent if the stone is on cooldown or missing - the spoken 'go home' order (Talk & Command) answers honestly instead. Not usable in battlegrounds."),
    order("t_guidestop", "Stop guiding", "wl guide stop",
        "Cancel an active guide escort ('Alright, staying with you.'). Follow, Stay and Reset AI cancel it too."),
}

-- ─── Talk & Command reference (v1.4.0) — patterns, not buttons ─────────────
local function talkBuilder(parent)
    local scroll, child = WLGM.CreateScrollContent(parent)
    child:SetWidth(744)
    local blocks = {
        { nil,
          WLGM.colors.muted .. "Talk to your bots in plain English - no commands. Server gate: WowLegends.AiCommand.Enabled = 1 (ships OFF by default; ON on the PTR). The exact phrases below are deterministic and work with NO AI backend configured; free-form sentences need an AI backend. $-prefixed orders always work regardless." .. WLGM.colors.reset },
        { "Whisper one bot (no $)",
          "follow - stay - attack - flee - drink - eat - come here - go home - attack the <mob name>\n'go home' pre-checks the hearthstone cooldown ('My hearthstone is still cooling down.'). 'attack the <mob>' finds the mob within 60 yds of YOU and sets your target. The bot answers with one ack ('On it - right behind you.') or an honest refusal ('Pulling is a tank's job - I'm not built for it.')." },
        { "Talk to the whole group (party/raid/say/yell)",
          "'everyone follow me' - 'all of you attack the kobold miner' - 'bots go home' - 'you guys stay here'\nThe group answers with ONE voice. Drastic calls (everyone go home / everyone grind) ask you to repeat the order within 45 s before obeying." },
        { "The Guide - spoken escort",
          "'take me to / lead me to / guide me to / show me the way to <place>'\nDestinations: teleport-catalog places (booty bay), dungeon entrances, 'my quest', role NPCs (an innkeeper, my trainer, a repair vendor, the auction house, a flight master, the bank, a stable master), starting zones ('the troll starting zone').\nThe bot walks you there by road, yells if you fall behind, and comes back for you. Same continent only ('That's beyond this land - we'd need a ship or zeppelin.').\nGates: WowLegends.BotGuide.Enabled = 1 (default on) + AiCommand on. Zero AI cost - fully deterministic. Cancel via Travel & Guide, $follow or $stay." },
        { "The Sage - ask about the world",
          "Question-shaped whispers that name a game entity get answers grounded in this server's REAL data:\n'who sells Refreshing Spring Water?' - 'where is Mankrik?' - 'price of the Bronze Tube?' - 'what does [linked quest] reward?'\nCovers items (prices, vendors + the nearest one with direction), quests (giver, objective, rewards) and NPCs (roles, nearest spawn).\nGate: WowLegends.AiChat.Sage.Enabled = 1 (default on); rides AI chat." },
    }
    local y = 8
    for _, b in ipairs(blocks) do
        if b[1] then
            local hdr = WLGM.CreateSectionHeader(child, b[1])
            hdr:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -y)
            y = y + hdr:GetHeight() + 4
        end
        local fs = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -y)
        fs:SetWidth(724)
        fs:SetJustifyH("LEFT")
        fs:SetText(b[2])
        y = y + fs:GetStringHeight() + 14
    end
    child:SetHeight(math.max(y, 80))
end

-- ─── Roles / specs ($talents) ──────────────────────────────────────────────
local Roles = {
    order("r_report",  "Current spec",  "talents",          "Report the bot's current spec + help."),
    order("r_list",    "List specs",    "talents spec list","List this class's premade specs (point spreads)."),
    order("r_set",     "Set spec",      "talents spec %s",  "Switch to a named spec - this sets tank/heal/dps.\nWarrior: arms fury protection | Paladin: holy protection retribution | Hunter: beast mastery / marksmanship / survival | Rogue: assasination combat subtlety | Priest: discipline holy shadow | DK: blood frost unholy | Shaman: elemental enhancement restoration | Mage: arcane fire frost | Warlock: affliction demonology destruction | Druid: balance / feral combat / restoration.", { {key="spec",placeholder="spec name",width=150} }),
    order("r_switch",  "Dual-spec",     "talents switch %s","Activate primary (1) or secondary (2) spec.", { {key="n",placeholder="1 or 2",numeric=true,width=70} }),
    order("r_autopick","Auto-pick tree","talents autopick", "Auto-pick a full talent tree for the level."),
}

-- ─── Console (GM/owner: random-bot population) ─────────────────────────────
local Console = {
    pb("c_stats",   "Random bots: stats",   ".playerbots rndbot stats",   "Show random-bot population stats.", nil, 4),
    pb("c_reload",  "Random bots: reload",  ".playerbots rndbot reload",  "Reload the random-bot config.", nil, 4),
    pb("c_update",  "Random bots: update",  ".playerbots rndbot update",  "Force a random-bot update tick.", nil, 4),
    pb("c_init",    "Random bots: init",    ".playerbots rndbot init",    "Re-initialize the random-bot pool.", nil, 4, true),
    pb("c_refresh", "Random bots: refresh", ".playerbots rndbot refresh", "Refresh random-bot gear/consumables.", nil, 4),
    pb("c_pmon",    "Perf monitor toggle",  ".playerbots pmon toggle",    "Toggle the playerbot performance monitor.", nil, 4),
}

-- ─── Scope selector + tab assembly ─────────────────────────────────────────
local function buildScopeSelector(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
    bar:SetHeight(24)

    local lbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", bar, "LEFT", 4, 0)
    lbl:SetText(WLGM.colors.muted .. "Send $ orders to:" .. WLGM.colors.reset)

    local partyBtn = WLGM.MakeFlatButton(bar, 150, 20, "All my bots (party)", { justify = "CENTER" })
    partyBtn:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    local whisBtn = WLGM.MakeFlatButton(bar, 150, 20, "Targeted bot (whisper)", { justify = "CENTER" })
    whisBtn:SetPoint("LEFT", partyBtn, "RIGHT", 6, 0)

    local function refresh()
        if botScope == "party" then
            partyBtn.bg:SetTexture(0.10, 0.30, 0.40, 0.95); partyBtn.label:SetTextColor(1, 0.82, 0.30)
            whisBtn.bg:SetTexture(0.13, 0.15, 0.19, 0.95); whisBtn.label:SetTextColor(0.82, 0.82, 0.82)
        else
            whisBtn.bg:SetTexture(0.10, 0.30, 0.40, 0.95); whisBtn.label:SetTextColor(1, 0.82, 0.30)
            partyBtn.bg:SetTexture(0.13, 0.15, 0.19, 0.95); partyBtn.label:SetTextColor(0.82, 0.82, 0.82)
        end
    end
    partyBtn:SetScript("OnClick", function() botScope = "party"; refresh() end)
    whisBtn:SetScript("OnClick", function() botScope = "whisper"; refresh() end)
    refresh()

    local note = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("LEFT", whisBtn, "RIGHT", 12, 0)
    note:SetText("Whisper needs a bot targeted")
    return bar
end

WLGM.RegisterTab({
    id = "bots", label = "Bots",
    builder = function(parent)
        local bar = buildScopeSelector(parent)
        local body = CreateFrame("Frame", nil, parent)
        body:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
        body:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        WLGM.BuildSubTabs(body, {
            { label = "Party",    rows = Party,    layoutOpts = { rowsPerColumn = 9, columnWidth = 380, sectionTitle = "Build your party (.playerbots)" } },
            { label = "Orders",   builder = function(p)
                WLGM.BuildScrollSections(p, {
                    { title = "Movement", rows = Movement },
                    { title = "Combat",   rows = Combat },
                })
            end },
            { label = "Roles",    rows = Roles,    layoutOpts = { yTop = 8, sectionTitle = "Set roles via spec ($talents)" } },
            { label = "Travel & Guide", builder = function(p)
                WLGM.BuildScrollSections(p, { { rows = Travel } },
                    "Bots can walk you anywhere: spoken phrases like 'take me to booty bay' or 'lead me to an innkeeper' start a guide escort (see Talk & Command). "
                    .. "The raw $wl guide <mapId> <x> <y> <z> <zTol> [label] form is internal/advanced - the spoken phrases build it for you.")
            end },
            { label = "Talk & Command", builder = talkBuilder },
            { label = "Manage",   rows = Manage,   layoutOpts = { rowsPerColumn = 10, columnWidth = 400, sectionTitle = "Regear, re-roll & account linking (.playerbots)" } },
            { label = "Console",  rows = Console,  layoutOpts = { yTop = 8, sectionTitle = "Random-bot population (GM / owner)" } },
        }, "bots")
    end,
})
