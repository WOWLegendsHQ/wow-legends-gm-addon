-- Headless smoke-test harness: stub the 3.3.5a WoW API, load the addon in TOC
-- order, fire ADDON_LOADED + PLAYER_LOGIN, and dry-run BuildLine on every def.

unpack = table.unpack          -- 5.1 global the addon relies on
local MSGS, ERRORS, FMT_ERRORS = {}, {}, {}

-- ─── Frame / region stub ───────────────────────────────────────────────────
local FRAMES = {}
local FrameMT
local methods = {}

local function newFrame()
    local f = { _scripts = {}, _events = {} }
    table.insert(FRAMES, f)
    return setmetatable(f, FrameMT)
end

function methods.GetText(self) return self._text or "" end
function methods.SetText(self, t) self._text = t; return self end
function methods.GetStringWidth() return 12 end
function methods.GetStringHeight() return 12 end
function methods.GetHeight() return 12 end
function methods.GetWidth() return 120 end
function methods.GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function methods.GetBottom() return 50 end
function methods.GetTop() return 100 end
function methods.GetLeft() return 0 end
function methods.GetRight() return 100 end
function methods.GetVerticalScroll() return 0 end
function methods.GetVerticalScrollRange() return 0 end
function methods.HasFocus() return false end
function methods.GetID(self) return self._id or 1 end
function methods.SetID(self, n) self._id = n; return self end
function methods.IsShown() return false end
function methods.GetObjectType() return "Frame" end
function methods.CreateFontString() return newFrame() end
function methods.CreateTexture() return newFrame() end
function methods.GetFontString(self) self._fs = self._fs or newFrame(); return self._fs end
function methods.SetFontString(self, fs) self._fs = fs; return self end
function methods.GetScrollBar(self) self._sb = self._sb or newFrame(); return self._sb end
function methods.GetRegions() return end
function methods.RegisterEvent(self, e) self._events[e] = true; return self end
function methods.UnregisterEvent(self, e) self._events[e] = nil; return self end
function methods.UnregisterAllEvents(self) self._events = {}; return self end
function methods.SetScript(self, name, fn) self._scripts[name] = fn; return self end
function methods.HookScript(self, name, fn)
    local prev = self._scripts[name]
    self._scripts[name] = function(...) if prev then prev(...) end fn(...) end
    return self
end
function methods.GetScript(self, name) return self._scripts[name] end

-- No-op (chainable) setters/actions. Anything NOT listed here or above reads
-- as nil on a frame — matching real WoW, where unset fields (.data, ._name) are
-- nil rather than a callable. (A function __index would wrongly make `if not
-- self.data` always truthy.)
for _, name in ipairs({
    "ClearAllPoints", "ClearFocus", "EnableMouse", "EnableMouseWheel", "EnableKeyboard",
    "Hide", "Raise", "RegisterForClicks", "RegisterForDrag", "SetAllPoints", "SetAlpha",
    "SetAutoFocus", "SetBackdrop", "SetBackdropBorderColor", "SetBackdropColor",
    "SetClampedToScreen", "SetCursorPosition", "SetDrawLayer", "SetFontObject",
    "SetFontString", "SetFrameLevel", "SetFrameStrata", "SetHeight", "SetHighlightTexture",
    "SetJustifyH", "SetJustifyV", "SetMask", "SetMaxLetters", "SetMovable", "SetNormalTexture",
    "SetOwner", "SetParent", "SetPoint", "SetScale", "SetScrollChild", "SetSize",
    "SetButtonState", "SetTexCoord", "SetTextColor", "SetTextInsets", "SetTexture",
    "SetToplevel", "SetValue", "SetVertexColor", "SetVerticalScroll", "SetMinMaxValues",
    "SetWidth", "Show", "StartMoving", "StopMovingOrSizing", "AddLine", "AddMessage",
}) do
    methods[name] = function(self) return self end
end

FrameMT = { __index = methods }

-- ─── Globals ────────────────────────────────────────────────────────────────
CreateFrame = function(_, name) local f = newFrame(); if name then _G[name] = f end; return f end
UIParent = newFrame()
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) table.insert(MSGS, msg or "") end }
GameTooltip = newFrame()
StaticPopupDialogs = {}
StaticPopup_Show = function() return nil end
SlashCmdList = {}
YES, NO = "Yes", "No"

for _, n in ipairs({ "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge",
    "GameFontHighlight", "GameFontHighlightSmall", "GameFontDisable", "GameFontDisableSmall" }) do
    _G[n] = {}
end

GetTime = function() return 0 end
GetAddOnMetadata = function(_, key) return key == "Version" and "0.1.0" or "x" end
SendChatMessage = function() end
ChatFrame_OpenChat = function() end
PlaySound = function() end
IsShiftKeyDown = function() return false end
GetNumRaidMembers = function() return 0 end
GetNumPartyMembers = function() return 0 end
UnitName = function() return "Tester" end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitFactionGroup = function() return "Alliance" end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end

