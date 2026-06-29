-- WoWLegends_GM/UI/Tabs/Quest.lua
-- Quest control: add / complete / remove / reward / status on the selected
-- player, plus a quest-name lookup. Authored from the Quest command slice.

local addonName, WLGM = ...

-- ─── Quest control rows ────────────────────────────────────────────────────
local Quest = {
    { id="quest_add", label="Add quest", format=".quest add %s", level=2, group="Quest",
      args={ {key="id",placeholder="quest id",numeric=true,width=100} },
      tooltip="Add quest #id to the target character's quest log.\nQuests started from an item can't be added this way - the command prints the correct .additem call instead." },
    { id="quest_complete", label="Complete quest", format=".quest complete %s", level=2, group="Quest",
      args={ {key="id",placeholder="quest id",numeric=true,width=100} },
      tooltip="Mark every objective complete for one of the target character's active quests, so they can turn it in for the reward." },
    { id="quest_reward", label="Reward quest", format=".quest reward %s", level=2, group="Quest",
      args={ {key="id",placeholder="quest id",numeric=true,width=100} },
      tooltip="Grant the quest reward to the selected player and remove the quest from their log.\nThe quest must already be in the completed state." },
    { id="quest_status", label="Quest status", format=".quest status %s %s", level=2, group="Quest",
      args={ {key="id",placeholder="quest id",numeric=true,width=100}, {key="name",placeholder="player",fallback="target",optional=true} },
      tooltip="Show the selected player's status for a quest. Leave the name blank to use your current target.\n.quest status <id> [player]" },
    { id="quest_remove", label="Remove quest", format=".quest remove %s", level=2, group="Quest", danger=true,
      args={ {key="id",placeholder="quest id",numeric=true,width=100} },
      tooltip="Reset quest #id to not-completed and not-active and drop it from the selected player's active quest list." },
    { id="lookup_quest", label="Lookup quest", format=".lookup quest %s", level=1, group="Quest",
      args={ {key="name",placeholder="name part",width=150} },
      tooltip="Search quests by part of their name and list every match with its quest ID." },
}

WLGM.RegisterTab({
    id = "quest", label = "Quest",
    builder = function(parent)
        WLGM.LayoutRows(parent, Quest, { yTop = 8, sectionTitle = "Quest control", rowsPerColumn = 10, columnWidth = 420 })
    end,
})
