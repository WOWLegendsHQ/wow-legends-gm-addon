-- WoWLegends_GM/Data/CatalogLocal.lua
-- HAND-AUTHORED catalog overlay (safe to edit). Catalog.lua is regenerated
-- from the website and any hand-edit there is lost on the next regen — this
-- file patches/append entries AFTER it loads, so addon-critical corrections
-- survive regeneration.

local addonName, WLGM = ...

-- Enriched or added entries, keyed by exact command name (n). Fields mirror
-- Catalog.lua: l=accessLevel g=group u=usage d=description w=WLonly.
local OVERRIDES = {
    { n = "talents spec [name]", l = 5, g = "bot:setup", u = "talents spec <premadeName>",
      d = "Set the bot's spec (= its tank/heal/dps role). <premadeName> must be the PREMADE config name, matched exactly - e.g. 'prot pve', 'resto pvp' - NOT the tree name the bot reports ('protection' fails with 'Spec not found'). Whisper 'talents spec list' for the bot's own valid names, or use the dropdown in Bots > Roles (it also auto-runs autogear, since a spec change alone does not re-gear).",
      w = 0 },
    { n = "talents spec list", l = 5, g = "bot:setup", u = "talents spec list",
      d = "List the bot's valid PREMADE spec names (live from the server config). These exact strings - 'prot pve', 'cat pve', ... - are what 'talents spec <name>' accepts; the friendly tree names it reports elsewhere are not.",
      w = 0 },
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
