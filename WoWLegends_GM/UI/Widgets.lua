-- WoWLegends_GM/UI/Widgets.lua
-- Reusable UI factories used by every tab. Built from lightweight, single-
-- texture widgets (not the heavy Blizzard templates) so a tab can stack 40+
-- rows without the per-frame texture churn that tanks FPS during scroll.

local addonName, WLGM = ...

local ROW_HEIGHT  = 26
local ROW_SPACING = 4
local LABEL_WIDTH = 150
local INPUT_WIDTH = 100
local PIP_WIDTH   = 6

-- ─── Backdrops ─────────────────────────────────────────────────────────────
WLGM.backdrops = {
    panel = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    },
    inset = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    },
}

function WLGM.ApplyBackdrop(frame, kind, bgAlpha, r, g, b)
    frame:SetBackdrop(WLGM.backdrops[kind or "panel"])
    frame:SetBackdropColor(r or 0.04, g or 0.05, b or 0.07, bgAlpha or 0.92)
    frame:SetBackdropBorderColor(0.30, 0.45, 0.55, 1)
end

-- ─── Section header ────────────────────────────────────────────────────────
function WLGM.CreateSectionHeader(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetText(WLGM.colors.label .. text .. WLGM.colors.reset)
    return fs
end

-- ─── Flat widget factories ─────────────────────────────────────────────────
function WLGM.MakeFlatButton(parent, w, h, text, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    bg:SetTexture(0.13, 0.15, 0.19, 0.95)
    b.bg = bg

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(b)
    hl:SetTexture(1, 1, 1, 0.16)

    local fs = b:CreateFontString(nil, "OVERLAY", opts.font or "GameFontNormalSmall")
    fs:SetPoint("LEFT", b, "LEFT", opts.padLeft or 6, 0)
    fs:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    fs:SetJustifyH(opts.justify or "LEFT")
    fs:SetText(text)
    if opts.danger then fs:SetTextColor(1, 0.45, 0.45) end
    b:SetFontString(fs)
    b.label = fs
    return b
end

local function makeFlatEditBox(parent, w, h, placeholder, isNumeric)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetSize(w, h)
    e:SetFontObject(GameFontHighlightSmall)
    e:SetTextColor(1, 1, 1, 1)
    e:SetTextInsets(6, 6, 0, 0)
    e:SetAutoFocus(false)
    e:SetMaxLetters(isNumeric and 14 or 96)

    local bg = e:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(e)
    bg:SetTexture(0, 0, 0, 0.55)

    local border = e:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", e, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", 1, -1)
    border:SetTexture(0.25, 0.35, 0.42, 0.7)
    bg:SetDrawLayer("BACKGROUND", 1)

    if placeholder then
        local hint = e:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hint:SetPoint("LEFT", e, "LEFT", 6, 0)
        hint:SetText(placeholder)
        e.hint = hint
        local function refresh()
            if e:GetText() == "" and not e:HasFocus() then hint:Show() else hint:Hide() end
        end
        e.refreshHint = refresh
        e:HookScript("OnTextChanged", refresh)
        e:HookScript("OnEditFocusGained", refresh)
        e:HookScript("OnEditFocusLost", refresh)
    end
    return e
end
WLGM.MakeFlatEditBox = makeFlatEditBox

-- ─── Flat dropdown (choice) ────────────────────────────────────────────────
-- A themed select control. choices = list of strings or { text, value } tables.
-- Reads via frame.GetValue(); set with frame.SetValue(v); frame.SetChoices(list).
local openChoiceMenu, choiceCloser
local function closeChoiceMenu()
    if openChoiceMenu then openChoiceMenu:Hide() end
    openChoiceMenu = nil
    if choiceCloser then choiceCloser:Hide() end
end
WLGM.CloseChoiceMenu = closeChoiceMenu

local function ensureCloser()
    if choiceCloser then return choiceCloser end
    choiceCloser = CreateFrame("Button", nil, UIParent)
    choiceCloser:SetAllPoints(UIParent)
    choiceCloser:SetFrameStrata("FULLSCREEN")
    choiceCloser:Hide()
    choiceCloser:SetScript("OnClick", closeChoiceMenu)
    return choiceCloser
end

function WLGM.CreateChoice(parent, w, h, choices, placeholder, onSelect)
    local c = CreateFrame("Button", nil, parent)
    c:SetSize(w, h)
    local bg = c:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(c); bg:SetTexture(0, 0, 0, 0.55)
    bg:SetDrawLayer("BACKGROUND", 1); c.bg = bg
    local border = c:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", c, "TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 1, -1)
    border:SetTexture(0.25, 0.35, 0.42, 0.7)
    local hl = c:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(c); hl:SetTexture(1, 1, 1, 0.12)
    local txt = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", c, "LEFT", 6, 0); txt:SetPoint("RIGHT", c, "RIGHT", -14, 0); txt:SetJustifyH("LEFT")
    txt:SetText(placeholder or "select"); txt:SetTextColor(0.6, 0.7, 0.85); c.text = txt
    local arrow = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", c, "RIGHT", -5, 0); arrow:SetText("v"); arrow:SetTextColor(0.6, 0.7, 0.85)

    c.value, c.choices = nil, choices or {}
    function c.GetValue() return c.value end
    function c.SetChoices(list) c.choices = list or {} end
    function c.SetValue(v)
        c.value = v
        if v == nil or v == "" then
            txt:SetText(placeholder or "select"); txt:SetTextColor(0.6, 0.7, 0.85)
        else
            local disp = v
            for _, opt in ipairs(c.choices) do
                if type(opt) == "table" then if opt.value == v then disp = opt.text; break end
                elseif opt == v then disp = v; break end
            end
            txt:SetText(disp); txt:SetTextColor(1, 1, 1)
        end
    end

    local menu
    local function rebuild()
        if not menu then
            menu = CreateFrame("Frame", nil, UIParent)
            menu:SetFrameStrata("FULLSCREEN_DIALOG")
            menu:EnableMouse(true)
            WLGM.ApplyBackdrop(menu, "inset", 0.98, 0.05, 0.07, 0.10)
            menu:Hide(); menu._btns = {}; c.menu = menu
        end
        for _, b in ipairs(menu._btns) do b:Hide() end
        local maxw, y = w, -4
        for i, opt in ipairs(c.choices) do
            local text = type(opt) == "table" and opt.text or opt
            local val  = type(opt) == "table" and opt.value or opt
            local b = menu._btns[i]
            if not b then b = WLGM.MakeFlatButton(menu, w - 8, 18, "", { padLeft = 6 }); menu._btns[i] = b end
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, y)
            b.label:SetText(text); b._val = val; b:Show()
            b:SetScript("OnClick", function(self)
                c.SetValue(self._val); closeChoiceMenu()
                if onSelect then onSelect(self._val) end
            end)
            local tw = (b.label:GetStringWidth() or 0) + 28
            if tw > maxw then maxw = tw end
            y = y - 20
        end
        menu:SetWidth(math.max(w, maxw)); menu:SetHeight(-y + 6)
        for _, b in ipairs(menu._btns) do b:SetWidth(menu:GetWidth() - 8) end
    end

    c:SetScript("OnClick", function(self)
        if menu and menu:IsShown() then closeChoiceMenu(); return end
        closeChoiceMenu(); rebuild()
        menu:ClearAllPoints()
        local bottom = self:GetBottom() or 100
        if bottom - menu:GetHeight() < 0 then menu:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        else menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2) end
        ensureCloser():Show(); menu:Show(); menu:Raise()
        openChoiceMenu = menu
    end)
    return c
