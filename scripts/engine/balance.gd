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
## Job shares used to place a new Jan once Chopping and Fishing are covered. [brief] 3 : 2 : 2
const JOB_SHARES := {"chop": 3.0, "hunt": 2.0, "build": 2.0}

# ---------- Meagan ----------

const MEAGAN_WALK_SPEED := 6.0  # [proto] brisk, hypercasual
## She gathers automatically while within this distance of a resource node. [proto]
const GATHER_RANGE := 3.0
## Hand-gathering per second by resource. [brief]
const GATHER_RATE := {"wood": 5.0, "food": 3.0, "materials": 1.0}
## Bag size: all resources together. [brief]
const BAG_BASE := 20.0
const BAG_PER_SLED_SHED_LEVEL := 10.0
## Resources move between her bag and a building she stands near. [f1] 20 units/s shared
const SITE_REACH := 4.5
const MAGNET_PER_SECOND := 20.0
## Construction and upgrades are paid only while she stands on the plot's pad. [proto]
const PAD_RADIUS := 1.4
## The furnace feeds itself from the Stockpile's Wood this fast, up to its fuel cap. [proto]
const FURNACE_FEED_PER_SECOND := 5.0
## She thaws a frozen Jan when this close. [proto]
const RESCUE_RANGE := 2.0
## Combat. [brief]
const MEAGAN_HP := 100.0
const MEAGAN_DAMAGE_PER_SECOND := 10.0
const MEAGAN_ATTACK_RANGE := 2.5  # [proto]

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
	"hunt": {"name": "Fishing", "building": "hunting_lodge", "resource": "food", "base": 0.6, "growth": 1.15},
	"build": {"name": "Building", "building": "workshop", "resource": "materials", "base": 0.1, "growth": 1.2},
	"guard": {"name": "Guarding", "building": "barracks", "resource": "", "base": 0.0, "growth": 1.15},
}

# ---------- Buildings ----------

## cost(n) = cost × growth^n, n = levels bought so far (level − start). unlock = Furnace level needed. [brief]
## start is the level a new winter begins at; 0 means it has to be built on a plot first.
const BUILDINGS := {
	"furnace": {"name": "Furnace", "max": 10, "unlock": 1, "start": 1, "cost": {"wood": 100.0, "materials": 20.0}, "growth": 1.8},
	"lumber_yard": {"name": "Lumber Yard", "max": 25, "unlock": 1, "start": 1, "cost": {"wood": 15.0}, "growth": 1.12},
	"hunting_lodge": {"name": "Fishing Lodge", "max": 25, "unlock": 1, "start": 1, "cost": {"wood": 15.0}, "growth": 1.12},
	"sled_shed": {"name": "Sled Shed", "max": 10, "unlock": 1, "start": 0, "cost": {"wood": 30.0}, "growth": 1.3},
	"storehouse": {"name": "Storehouse", "max": 15, "unlock": 1, "start": 0, "cost": {"wood": 40.0, "materials": 5.0}, "growth": 1.15},
	"kitchen": {"name": "Kitchen", "max": 10, "unlock": 2, "start": 0, "cost": {"wood": 40.0, "materials": 5.0}, "growth": 1.15},
	"workshop": {"name": "Workshop", "max": 20, "unlock": 2, "start": 0, "cost": {"wood": 60.0, "materials": 10.0}, "growth": 1.15},
	"barracks": {"name": "Barracks", "max": 20, "unlock": 2, "start": 0, "cost": {"wood": 60.0, "materials": 10.0}, "growth": 1.15},
	"bunkhouse": {"name": "Bunkhouse", "max": 10, "unlock": 3, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
	"watchtower": {"name": "Watchtower", "max": 10, "unlock": 4, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
	"hot_springs": {"name": "Hot Springs", "max": 5, "unlock": 7, "start": 0, "cost": {"wood": 120.0, "materials": 30.0}, "growth": 1.25},
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
## A wolf this close to working Jans detours to them; after WOLF_SCARE_TIME beside them one flees for good. [brief] + [proto] distances
const WOLF_DETOUR_RANGE := 7.0
const WOLF_REACH := 2.0
const WOLF_SCARE_TIME := 3.0
## A wolf stops to fight a guard or Meagan within this range. [proto]
const WOLF_ENGAGE_RANGE := 2.5
## Fighting wolves close in to this far from their foe, and wolves keep this far from each
## other, so a pack spreads round its target instead of piling up. About a wolf's length. [proto]
const WOLF_FIGHT_DISTANCE := 1.3
const WOLF_SPACING := 1.3
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
