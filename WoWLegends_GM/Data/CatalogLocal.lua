-- WoWLegends_GM/Data/CatalogLocal.lua
-- HAND-AUTHORED catalog overlay (safe to edit). Catalog.lua is regenerated
-- from the website and any hand-edit there is lost on the next regen — this
-- file patches/append entries AFTER it loads, so addon-critical corrections
-- survive regeneration.

local addonName, WLGM = ...

-- Enriched or added entries, keyed by exact command name (n). Fields mirror
-- Catalog.lua: l=accessLevel g=group u=usage d=description w=WLonly.
-- The two 'talents spec' rows ENRICH in place: their n must match the website's
-- name exactly. The site added a '$' prefix to every bot order on 2026-10-27;
-- if these rows ever append instead (count = site + 4), re-anchor them here.
local OVERRIDES = {
    { n = "$talents spec [name]", l = 5, g = "bot:setup", u = "$talents spec <premadeName>",
      d = "Set the bot's spec (= its tank/heal/dps role). <premadeName> must be the PREMADE config name, matched exactly - e.g. 'prot pve', 'resto pvp' - NOT the tree name the bot reports ('protection' fails with 'Spec not found'). Whisper '$talents spec list' for the bot's own valid names, or use the dropdown in Bots > Roles (it also auto-runs autogear, since a spec change alone does not re-gear).",
      w = 0 },
    { n = "$talents spec list", l = 5, g = "bot:setup", u = "$talents spec list",
      d = "List the bot's valid PREMADE spec names (live from the server config). These exact strings - 'prot pve', 'cat pve', ... - are what '$talents spec <name>' accepts; the friendly tree names it reports elsewhere are not.",
      w = 0 },

    -- ADDED, not enriched: the website catalog lists the 10 PLAYER .camp
    -- commands only. These two exist in the shipped v1.5.0 module
    -- (wowlegends_warbandcamp.cpp command table, verified 2026-08-09) and are
    -- GM/admin tools, which is exactly what this addon is for. See
    -- GM_COMMANDS.md section 1.10.
    -- NOTE for the next catalog regen: these two APPEND on purpose, so the
    -- harness count is the website total + 2. That is NOT the anchor-drift
    -- symptom - check the 'talents spec' rows enriched in place instead.
    { n = ".camp catalogue", l = 2, g = "warband camp", u = ".camp catalogue",
      d = "GM screenshot rig: WIPES your own camp's props, then lays the entire 69-piece catalogue out on a grid around you and lists the labels in placement order. Stand in your camp; slots that fail the flatness check are skipped (flat ground like Mulgore works best). Not a player tool.",
      w = 1 },
    { n = ".camp diag", l = 3, g = "warband camp", u = ".camp diag <name>",
      d = "Admin self-test against any ONLINE character (a bot will do): reports map/zone/position, outdoors, ground delta, water, phase mask, whether a claim would be allowed here, the phase bit on offer and the realm camp count - then really spawns a prop through the live path, proves it is in the map and removes it. The only .camp command that works from RA/console.",
      w = 1 },

    -- v1.8.0 Living World GM subcommands (read from the mod-wowlegends command
    -- tables, 2026-11-02). The website lists only the player rows and a single
    -- .crowd summary, so these APPEND today; if the site ever adds one under the
    -- same name it ENRICHES instead, so nothing doubles up. Same rows as the
    -- Living World tab (UI/Tabs/World.lua).
    { n = ".bounty status", l = 2, g = "most wanted", u = ".bounty status", d = "GM overview of the bounty system and its live settings.", w = 1 },
    { n = ".bounty set", l = 2, g = "most wanted", u = ".bounty set <char> <amount>", d = "Set a character's bounty exactly; wanted level = floor(sqrt(amount / 10)): 250 = W5, 1000 = W10, 4000 = W20. Online only.", w = 1 },
    { n = ".bounty coins", l = 2, g = "most wanted", u = ".bounty coins <char> <amount>", d = "Set a character's Bounty Coins exactly. Online only.", w = 1 },
    { n = ".bounty addcoins", l = 2, g = "most wanted", u = ".bounty addcoins <char> <amount>", d = "Add Bounty Coins to a character. Works offline.", w = 1 },
    { n = ".bounty hunter", l = 2, g = "most wanted", u = ".bounty hunter [char]", d = "Send a bounty hunter now, ignoring a smoke bomb. Blank = yourself. Online only.", w = 1 },
    { n = ".bounty hitman", l = 2, g = "most wanted", u = ".bounty hitman <target> <wanted> <delay seconds> <buyer>", d = "A hitman contract as if the buyer paid: wanted level W, sent after the delay. Target and buyer may be offline.", w = 1 },
    { n = ".bounty reset", l = 2, g = "most wanted", u = ".bounty reset <char>", d = "Wipe a character's whole bounty record. Online only.", w = 1 },
    { n = ".nemesis status", l = 2, g = "nemesis", u = ".nemesis status <player>", d = "A player's nemesis bot, wins on each side, its rank and when it last hunted. Online only.", w = 1 },
    { n = ".nemesis set", l = 2, g = "nemesis", u = ".nemesis set <player> <bot>", d = "Make that bot the player's nemesis. Both online.", w = 1 },
    { n = ".nemesis test", l = 2, g = "nemesis", u = ".nemesis test <player>", d = "Send the player's nemesis now - only where they can be attacked.", w = 1 },
    { n = ".nemesis clear", l = 2, g = "nemesis", u = ".nemesis clear <player>", d = "Remove the player's nemesis. Online only.", w = 1 },
    { n = ".botlife status", l = 2, g = "bot life", u = ".botlife status", d = "Is Bot life on, and which hour and phase of the day it follows.", w = 1 },
    { n = ".botlife on", l = 2, g = "bot life", u = ".botlife on", d = "Switch Bot life on until restart.", w = 1 },
    { n = ".botlife off", l = 2, g = "bot life", u = ".botlife off", d = "Switch Bot life off until restart.", w = 1 },
    { n = ".botlife hour", l = 2, g = "bot life", u = ".botlife hour <0-23|auto>", d = "Pretend it is that hour of the day; auto follows the realm clock again.", w = 1 },
    { n = ".botlife census", l = 2, g = "bot life", u = ".botlife census", d = "Count the bots in town and inns and out in the world.", w = 1 },
    { n = ".innkeeper status", l = 2, g = "innkeepers", u = ".innkeeper status", d = "Feature state, current shift, night hours and each inn's keepers.", w = 1 },
    { n = ".innkeeper shift", l = 2, g = "innkeepers", u = ".innkeeper shift [auto|day|night]", d = "Force the day or night keeper on duty, or follow the clock.", w = 1 },
    { n = ".innkeeper deeds", l = 2, g = "innkeepers", u = ".innkeeper deeds <player>", d = "The deeds the server remembers for a player (last 20). Online only.", w = 1 },
    { n = ".innkeeper deed", l = 2, g = "innkeepers", u = ".innkeeper deed <player> <raid|dungeon|worldboss|loot|level|pvp|death|quest> <what> [| where]", d = "Record a deed by hand, for testing. Online only.", w = 1 },
    { n = ".innkeeper test", l = 2, g = "innkeepers", u = ".innkeeper test <sw|org|dal-a|dal-h> <player> [say text]", d = "The keeper on duty greets the player, or answers the line. AI-written and queued: needs AI chat.", w = 1 },
}

local function apply()
    local cat = WLGM.Catalog
    if not cat then return end
    local byName = {}
    for _, e in ipairs(cat) do byName[e.n] = e end
    for _, o in ipairs(OVERRIDES) do
        local e = byName[o.n]
        if e then
            e.u, e.d = o.u, o.d       -- enrich the generated entry in place
        else
            table.insert(cat, o)      -- entry missing from the website data: add it
        end
    end
end
apply()
