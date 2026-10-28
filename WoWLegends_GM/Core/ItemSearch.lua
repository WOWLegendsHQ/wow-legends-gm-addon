-- WoWLegends_GM/Core/ItemSearch.lua
-- Name -> item ID resolution via the server's own `.lookup item` command.
--
-- We send `.lookup item <text>`, capture the CHAT_MSG_SYSTEM reply lines for a
-- short window, parse "<id> - [Name]" out of each one and hand the list to a
-- callback. Because the data comes from the live world DB it always matches
-- the server exactly, custom items included, and needs no bundled data file.
--
-- AzerothCore reply formats handled:
--   in-game : "49623 - |cffffffff|Hitem:49623:0:0:0:0:0:0:0:0|h[Shadowmourne]|h|r "
--   console : "49623 - Shadowmourne"
--   none    : "No items found!"
--   capped  : "Result limit reached (max results: N)"

local addonName, WLGM = ...

local IDLE_FINISH  = 0.75   -- seconds of silence after the last result => done
local MAX_WAIT     = 4.0    -- give up if the server says nothing at all
local MIN_QUERY    = 2      -- refuse 1-letter searches (thousands of lines)

local session          -- the one active search, or nil
local hideFromChat = true

-- Parse one system line. Returns kind, a, b:
--   "item", id, name  |  "none"  |  "limit"  |  nil (not ours)
local function parseLine(msg)
    if type(msg) ~= "string" then return nil end
    local id, name = msg:match("^%s*(%d+)%s*%-%s*.-|Hitem:[%d:%-]+|h%[(.-)%]|h")
    if id then return "item", tonumber(id), name end
    local lower = msg:lower()
    if lower:find("no items found", 1, true) then return "none" end
    if lower:find("result limit", 1, true) or lower:find("max results", 1, true) then return "limit" end
    id, name = msg:match("^%s*(%d+)%s*%-%s*(.-)%s*$")
    if id and name ~= "" and not name:find("|H", 1, true) then return "item", tonumber(id), name end
    return nil
end
WLGM.ParseItemLookupLine = parseLine

local function finish()
    local s = session
    if not s then return end
    session = nil
    s.frame:UnregisterAllEvents()
    s.frame:SetScript("OnUpdate", nil)
    if s.callback then
        local ok, err = pcall(s.callback, s.results, { truncated = s.truncated, none = s.none, query = s.query })
        if not ok then WLGM.Warn("item search callback error: " .. tostring(err)) end
    end
end

-- Hide the raw lookup spam from chat while a search is running (the results
-- are shown in the panel instead).
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg, ...)
    if session and hideFromChat and parseLine(msg) then return true end
    return false, msg, ...
end)

-- WLGM.SearchItems(query, callback)
-- callback(results, info) where results = { {id=, name=}, ... } sorted by name
-- and info = { truncated=bool, none=bool, query=string }.
-- Returns false (and warns) if the query is too short.
function WLGM.SearchItems(query, callback)
    query = WLGM.Trim(query or ""):gsub("^%[", ""):gsub("%]$", "")
    if #query < MIN_QUERY then
        WLGM.Warn("type at least " .. MIN_QUERY .. " letters of the item name.")
        return false
    end

    -- A newer search supersedes an older one still in flight.
    if session then
        session.callback = nil
        finish()
    end

    local s = {
        query = query, callback = callback, results = {}, seen = {},
        started = GetTime(), lastAt = nil, frame = CreateFrame("Frame"),
    }
    session = s

    s.frame:RegisterEvent("CHAT_MSG_SYSTEM")
    s.frame:SetScript("OnEvent", function(_, _, msg)
        local kind, id, name = parseLine(msg)
        if kind == "item" then
            if not s.seen[id] then
                s.seen[id] = true
                s.results[#s.results + 1] = { id = id, name = name }
            end
            s.lastAt = GetTime()
        elseif kind == "limit" then
            s.truncated = true
            s.lastAt = GetTime()
        elseif kind == "none" then
            s.none = true
            finish()
        end
    end)
    s.frame:SetScript("OnUpdate", function()
        local now = GetTime()
        if (s.lastAt and now - s.lastAt >= IDLE_FINISH) or (now - s.started >= MAX_WAIT) then
            table.sort(s.results, function(a, b)
                if a.name == b.name then return a.id < b.id end
                return a.name < b.name
            end)
            finish()
        end
    end)

    SendChatMessage(".lookup item " .. query, "SAY")
    return true
end

function WLGM.IsItemSearchRunning() return session ~= nil end

-- Build and send the .additem line for an ID. player is optional (blank =
-- yourself / your selected character, as the server decides).
function WLGM.AddItemById(id, count, player)
    id = tonumber(id)
    if not id then WLGM.Warn("invalid item id"); return end
    count = tonumber(count) or 1
    if count == 0 then count = 1 end
    local line
    if WLGM.IsBlank(player) then
        line = string.format(".additem %d %d", id, count)
    else
        line = string.format(".additem %s %d %d", WLGM.Trim(player), id, count)
    end
    WLGM.RunCommand(line)
end
