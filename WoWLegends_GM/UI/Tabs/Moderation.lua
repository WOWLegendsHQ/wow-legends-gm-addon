-- WoWLegends_GM/UI/Tabs/Moderation.lua
-- Moderation: bans, mutes, freezes, kicks, accounts, GM tickets,
-- deserter debuffs, and player/account lookups.
-- Authored from the Moderation command slice.

local addonName, WLGM = ...

-- Shared player-name arg: blank field falls back to the current target.
local function nameArg(opt) return { key="name", placeholder="player", fallback="target", optional=opt, width=140 } end

-- ─── Bans ──────────────────────────────────────────────────────────────────
local Bans = {
    { id="ban_account", label="Ban account", format=".ban account %s %s %s", level=2, danger=true, group="Moderation",
      args={ {key="name",placeholder="account",width=140},{key="time",placeholder="bantime",width=90},{key="reason",placeholder="reason",width=140} },
      tooltip="Ban an account and kick the player.\nbantime: negative = permanent, else a timestring like \"4d20h3s\"." },
    { id="ban_character", label="Ban character", format=".ban character %s %s %s", level=2, danger=true, group="Moderation",
      args={ {key="name",placeholder="character",width=140},{key="time",placeholder="bantime",width=90},{key="reason",placeholder="reason",width=140} },
      tooltip="Ban a single character and kick the player.\nbantime: negative = permanent, else \"4d20h3s\"." },
    { id="ban_playeraccount", label="Ban player's account", format=".ban playeraccount %s %s %s", level=2, danger=true, group="Moderation",
      args={ {key="name",placeholder="player",width=140},{key="time",placeholder="bantime",width=90},{key="reason",placeholder="reason",width=140} },
      tooltip="Ban the account that owns this character and kick the player.\nbantime: negative = permanent, else \"4d20h3s\"." },
    { id="ban_ip", label="Ban IP", format=".ban ip %s %s %s", level=2, danger=true, group="Moderation",
      args={ {key="ip",placeholder="IP address",width=120},{key="time",placeholder="bantime",width=90},{key="reason",placeholder="reason",width=140} },
      tooltip="Ban an IP address.\nbantime: negative = permanent, else \"4d20h3s\"." },

    { id="unban_account", label="Unban account", format=".unban account %s", level=3, group="Moderation",
      args={ {key="name",placeholder="account pattern",width=160} }, tooltip="Lift account bans matching this name pattern." },
    { id="unban_character", label="Unban character", format=".unban character %s", level=3, group="Moderation",
      args={ {key="name",placeholder="character",width=160} }, tooltip="Lift the ban for this character name pattern." },
    { id="unban_playeraccount", label="Unban player's account", format=".unban playeraccount %s", level=3, group="Moderation",
      args={ {key="name",placeholder="character",width=160} }, tooltip="Lift the account ban tied to this character name." },
    { id="unban_ip", label="Unban IP", format=".unban ip %s", level=3, group="Moderation",
      args={ {key="ip",placeholder="IP pattern",width=160} }, tooltip="Lift IP bans matching this pattern." },

    { id="baninfo_account", label="Ban info: account", format=".baninfo account %s", level=2, group="Moderation",
      args={ {key="id",placeholder="account id",width=120} }, tooltip="Show full information about a specific account ban." },
    { id="baninfo_character", label="Ban info: character", format=".baninfo character %s", level=2, group="Moderation",
      args={ {key="name",placeholder="character",width=140} }, tooltip="Show full information about a specific character ban." },
    { id="baninfo_ip", label="Ban info: IP", format=".baninfo ip %s", level=2, group="Moderation",
      args={ {key="ip",placeholder="IP address",width=120} }, tooltip="Show full information about a specific IP ban." },

    { id="banlist_account", label="Ban list: accounts", format=".banlist account %s", level=2, group="Moderation",
      args={ {key="name",placeholder="filter (opt)",width=130,optional=true} }, tooltip="Search account bans by name pattern, or list all account bans when blank." },
    { id="banlist_character", label="Ban list: characters", format=".banlist character %s", level=2, group="Moderation",
      args={ {key="name",placeholder="pattern",width=130} }, tooltip="Search the banlist for a character name pattern (pattern required)." },
    { id="banlist_ip", label="Ban list: IPs", format=".banlist ip %s", level=2, group="Moderation",
      args={ {key="ip",placeholder="filter (opt)",width=130,optional=true} }, tooltip="Search IP bans by pattern, or list all IP bans when blank." },
}