end

-- ─── Single command row ────────────────────────────────────────────────────
-- def = { id, label, format, args, danger, level, wl, group, tooltip }
-- An arg with `choices` (list of strings / {text,value}) renders a dropdown
-- instead of an edit box. `on/off` placeholders auto-upgrade to a dropdown.
function WLGM.CreateCommandRow(parent, def)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.def = def

    local rowKey = (def.group or "?") .. ":" .. (def.id or def.label or "?")

    -- Tier pip (item-quality colour for the required access level; bot orders
    -- use the "Bot" colour since they are issued to bots, not gated by GM tier).
    local pip = row:CreateTexture(nil, "ARTWORK")
    pip:SetPoint("LEFT", row, "LEFT", 0, 0)
    pip:SetSize(PIP_WIDTH, ROW_HEIGHT - 4)
    local tierIdx = (def.send == "bot") and 5 or (def.level or 0)
    local tcol = (WLGM.tiers[tierIdx] or WLGM.tiers[0]).rgb
    pip:SetTexture(tcol[1], tcol[2], tcol[3], 0.95)

    -- Label button. WL-only commands wear a gold star and gold text.
    local labelText = def.label or def.id or "?"
    if def.wl then labelText = WLGM.colors.legend .. "* " .. WLGM.colors.reset .. WLGM.colors.brand .. labelText .. WLGM.colors.reset end
    local btn = WLGM.MakeFlatButton(row, LABEL_WIDTH, ROW_HEIGHT - 2, labelText, { danger = def.danger and not def.wl })
    btn:SetPoint("LEFT", pip, "RIGHT", 4, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.button = btn

    local execute, gatherValues

    row.edits = {}
    row.getters = {}
    local prev = btn
    for _, arg in ipairs(def.args or {}) do
        local choices = arg.choices
        if type(choices) == "function" then choices = choices() end
        if not choices and arg.placeholder and arg.placeholder:lower():match("^on%s*/%s*off") then choices = { "on", "off" } end
        if choices then
            local ch = WLGM.CreateChoice(row, arg.width or INPUT_WIDTH, ROW_HEIGHT - 2, choices, arg.placeholder,
                function(v) WLGM.SetInputCache(rowKey, arg.key, v) end)
            ch:SetPoint("LEFT", prev, "RIGHT", 8, 0)
            local cached = WLGM.GetInputCache(rowKey, arg.key)
            if cached and cached ~= "" then ch.SetValue(cached) end
            row.getters[arg.key] = ch.GetValue
            prev = ch
        else
            local edit = makeFlatEditBox(row, arg.width or INPUT_WIDTH, ROW_HEIGHT - 2, arg.placeholder, arg.numeric)
            edit:SetPoint("LEFT", prev, "RIGHT", 8, 0)
            edit:HookScript("OnTextChanged", function(self) WLGM.SetInputCache(rowKey, arg.key, self:GetText()) end)
            edit:SetScript("OnEnterPressed", function(self) self:ClearFocus(); execute() end)
            edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            local cached = WLGM.GetInputCache(rowKey, arg.key)
            if cached and cached ~= "" then edit:SetText(cached) end
            if edit.refreshHint then edit.refreshHint() end
            row.edits[arg.key] = edit
            row.getters[arg.key] = function() return edit:GetText() end
            prev = edit
        end
    end

    gatherValues = function()
        local v = {}
        for _, arg in ipairs(def.args or {}) do
            local g = row.getters[arg.key]
            v[arg.key] = g and g() or nil
        end
        return v
    end

    execute = function()
        local line, err = WLGM.BuildLine(def, gatherValues())
        if not line then WLGM.Warn(err or "invalid args"); return end
        if def.send == "bot" then
            local scope = (def.getScope and def.getScope()) or def.botScope or "party"
            WLGM.RunBotOrder(line, { scope = scope })
        else
            WLGM.RunCommand(line, { danger = def.danger })
        end
    end

    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            WLGM.ToggleFavorite(def)
        elseif IsShiftKeyDown() then
            ChatFrame_OpenChat(WLGM.PreviewLine(def, gatherValues()))
        else
            execute()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local title = (def.wl and (WLGM.colors.legend .. "* ") or "") .. (def.label or def.id or "")
        GameTooltip:SetText(title, 1, 0.82, 0.30)
        GameTooltip:AddLine(WLGM.PreviewLine(def, gatherValues()), 0.27, 0.84, 1, true)
        if def.tooltip then GameTooltip:AddLine(def.tooltip, 1, 1, 1, true) end
        GameTooltip:AddLine(" ")
        if def.send == "bot" then
            GameTooltip:AddLine("Bot order - sent to your bots (party) or the targeted bot (whisper).", 0.90, 0.80, 0.50, true)
        else
            GameTooltip:AddLine("Requires: " .. WLGM.TierTag(def.level), 0.7, 0.7, 0.7)
        end
        if def.wl then GameTooltip:AddLine("WoW Legends exclusive command", 1, 0.50, 0.0) end
        if def.danger then GameTooltip:AddLine("Asks for confirmation before sending.", 1, 0.45, 0.45) end
        GameTooltip:AddLine("Left-click run  /  Shift-click edit in chat  /  Right-click pin", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

-- ─── Vertical / column row layout ──────────────────────────────────────────
-- Returns the total height used so callers can size scroll content.
function WLGM.LayoutRows(parent, defs, opts)
    opts = opts or {}
    local x = opts.x or 8
    local y = -(opts.yTop or 8)

    if opts.sectionTitle then
        local hdr = WLGM.CreateSectionHeader(parent, opts.sectionTitle)
        hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        y = y - hdr:GetHeight() - 6
    end

    local startY = y
    local colWidth = opts.columnWidth or 430
    local rowsPerColumn = opts.rowsPerColumn
    local col, count = 0, 0
    local rowTopMin = startY   -- top of the lowest row placed (most negative)

    for _, def in ipairs(defs) do
        local row = WLGM.CreateCommandRow(parent, def)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", x + col * colWidth, y)
        row:SetWidth(colWidth - 16)
        if y < rowTopMin then rowTopMin = y end
        y = y - (ROW_HEIGHT + ROW_SPACING)
        count = count + 1
        if rowsPerColumn and count % rowsPerColumn == 0 then
            col = col + 1
            y = startY
        end
    end
    -- Height runs to the bottom of the LOWEST row, not the post-loop cursor:
    -- when #rows is an exact multiple of rowsPerColumn the loop resets y to the
    -- top, which would otherwise report a header-only height and overlap the
    -- next section.
    return -(rowTopMin - ROW_HEIGHT) + 8
end

-- Auto-pick (columnWidth, rowsPerColumn) from the widest row: dense 2 columns
-- for narrow rows, a single full-width column when any row is wide/multi-input
-- (so nothing runs off the right edge).
local function autoColumns(rows)
    local maxw = 0
    for _, def in ipairs(rows) do
        local w = PIP_WIDTH + 4 + LABEL_WIDTH
        for _, a in ipairs(def.args or {}) do w = w + 8 + (a.width or INPUT_WIDTH) end
        if w > maxw then maxw = w end
    end
    if maxw <= 360 and #rows > 5 then return 372, math.ceil(#rows / 2) end
    return 744, nil
end

-- Lay a single rows list inside a vertical scroll, auto-choosing 1/2 columns.
function WLGM.BuildScrollRows(parent, rows, opts)
    local scroll, child = WLGM.CreateScrollContent(parent)
    child:SetWidth(744)
    local lo = {}
    for k, v in pairs(opts or {}) do lo[k] = v end
    lo.x = 8
    lo.columnWidth, lo.rowsPerColumn = autoColumns(rows)
    local h = WLGM.LayoutRows(child, rows, lo)
    child:SetHeight(math.max(h, 80))
    return scroll, child
end

-- Stacked sections (each an optional title + auto-column rows) plus an optional
-- intro paragraph, all in one vertical scroll. Replaces the old side-by-side
-- "second section in a right-hand column" layout, which overflowed for rows
-- with several input fields.
-- sections = { { title = "..."(opt), rows = {...} }, ... }
function WLGM.BuildScrollSections(parent, sections, info)
    local scroll, child = WLGM.CreateScrollContent(parent)
    child:SetWidth(744)
    local top = 8
    if info then
        local fs = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -top)
        fs:SetWidth(724); fs:SetJustifyH("LEFT")
        fs:SetText(WLGM.colors.muted .. info .. WLGM.colors.reset)
        top = top + fs:GetStringHeight() + 12
    end
    for _, sec in ipairs(sections) do
        local cw, rpc = autoColumns(sec.rows)
        local h = WLGM.LayoutRows(child, sec.rows,
            { yTop = top, x = 8, sectionTitle = sec.title, columnWidth = cw, rowsPerColumn = rpc })
        top = h + 6
    end
    child:SetHeight(math.max(top, 80))
    return scroll, child
end

-- ─── Sub-tab strip ─────────────────────────────────────────────────────────
-- subTabsDef = { { label, rows, builder, layoutOpts }, ... }
function WLGM.BuildSubTabs(parent, subTabsDef, dbKey)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
    strip:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -2)
    strip:SetHeight(22)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 0, -1)
    divider:SetPoint("TOPRIGHT", strip, "BOTTOMRIGHT", 0, -1)
    divider:SetHeight(1)
    divider:SetTexture(0.30, 0.45, 0.55, 0.6)

    local subContent = CreateFrame("Frame", nil, parent)
    subContent:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 0, -6)
    subContent:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)

    local entries = {}
    local function selectSub(idx)
        for i, e in ipairs(entries) do
            if i == idx then
                e.button.bg:SetTexture(0.10, 0.30, 0.40, 0.95)
                e.button.label:SetTextColor(1, 0.82, 0.30)
                e.contentFrame:Show()
            else
                e.button.bg:SetTexture(0.13, 0.15, 0.19, 0.95)
                e.button.label:SetTextColor(0.82, 0.82, 0.82)
                e.contentFrame:Hide()
            end
        end
        if dbKey and WLGM.db then WLGM.db.subTabs[dbKey] = idx end
    end

    local sizer = strip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    local prev
    for i, def in ipairs(subTabsDef) do
        sizer:SetText(def.label)
        local w = math.max(54, math.ceil(sizer:GetStringWidth()) + 18)
        local btn = WLGM.MakeFlatButton(strip, w, 20, def.label, { justify = "CENTER", padLeft = 4 })
        if prev then btn:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else btn:SetPoint("LEFT", strip, "LEFT", 0, 0) end
        prev = btn

        local content = CreateFrame("Frame", nil, subContent)
        content:SetAllPoints(subContent)
        content:Hide()

        if def.rows then WLGM.BuildScrollRows(content, def.rows, def.layoutOpts) end
        if def.builder then
            local ok, err = pcall(def.builder, content)
            if not ok then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff5555WLGM sub-tab '" .. tostring(def.label) .. "' error:|r " .. tostring(err))
            end
        end

        btn:SetScript("OnClick", function() selectSub(i) end)
        table.insert(entries, { button = btn, contentFrame = content })
    end
    sizer:Hide()

    WLGM.db.subTabs = WLGM.db.subTabs or {}
    local saved = (dbKey and WLGM.db.subTabs[dbKey]) or 1
    if not entries[saved] then saved = 1 end
    selectSub(saved)
