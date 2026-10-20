class_name MapData
extends RefCounted
## The world's geometry, and the fixed starting grid every winter begins with. Positions are
## Vector2 metres: x is world X, y is world Z. The furnace sits at the origin; +y is towards the
## bottom of the screen. The live layout (plots, resource spots, edges) is in GameState, because
## new tiles add to it during a winter.

## The world is a grid of square tiles; tile (0, 0) is centred on the furnace. [proto] 2026-10-20
const TILE_SIZE := 20.0
## The starting grid: tiles -1..1 each way, 3 × 3. [agreed 2026-10-20]
const START_RADIUS := 1

## The starting grid's plots. Index 0 is the furnace. `type` is the building the plot holds
## (the game decides, agreed 2026-10-20); `built` ones exist from the start of a winter.
## Drawn in about 30% round the furnace (ink_v3 review, 2026-10-20) so the town reads as one
## cluster linked by its tracks; each house kit footprint keeps about 2 m clear of the next. [proto]
const START_SITES := [
	{"pos": Vector2(0, 0), "type": "furnace", "built": true},
	{"pos": Vector2(-7, -5), "type": "lumber_yard", "built": true},
	{"pos": Vector2(7, -6), "type": "hunting_lodge", "built": true},
	{"pos": Vector2(10.5, 4.5), "type": "storehouse", "built": false},
	{"pos": Vector2(-4, 9), "type": "kitchen", "built": false},
	{"pos": Vector2(4, 9), "type": "barracks", "built": false},
	{"pos": Vector2(-10, 2), "type": "bunkhouse", "built": false},
	{"pos": Vector2(11, -1), "type": "watchtower", "built": false},
	{"pos": Vector2(-4, -12), "type": "hot_springs", "built": false},
]
## Half the width of a building's square footprint.
const SITE_HALF_SIZE := 2.0
const FURNACE_RADIUS := 1.8

## The starting grid's resource spots: two forests, a fishing pond (kind "hunting") and the scrap
## heap right behind the furnace, so the first Materials are close. [proto] 2026-10-20
const START_NODES := [
	{"kind": "forest", "pos": Vector2(-14, -13)},
	{"kind": "forest", "pos": Vector2(-13, 14)},
	{"kind": "hunting", "pos": Vector2(13, -12)},
	{"kind": "scrap", "pos": Vector2(0, -7)},
]

## The Stockpile, the town's store, just right of the furnace. [agreed 2026-10-19]
const STOCKPILE_POS := Vector2(5, 1.5)


## The tile a point is on.
static func tile_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE_SIZE + 0.5), floori(pos.y / TILE_SIZE + 0.5))


## The ground a tile covers.
static func tile_rect(tile: Vector2i) -> Rect2:
	return Rect2((Vector2(tile) - Vector2(0.5, 0.5)) * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE))


## The ground the starting grid covers.
static func start_bounds() -> Rect2:
	return tile_rect(Vector2i(-START_RADIUS, -START_RADIUS)).merge(tile_rect(Vector2i(START_RADIUS, START_RADIUS)))


## The Stockpile's pad, where she stands to drop off everything she carries.
static func stockpile_pad() -> Vector2:
	return STOCKPILE_POS + Vector2(0, 1.8)


static func site_pos(s: GameState, i: int) -> Vector2:
	return s.sites[i].pos


## The build pad in front of a plot, where she stands to pay for construction and upgrades.
static func pad_pos(s: GameState, i: int) -> Vector2:
	var half := FURNACE_RADIUS if i == 0 else SITE_HALF_SIZE
	return s.sites[i].pos + Vector2(0, half + 0.9)


static func node_pos(s: GameState, i: int) -> Vector2:
	return s.node_defs[i].pos


static func node_kind(s: GameState, i: int) -> String:
	return s.node_defs[i].kind


## The plot a building stands on (built or under construction), or -1.
static func site_of_building(sites: Array, building: String) -> int:
	for i in sites.size():
		if sites[i].building == building:
			return i
	return -1
