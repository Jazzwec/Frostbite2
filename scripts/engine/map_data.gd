class_name MapData
extends RefCounted
## The town layout as data. Positions are Vector2 metres: x is world X, y is world Z.
## The furnace sits at the origin; +y is towards the bottom of the screen.

## The snowfield. [brief] about three phone screens.
const BOUNDS := Rect2(-24.0, -40.0, 48.0, 80.0)

## Building plots. Index 0 is the furnace. `fixed` buildings exist from the start of a winter.
const SITES := [
	{"pos": Vector2(0, 0), "fixed": "furnace"},
	{"pos": Vector2(-9, -6), "fixed": "lumber_yard"},
	{"pos": Vector2(9, -6), "fixed": "hunting_lodge"},
	{"pos": Vector2(-9, 4), "fixed": ""},
	{"pos": Vector2(9, 4), "fixed": ""},
	{"pos": Vector2(-5, 12), "fixed": ""},
	{"pos": Vector2(5, 12), "fixed": ""},
	{"pos": Vector2(-6, -15), "fixed": ""},
	{"pos": Vector2(6, -15), "fixed": ""},
	{"pos": Vector2(-15, -1), "fixed": ""},
	{"pos": Vector2(15, -1), "fixed": ""},
]
## Half the width of a building's square footprint.
const SITE_HALF_SIZE := 2.0
const FURNACE_RADIUS := 1.8

## Resource spots on the outskirts. [brief] 4 forests, 3 hunting grounds, 3 scrap heaps.
## One scrap heap sits right behind the furnace so the first Materials are close.
const RESOURCE_NODES := [
	{"kind": "forest", "pos": Vector2(-17, -26)},
	{"kind": "forest", "pos": Vector2(17, -30)},
	{"kind": "forest", "pos": Vector2(-18, 24)},
	{"kind": "forest", "pos": Vector2(16, 32)},
	{"kind": "hunting", "pos": Vector2(-20, 10)},
	{"kind": "hunting", "pos": Vector2(20, -14)},
	{"kind": "hunting", "pos": Vector2(2, 34)},
	{"kind": "scrap", "pos": Vector2(0, -7)},
	{"kind": "scrap", "pos": Vector2(-19, -37)},
	{"kind": "scrap", "pos": Vector2(21, 21)},
]

## Where frozen Jans wait, near the map edge.
const ARRIVAL_SPOTS := [
	Vector2(-21, -33), Vector2(21, -36), Vector2(-22, -6), Vector2(22, 6),
	Vector2(-21, 36), Vector2(20, 37), Vector2(0, -38), Vector2(-4, 38),
]

## Where wolf packs come in from.
const WOLF_SPAWNS := [Vector2(0, -40), Vector2(-24, -20), Vector2(24, 18), Vector2(-24, 28), Vector2(24, -30)]


## The site a job's building stands on, or -1.
## The Stockpile, the town's store, just right of the furnace. [agreed 2026-10-19]
const STOCKPILE_POS := Vector2(5, 1.5)


## The Stockpile's pad, where she stands to drop off everything she carries.
static func stockpile_pad() -> Vector2:
	return STOCKPILE_POS + Vector2(0, 1.8)


## The build pad in front of a plot, where she stands to pay for construction and upgrades.
static func pad_pos(i: int) -> Vector2:
	var half := FURNACE_RADIUS if i == 0 else SITE_HALF_SIZE
	return SITES[i].pos + Vector2(0, half + 0.9)


static func site_of_building(sites: Array, building: String) -> int:
	for i in sites.size():
		if sites[i].building == building:
			return i
	return -1
