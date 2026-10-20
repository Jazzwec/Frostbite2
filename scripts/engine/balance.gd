class_name Balance
extends RefCounted
## Every tunable number in the game. Engine code reads these and never hard-codes a number.
## Sources: [brief] docs/design-brief.md, [f1] Frostbite 1's planned value (docs/frostbite1/balance.ts),
## [proto] new for the Frostbite2 prototype. Distances are metres, times are seconds.

# ---------- Simulation ----------

## Fixed tick length. [brief] 10 ticks per second.
const TICK := 0.1
## Most real time one advance() call may simulate; longer frames are dropped, never caught up. [f1]
const MAX_ADVANCE := 1.0
## The winter is saved this often while playing, and on pause, focus loss and quit. [backlog]
const AUTOSAVE_INTERVAL := 10.0
## The "Drag anywhere to move" hint counts as done once Meagan is this far from where she started. [proto]
const HINT_MOVED_ENOUGH := 2.0

# ---------- Heat and fuel ----------

## Heat cap = Furnace level × this. [brief]
const HEAT_CAP_PER_FURNACE_LEVEL := 100.0
## Heat gained per Wood burned. [brief]
const HEAT_PER_WOOD := 10.0
## Each Furnace level above 1 makes each Wood give this much more heat. [brief] +5% per level
const HEAT_PER_WOOD_BONUS_PER_LEVEL := 0.05
## Drain per second = base + per Jan + per non-Furnace building level. [brief]
const DRAIN_BASE := 0.5
const DRAIN_PER_JAN := 0.1
const DRAIN_PER_BUILDING_LEVEL := 0.05
## Below this fraction of the heat cap, jobs run at COLD_OUTPUT_MULT. [brief]
const COLD_THRESHOLD := 0.3
const COLD_OUTPUT_MULT := 0.5
## Wood the furnace holds per Furnace level. [f1]
const FUEL_CAP_PER_FURNACE_LEVEL := 30.0
## Low-heat warnings, as fractions of the heat cap: the warning shows below WARNING, clears
## above CLEAR, and a countdown to the fire going out shows below COUNTDOWN. [proto]
const LOW_HEAT_WARNING := 0.25
const LOW_HEAT_CLEAR := 0.4
const FIRE_OUT_COUNTDOWN := 0.10

# ---------- Food ----------

## Each Jan eats 1 Food per minute. [brief]
const FOOD_PER_JAN_PER_SECOND := 1.0 / 60.0
## Each Kitchen level cuts the Food a Jan eats by this share of the base (additive, so Lv 10
## halves it). [brief] + [f1] kitchenReductionPerLevel
const KITCHEN_FOOD_CUT_PER_LEVEL := 0.05
## With no Food in store, Jans work this much slower. [brief]
const HUNGRY_OUTPUT_MULT := 0.75

# ---------- Storage caps (the piles at the producers) ----------

const CAP_WOOD := 300.0  # [brief]
const CAP_FOOD := 150.0  # [brief]
const CAP_MATERIALS := 100.0  # [brief]
## Lumber Yard adds this much Wood cap per level above 1. [brief]
const WOOD_CAP_PER_LUMBER_LEVEL := 50.0
## Storehouse multiplies every cap by this per level, compounding. [brief]
## Every Stockpile level above the first multiplies every cap by this. [proto, agreed 2026-10-20]
const STOCKPILE_CAP_GROWTH := 1.2
const STOREHOUSE_CAP_GROWTH := 1.25

# ---------- Jans ----------

const JAN_CAP_PER_FURNACE_LEVEL := 4  # [brief]
const JAN_CAP_PER_BUNKHOUSE_LEVEL := 2  # [brief]
## Seconds between arrivals when the city is empty; × (1 + slowdown × fill²) as it fills. [brief]
const ARRIVAL_BASE_INTERVAL := 60.0
const ARRIVAL_FILL_SLOWDOWN := 2.0
## Most frozen Jans waiting at the edge at once. [brief]
const ARRIVAL_MAX_WAITING := 3
## The first frozen Jan appears this soon after a new game, so Meagan can rescue him herself. [proto]
const FIRST_ARRIVAL_DELAY := 5.0
## Each producer (Lumber Yard, Fishing Lodge, Workshop) holds this many Jans; upgrading raises its
## rate, not its room, so growing means building more of them. [proto] agreed 2026-10-20
const PRODUCER_JAN_CAP := 3
## Job shares used to place a new Jan once Chopping and Fishing are covered. [brief] 3 : 2 : 2
const JOB_SHARES := {"chop": 3.0, "hunt": 2.0, "build": 2.0}
## Auto-assign unlocks at this Furnace level and rebalances this often. [brief] + [f1] AUTO_JOB
const AUTO_ASSIGN_FURNACE_LEVEL := 4
const AUTO_ASSIGN_EVERY := 5.0

