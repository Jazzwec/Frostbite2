class_name GameState
extends RefCounted
## Everything that changes during a winter. Only the engine writes to it; scenes read it.

## Active play time in seconds.
var time := 0.0

var heat := 0.0
## Set when the fire goes out; the winter is over and nothing ticks any more.
var game_over := false
## Wood delivered into the furnace, waiting to burn.
var fuel := 0.0
## Wood burned per second last tick, for the fire's look.
var burn_rate := 0.0

## The Stockpile by the furnace, the town's store: Jans' output and whatever Meagan drops off.
## Build pads and the furnace draw from it.
var piles := {"wood": 0.0, "food": 0.0, "materials": 0.0}

## Meagan. Her position comes from the scene every frame.
var meagan_pos := Vector2(0, 3)
var bag := {"wood": 0.0, "food": 0.0, "materials": 0.0}
var meagan_hp := Balance.MEAGAN_HP
var meagan_injured := false
## The frozen Jan she was sent to, or -1.
var rescue_target := -1
## What she did this tick, for her animation: "" | full | gather | load | store | fuel | build | fight.
## The target is a node index, site index or wolf id; the position is where to face.
var meagan_activity := ""
var meagan_target := -1
var meagan_target_pos := Vector2.ZERO

## The winter's world (agreed 2026-10-20): its seed decides what every tile beyond the starting
## grid holds. Open tiles by "x,y" key; gates on the border of closed tiles next to open ones:
## {tile: Vector2i, pos: Vector2 (on the border), pad: Vector2, cost, progress, paying: bool};
## and the small furnaces lit by opening tiles: {tile, pos}.
var run_seed := 0
var tiles := {}
var gates: Array = []
var stoves: Array = []
## What opened tiles held besides resource spots and plots, for later phases:
## camps {pos, jans, tile}, chests {pos, kind, rarity, tile, opened}, dens {pos, tile}.
var camps: Array = []
var chests: Array = []
var dens: Array = []

## What chests gave her this winter (agreed 2026-10-20): run-long modifiers from boons, by key
## (bag_add, walk_mult, gather_mult, drain_cut, work_mult, producer_slots, cap_mult, cache_mult),
## the boons taken, and her gear: each slot's tier ("" for none).
var mods := {}
var boons: Array = []
var gear := {"axe": "", "boots": "", "sled": ""}
## A chest's choice waiting for her, or {}: {kind: "boon", chest, options: [boon ids]} or
## {kind: "gear", chest, slot, tier}. The world waits while it's open.
var offer := {}

## The ground Meagan can walk on and wolves stay within: the box round the open tiles.
var bounds := Rect2()

## One entry per plot: {type: the building it holds (the game decides), pos: Vector2,
## building: String ("" = not started yet), level: int, upgrading: bool, progress: {resource: amount}}.
## A plot under first construction has its building, level 0 and upgrading = true.
## Index 0 is always the furnace.
var sites: Array = []

## The resource spots: {kind, pos: Vector2}, and the stock left at each, by the same index.
var node_defs: Array = []
var nodes: Array = []

## Rescued Jans: {id, job ("" = idle), hp, ko, pos: Vector2}. hp, ko and pos matter for guards.
var jans: Array = []
## Where frozen Jans wait, and where wolf packs come in from.
var arrival_spots: Array = []
var wolf_spawns: Array = []
## Frozen Jans waiting to be thawed: {id, spot, pos}.
var arrivals: Array = []
var next_arrival_in := Balance.FIRST_ARRIVAL_DELAY
var rescued_total := 0
## Jans lost to the cold or to wolves.
var lost_total := 0
var hungry := false
## Auto-assign: on or off, and seconds until its next rebalance.
var auto_assign := false
var auto_assign_in := 0.0

## Blizzards: the next one starts at blizzard_at; it is active until blizzard_ends_at.
var blizzard_at := Balance.BLIZZARD_FIRST_AT
var blizzard_ends_at := 0.0
var blizzard_active := false
var blizzard_warned := false
var blizzards_survived := 0

## Wolves: {id, pos: Vector2, hp, max_hp, damage, loot_scale, mode, target, scare_timer, scared},
## plus foe_pos (who it's fighting) once it has fought.
## mode: "furnace" (heading in), "jans" (detouring to a site), "fight", "leave".
var wolves: Array = []
## Time of the next attack, or -1 until the Furnace reaches Lv 2.
var attack_at := -1.0
## Whether the coming attack has been announced (only a Watchtower does that).
var attack_warned := false
var attacks_repelled := 0

var next_id := 1


func new_id() -> int:
	next_id += 1
	return next_id - 1


## Every field above, by name, for saving. Values are copied deeply, so the dictionary doesn't
## change as the game goes on.
func to_dict() -> Dictionary:
	var out := {}
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = get(prop.name)
			out[prop.name] = value.duplicate(true) if value is Array or value is Dictionary else value
	return out


## The state saved by to_dict(). Fields missing from an older save keep their defaults, and
## unknown ones are ignored.
static func from_dict(data: Dictionary) -> GameState:
	var s := GameState.new()
	for prop in s.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and data.has(prop.name):
			var value: Variant = data[prop.name]
			s.set(prop.name, value.duplicate(true) if value is Array or value is Dictionary else value)
	return s