-- ─── Mute / Kick / Freeze ──────────────────────────────────────────────────
local Mute = {
    { id="mute", label="Mute player", format=".mute %s %s %s", level=2, danger=true, group="Moderation",
      args={ nameArg(true), {key="time",placeholder="mutetime",width=90}, {key="reason",placeholder="reason (opt)",width=140,optional=true} },
      tooltip="Disable chat for the account of this character (or your target). Player may be offline.\nmutetime: a timestring like \"1d15h33s\"." },
    { id="unmute", label="Unmute player", format=".unmute %s", level=2, group="Moderation",
      args={ nameArg(true) }, tooltip="Restore chat for the account of this character (or your target). May be offline." },
    { id="mutehistory", label="Mute history", format=".mutehistory %s", level=2, group="Moderation",
      args={ {key="account",placeholder="account",width=160} }, tooltip="Show the mute history for an account." },
    { id="whispers", label="GM whispers on/off", format=".whispers %s", level=1, group="Moderation",
      args={ {key="state",placeholder="on / off",width=90} }, tooltip="Enable or disable accepting whispers from players while GM. Defaults to the server config." },

    { id="kick", label="Kick player", format=".kick %s %s", level=2, danger=true, group="Moderation",
      args={ nameArg(true), {key="reason",placeholder="reason (opt)",width=160,optional=true} },
      tooltip="Kick the named character (or your target) from the world. Default reason is \"No Reason\"." },

    { id="freeze", label="Freeze player", format=".freeze %s", level=2, danger=true, group="Moderation",
      args={ nameArg(true) }, tooltip="Freeze a player in place and disable their chat. Blank = your target." },
    { id="unfreeze", label="Unfreeze player", format=".unfreeze %s", level=2, group="Moderation",
      args={ nameArg(true) }, tooltip="Unfreeze a player and re-enable their chat. Blank = your target." },
    { id="listfreeze", label="List frozen", format=".listfreeze", level=2, group="Moderation",
      tooltip="List all currently frozen players." },
}

-- ─── Accounts ──────────────────────────────────────────────────────────────
local Accounts = {
    { id="acc_create", label="Create account", format=".account create %s %s %s", level=4, group="Moderation",
      args={ {key="account",placeholder="account",width=140},{key="password",placeholder="password",width=140},{key="email",placeholder="email (opt)",width=160,optional=true} },
      tooltip="Create an account with a password. Email is optional." },
    { id="acc_delete", label="Delete account", format=".account delete %s", level=4, danger=true, group="Moderation",
      args={ {key="account",placeholder="account",width=160} }, tooltip="Delete an account and ALL of its characters. Irreversible." },
    { id="acc_set_gmlevel", label="Set GM level", format=".account set gmlevel %s %s", level=3, group="Moderation",
      args={ {key="account",placeholder="account",width=140},{key="level",placeholder="0-3",numeric=true,width=70} },
      tooltip="Set the security level (0-3) for an account. Leave the player selected and omit the account to target them." },
    { id="acc_set_password", label="Set password", format=".account set password %s %s %s", level=3, group="Moderation",
      args={ {key="account",placeholder="account",width=140},{key="password",placeholder="password",width=140},{key="confirm",placeholder="confirm",width=140} },
      tooltip="Set a new password for an account (entered twice to confirm)." },
    { id="acc_set_addon", label="Set addon (expansion)", format=".account set addon %s %s", level=2, group="Moderation",
      args={ {key="account",placeholder="account (opt)",width=140,optional=true},{key="addon",placeholder="0/1/2",numeric=true,width=70} },
      tooltip="Set the allowed expansion level for an account: 0 normal, 1 TBC, 2 WotLK. Blank account = your target." },
    { id="acc_onlinelist", label="Online accounts", format=".account onlinelist", level=4, group="Moderation",
      tooltip="Show the list of currently online accounts." },
    { id="acc_lock_ip", label="Lock to IP", format=".account lock ip %s", level=0, group="Moderation",
      args={ {key="state",placeholder="on / off",width=90} }, tooltip="Restrict login to the current IP, or remove that requirement (your own account)." },
    { id="acc_lock_country", label="Lock to country", format=".account lock country %s", level=0, group="Moderation",
      args={ {key="state",placeholder="on / off",width=90} }, tooltip="Restrict login to the current country, or remove that requirement (your own account)." },
}