-- Faux scroll + dropdown API
FauxScrollFrame_GetOffset = function() return 0 end
FauxScrollFrame_Update = function() end
FauxScrollFrame_SetOffset = function() end
FauxScrollFrame_OnVerticalScroll = function(_, _, _, fn) if fn then pcall(fn) end end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_JustifyText = function() end
UIDropDownMenu_Initialize = function(dd, fn) if fn then pcall(fn, dd, 1) end end
UIDropDownMenu_CreateInfo = function() return {} end
UIDropDownMenu_AddButton = function() end
UIDropDownMenu_SetText = function() end
UIDropDownMenu_SetSelectedValue = function() end

-- ─── Load addon in TOC order ────────────────────────────────────────────────
local files = {
    "Core/Init.lua", "Core/Util.lua", "Core/SavedVars.lua", "Core/CommandRunner.lua",
    "Data/Catalog.lua", "Data/Teleports.lua",
    "UI/ConfirmDialog.lua", "UI/Widgets.lua", "UI/MainFrame.lua",
    "UI/Tabs/Legends.lua", "UI/Tabs/General.lua", "UI/Tabs/Player.lua", "UI/Tabs/Items.lua",
    "UI/Tabs/NPC.lua", "UI/Tabs/Object.lua", "UI/Tabs/Teleport.lua", "UI/Tabs/Quest.lua",
    "UI/Tabs/Server.lua", "UI/Tabs/Moderation.lua", "UI/Tabs/Bots.lua", "UI/Tabs/Search.lua",
    "UI/Tabs/Favorites.lua", "UI/Tabs/History.lua", "UI/ToggleButton.lua",
}

local WLGM = {}
for _, rel in ipairs(files) do
    local chunk, lerr = loadfile(BASE .. "/" .. rel)
    if not chunk then
        table.insert(ERRORS, "LOAD " .. rel .. ": " .. tostring(lerr))
    else
        local ok, rerr = pcall(chunk, "WoWLegends_GM", WLGM)
        if not ok then table.insert(ERRORS, "RUN " .. rel .. ": " .. tostring(rerr)) end
    end
end

-- Dry-run BuildLine on every command def as rows are built (catches %s/arg
-- mismatches that only surface when a command is actually assembled).
if WLGM.CreateCommandRow then
    local orig = WLGM.CreateCommandRow
    WLGM.CreateCommandRow = function(parent, def)
        local vals = {}
        for _, a in ipairs(def.args or {}) do vals[a.key] = a.numeric and "1" or "x" end
        local ok, line = pcall(WLGM.BuildLine, def, vals)
        if not ok then
            table.insert(FMT_ERRORS, (def.id or def.label or "?") .. ": " .. tostring(line))
        end
        return orig(parent, def)
    end
end

-- Regression: LayoutRows must report real height even when #rows is an exact
-- multiple of rowsPerColumn (else stacked sections overlap).
if WLGM.LayoutRows then
    for _, rpc in ipairs({ 2, 3 }) do
        local fake = {}
        for i = 1, rpc * 2 do fake[i] = { id = "t" .. i, label = "t", format = ".x", group = "g" } end
        local h = WLGM.LayoutRows(newFrame(), fake, { yTop = 8, rowsPerColumn = rpc, columnWidth = 372 })
        if not h or h < 70 then
            table.insert(ERRORS, "LayoutRows height collapse: " .. (rpc * 2) .. " rows / " .. rpc .. "-col returned " .. tostring(h))
        end
    end
end

-- ─── Fire events ────────────────────────────────────────────────────────────
local function fire(event, arg)
    for _, f in ipairs(FRAMES) do
        if f._events[event] and f._scripts.OnEvent then
            local ok, err = pcall(f._scripts.OnEvent, f, event, arg)
            if not ok then table.insert(ERRORS, "EVENT " .. event .. ": " .. tostring(err)) end
        end
    end
end
fire("ADDON_LOADED", "WoWLegends_GM")
fire("PLAYER_LOGIN")

-- Fuzz: invoke every OnClick once (opens dropdowns, runs commands, switches
-- tabs/sub-tabs) to exercise click paths a build-only pass never reaches.
local CLICK_ERRORS = {}
local n = #FRAMES
for i = 1, n do
    local f = FRAMES[i]
    local fn = f._scripts and f._scripts.OnClick
    if fn then
        local ok, err = pcall(fn, f, "LeftButton")
        if not ok then table.insert(CLICK_ERRORS, tostring(err)) end
    end
end

-- ─── Report ─────────────────────────────────────────────────────────────────
RESULT = {
    tabs = WLGM.tabs and #WLGM.tabs or 0,
    catalog = WLGM.Catalog and #WLGM.Catalog or 0,
    teleports = WLGM.Teleports and #WLGM.Teleports or 0,
    errors = ERRORS,
    fmt_errors = FMT_ERRORS,
    click_errors = CLICK_ERRORS,
    chat = MSGS,
}