# ---------- Meagan ----------

const MEAGAN_WALK_SPEED := 6.0  # [proto] brisk, hypercasual
## She gathers automatically while within this distance of a resource node. [proto]
const GATHER_RANGE := 3.0
## Hand-gathering per second by resource. [brief]
const GATHER_RATE := {"wood": 5.0, "food": 3.0, "materials": 1.0}
## Her bag (back since 2026-10-20): all resources together. [brief] Each Stockpile level above the
## first adds to it. [proto, agreed 2026-10-20]
const BAG_BASE := 20.0
const BAG_PER_STOCKPILE_LEVEL := 10.0
## On any stockpile's pad her bag empties this fast. [f1] 20 units/s
const STORE_PER_SECOND := 20.0
## A build pad or gate she stands on takes what it needs (from her bag, then the store) this fast.
## [f1] 20 units/s shared
const PAD_PAY_PER_SECOND := 20.0
## Construction and upgrades are paid only while she stands on the plot's pad. [proto]
const PAD_RADIUS := 1.4
## Jans haul their work (agreed 2026-10-20): a load is this much, carried to the nearest stockpile
## at walking pace, slowed by the path factor for the way round buildings. [proto]
const CARRY_LOAD := {"chop": 5.0, "hunt": 3.0, "build": 1.0}
const JAN_WALK_SPEED := 3.0
const JAN_PATH_FACTOR := 1.25
## The furnace feeds itself from the Stockpile's Wood this fast, up to its fuel cap. [proto]
const FURNACE_FEED_PER_SECOND := 5.0
## She thaws a frozen Jan when this close. [proto]
const RESCUE_RANGE := 2.0
## Combat. [brief]
const MEAGAN_HP := 100.0
## Knocked down, she gets up after this long with this share of her HP, raid or not (fight_v2
## review 2: thieves you can still catch; the brief had her down until the raid ended). [proto]
const MEAGAN_DOWN_TIME := 6.0
const MEAGAN_GETUP_HP := 0.5
const MEAGAN_DAMAGE_PER_SECOND := 10.0
const MEAGAN_ATTACK_RANGE := 2.5  # [proto]
## Hypercasual fighting (agreed 2026-10-20, numbers from Astra's steer, all [proto]): she
## fights on her own, two ways. Snowballs at range; a walking-stick sweep up close. She swaps to
## melee as soon as a wolf is within reach, and back to snowballs only once none has been within
## the exit distance for a moment (so it doesn't flicker). One shared cooldown.
const MEAGAN_MELEE_REACH := 2.5
const MEAGAN_MELEE_DAMAGE := 10.0
const MEAGAN_MELEE_EVERY := 0.8
## From the start of the sweep to its hit: a short anticipation, its direction committed at the
## start (fight_v2 review 1: 0.12-0.18 s).
const MEAGAN_MELEE_IMPACT := 0.16
const MEAGAN_MELEE_KNOCK := 0.25
const MEAGAN_MELEE_EXIT := 3.0
const MEAGAN_MELEE_EXIT_TIME := 0.4
## She keeps a target at least this long before turning to a nearer one (fight_v2 review 1).
const MEAGAN_TARGET_HOLD := 0.4
const MEAGAN_RANGED_RANGE := 7.0
const MEAGAN_RANGED_DAMAGE := 6.0
const MEAGAN_RANGED_EVERY := 0.75
## From the start of the throw to the snowball leaving her hand, and how fast it flies (m/s).
const MEAGAN_RANGED_RELEASE := 0.18
const SNOWBALL_SPEED := 18.0
const MEAGAN_RANGED_KNOCK := 0.1
## With a wolf this close she stops gathering, building and storing, and goes back to them this
## long after the last one has gone.
const FIGHT_PAUSE_RANGE := 7.0
const FIGHT_RESUME := 1.0

# ---------- Resource nodes ----------

## Stock per node and seconds to regrow from empty. [brief]
const NODES := {
	"forest": {"resource": "wood", "stock": 60.0, "regrow": 180.0},
	"hunting": {"resource": "food", "stock": 40.0, "regrow": 180.0},
	"scrap": {"resource": "materials", "stock": 15.0, "regrow": 240.0},
}