-- ─── Tickets ───────────────────────────────────────────────────────────────
local Tickets = {
    { id="ticket_list", label="Open tickets", format=".ticket list", level=2, group="Moderation",
      tooltip="Display the list of open GM tickets." },
    { id="ticket_onlinelist", label="Online ticket owners", format=".ticket onlinelist", level=2, group="Moderation",
      tooltip="Display open GM tickets whose owner is currently online." },
    { id="ticket_closedlist", label="Closed tickets", format=".ticket closedlist", level=2, group="Moderation",
      tooltip="Display the list of closed GM tickets." },
    { id="ticket_escalatedlist", label="Escalated tickets", format=".ticket escalatedlist", level=2, group="Moderation",
      tooltip="List all open tickets currently in the escalation queue." },
    { id="ticket_viewid", label="View ticket", format=".ticket viewid %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Show details about an open, non-deleted ticket by ID." },
    { id="ticket_assign", label="Assign ticket", format=".ticket assign %s %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90},{key="gm",placeholder="GM name",width=140} }, tooltip="Assign a ticket to the named Game Master." },
    { id="ticket_unassign", label="Unassign ticket", format=".ticket unassign %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Unassign a ticket from its current Game Master." },
    { id="ticket_comment", label="Comment on ticket", format=".ticket comment %s %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90},{key="text",placeholder="comment",width=180} }, tooltip="Add or modify a comment on a ticket." },
    { id="ticket_escalate", label="Escalate ticket", format=".ticket escalate %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Add a ticket to the escalation queue." },
    { id="ticket_complete", label="Complete ticket", format=".ticket complete %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Mark a ticket as complete." },
    { id="ticket_close", label="Close ticket", format=".ticket close %s", level=2, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Close a ticket. Does not delete it permanently." },
    { id="ticket_delete", label="Delete ticket", format=".ticket delete %s", level=3, danger=true, group="Moderation",
      args={ {key="id",placeholder="ticket id",numeric=true,width=90} }, tooltip="Permanently delete a ticket (must be closed first). Irreversible." },
    { id="ticket_reset", label="Reset all tickets", format=".ticket reset", level=4, danger=true, group="Moderation",
      tooltip="Remove all closed tickets and reset the counter (only if no open tickets remain)." },
}

-- ─── Deserter ──────────────────────────────────────────────────────────────
local Deserter = {
    { id="des_bg_add", label="Add BG deserter", format=".deserter bg add %s %s", level=3, group="Moderation",
      args={ nameArg(false), {key="time",placeholder="time (opt)",width=90,optional=true} },
      tooltip="Apply the Battleground deserter debuff to a player or your target.\nOptional time like \"1h15m30s\" (default 15m)." },
    { id="des_bg_remove", label="Remove BG deserter", format=".deserter bg remove %s", level=3, group="Moderation",
      args={ nameArg(false) }, tooltip="Remove the Battleground deserter debuff from a player or your target." },
    { id="des_inst_add", label="Add instance deserter", format=".deserter instance add %s %s", level=3, group="Moderation",
      args={ nameArg(false), {key="time",placeholder="time (opt)",width=90,optional=true} },
      tooltip="Apply the instance deserter debuff to a player or your target.\nOptional time like \"1h15m30s\" (default 30m)." },
    { id="des_inst_remove", label="Remove instance deserter", format=".deserter instance remove %s", level=3, group="Moderation",
      args={ nameArg(false) }, tooltip="Remove the instance deserter debuff from a player or your target." },
}

-- ─── Lookup (pinfo + .lookup player) ───────────────────────────────────────
local Lookup = {
    { id="pinfo", label="Player info", format=".pinfo %s", level=2, group="Moderation",
      args={ {key="player",placeholder="name/GUID (opt)",fallback="target",optional=true,width=150} },
      tooltip="Show account and guild information for the selected player, or one found by name / GUID." },
    { id="lookup_player_account", label="Lookup by account", format=".lookup player account %s %s", level=2, group="Moderation",
      args={ {key="account",placeholder="account",width=140},{key="limit",placeholder="limit (opt)",numeric=true,width=80,optional=true} },
      tooltip="Find players whose account username matches, with an optional result limit." },
    { id="lookup_player_email", label="Lookup by email", format=".lookup player email %s %s", level=2, group="Moderation",
      args={ {key="email",placeholder="email",width=160},{key="limit",placeholder="limit (opt)",numeric=true,width=80,optional=true} },
      tooltip="Find players whose account email matches, with an optional result limit." },
    { id="lookup_player_ip", label="Lookup by IP", format=".lookup player ip %s %s", level=2, group="Moderation",
      args={ {key="ip",placeholder="IP address",width=140},{key="limit",placeholder="limit (opt)",numeric=true,width=80,optional=true} },
      tooltip="Find players whose last-used IP matches, with an optional result limit." },
}

WLGM.RegisterTab({
    id = "moderation", label = "Moderation",
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Bans",     rows = Bans,      layoutOpts = { rowsPerColumn = 8, columnWidth = 420 } },
            { label = "Mute",     rows = Mute },
            { label = "Accounts", rows = Accounts },
            { label = "Tickets",  rows = Tickets,   layoutOpts = { rowsPerColumn = 7, columnWidth = 420 } },
            { label = "Deserter", rows = Deserter },
            { label = "Lookup",   rows = Lookup },
        }, "moderation")
    end,
})
