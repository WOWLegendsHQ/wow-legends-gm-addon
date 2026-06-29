-- WoWLegends_GM/UI/Tabs/Object.lua
-- Gameobject control: .gobject add/move/turn/find/info/activate/set + .go object lookup.
-- Authored from the Object command slice (AzerothCore 3.3.5a).

local addonName, WLGM = ...

-- ─── Spawn & remove ────────────────────────────────────────────────────────
local Spawn = {
    { id="gob_add", label="Add gameobject", format=".gobject add %s %s", level=3, group="Object",
      args={ {key="id",placeholder="template id",numeric=true,width=100}, {key="spawntime",placeholder="spawntime secs (opt)",numeric=true,width=130,optional=true} },
      tooltip="Spawn a gameobject from its template id at your location and save it to the DB. Optional spawntime in seconds." },
    { id="gob_addtemp", label="Add temp gameobject", format=".gobject add temp", level=2, group="Object",
      tooltip="Add a temporary gameobject at your location. NOT saved to the database - gone on restart." },
    { id="gob_delete", label="Delete gameobject", format=".gobject delete %s", level=3, group="Object", danger=true,
      args={ {key="guid",placeholder="spawn guid",numeric=true,width=110} },
      tooltip="Permanently delete the gameobject spawn with this DB guid." },
    { id="gob_load", label="Load spawn", format=".gobject load %s", level=3, group="Object",
      args={ {key="guid",placeholder="spawn id",numeric=true,width=110} },
      tooltip="Load a saved gameobject spawn from the database into the world by its guid." },
    { id="gob_respawn", label="Respawn gameobject", format=".gobject respawn %s", level=2, group="Object",
      args={ {key="guid",placeholder="guid (opt)",numeric=true,width=110,optional=true} },
      tooltip="Respawn the selected gameobject, or the one with the given guid." },
    { id="gob_spawngroup", label="Spawn group", format=".gobject spawngroup %s", level=3, group="Object",
      args={ {key="groupId",placeholder="group id",numeric=true,width=100} },
      tooltip="Spawn all gameobjects in the given spawn group." },
    { id="gob_despawngroup", label="Despawn group", format=".gobject despawngroup %s", level=3, group="Object", danger=true,
      args={ {key="groupId",placeholder="group id",numeric=true,width=100} },
      tooltip="Despawn all gameobjects in the given spawn group." },
}

-- ─── Position & state ──────────────────────────────────────────────────────
local Move = {
    { id="gob_move", label="Move gameobject", format=".gobject move %s %s %s %s", level=3, group="Object",
      args={ {key="guid",placeholder="goguid",numeric=true,width=90}, {key="x",placeholder="x (opt)",numeric=true,width=70,optional=true}, {key="y",placeholder="y (opt)",numeric=true,width=70,optional=true}, {key="z",placeholder="z (opt)",numeric=true,width=70,optional=true} },
      tooltip="Move gameobject #goguid to your position, or to the given (x y z) coordinates." },
    { id="gob_turn", label="Turn gameobject", format=".gobject turn %s", level=3, group="Object",
      args={ {key="guid",placeholder="goguid",numeric=true,width=90} },
      tooltip="Set the gameobject's orientation to match your character's current facing." },
    { id="gob_activate", label="Activate gameobject", format=".gobject activate %s", level=2, group="Object",
      args={ {key="guid",placeholder="guid",numeric=true,width=90} },
      tooltip="Activate an object like a door or a button." },
    { id="gob_setphase", label="Set phase", format=".gobject set phase %s %s", level=3, group="Object",
      args={ {key="guid",placeholder="guid",numeric=true,width=90}, {key="phasemask",placeholder="phasemask",numeric=true,width=100} },
      tooltip="Change the gameobject's phasemask (saved to DB, persistent) and update player vision." },
    { id="gob_setstate", label="Set state", format=".gobject set state %s %s %s", level=3, group="Object",
      args={ {key="guid",placeholder="GUIDLow",numeric=true,width=90}, {key="objectType",placeholder="object type",numeric=true,width=90}, {key="objectState",placeholder="object state",numeric=true,width=100} },
      tooltip="Set the byte value or send a custom animation for the given gameobject guid." },
}

-- ─── Find & inspect ────────────────────────────────────────────────────────
local Find = {
    { id="gob_near", label="Near gameobjects", format=".gobject near %s", level=1, group="Object",
      args={ {key="distance",placeholder="distance (opt, 10)",numeric=true,width=130,optional=true} },
      tooltip="List nearby gameobjects (guid + coords) sorted by distance. Default radius 10 yards." },
    { id="gob_target", label="Target nearest", format=".gobject target %s", level=1, group="Object",
      args={ {key="query",placeholder="id or name part (opt)",width=160,optional=true} },
      tooltip="Locate and show the position of the nearest gameobject. Optionally filter by template id or name part." },
    { id="gob_info", label="Gameobject info", format=".gobject info %s", level=1, group="Object",
      args={ {key="entry",placeholder="entry (opt)",numeric=true,width=110,optional=true} },
      tooltip="Query info for the selected gameobject, or for the given template entry." },
    { id="go_object", label="Go to object", format=".go object %s", level=1, group="Object",
      args={ {key="guid",placeholder="object guid",numeric=true,width=110} },
      tooltip="Teleport your character to the gameobject with this spawn guid. (Replaces deprecated .lookup object.)" },
    { id="lk_gobject", label="Lookup gobject", format=".lookup gobject %s", level=1, group="Object",
      args={ {key="q",placeholder="search",width=140} },
      tooltip="Search gameobject templates by name and list matching entry ids." },
}

WLGM.RegisterTab({
    id = "object", label = "Object",
    builder = function(parent)
        WLGM.BuildScrollSections(parent, {
            { title = "Spawn & remove",   rows = Spawn },
            { title = "Position & state", rows = Move },
            { title = "Find & inspect",   rows = Find },
        })
    end,
})