# ---------- Jobs ----------

## Rate per Jan = base × growth^(building level − 1). [brief]
const JOBS := {
	"chop": {"name": "Chopping", "building": "lumber_yard", "resource": "wood", "base": 1.0, "growth": 1.15},
	# Fishing was 0.6 Food/s a Jan: one fisher fed 36 Jans, so raids could never starve the town.
	# ChatGPT's steer (fight_v2): 0.05, about three Jans fed per fisher. [proto, 2026-10-20]
	"hunt": {"name": "Fishing", "building": "hunting_lodge", "resource": "food", "base": 0.05, "growth": 1.15},
	"build": {"name": "Building", "building": "workshop", "resource": "materials", "base": 0.1, "growth": 1.2},
	"guard": {"name": "Guarding", "building": "barracks", "resource": "", "base": 0.0, "growth": 1.15},
}

# ---------- Buildings ----------

## cost(n) = cost × growth^n, n = levels bought so far (level − start). unlock = Furnace level needed. [brief]
## start is the level a new winter begins at; 0 means it has to be built on a plot first.
## The Sled Shed is out of the game for now (2026-10-20).
const BUILDINGS := {
	"furnace": {"name": "Furnace", "max": 10, "unlock": 1, "start": 1, "cost": {"wood": 100.0, "materials": 20.0}, "growth": 1.8},
	"lumber_yard": {"name": "Lumber Yard", "max": 25, "unlock": 1, "start": 1, "cost": {"wood": 15.0}, "growth": 1.12},
	"hunting_lodge": {"name": "Fishing Lodge", "max": 25, "unlock": 1, "start": 1, "cost": {"wood": 15.0}, "growth": 1.12},
	"storehouse": {"name": "Storehouse", "max": 15, "unlock": 1, "start": 0, "cost": {"wood": 40.0, "materials": 5.0}, "growth": 1.15},
	"kitchen": {"name": "Kitchen", "max": 10, "unlock": 2, "start": 0, "cost": {"wood": 40.0, "materials": 5.0}, "growth": 1.15},
	"workshop": {"name": "Workshop", "max": 20, "unlock": 2, "start": 0, "cost": {"wood": 60.0, "materials": 10.0}, "growth": 1.15},
	"barracks": {"name": "Barracks", "max": 20, "unlock": 2, "start": 0, "cost": {"wood": 60.0, "materials": 10.0}, "growth": 1.15},
	"bunkhouse": {"name": "Bunkhouse", "max": 10, "unlock": 3, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
	"watchtower": {"name": "Watchtower", "max": 10, "unlock": 4, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
	"hot_springs": {"name": "Hot Springs", "max": 5, "unlock": 7, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
	# Meagan's weapons and the guards' kit (agreed 2026-10-20): ARMORY_LEVELS. [proto]
	"armory": {"name": "Armory", "max": 10, "unlock": 1, "start": 0, "cost": {"wood": 40.0, "materials": 12.0}, "growth": 1.27},
	# Not a plot: the stockpiles share this level (agreed 2026-10-20). [proto]
	"stockpile": {"name": "Stockpile", "max": 10, "unlock": 1, "start": 1, "cost": {"wood": 60.0, "materials": 10.0}, "growth": 1.5},
}
## The Furnace's first upgrade is Wood only, before Materials exist. [brief]
const FURNACE_FIRST_UPGRADE_COST := {"wood": 100.0}

# ---------- Blizzards ----------

const BLIZZARD_FIRST_AT := 15.0 * 60.0  # [brief]
const BLIZZARD_GAP_MIN := 20.0 * 60.0  # [brief]
const BLIZZARD_GAP_MAX := 40.0 * 60.0  # [brief]
const BLIZZARD_WARNING := 3.0 * 60.0  # [brief]
## Each Watchtower level warns of blizzards a minute sooner. [brief]
const WATCHTOWER_BLIZZARD_WARNING_PER_LEVEL := 60.0
const BLIZZARD_DURATION := 2.0 * 60.0  # [brief]
const BLIZZARD_DRAIN_MULT := 3.0  # [brief]
## Each Hot Springs level cuts the heat drain by this share (additive, so Lv 5 halves it).
## [brief] + [f1] hotSpringsReductionPerLevel
const HOT_SPRINGS_DRAIN_CUT_PER_LEVEL := 0.1
## The dev panel's "force blizzard" starts one this soon. [proto]
const BLIZZARD_FORCED_DELAY := 10.0

# ---------- Wolves and guards ----------

## Attacks start at this Furnace level and come every 8 to 15 minutes. [brief]
const ATTACK_MIN_FURNACE_LEVEL := 2
## Only a Watchtower warns of attacks: this many seconds ahead per level. [brief]
const WATCHTOWER_ATTACK_WARNING_PER_LEVEL := 15.0
## Every wave is announced this long ahead, Watchtower or not (ChatGPT's steer, fight_v2). [proto]
const WAVE_WARNING := 15.0
const ATTACK_GAP_MIN := 8.0 * 60.0
const ATTACK_GAP_MAX := 15.0 * 60.0
const WOLF_PACK_MIN := 2  # [brief]
const WOLF_PACK_MAX := 4  # [brief]
const WOLF_HP := 20.0  # [brief]
const WOLF_DAMAGE_PER_SECOND := 2.0  # [brief]
const WOLF_LOOT := {"food": 15.0, "materials": 3.0}  # [brief]
## HP, damage and loot × this per Furnace level above 2. [brief]
const WOLF_SCALE_PER_FURNACE_LEVEL := 1.6
## About 10 s from the map edge to the furnace. [brief]
const WOLF_SPEED := 4.0
## Enemy speeds in ENEMIES are the steer's; this scales them all (1 = as given). [proto]
const SPEED_SCALE := 1.0
## A wolf this close to working Jans detours to them; after WOLF_SCARE_TIME beside them one flees for good. [brief] + [proto] distances
const WOLF_DETOUR_RANGE := 7.0
const WOLF_REACH := 2.0
const WOLF_SCARE_TIME := 3.0
## A wolf stops to fight a guard or Meagan within this range. [proto]
const WOLF_ENGAGE_RANGE := 5.0
## Fighting wolves close in to this far from their foe, and wolves keep this far from each
## other, so a pack spreads round its target instead of piling up. About a wolf's length. [proto]
const WOLF_FIGHT_DISTANCE := 1.3
const WOLF_SPACING := 1.3
## A wolf bites (agreed 2026-10-20, from Astra's steer, [proto]): it starts within BITE_START of
## its victim, crouches (the telegraph), lunges, and the bite lands only if the victim is still
## within BITE_REACH; then it recovers and waits. Damage per bite keeps its damage per second.
## At most WOLF_MAX_WINDUPS wolves wind up at once, their starts at least WOLF_WINDUP_GAP apart.
const WOLF_BITE_START := 1.6
const WOLF_BITE_REACH := 1.9
const WOLF_BITE_WINDUP := 0.4
const WOLF_BITE_LUNGE := 0.12
const WOLF_BITE_LUNGE_DISTANCE := 0.6
const WOLF_BITE_RECOVER := 0.28
const WOLF_BITE_EVERY := 1.5
const WOLF_MAX_WINDUPS := 2
const WOLF_WINDUP_GAP := 0.25
## A wolf reaching the furnace takes these fractions, scares off this many Jans, then leaves. [brief]
const BREAKTHROUGH_WOOD := 0.15
const BREAKTHROUGH_FOOD := 0.15
const BREAKTHROUGH_HEAT := 0.2
const BREAKTHROUGH_JANS := 1
const FURNACE_REACH := 2.5  # [proto]
## Guards. [brief] 30 HP, 3 damage/s, half damage without a kit (kits aren't in the prototype).
const GUARD_HP := 30.0
const GUARD_DAMAGE_PER_SECOND := 3.0
const GUARD_NO_KIT_MULT := 0.5
## Barracks level adds this to guard strength, compounding. [brief] +15% per level
const GUARD_GROWTH := 1.15
const GUARD_SPEED := 4.0  # [proto]
const GUARD_RANGE := 1.6  # [proto]
## Guards wait in a ring this far from the furnace. [proto]
const GUARD_RING_RADIUS := 4.0
## Guards strike once every this many seconds at the nearest wolf they can see, and don't chase
## further than the leash from their post. [proto, Astra's steer]
const GUARD_STRIKE_EVERY := 1.0
const GUARD_SIGHT := 6.0
const GUARD_LEASH := 8.0

# ---------- The world: tiles and small furnaces (agreed 2026-10-20) ----------

## Every small furnace (one per opened tile) adds this to the heat drain. [proto]
const STOVE_DRAIN := 0.15
## Opening a tile costs Wood 40 × 1.6^(d − 1), plus Materials 10 × 1.6^(d − 2) from d = 2, where d is
## how many rings of tiles out from the starting grid it is (1 = touching it). [proto]
const GATE_WOOD := 40.0
const GATE_MATERIALS := 10.0
const GATE_GROWTH := 1.6
## The gate's pad sits this far inside the open tile, in front of the border. [proto]
const GATE_PAD_INSET := 1.8
## A small furnace's pad sits this far into its tile; the furnace's upgrade can be paid there.
## [proto, agreed 2026-10-20]
const STOVE_PAD_INSET := 2.4
## Each opened tile's small stockpile stands one of these far into the tile from its small
## furnace and one of these far to a side, whichever leaves the most room. [proto, agreed 2026-10-20]
const STOCKPILE_STOVE_INSETS := [3.0, 2.6, 3.8]
const STOCKPILE_STOVE_SIDES := [2.6, 4.0, 5.5]
## The frontier (agreed 2026-10-20): along every edge between open and closed ground, a single
## frozen Jan can wait this far inside it and this far to one side of its gate, and wolves come in
## on the border this far to the other side. [proto]
const ARRIVAL_INSET := 3.0
const ARRIVAL_SIDE := 5.0
const WOLF_SPAWN_SIDE := 5.0
## A camp's frozen Jans stand this far apart round its middle. [proto]
const CAMP_SPREAD := 1.2
## A small furnace's warm patch at full heat, in metres. [proto]
const STOVE_WARM_RADIUS := 3.5

## What a generated tile holds. [proto]
const TILE_NODES_MIN := 1
const TILE_NODES_MAX := 2
const TILE_PRODUCERS_MAX := 2
## Resource spot kinds in generated tiles, by weight.
const TILE_NODE_WEIGHTS := {"forest": 0.45, "hunting": 0.3, "scrap": 0.25}
## The producer that works each kind of resource spot.
const PRODUCER_FOR := {"forest": "lumber_yard", "hunting": "hunting_lodge", "scrap": "workshop"}
const TILE_CAMP_CHANCE := 0.35
const TILE_CAMP_JANS_MIN := 1
const TILE_CAMP_JANS_MAX := 3
const TILE_CHEST_CHANCE := 0.3
## Chest kinds by weight, and each kind's rarities by weight: boon chests are rare (a choice of 2)
## or epic (a choice of 3).
const CHEST_KINDS := {"cache": 0.5, "boon": 0.3, "gear": 0.2}
const CHEST_RARITIES := {
	"cache": {"common": 1.0},
	"boon": {"rare": 0.7, "epic": 0.3},
	"gear": {"common": 0.55, "rare": 0.33, "epic": 0.12},
}
const TILE_DEN_CHANCE := 0.2
## Wolf dens only this many rings out or further.
const TILE_DEN_MIN_RING := 3

# ---------- Treasures (agreed 2026-10-20) ----------

## She opens a chest by walking this close. [proto]
const CHEST_RANGE := 1.5
## Boon chests offer this many run-long boons to choose from, by rarity.
const BOON_CHOICES := {"rare": 2, "epic": 3}
## Run-long boons: each adds its value to one modifier, and taking one twice adds up. [proto]
const BOONS := {
	"quick_builds": {"name": "Quick builds", "text": "Building takes resources 50% faster", "mod": "pay_mult", "value": 0.5},
	"fast_feet": {"name": "Fast feet", "text": "Meagan walks 15% faster", "mod": "walk_mult", "value": 0.15},
	"quick_hands": {"name": "Quick hands", "text": "Meagan gathers 20% faster", "mod": "gather_mult", "value": 0.2},
	"slow_burn": {"name": "Slow burn", "text": "Heat drains 10% slower", "mod": "drain_cut", "value": 0.1},
	"eager_jans": {"name": "Eager Jans", "text": "Jans work 15% faster", "mod": "work_mult", "value": 0.15},
	"roomy_huts": {"name": "Roomy huts", "text": "Every producer holds 1 more Jan", "mod": "producer_slots", "value": 1.0},
	"deep_stores": {"name": "Deep stores", "text": "The Stockpile holds 25% more", "mod": "cap_mult", "value": 0.25},
	"lucky_finds": {"name": "Lucky finds", "text": "Caches hold 50% more", "mod": "cache_mult", "value": 0.5},
}
## The most of the heat drain boons can take off.
const DRAIN_CUT_MAX := 0.5
## Resource caches: one resource by weight, base amount × (1 + 0.5 × (ring − 1)), into the
## Stockpile up to its cap. [proto]
const CACHE_AMOUNTS := {"wood": 40.0, "food": 30.0, "materials": 10.0}
const CACHE_WEIGHTS := {"wood": 0.5, "food": 0.3, "materials": 0.2}
const CACHE_RING_GROWTH := 0.5
## Meagan's gear: three slots, each raising one modifier by its tier. A gear chest's rarity is
## the item's tier. [proto]
const GEAR := {
	"axe": {"name": "Axe", "text": "gathering", "mod": "gather_mult", "tiers": {"common": 0.15, "rare": 0.3, "epic": 0.5}},
	"boots": {"name": "Boots", "text": "walking", "mod": "walk_mult", "tiers": {"common": 0.1, "rare": 0.2, "epic": 0.3}},
	"sled": {"name": "Sled", "text": "gathering", "mod": "gather_mult", "tiers": {"common": 0.1, "rare": 0.2, "epic": 0.3}},
}

# ---------- Enemies, waves, the Armory and outposts (agreed 2026-10-20) ----------
# The user asked for an Armory, escalating waves, new enemies and outposts on the map, with
# raids that drain the store; the numbers are ChatGPT's steer (source_art/direction/fight_v2/
# steer.md), all [proto].

## Every enemy kind. `shape` is how it attacks: "wedge" (a bite or swipe in an arc in front),
## "ring" (a slam all round it) or "shot" (a thrown shard). `hold` is how far from its target it
## stands (centre to centre), `reach` how far its attack lands (for a shot, how close to where it
## was aimed). `tell` is the wind-up before it lands, `cooldown` from one hit to the next wind-up.
## `recover` is how long it holds its strike pose afterwards, the opening to step in (fight_v2
## review 1: wind-ups 0.65-1.2 s, heavy hitters show a long recovery). `steal` is how much it
## carries off from the store; `loot` its Materials when killed; `cost` its share of a wave's
## budget; `first` the first wave it can come in; `knocked` how much of a knockback it takes;
## `weight` how much of the wind-up limit it uses; `width` its body's width in metres (0.8 / 1 /
## 1.5 / 1.8 of a wolf's, review 1), which spaces a pack. HP is about 35-45% over the steer's,
## because the longer wind-ups made every raid easier (tests/sim_waves.gd).
const ENEMIES := {
	"fox": {"name": "Frost fox", "hp": 14.0, "speed": 3.6, "shape": "wedge", "hold": 1.0, "reach": 1.5, "arc": 45.0,
		"tell": 0.65, "recover": 0.28, "damage": 2.0, "cooldown": 1.4, "steal": 5.0, "loot": 1.0, "cost": 1, "first": 3, "knocked": 1.0, "weight": 1, "width": 0.56},
	"wolf": {"name": "Wolf", "hp": 29.0, "speed": 2.5, "shape": "wedge", "hold": 1.3, "reach": 1.9, "arc": 60.0,
		"tell": 0.65, "recover": 0.28, "damage": 3.0, "cooldown": 1.5, "steal": 8.0, "loot": 1.0, "cost": 2, "first": 1, "knocked": 1.0, "weight": 1, "width": 0.7},
	"bear": {"name": "Bear", "hp": 135.0, "speed": 1.4, "shape": "wedge", "hold": 1.8, "reach": 2.8, "arc": 110.0,
		"tell": 0.9, "lock": 0.45, "recover": 0.45, "damage": 10.0, "cooldown": 2.6, "steal": 20.0, "loot": 5.0, "cost": 8, "first": 5, "knocked": 0.25, "weight": 1, "width": 1.05},
	"raider": {"name": "Raider", "hp": 43.0, "speed": 2.1, "shape": "shot", "hold": 5.0, "reach": 0.7, "arc": 0.0,
		"tell": 1.0, "recover": 0.3, "damage": 4.0, "cooldown": 2.0, "steal": 15.0, "loot": 3.0, "cost": 4, "first": 4, "knocked": 1.0, "weight": 0, "width": 0.6},
	"troll": {"name": "Ice troll", "hp": 320.0, "speed": 1.1, "shape": "ring", "hold": 2.0, "reach": 3.0, "arc": 360.0,
		"tell": 1.2, "lock": 0.55, "recover": 0.7, "damage": 16.0, "cooldown": 4.5, "steal": 40.0, "loot": 15.0, "cost": 20, "first": 6, "knocked": 0.0, "weight": 2, "width": 1.26},
}
## A wedge attack's short lunge before it lands.
const ENEMY_LUNGE := 0.12
## A wind-up's aim follows its victim until this long before the strike, then locks, so the end
## of the tell shows exactly where it lands (fight_v2 review 1; 0.4 s from review 2). A kind's
## own `lock` overrides it (review 3: bear 0.45 s, troll 0.55 s, more ground to clear).
const ENEMY_AIM_LOCK := 0.4
## Around one defender at most this many melee enemies strike; the rest wait a body length
## (ENEMY_WAIT_BACK widths) farther out, and give up as usual (review 3: spacing round Meagan).
const ENEMY_MAX_ENGAGED := 2
const ENEMY_WAIT_BACK := 1.8
## The strikers round one defender keep this many degrees apart (review 5: 100-120 when there's
## room; at least 70), and out of the arc this wide straight towards the camera (south), where
## they'd be drawn over her (fight_v2 review 4). Waiting enemies keep WAIT_SEPARATION off the
## strikers' lines, so they never stand behind one.
const SLOT_SEPARATION := 110.0
const SLOT_CLEAR_SOUTH := 40.0
const WAIT_SEPARATION := 45.0
## Only one melee wind-up at a time against one defender, the next starting at least this long
## after the last one struck (review 3: one committed danger shape at her feet). [proto]
const ENEMY_WINDUP_STAGGER := 0.3
## Hits on an enemy still recovering from its own strike do this much more damage: the opening a
## dodge earns (review 3: make recovery windows usable). [proto]
const RECOVERY_DAMAGE_MULT := 1.5
## Bodies in a pack keep this much of a body width apart (review 1: about 0.7; review 2: 0.9).
const ENEMY_GAP := 0.9
## A thrown shard's speed, and how long before release its aim locks.
const ENEMY_SHOT_SPEED := 6.0
## Enemies head for the store; they fight the nearest defender within this distance, but give up
## on one after this long without landing a hit (so she can't lead every raid round in circles),
## ignoring defenders for a while.
const ENEMY_ENGAGE := 4.0
const ENEMY_GIVE_UP := 3.0
const ENEMY_IGNORE := 4.0
## At most this much melee wind-up at once (a troll counts double), plus one thrower.
const ENEMY_MAX_MELEE_WINDUP := 2
const ENEMY_MAX_SHOT_WINDUP := 1

## Waves: the first after 4 minutes of play, then every max(75, 150 × 0.94^(n−1)) s. A wave's
## budget is round(10 × 1.2^(n−1) × 1.15^floor((n−1)/5)), spent up to 96; beyond that its
## enemies get tougher instead (HP × the overflow, damage × its square root).
const WAVE_FIRST := 240.0
const WAVE_GAP := 150.0
const WAVE_GAP_SHRINK := 0.94
const WAVE_GAP_MIN := 75.0
const WAVE_BUDGET := 10.0
const WAVE_GROWTH := 1.2
const WAVE_STEP := 1.15
const WAVE_STEP_EVERY := 5
const WAVE_SPEND_MAX := 96.0
## Kinds drawn by weight once a wave's guaranteed members are paid; a troll every few waves.
const WAVE_WEIGHTS := {"wolf": 0.4, "fox": 0.3, "raider": 0.2, "bear": 0.1}
const WAVE_GUARANTEED := {3: {"fox": 4}, 4: {"raider": 2}, 5: {"bear": 1}}
const WAVE_TROLL_EVERY := 6
const WAVE_MAX := {"bear": 3, "raider": 6}
const WAVE_FOX_SHARE := 0.4
## Enemies come in groups this big, this far apart, with at most this many on the map; from
## wave 5 they come from two directions.
const WAVE_GROUP := 6
const WAVE_GROUP_GAP := 6.0
const WAVE_MAX_ALIVE := 24
const WAVE_TWO_SIDES_FROM := 5

## Raids drain the store (the user's rule, 2026-10-20): an enemy that reaches the furnace or a
## stockpile spends a moment stealing (a hit interrupts it), takes Food first, then Wood, then
## Materials, up to what it carries, and runs off a little slower. Killing it gives it all back.
const STEAL_REACH := 1.5
const STEAL_TIME := 2.0
const STEAL_RETRY := 1.0
const CARRY_SPEED := 0.8
## A thief that reaches the edge with its loot waits there while Meagan is down and this long
## after she's up, so it can still be caught (fight_v2 review 3). [proto]
const CATCH_GRACE := 3.0
## Thieves leave the pantry's bottom shelf: never the last this much Food per Jan (about three
## minutes of eating), so one theft can't start a starvation spiral while the fishers' loads are
## on their way (fight_v2 review 1: a recoverable first breach). [proto]
const STEAL_FOOD_FLOOR_PER_JAN := 3.0
## With no Food, after a grace the Jans start leaving, one every so often, idle ones first; it
## stops once Food has stayed up a while.
const STARVE_GRACE := 30.0
const STARVE_LEAVE_EVERY := 20.0
const STARVE_FED := 10.0
const STARVE_FED_FOR := 20.0

## The Armory (agreed 2026-10-20): each level, Meagan's snowball (range, damage, interval), her
## stick (reach, damage, interval, knockback) and the guards' kit (damage per strike, HP). Level 1
## is where she starts. The stick sweeps 100° and hits up to 3.
const ARMORY_LEVELS := [
	{"snow": [7.0, 6.0, 0.75], "stick": [2.5, 10.0, 0.8, 0.35], "guard": [3.0, 30.0]},
	{"snow": [7.2, 7.0, 0.73], "stick": [2.5, 12.0, 0.78, 0.4], "guard": [4.0, 35.0]},
	{"snow": [7.4, 9.0, 0.71], "stick": [2.6, 14.0, 0.76, 0.45], "guard": [5.0, 41.0]},
	{"snow": [7.6, 11.0, 0.69], "stick": [2.6, 17.0, 0.73, 0.5], "guard": [6.0, 48.0]},
	{"snow": [7.8, 13.0, 0.67], "stick": [2.7, 20.0, 0.7, 0.55], "guard": [7.0, 56.0]},
	{"snow": [8.0, 16.0, 0.65], "stick": [2.7, 24.0, 0.67, 0.6], "guard": [8.0, 65.0]},
	{"snow": [8.2, 19.0, 0.63], "stick": [2.8, 28.0, 0.64, 0.65], "guard": [10.0, 75.0]},
	{"snow": [8.4, 23.0, 0.61], "stick": [2.8, 33.0, 0.61, 0.7], "guard": [12.0, 86.0]},
	{"snow": [8.6, 27.0, 0.59], "stick": [2.9, 39.0, 0.58, 0.75], "guard": [14.0, 98.0]},
	{"snow": [8.8, 32.0, 0.57], "stick": [3.0, 46.0, 0.55, 0.8], "guard": [16.0, 112.0]},
]
const STICK_ARC := 100.0
const STICK_TARGETS := 3
## She goes back to snowballs once nothing has been within this much of her stick's reach for
## MEAGAN_MELEE_EXIT_TIME (fight_v2 review 1: in at 1.0x, out beyond 1.25x).
const MELEE_EXIT_MULT := 1.25

## Outposts (agreed 2026-10-20): a chance per opened tile by ring, a kind by weight, its
## defenders asleep until she comes within the alert radius (or hits one), leashed to it, and
## its reward (Materials, or a chest of spoils), all × P = min(2, 1 + 0.15 × (ring − 2)).
const OUTPOST_CHANCE := {2: 0.12, 3: 0.12, 4: 0.18, 5: 0.18}
const OUTPOST_CHANCE_FAR := 0.24
const OUTPOST_KINDS := {"fox_den": 0.35, "wolf_hollow": 0.3, "raider_camp": 0.25, "bear_cave": 0.1}
const OUTPOSTS := {
	"fox_den": {"name": "Fox den", "defenders": {"fox": 6}, "pay": {"materials": 10.0}, "chest": false},
	"wolf_hollow": {"name": "Wolf hollow", "defenders": {"wolf": 4}, "pay": {"materials": 12.0}, "chest": false},
	"raider_camp": {"name": "Raider camp", "defenders": {"raider": 3, "wolf": 2}, "pay": {"materials": 18.0, "wood": 20.0}, "chest": true},
	"bear_cave": {"name": "Bear cave", "defenders": {"bear": 1, "wolf": 2}, "pay": {"materials": 20.0, "food": 15.0}, "chest": true},
}
const OUTPOST_ALERT := 5.0
const OUTPOST_LEASH := 10.0
const OUTPOST_MAX_OPEN := 3
const OUTPOST_ROOM := 2.6
## Woken, an outpost's defenders take this long to get up before they fight (review 1).
const OUTPOST_WAKE := 0.8