end

-- ─── Dropdown ──────────────────────────────────────────────────────────────
-- options = list of strings or { text, value } tables. Returns the frame; the
-- current value is read via frame.GetValue().
function WLGM.CreateDropdown(parent, width, options, placeholder, onSelect)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd.selected = nil
    UIDropDownMenu_SetWidth(dd, width)
    UIDropDownMenu_JustifyText(dd, "LEFT")
    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, opt in ipairs(options) do
            local text  = type(opt) == "table" and opt.text  or opt
            local value = type(opt) == "table" and opt.value or opt
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = text, value
            info.checked = (dd.selected == value)
            info.func = function(item)
                dd.selected = item.value
                UIDropDownMenu_SetText(dd, item.text)
                if onSelect then onSelect(item.value) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(dd, placeholder or "select")
    function dd.GetValue() return dd.selected end
    function dd.SetOptions(newOpts) options = newOpts end
    return dd
end

-- ─── Scrollable content holder (with mouse-wheel) ──────────────────────────
function WLGM.CreateScrollContent(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local target = cur - delta * (ROW_HEIGHT * 2)
        if target < 0 then target = 0 elseif target > max then target = max end
        self:SetVerticalScroll(target)
    end)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(860, 400)
    scroll:SetScrollChild(content)
    scroll.content = content
    return scroll, content
end

WLGM.ROW_HEIGHT = ROW_HEIGHT
