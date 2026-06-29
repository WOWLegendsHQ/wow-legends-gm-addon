-- WoWLegends_GM/UI/Tabs/Items.lua
-- Items: add items / item sets, move / restore / refund items, clear bags,
-- send items / money / mail, mail management, and item / item-set lookups.

local addonName, WLGM = ...

local function nameArg(opt)
    return { key="name", placeholder="player", fallback="target", optional=opt, width=150 }
end

-- ─── Add items & item sets ─────────────────────────────────────────────────
local Add = {
    { id="additem", label="Add item", format=".additem %s %s", level=2, group="Items",
      args={ {key="item",placeholder="itemID / \"name\"",width=150}, {key="count",placeholder="count",numeric=true,optional=true} },
      tooltip="Add an item to yourself or your selected character. Accepts item ID, name or link.\nA negative count REMOVES that many instead. .additem <item> [count]" },
    { id="additem_target", label="Add item to player", format=".additem %s %s %s", level=2, group="Items",
      args={ nameArg(), {key="item",placeholder="itemID / \"name\"",width=150}, {key="count",placeholder="count",numeric=true,optional=true} },
      tooltip="Add an item to a named player (or current target). .additem <player> <item> [count]" },
    { id="additemset", label="Add item set", format=".additemset %s", level=2, group="Items",
      args={ {key="setid",placeholder="itemsetID",numeric=true,width=110} },
      tooltip="Add one of each item from the given item set to your (or your selected character's) inventory." },
    { id="bags_clear", label="Clear bags", format=".bags clear %s", level=2, group="Items", danger=true,
      args={ {key="quality",placeholder="quality / all",width=110} },
      tooltip="Clear from the player's bags all items at and below the given quality (or 'all' for everything).\nIrreversible." },
}

-- ─── Manage held items ─────────────────────────────────────────────────────
local Manage = {
    { id="item_move", label="Move item", format=".itemmove %s %s", level=2, group="Items",
      args={ {key="src",placeholder="source slot",numeric=true,width=100}, {key="dst",placeholder="dest slot",numeric=true,width=100} },
      tooltip="Move an item from one inventory slot to another. .itemmove <sourceSlot> <destSlot>" },
    { id="item_restore_list", label="Restorable items", format=".item restore list %s", level=2, group="Items",
      args={ nameArg(true) },
      tooltip="List a player's disposed/recoverable items, with the recovery IDs used by Restore item." },
    { id="item_restore", label="Restore item", format=".item restore %s %s", level=2, group="Items",
      args={ {key="recoveryid",placeholder="recoveryID",numeric=true,optional=true,width=100}, nameArg(true) },
      tooltip="Restore a disposed item for a player. Get the recovery ID from 'Restorable items'.\n.item restore [recoveryItemId] [player]" },
    { id="item_refund", label="Refund item", format=".item refund %s %s %s", level=3, group="Items", danger=true,
      args={ nameArg(), {key="item",placeholder="item",width=120}, {key="cost",placeholder="extendedCost",numeric=true,width=110} },
      tooltip="Remove the item and restore honor / arena points / items per its extended cost. .item refund <player> <item> <extendedCost>" },
    { id="inv_count", label="Inventory count", format=".inventory count %s", level=1, group="Items",
      args={ nameArg(true) },
      tooltip="Count free bag slots for a player, broken down by bag type." },
}

-- ─── Send items, money & mail ──────────────────────────────────────────────
local Send = {
    { id="send_items", label="Send items", format=".send items %s %s", level=2, group="Items",
      args={ nameArg(), {key="rest",placeholder="\"subject\" \"text\" itemID[:count] ...",width=320} },
      tooltip="Mail items to a player. Subject and text in quotes, then item IDs (optional :count each).\nMax 12 stacks per mail.\ne.g. .send items Bob \"Gift\" \"Enjoy\" 49623:1 6948" },
    { id="send_money", label="Send money", format=".send money %s %s", level=2, group="Items",
      args={ nameArg(), {key="rest",placeholder="\"subject\" \"text\" copper",width=260} },
      tooltip="Mail money (in copper) to a player. Subject and text in quotes.\ne.g. .send money Bob \"Reward\" \"Well done\" 100000" },
    { id="send_mail", label="Send mail", format=".send mail %s %s", level=2, group="Items",
      args={ nameArg(), {key="rest",placeholder="\"subject\" \"text\"",width=240} },
      tooltip="Send a plain text mail to a player. Subject and text must be in quotes.\ne.g. .send mail Bob \"Hello\" \"Welcome to the realm\"" },
    { id="send_message", label="Send screen message", format=".send message %s %s", level=3, group="Items",
      args={ nameArg(), {key="message",placeholder="message",width=240} },
      tooltip="Send an on-screen message to a player from ADMINISTRATOR." },
    { id="mail_list", label="List mail", format=".mail list %s", level=2, group="Items",
      args={ nameArg(true) },
      tooltip="Show all mail data (no subject/body) for the target player." },
    { id="mail_return", label="Return mail", format=".mail return %s %s", level=2, group="Items",
      args={ nameArg(), {key="mailid",placeholder="mailID",numeric=true,width=100} },
      tooltip="Return the specified mail to its original sender. .mail return <player> <mailId>" },
    { id="mailbox", label="Open my mailbox", format=".mailbox", level=1, group="Items",
      tooltip="Show your own mailbox contents." },
}

-- ─── Lookup ────────────────────────────────────────────────────────────────
local Lookup = {
    { id="lookup_item", label="Lookup item", format=".lookup item %s", level=1, group="Items",
      args={ {key="name",placeholder="item name",width=180} },
      tooltip="Look up items by name and return all matches with their item IDs." },
    { id="lookup_itemset", label="Lookup item set", format=".lookup itemset %s", level=1, group="Items",
      args={ {key="name",placeholder="set name",width=180} },
      tooltip="Look up item sets by name and return all matches with their item-set IDs." },
    { id="list_item", label="Find item owners", format=".list item %s %s", level=1, group="Items",
      args={ {key="itemid",placeholder="itemID",numeric=true,width=110}, {key="max",placeholder="max (def 10)",numeric=true,optional=true,width=100} },
      tooltip="Find an item ID across all character inventories, mails, auctions and guild banks.\nReports item GUID, owner and account. .list item <itemId> [maxCount]" },
}

WLGM.RegisterTab({
    id = "items", label = "Items",
    builder = function(parent)
        WLGM.BuildSubTabs(parent, {
            { label = "Add",         rows = Add,    layoutOpts = { yTop = 8, sectionTitle = "Add items & item sets" } },
            { label = "Manage",      rows = Manage, layoutOpts = { yTop = 8, sectionTitle = "Move, restore & refund items" } },
            { label = "Send & Mail", rows = Send,   layoutOpts = { yTop = 8, sectionTitle = "Send items, money & mail", rowsPerColumn = 7, columnWidth = 430 } },
            { label = "Lookup",      rows = Lookup, layoutOpts = { yTop = 8, sectionTitle = "Item & item-set lookup" } },
        }, "items")
    end,
})
