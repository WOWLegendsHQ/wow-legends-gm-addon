-- WoWLegends_GM/UI/MainFrame.lua
-- Movable parent window: header, left tab rail, content area, footer legend.

local addonName, WLGM = ...

local FRAME_W, FRAME_H = 940, 588
local HEADER_H = 32
local RAIL_W   = 132
local FOOTER_H = 22

WLGM.tabs = {}   -- { id, label, wl, builder, onShow, button, contentFrame }

function WLGM.RegisterTab(def) table.insert(WLGM.tabs, def) end

local function selectTab(index)
    local tabs = WLGM.tabs
    if not tabs[index] then return end
    for i, tab in ipairs(tabs) do
        if tab.button then
            if i == index then
                tab.button.bg:SetTexture(0.10, 0.30, 0.40, 0.95)
                tab.button.sel:Show()
                tab.button.label:SetTextColor(1, 0.82, 0.30)
            else
                tab.button.bg:SetTexture(0, 0, 0, 0)
                tab.button.sel:Hide()
                tab.button.label:SetTextColor(tab.wl and 1 or 0.85, tab.wl and 0.79 or 0.85, tab.wl and 0.30 or 0.88)
            end
        end
        if tab.contentFrame then
            if i == index then tab.contentFrame:Show() else tab.contentFrame:Hide() end
        end
    end
    if tabs[index].onShow then pcall(tabs[index].onShow) end
    if WLGM.db then WLGM.db.activeTab = index end
end
WLGM.SelectTab = selectTab

-- Jump to a tab by id (used by /wlgm search and cross-tab links).
function WLGM.SelectTabById(id)
    for i, tab in ipairs(WLGM.tabs) do
        if tab.id == id then selectTab(i); return i end
    end
end

local function buildRail(main)
    local rail = CreateFrame("Frame", nil, main)
    rail:SetPoint("TOPLEFT", main, "TOPLEFT", 6, -HEADER_H - 4)
    rail:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 6, FOOTER_H + 4)
    rail:SetWidth(RAIL_W)
    WLGM.ApplyBackdrop(rail, "inset", 0.5, 0.02, 0.03, 0.05)
    main.rail = rail
    return rail
end

local function buildAllTabs()
    local main = WoWLegendsGM_MainFrame
    local rail = main.rail

    local content = CreateFrame("Frame", nil, main)
    content:SetPoint("TOPLEFT", rail, "TOPRIGHT", 8, 0)
    content:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -8, FOOTER_H + 4)
    main.contentArea = content

    local prev
    for i, tab in ipairs(WLGM.tabs) do
        local label = tab.label
        if tab.wl then label = "* " .. label end
        local btn = WLGM.MakeFlatButton(rail, RAIL_W - 12, 30, label, { padLeft = 10, font = "GameFontNormal" })
        btn.bg:SetTexture(0, 0, 0, 0)

        -- Left selection accent bar (shown only on the active tab).
        local sel = btn:CreateTexture(nil, "OVERLAY")
        sel:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 0)
        sel:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -2, 0)
        sel:SetWidth(3)
        sel:SetTexture(1, 0.79, 0.30, 1)
        sel:Hide()
        btn.sel = sel

        if prev then btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
        else btn:SetPoint("TOPLEFT", rail, "TOPLEFT", 6, -6) end
        btn:SetID(i)
        btn:SetScript("OnClick", function(self) selectTab(self:GetID()) end)
        tab.button = btn
        prev = btn

        local cf = CreateFrame("Frame", nil, content)
        cf:SetAllPoints(content)
        cf:Hide()
        tab.contentFrame = cf
        if tab.builder then
            local ok, err = pcall(tab.builder, cf)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff5555WLGM tab '" .. tostring(tab.label) .. "' build error:|r " .. tostring(err))
            end
        end
    end

    selectTab((WLGM.db and WLGM.db.activeTab) or 1)
end

function WLGM.RestoreMainFramePosition()
    if WoWLegendsGM_MainFrame then
        WLGM.RestoreFramePoint(WoWLegendsGM_MainFrame, "frame", WLGM.defaults.frame)
    end
end

local function createMainFrame()
    local f = CreateFrame("Frame", "WoWLegendsGM_MainFrame", UIParent)
    f:SetSize(FRAME_W, FRAME_H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); WLGM.SaveFramePoint(self, "frame") end)
    f:SetScript("OnShow", function() if WLGM.db and WLGM.db.frame then WLGM.db.frame.shown = true end end)
    f:SetScript("OnHide", function() if WLGM.db and WLGM.db.frame then WLGM.db.frame.shown = false end end)
    WLGM.ApplyBackdrop(f, "panel", 0.95)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    header:SetHeight(HEADER_H)
    WLGM.ApplyBackdrop(header, "inset", 0.6, 0.06, 0.09, 0.12)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", header, "LEFT", 12, 0)
    title:SetText(WLGM.colors.brand .. "WoW Legends" .. WLGM.colors.reset .. " " ..
        WLGM.colors.white .. "GM" .. WLGM.colors.reset ..
        "  " .. WLGM.colors.muted .. "v" .. WLGM.version .. WLGM.colors.reset)

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("RIGHT", header, "RIGHT", 2, 0)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Current-target readout (many commands fall back to UnitName("target")).
    local targetFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetFS:SetPoint("RIGHT", close, "LEFT", -10, 0)
    local function updateTarget()
        local n = UnitName("target")
        if n and n ~= "" then
            local _, cls = UnitClass("target")
            targetFS:SetText(WLGM.colors.muted .. "Target: " .. WLGM.colors.reset .. WLGM.colors.accent .. n .. WLGM.colors.reset)
        else
            targetFS:SetText(WLGM.colors.muted .. "No target" .. WLGM.colors.reset)
        end
    end
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:SetScript("OnEvent", updateTarget)
    f:HookScript("OnShow", updateTarget)

    -- Global search box (Enter jumps to the Search tab, pre-filtered).
    local search = WLGM.MakeFlatEditBox(header, 180, 20, "Search all commands...")
    search:SetPoint("RIGHT", targetFS, "LEFT", -16, 0)
    search:SetScript("OnEnterPressed", function(self)
        local q = self:GetText()
        self:ClearFocus()
        if WLGM.OpenSearch then WLGM.OpenSearch(q) end
    end)
    f.searchBox = search

    f.header = header

    -- Footer: access-tier legend.
    local footer = CreateFrame("Frame", nil, f)
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 4)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
    footer:SetHeight(FOOTER_H)
    local legend = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    legend:SetPoint("LEFT", footer, "LEFT", 4, 0)
    local parts = {}
    for i = 0, 5 do table.insert(parts, WLGM.tiers[i].color .. WLGM.tiers[i].name .. WLGM.colors.reset) end
    legend:SetText(table.concat(parts, "  ") .. "    " .. WLGM.colors.legend .. "* WoW Legends exclusive" .. WLGM.colors.reset)

    f.tabRail = buildRail(f)
    f:Hide()
    return f
end

WLGM.AddLogin(function()
    if not WoWLegendsGM_MainFrame then createMainFrame() end
    WLGM.RestoreMainFramePosition()
    buildAllTabs()
    if WLGM.db and WLGM.db.frame and WLGM.db.frame.shown then WoWLegendsGM_MainFrame:Show() end
end)

-- Create the shell early so tab files can reference it; surface load errors.
local ok, err = pcall(createMainFrame)
if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000WLGM MainFrame ERROR:|r " .. tostring(err))
    WLGM._mainFrameLoadError = tostring(err)
end
