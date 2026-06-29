-- WoWLegends_GM/Core/CommandRunner.lua
-- The single chokepoint for sending dot-commands to the server.

local addonName, WLGM = ...

-- Deliver a dot-command. AzerothCore (like TrinityCore) intercepts messages
-- that begin with the command prefix in the chat handler BEFORE they are
-- broadcast, so SendChatMessage("SAY") runs the command silently — no public
-- SAY line appears, only the server's response.
function WLGM._ExecuteRaw(line)
    if WLGM.IsBlank(line) then return end
    SendChatMessage(line, "SAY")
    WLGM.PushHistory(line)
end

-- Public entry. opts.danger=true (and the global confirm toggle) pops a confirm
-- dialog first; the dialog runs _ExecuteRaw on accept.
function WLGM.RunCommand(line, opts)
    if WLGM.IsBlank(line) then return end
    local wantConfirm = opts and opts.danger and (not WLGM.db or WLGM.db.confirmDanger ~= false)
    if wantConfirm then
        local dialog = StaticPopup_Show("WLGM_CONFIRM_CMD", line)
        if dialog then dialog.data = line end
        return
    end
    WLGM._ExecuteRaw(line)
end

-- Bot orders use the '$' command prefix (WL sets AiPlayerbot.CommandPrefix="$")
-- and are delivered as chat: PARTY/RAID to command ALL your bots at once, or
-- WHISPER to order a single targeted bot. A plain (no-$) whisper would feed the
-- bot's AI chat instead of issuing an order, so we always force a leading '$'.
function WLGM.RunBotOrder(text, opts)
    if WLGM.IsBlank(text) then return end
    opts = opts or {}
    text = WLGM.Trim(text)
    if text:sub(1, 1) ~= "$" then text = "$" .. text end
    local scope = opts.scope or "party"
    if scope == "whisper" then
        local bot = opts.bot
        if WLGM.IsBlank(bot) then bot = UnitName("target") end
        if WLGM.IsBlank(bot) then WLGM.Warn("no bot targeted to whisper the order to."); return end
        SendChatMessage(text, "WHISPER", nil, bot)
    elseif scope == "raid" then
        SendChatMessage(text, (GetNumRaidMembers and GetNumRaidMembers() > 0) and "RAID" or "PARTY")
    else
        SendChatMessage(text, "PARTY")
    end
    WLGM.PushHistory(text)   -- store clean so History can re-run it
end

-- Build a command string from a def + a table of arg values keyed by arg.key.
-- Returns (string) or (nil, errorMessage).
function WLGM.BuildLine(def, values)
    if not def or not def.format then return nil, "no command" end
    local args = def.args or {}
    if #args == 0 then return def.format end

    local resolved = {}
    for i, arg in ipairs(args) do
        local v = WLGM.ResolveArg(values and values[arg.key], arg)
        if WLGM.IsBlank(v) then
            if arg.optional then
                v = arg.default or ""
            else
                return nil, "missing: " .. (arg.placeholder or arg.key)
            end
        end
        if arg.numeric and not WLGM.IsBlank(v) then
            local n = tonumber(v)
            if not n then return nil, (arg.placeholder or arg.key) .. " must be a number" end
            v = tostring(n)
        end
        resolved[i] = v
    end

    -- Drop trailing blank optionals so the line stays tidy.
    while #resolved > 0 and resolved[#resolved] == "" do resolved[#resolved] = nil end

    local placeholders = 0
    for _ in def.format:gmatch("%%s") do placeholders = placeholders + 1 end

    if #resolved == placeholders then
        return string.format(def.format, unpack(resolved))
    else
        local padded = {}
        for i = 1, placeholders do padded[i] = resolved[i] or "" end
        local line = string.format(def.format, unpack(padded))
        return (line:gsub("%s+$", ""))
    end
end

-- Preview the command with <placeholders> shown for unfilled args. Bot orders
-- (def.send=="bot") are shown with the '$' prefix the server expects.
function WLGM.PreviewLine(def, values)
    local line = def.format or ""
    for _, arg in ipairs(def.args or {}) do
        local v = values and values[arg.key]
        local sub = (v and v ~= "" and v) or ("<" .. (arg.placeholder or arg.key) .. ">")
        line = line:gsub("%%s", sub:gsub("%%", "%%%%"), 1)
    end
    if def.send == "bot" and line:sub(1, 1) ~= "$" then line = "$" .. line end
    return line
end

-- /wlgm probe <command>: send a command and echo the next ~2s of system
-- responses inline, prefixed, so live-testing a command is low-noise.
function WLGM.Probe(line)
    line = WLGM.Trim(line or "")
    if line == "" then
        WLGM.Print("usage: /wlgm probe <command>")
        return
    end
    if not line:match("^[%./]") then line = "." .. line end

    local capture = {}
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_SYSTEM")
    listener:SetScript("OnEvent", function(_, _, msg) table.insert(capture, msg) end)

    DEFAULT_CHAT_FRAME:AddMessage(WLGM.colors.brand .. "[WLGM probe]" .. WLGM.colors.reset .. " " .. line)
    SendChatMessage(line, "SAY")
    WLGM.PushHistory(line)

    WLGM.After(2, function()
        listener:UnregisterAllEvents()
        listener:SetScript("OnEvent", nil)
        if #capture == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("  " .. WLGM.colors.muted .. "(no system response in 2s)" .. WLGM.colors.reset)
        else
            for _, msg in ipairs(capture) do
                DEFAULT_CHAT_FRAME:AddMessage("  " .. WLGM.colors.accent .. ">" .. WLGM.colors.reset .. " " .. msg)
            end
        end
    end)
end
