-- WoWLegends_GM/Core/Util.lua
-- Theme colours, print helpers, small string/target utilities.

local addonName, WLGM = ...

-- ─── Brand palette ─────────────────────────────────────────────────────────
WLGM.colors = {
    brand   = "|cffffc94d",   -- WoW Legends gold
    accent  = "|cff45d7ff",   -- frost cyan (Wrath)
    legend  = "|cffff8000",   -- legendary orange (WL-only marker)
    good     = "|cff33ff99",
    warn     = "|cffff9933",
    danger   = "|cffff4444",
    label    = "|cffffd100",
    muted    = "|cff8899aa",
    white    = "|cffffffff",
    reset    = "|r",
}

-- RGB equivalents for SetTextColor / SetVertexColor calls.
WLGM.rgb = {
    brand  = { 1.00, 0.79, 0.30 },
    accent = { 0.27, 0.84, 1.00 },
    legend = { 1.00, 0.50, 0.00 },
    good   = { 0.20, 1.00, 0.60 },
    danger = { 1.00, 0.27, 0.27 },
    muted  = { 0.53, 0.60, 0.67 },
}

-- Access-tier metadata (mirrors WoW item-quality colours for instant reading).
WLGM.tiers = {
    [0] = { name = "Player",        color = "|cff9d9d9d", rgb = { 0.62, 0.62, 0.62 } },
    [1] = { name = "Moderator",     color = "|cff1eff00", rgb = { 0.12, 1.00, 0.00 } },
    [2] = { name = "Game Master",   color = "|cff0070dd", rgb = { 0.00, 0.44, 0.87 } },
    [3] = { name = "Administrator", color = "|cffa335ee", rgb = { 0.64, 0.21, 0.93 } },
    [4] = { name = "Console",       color = "|cffff8000", rgb = { 1.00, 0.50, 0.00 } },
    [5] = { name = "Bot order ($)",  color = "|cffe6cc80", rgb = { 0.90, 0.80, 0.50 } },
}

function WLGM.TierTag(level)
    local t = WLGM.tiers[level or 0] or WLGM.tiers[0]
    return t.color .. t.name .. WLGM.colors.reset
end

-- ─── Print ─────────────────────────────────────────────────────────────────
function WLGM.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(WLGM.colors.brand .. "WLGM" .. WLGM.colors.reset .. ": " .. tostring(msg))
end

function WLGM.Warn(msg)
    DEFAULT_CHAT_FRAME:AddMessage(WLGM.colors.brand .. "WLGM" .. WLGM.colors.reset
        .. ": " .. WLGM.colors.warn .. tostring(msg) .. WLGM.colors.reset)
end

-- ─── String / value helpers ────────────────────────────────────────────────
function WLGM.IsBlank(s)
    return s == nil or s == "" or (type(s) == "string" and s:match("^%s*$") ~= nil)
end

function WLGM.Trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Resolve an arg value, applying its fallback when blank.
--   fallback="target" → UnitName("target")
--   fallback="self"   → UnitName("player")
function WLGM.ResolveArg(value, arg)
    if value == nil or value == "" then
        if arg and arg.fallback == "target" then
            local n = UnitName("target")
            if n and n ~= "" then return n end
        elseif arg and arg.fallback == "self" then
            return UnitName("player")
        end
        return nil
    end
    return value
end
