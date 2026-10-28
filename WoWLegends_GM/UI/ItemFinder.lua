-- WoWLegends_GM/UI/ItemFinder.lua
-- "Find & Add" sub-tab for the Items tab: search items by name (server-side
-- `.lookup item`, see Core/ItemSearch.lua), pick from the results and spawn
-- them with one click - no more looking up item IDs on Wowhead.

local addonName, WLGM = ...

local ROW_H    = 24
local CACHE    = "Items:finder"   -- input-cache row key

local function qualityHex(id)
    local _, _, quality = GetItemInfo(id)
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local c = ITEM_QUALITY_COLORS[quality]
        return c.hex or string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    return "|cffffffff"
end

function WLGM.BuildItemFinder(parent)
    local results = {}

    -- ─── Controls: search ────────────────────────────────────────────────
    local box = WLGM.MakeFlatEditBox(parent, 260, 22, "Item name, e.g. shadowmourne")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)

    local searchBtn = WLGM.MakeFlatButton(parent, 80, 22, "Search", { justify = "CENTER" })
    searchBtn:SetPoint("LEFT", box, "RIGHT", 8, 0)

    local status = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("LEFT", searchBtn, "RIGHT", 10, 0)
    status:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    status:SetJustifyH("LEFT")

    -- ─── Controls: who / how many ────────────────────────────────────────
    local giveLbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    giveLbl:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
    giveLbl:SetText(WLGM.colors.label .. "Give to" .. WLGM.colors.reset)

    local playerBox = WLGM.MakeFlatEditBox(parent, 150, 22, "me / selected char")
    playerBox:SetPoint("LEFT", giveLbl, "RIGHT", 8, 0)

    local countLbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLbl:SetPoint("LEFT", playerBox, "RIGHT", 14, 0)
    countLbl:SetText(WLGM.colors.label .. "Count" .. WLGM.colors.reset)

    local countBox = WLGM.MakeFlatEditBox(parent, 60, 22, "1", true)
    countBox:SetPoint("LEFT", countLbl, "RIGHT", 8, 0)

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", countBox, "RIGHT", 14, 0)
    hint:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText("Click Add to spawn. Shift-click a row to link it in chat.")

    for _, pair in ipairs({ { box, "query" }, { playerBox, "player" }, { countBox, "count" } }) do
        local e, key = pair[1], pair[2]
        local cached = WLGM.GetInputCache(CACHE, key)
        if cached and cached ~= "" then e:SetText(cached) end
        if e.refreshHint then e.refreshHint() end
        e:HookScript("OnTextChanged", function(self) WLGM.SetInputCache(CACHE, key, self:GetText()) end)
        e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    end

    -- ─── Results list (virtual scroll) ───────────────────────────────────
    local list = CreateFrame("Frame", nil, parent)
    list:SetPoint("TOPLEFT", giveLbl, "BOTTOMLEFT", 0, -12)
    list:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)

    local bg = list:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(list); bg:SetTexture(0, 0, 0, 0.25)

    local scroll = CreateFrame("ScrollFrame", "WLGM_ItemFinderScroll", list, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 0)

    local empty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", list, "CENTER", 0, 0)
    empty:SetText("Type part of an item name above and press Enter.")

    local rows = {}
    local updateList

    local function currentCount() return tonumber(countBox:GetText()) or 1 end

    local function makeRow(i)
        local r = CreateFrame("Button", nil, list)
        r:SetHeight(ROW_H)
        r:SetPoint("TOPLEFT", list, "TOPLEFT", 2, -(i - 1) * ROW_H - 2)
        r:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
        r:RegisterForClicks("LeftButtonUp")

        local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(r); hl:SetTexture(1, 1, 1, 0.08)

        local icon = r:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ROW_H - 4, ROW_H - 4)
        icon:SetPoint("LEFT", r, "LEFT", 2, 0)
        r.icon = icon

        local add = WLGM.MakeFlatButton(r, 54, ROW_H - 4, "Add", { justify = "CENTER" })
        add:SetPoint("RIGHT", r, "RIGHT", -4, 0)
        add.bg:SetTexture(0.10, 0.30, 0.18, 0.95)
        r.add = add

        local idFS = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        idFS:SetPoint("RIGHT", add, "LEFT", -10, 0)
        idFS:SetWidth(70); idFS:SetJustifyH("RIGHT")
        r.idFS = idFS

        local name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        name:SetPoint("RIGHT", idFS, "LEFT", -8, 0)
        name:SetJustifyH("LEFT")
        r.name = name

        add:SetScript("OnClick", function()
            local d = r.data; if not d then return end
            WLGM.AddItemById(d.id, currentCount(), playerBox:GetText())
        end)
        add:SetScript("OnEnter", function(self)
            local d = r.data; if not d then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Add " .. currentCount() .. "x " .. d.name, 1, 0.82, 0.30)
            local p = WLGM.Trim(playerBox:GetText() or "")
            GameTooltip:AddLine(p ~= "" and (".additem " .. p .. " " .. d.id .. " " .. currentCount())
                or (".additem " .. d.id .. " " .. currentCount()), 0.27, 0.84, 1)
            GameTooltip:Show()
        end)
        add:SetScript("OnLeave", function() GameTooltip:Hide() end)

        r:SetScript("OnClick", function(self)
            local d = self.data; if not d then return end
            if IsShiftKeyDown() then
                local _, link = GetItemInfo(d.id)
                link = link or ("|cffffffff|Hitem:" .. d.id .. ":0:0:0:0:0:0:0:0|h[" .. d.name .. "]|h|r")
                if not ChatEdit_InsertLink(link) then ChatFrame_OpenChat(link) end
            end
        end)
        r:SetScript("OnEnter", function(self)
            local d = self.data; if not d then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. d.id .. ":0:0:0:0:0:0:0")
            GameTooltip:AddLine("Item ID " .. d.id, 0.27, 0.84, 1)
            GameTooltip:Show()
            -- Hovering asks the server for the item; recolour once it's cached.
            WLGM.After(0.5, function() if updateList then updateList() end end)
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return r
    end

    local function visibleRows()
        local h = list:GetHeight() or 0
        return math.max(1, math.floor((h - 4) / ROW_H))
    end

    updateList = function()
        local n = visibleRows()
        for i = #rows + 1, n do rows[i] = makeRow(i) end
        local off = FauxScrollFrame_GetOffset(scroll)
        for i, r in ipairs(rows) do
            local d = (i <= n) and results[off + i] or nil
            if d then
                r.data = d
                r.icon:SetTexture(GetItemIcon(d.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
                r.name:SetText(qualityHex(d.id) .. d.name .. "|r")
                r.idFS:SetText(d.id)
                r:Show()
            else
                r.data = nil; r:Hide()
            end
        end
        FauxScrollFrame_Update(scroll, #results, n, ROW_H)
        if #results > 0 then empty:Hide() else empty:Show() end
    end

    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, updateList)
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local target = FauxScrollFrame_GetOffset(self) - delta * 3
        if target < 0 then target = 0 end
        FauxScrollFrame_OnVerticalScroll(self, target * ROW_H, ROW_H, updateList)
    end)
    list:SetScript("OnShow", updateList)
    list:SetScript("OnSizeChanged", updateList)

    -- ─── Searching ───────────────────────────────────────────────────────
    local function doSearch()
        box:ClearFocus()
        local q = box:GetText()
        local started = WLGM.SearchItems(q, function(found, info)
            results = found
            if info.none or #found == 0 then
                status:SetText(WLGM.colors.warn .. "No items found for \"" .. info.query .. "\"." .. WLGM.colors.reset)
                empty:SetText("No matches. Try a shorter or different part of the name.")
            else
                local txt = WLGM.colors.good .. #found .. WLGM.colors.reset .. " item(s) for \"" .. info.query .. "\""
                if info.truncated then
                    txt = txt .. WLGM.colors.warn .. "  (server result limit hit - be more specific)" .. WLGM.colors.reset
                end
                status:SetText(txt)
            end
            FauxScrollFrame_OnVerticalScroll(scroll, 0, ROW_H, updateList)
        end)
        if started then
            status:SetText(WLGM.colors.muted .. "Searching..." .. WLGM.colors.reset)
        end
    end

    box:SetScript("OnEnterPressed", doSearch)
    searchBtn:SetScript("OnClick", doSearch)
    countBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    playerBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    -- /wlgm item <name> jumps here and searches.
    WLGM.OpenItemFinder = function(q)
        if WLGM.SelectTabById then WLGM.SelectTabById("items") end
        if parent.selectSelf then parent.selectSelf() end
        if q and WLGM.Trim(q) ~= "" then box:SetText(WLGM.Trim(q)) end
        doSearch()
    end

    updateList()
end
