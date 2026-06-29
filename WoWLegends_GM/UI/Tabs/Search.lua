-- WoWLegends_GM/UI/Tabs/Search.lua
-- Browse / search all 869 commands (Data/Catalog.lua) with a virtual scroll
-- list, text filter, per-tier toggles, and a WoW Legends-only toggle.

local addonName, WLGM = ...

local NUM_ROWS = 18
local ROW_H    = 22

local function isBot(entry) return entry.n:sub(1, 1) ~= "." end

WLGM.RegisterTab({
    id = "search", label = "Search",
    builder = function(parent)
        local state = { query = "", wlOnly = false, tiers = {} }
        for i = 0, 5 do state.tiers[i] = true end
        local filtered = {}

        -- Controls row -------------------------------------------------------
        local box = WLGM.MakeFlatEditBox(parent, 220, 22, "Filter by name, group or description...")
        box:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)

        local wlBtn = WLGM.MakeFlatButton(parent, 90, 22, "* WL only", { justify = "CENTER" })
        wlBtn:SetPoint("LEFT", box, "RIGHT", 10, 0)

        local countFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countFS:SetPoint("RIGHT", parent, "TOPRIGHT", -28, 0)
        countFS:SetPoint("TOP", box, "TOP", 0, -4)

        -- Tier toggle row ----------------------------------------------------
        local tierBtns = {}
        local prev
        for i = 0, 5 do
            local t = WLGM.tiers[i]
            local tb = WLGM.MakeFlatButton(parent, 96, 18, t.name, { justify = "CENTER", font = "GameFontNormalSmall" })
            tb.label:SetText(t.color .. t.name .. WLGM.colors.reset)
            if prev then tb:SetPoint("LEFT", prev, "RIGHT", 4, 0)
            else tb:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -6) end
            tb:SetID(i)
            tierBtns[i] = tb
            prev = tb
        end

        -- List ---------------------------------------------------------------
        local list = CreateFrame("Frame", nil, parent)
        list:SetPoint("TOPLEFT", tierBtns[0], "BOTTOMLEFT", 0, -8)
        list:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)

        local scroll = CreateFrame("ScrollFrame", "WLGM_SearchScroll", list, "FauxScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
        scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 0)

        local rows = {}
        local function makeRow(i)
            local r = CreateFrame("Button", nil, list)
            r:SetHeight(ROW_H)
            r:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
            r:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
            r:RegisterForClicks("LeftButtonUp")

            local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(r); hl:SetTexture(1, 1, 1, 0.10)
            local pip = r:CreateTexture(nil, "ARTWORK"); pip:SetPoint("LEFT", r, "LEFT", 2, 0); pip:SetSize(5, ROW_H - 6)
            r.pip = pip
            local name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            name:SetPoint("LEFT", pip, "RIGHT", 6, 0); name:SetWidth(232); name:SetJustifyH("LEFT")
            r.name = name
            local grp = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            grp:SetPoint("LEFT", name, "RIGHT", 4, 0); grp:SetWidth(96); grp:SetJustifyH("LEFT")
            r.grp = grp
            local use = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            use:SetPoint("LEFT", grp, "RIGHT", 4, 0); use:SetPoint("RIGHT", r, "RIGHT", -4, 0); use:SetJustifyH("LEFT")
            r.use = use

            r:SetScript("OnClick", function(self)
                local d = self.data; if not d then return end
                if isBot(d) then
                    if IsShiftKeyDown() then WLGM.RunBotOrder(d.n, { scope = "party" })
                    else ChatFrame_OpenChat("$" .. (d.u:gsub("^%$", ""))) end
                else
                    if IsShiftKeyDown() then WLGM.RunCommand(d.n)
                    else ChatFrame_OpenChat(d.u) end
                end
            end)
            r:SetScript("OnEnter", function(self)
                local d = self.data; if not d then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                GameTooltip:SetText((isBot(d) and (WLGM.colors.legend) or "") .. d.n, 1, 0.82, 0.30)
                GameTooltip:AddLine(d.u, 0.27, 0.84, 1, true)
                if d.d ~= "" then GameTooltip:AddLine(d.d, 1, 1, 1, true) end
                GameTooltip:AddLine(" ")
                if isBot(d) then
                    GameTooltip:AddLine("Bot order ($). Click to edit in chat, Shift-click to send to party.", 0.9, 0.8, 0.5, true)
                else
                    GameTooltip:AddLine("Requires: " .. WLGM.TierTag(d.l), 0.7, 0.7, 0.7)
                    GameTooltip:AddLine("Click to edit in chat, Shift-click to run.", 0.6, 0.6, 0.6, true)
                end
                if d.w == 1 then GameTooltip:AddLine("WoW Legends exclusive", 1, 0.50, 0) end
                GameTooltip:Show()
            end)
            r:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return r
        end
        for i = 1, NUM_ROWS do rows[i] = makeRow(i) end

        local function updateList()
            local off = FauxScrollFrame_GetOffset(scroll)
            for i = 1, NUM_ROWS do
                local d = filtered[off + i]
                local r = rows[i]
                if d then
                    r.data = d
                    local tier = WLGM.tiers[d.l] or WLGM.tiers[0]
                    r.pip:SetTexture(tier.rgb[1], tier.rgb[2], tier.rgb[3], 0.95)
                    local nm = d.n
                    if d.w == 1 then nm = WLGM.colors.legend .. "* " .. WLGM.colors.reset .. WLGM.colors.brand .. nm .. WLGM.colors.reset end
                    r.name:SetText(nm)
                    r.grp:SetText(d.g)
                    r.use:SetText(d.u)
                    r:Show()
                else
                    r.data = nil; r:Hide()
                end
            end
            FauxScrollFrame_Update(scroll, #filtered, NUM_ROWS, ROW_H)
        end
        scroll:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, updateList)
        end)

        local function applyFilter()
            wipe(filtered)
            local q = state.query:lower()
            for _, e in ipairs(WLGM.Catalog or {}) do
                local okTier = state.tiers[e.l]
                local okWl = (not state.wlOnly) or e.w == 1
                local okText = q == "" or e.n:lower():find(q, 1, true) or (e.g or ""):lower():find(q, 1, true) or (e.d or ""):lower():find(q, 1, true)
                if okTier and okWl and okText then filtered[#filtered + 1] = e end
            end
            countFS:SetText(WLGM.colors.muted .. #filtered .. " / " .. (#(WLGM.Catalog or {})) .. WLGM.colors.reset)
            FauxScrollFrame_OnVerticalScroll(scroll, 0, ROW_H, updateList)
        end

        box:SetScript("OnTextChanged", function(self) state.query = self:GetText() or ""; applyFilter() end)
        box:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
        local function refreshWlBtn()
            wlBtn.bg:SetTexture(state.wlOnly and 0.50 or 0.13, state.wlOnly and 0.30 or 0.15, state.wlOnly and 0.0 or 0.19, 0.95)
        end
        wlBtn:SetScript("OnClick", function() state.wlOnly = not state.wlOnly; refreshWlBtn(); applyFilter() end)
        refreshWlBtn()
        for i = 0, 5 do
            tierBtns[i]:SetScript("OnClick", function(self)
                local id = self:GetID()
                state.tiers[id] = not state.tiers[id]
                self:SetAlpha(state.tiers[id] and 1 or 0.35)
                applyFilter()
            end)
        end

        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local target = FauxScrollFrame_GetOffset(self) - delta * 3
            if target < 0 then target = 0 end
            FauxScrollFrame_OnVerticalScroll(self, target * ROW_H, ROW_H, updateList)
        end)

        applyFilter()

        -- Opened from the header search box or /wlgm search <q>.
        WLGM.OpenSearch = function(q)
            WLGM.SelectTabById("search")
            box:SetText(WLGM.Trim(q or ""))
            box:SetCursorPosition(0)
            applyFilter()
        end
    end,
})
