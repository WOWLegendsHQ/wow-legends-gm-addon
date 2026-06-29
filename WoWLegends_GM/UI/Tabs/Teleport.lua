-- WoWLegends_GM/UI/Tabs/Teleport.lua
-- Destinations: searchable browser over all world.game_tele names (.teleport).
-- Go: the .go family + .teleport name + appear/summon/recall + lookups.

local addonName, WLGM = ...

local NUM_ROWS, ROW_H = 17, 22
local CONTINENTS = { "All", "Eastern Kingdoms", "Kalimdor", "Outland", "Northrend", "Instances" }
local MAIN = { ["Eastern Kingdoms"]=true, ["Kalimdor"]=true, ["Outland"]=true, ["Northrend"]=true }

local function destinationsBuilder(parent)
    local state = { query = "", cont = "All" }
    local filtered = {}

    local box = WLGM.MakeFlatEditBox(parent, 220, 22, "Search destinations...")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    local countFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countFS:SetPoint("LEFT", box, "RIGHT", 12, 0)

    local contBtns, prev = {}, nil
    for _, c in ipairs(CONTINENTS) do
        local b = WLGM.MakeFlatButton(parent, 116, 18, c, { justify = "CENTER", font = "GameFontNormalSmall" })
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -6) end
        b.cont = c; contBtns[c] = b; prev = b
    end

    local list = CreateFrame("Frame", nil, parent)
    list:SetPoint("TOPLEFT", contBtns["All"], "BOTTOMLEFT", 0, -8)
    list:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    local scroll = CreateFrame("ScrollFrame", "WLGM_TeleScroll", list, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", list, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -26, 0)

    local rows = {}
    for i = 1, NUM_ROWS do
        local r = WLGM.MakeFlatButton(list, 400, ROW_H, "", { padLeft = 10 })
        r:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
        r:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
        r.bg:SetTexture(0, 0, 0, 0)
        local bucket = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        bucket:SetPoint("RIGHT", r, "RIGHT", -10, 0); r.bucket = bucket
        r:SetScript("OnClick", function(self) if self._name then WLGM.RunCommand(".teleport " .. self._name) end end)
        r:SetScript("OnEnter", function(self)
            if not self._name then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self._name, 1, 0.82, 0.30)
            GameTooltip:AddLine(".teleport " .. self._name, 0.27, 0.84, 1)
            GameTooltip:AddLine("Click to teleport there.", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[i] = r
    end

    local function update()
        local off = FauxScrollFrame_GetOffset(scroll)
        for i = 1, NUM_ROWS do
            local d = filtered[off + i]; local r = rows[i]
            if d then
                r._name = d.n
                r.label:SetText(d.n)
                r.bucket:SetText(d.m)
                r:Show()
            else r._name = nil; r:Hide() end
        end
        FauxScrollFrame_Update(scroll, #filtered, NUM_ROWS, ROW_H)
    end
    scroll:SetScript("OnVerticalScroll", function(self, o) FauxScrollFrame_OnVerticalScroll(self, o, ROW_H, update) end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local t = FauxScrollFrame_GetOffset(self) - delta * 3
        if t < 0 then t = 0 end
        FauxScrollFrame_OnVerticalScroll(self, t * ROW_H, ROW_H, update)
    end)

    local function apply()
        wipe(filtered)
        local q = state.query:lower()
        for _, e in ipairs(WLGM.Teleports or {}) do
            local okC = state.cont == "All"
                or (state.cont == "Instances" and not MAIN[e.m])
                or (e.m == state.cont)
            local okT = q == "" or e.n:lower():find(q, 1, true)
            if okC and okT then filtered[#filtered + 1] = e end
        end
        countFS:SetText(WLGM.colors.muted .. #filtered .. " destinations" .. WLGM.colors.reset)
        FauxScrollFrame_OnVerticalScroll(scroll, 0, ROW_H, update)
    end
    box:SetScript("OnTextChanged", function(self) state.query = self:GetText() or ""; apply() end)
    box:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    local function refreshCont()
        for c, b in pairs(contBtns) do
            b.bg:SetTexture(c == state.cont and 0.10 or 0.13, c == state.cont and 0.30 or 0.15, c == state.cont and 0.40 or 0.19, 0.95)
            b.label:SetTextColor(c == state.cont and 1 or 0.82, c == state.cont and 0.82 or 0.82, c == state.cont and 0.30 or 0.82)
        end
    end
    for c, b in pairs(contBtns) do b:SetScript("OnClick", function() state.cont = c; refreshCont(); apply() end) end
    refreshCont(); apply()
end

-- ─── Go / Lookup command rows ──────────────────────────────────────────────
local function nameArg(opt) return { key="name", placeholder="player", fallback="target", optional=opt } end
local Go = {
    { id="go_xyz",   label="go xyz",        format=".go xyz %s %s %s %s", level=1, group="Teleport",
      args={ {key="x",placeholder="x",numeric=true,width=70},{key="y",placeholder="y",numeric=true,width=70},{key="z",placeholder="z",numeric=true,width=70,optional=true},{key="map",placeholder="map (opt)",numeric=true,width=70,optional=true} },
      tooltip="Teleport to map coordinates. .go xyz <x> <y> [z [mapid [orientation]]]" },
    { id="go_zonexy",label="go zonexy",     format=".go zonexy %s %s %s", level=1, group="Teleport",
      args={ {key="x",placeholder="x",numeric=true,width=70},{key="y",placeholder="y",numeric=true,width=70},{key="zone",placeholder="zone (opt)",numeric=true,width=80,optional=true} },
      tooltip="Teleport to zone-relative coords. .go zonexy <x> <y> [zone]" },
    { id="go_grid",  label="go grid",       format=".go grid %s %s %s", level=1, group="Teleport",
      args={ {key="gx",placeholder="gridX",numeric=true,width=70},{key="gy",placeholder="gridY",numeric=true,width=70},{key="map",placeholder="map (opt)",numeric=true,width=70,optional=true} },
      tooltip=".go grid <gridX> <gridY> [mapId]" },
    { id="go_crid",  label="go creature id",format=".go creature id %s", level=1, group="Teleport",
      args={ {key="id",placeholder="entry",numeric=true,width=90} }, tooltip="Teleport to a spawn of creature entry. .go creature id <entry> [spawn]" },
    { id="go_crname",label="go creature name",format=".go creature name %s", level=1, group="Teleport",
      args={ {key="n",placeholder="name",width=140} }, tooltip="Teleport to a creature by template name." },
    { id="go_obid",  label="go object id",  format=".go gameobject id %s", level=1, group="Teleport",
      args={ {key="id",placeholder="entry",numeric=true,width=90} }, tooltip=".go gameobject id <entry> [spawn]" },
    { id="go_grave", label="go graveyard",  format=".go graveyard %s", level=1, group="Teleport",
      args={ {key="id",placeholder="graveyardId",numeric=true,width=100} } },
    { id="go_taxi",  label="go taxinode",   format=".go taxinode %s", level=1, group="Teleport",
      args={ {key="id",placeholder="taxinode",numeric=true,width=90} } },
    { id="go_trig",  label="go trigger",    format=".go trigger %s", level=1, group="Teleport",
      args={ {key="id",placeholder="trigger id",numeric=true,width=90} } },
    { id="go_ticket",label="go ticket",     format=".go ticket %s", level=1, group="Teleport",
      args={ {key="id",placeholder="ticketid",numeric=true,width=90} } },
}
local Move = {
    { id="tele",     label="teleport (name)", format=".teleport %s", level=1, group="Teleport",
      args={ {key="loc",placeholder="location",width=150} }, tooltip="Teleport yourself to a saved game_tele location. Use the Destinations tab to browse." },
    { id="telename", label="teleport player", format=".teleport name %s %s", level=2, group="Teleport",
      args={ nameArg(), {key="loc",placeholder="location",width=140} }, tooltip="Teleport another player to a saved location. .teleport name <player> <location>" },
    { id="appear",   label="appear (to player)", format=".appear %s", level=1, group="Teleport",
      args={ nameArg() }, tooltip="Teleport yourself to a player (online or offline)." },
    { id="summon",   label="summon (to me)", format=".summon %s", level=2, group="Teleport",
      args={ nameArg() }, tooltip="Summon a player to your position." },
    { id="recall",   label="recall", format=".recall %s", level=1, group="Teleport",
      args={ nameArg(true) }, tooltip="Return the player to their pre-teleport position." },
    { id="groupsummon", label="group summon", format=".groupsummon %s", level=2, group="Teleport",
      args={ nameArg() }, tooltip="Summon a player and their whole group." },
    { id="lk_tele",  label="lookup tele",  format=".lookup tele %s",  level=1, group="Teleport", args={ {key="q",placeholder="search",width=130} } },
    { id="lk_area",  label="lookup area",  format=".lookup area %s",  level=1, group="Teleport", args={ {key="q",placeholder="search",width=130} } },
    { id="lk_map",   label="lookup map",   format=".lookup map %s",   level=1, group="Teleport", args={ {key="q",placeholder="search",width=130} } },
}

local function goBuilder(parent)
    WLGM.BuildScrollSections(parent, {
        { title = "Go to coordinates / objects", rows = Go },
        { title = "Player teleport & lookup",    rows = Move },
    })
end

WLGM.RegisterTab({
    id = "teleport", label = "Teleport",
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Destinations", builder = destinationsBuilder },
            { label = "Go & Lookup",  builder = goBuilder },
        }, "teleport")
    end,
})
