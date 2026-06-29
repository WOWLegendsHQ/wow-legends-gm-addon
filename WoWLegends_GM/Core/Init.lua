-- WoWLegends_GM/Core/Init.lua
-- Addon namespace, defaults, event wiring, slash commands, C_Timer shim.
--
-- WoW Legends GM panel — WotLK 3.3.5a (AzerothCore Playerbot branch).
-- Every file receives the addon name and the shared private table via `...`:
--     local addonName, WLGM = ...
-- so there is exactly one shared table and no reliance on a global. We also
-- mirror it to _G.WLGM so it can be poked from /script for debugging.

local addonName, WLGM = ...
_G.WLGM = WLGM

WLGM.name    = "WoW Legends GM"
WLGM.short   = "WLGM"
WLGM.version = GetAddOnMetadata(addonName, "Version") or "0.1.0"

-- Persisted defaults (deep-merged into the SavedVariable on load).
WLGM.defaults = {
    frame   = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0, shown = false },
    button  = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -28, y = -90 },
    favorites = {},
    history   = {},
    inputs    = {},
    activeTab = 1,
    subTabs   = {},          -- per-tab remembered sub-tab index, keyed by tab id
    minimap   = { hide = false },
    confirmDanger = true,     -- show confirm popup for danger commands
}

local function copyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            copyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end
WLGM.CopyDefaults = copyDefaults

-- ─── Login-handler registry ───────────────────────────────────────────────
-- Each module appends a function via WLGM.AddLogin(); on PLAYER_LOGIN we run
-- each in sequence wrapped in pcall, so a failure in one (e.g. a tab builder)
-- never blocks the others (e.g. the toggle button).
WLGM._loginHandlers = {}
function WLGM.AddLogin(fn) table.insert(WLGM._loginHandlers, fn) end

-- ─── C_Timer.After shim ────────────────────────────────────────────────────
-- 3.3.5a has no C_Timer. A single shared OnUpdate ticker drains a queue of
-- delayed callbacks — good enough for the short, low-volume delays we use.
do
    local queue = {}
    local ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        for i = #queue, 1, -1 do
            if now >= queue[i].at then
                local fn = queue[i].fn
                table.remove(queue, i)
                local ok, err = pcall(fn)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555WLGM timer error:|r " .. tostring(err))
                end
            end
        end
        if #queue == 0 then self:Hide() end
    end)
    -- WLGM.After(delay, fn) — run fn after `delay` seconds.
    function WLGM.After(delay, fn)
        table.insert(queue, { at = GetTime() + (delay or 0), fn = fn })
        ticker:Show()
    end
end

-- ─── Event wiring ──────────────────────────────────────────────────────────
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        WoWLegendsGM_DB = WoWLegendsGM_DB or {}
        copyDefaults(WLGM.defaults, WoWLegendsGM_DB)
        WLGM.db = WoWLegendsGM_DB
    elseif event == "PLAYER_LOGIN" then
        for i, fn in ipairs(WLGM._loginHandlers or {}) do
            local ok, err = pcall(fn)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff5555WLGM login handler #" .. i .. " error:|r " .. tostring(err))
            end
        end
    end
end)

-- ─── Slash commands ────────────────────────────────────────────────────────
SLASH_WLGM1 = "/wlgm"
SLASH_WLGM2 = "/gm"
SLASH_WLGM3 = "/gmpanel"
SlashCmdList["WLGM"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lcmd = msg:lower()

    -- `probe` preserves original case (character names etc. matter).
    if lcmd == "probe" or lcmd:sub(1, 6) == "probe " then
        if WLGM.Probe then WLGM.Probe(msg:sub(7)) end
        return
    end

    if lcmd == "reset" then
        WLGM.db.frame, WLGM.db.button = nil, nil
        copyDefaults(WLGM.defaults, WLGM.db)
        if WLGM.RestoreMainFramePosition then WLGM.RestoreMainFramePosition() end
        if WLGM.RestoreButtonPosition then WLGM.RestoreButtonPosition() end
        WLGM.Print("positions reset.")
    elseif lcmd == "show" then
        if WoWLegendsGM_MainFrame then WoWLegendsGM_MainFrame:Show() end
    elseif lcmd == "hide" then
        if WoWLegendsGM_MainFrame then WoWLegendsGM_MainFrame:Hide() end
    elseif lcmd == "debug" then
        WLGM.DumpDebug()
    elseif lcmd:sub(1, 6) == "search" then
        if WLGM.OpenSearch then WLGM.OpenSearch(msg:sub(7)) end
    else
        if WLGM.Toggle then WLGM.Toggle() end
    end
end

-- Module load-status dump for troubleshooting (/wlgm debug).
function WLGM.DumpDebug()
    local c = WLGM.colors
    local function pp(label, val) DEFAULT_CHAT_FRAME:AddMessage("  " .. label .. ": " .. tostring(val)) end
    DEFAULT_CHAT_FRAME:AddMessage(c.accent .. WLGM.name .. " debug" .. c.reset .. "  v" .. WLGM.version)
    pp("MainFrame", WoWLegendsGM_MainFrame)
    pp("ToggleButton", WoWLegendsGM_ToggleButton)
    pp("tabs registered", WLGM.tabs and #WLGM.tabs or 0)
    pp("catalog entries", WLGM.Catalog and #WLGM.Catalog or 0)
    if WLGM._mainFrameLoadError then pp("MainFrame load error", WLGM._mainFrameLoadError) end
    DEFAULT_CHAT_FRAME:AddMessage("  modules:")
    for _, m in ipairs({
        { "Util",          WLGM.colors },
        { "SavedVars",     WLGM.PushHistory },
        { "CommandRunner", WLGM.RunCommand },
        { "Commands",      WLGM.Commands },
        { "Catalog",       WLGM.Catalog },
        { "Teleports",     WLGM.Teleports },
        { "ConfirmDialog", StaticPopupDialogs and StaticPopupDialogs["WLGM_CONFIRM_CMD"] },
        { "Widgets",       WLGM.CreateCommandRow },
        { "MainFrame",     WLGM.RegisterTab },
        { "ToggleButton",  WLGM.Toggle },
    }) do
        pp("    " .. m[1], m[2] and (c.good .. "ok" .. c.reset) or (c.danger .. "MISSING" .. c.reset))
    end
end
