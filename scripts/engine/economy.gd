class_name Economy
extends RefCounted
## Pure derived values: levels, caps, costs, drain and rates. Nothing here changes the state.

const PILE_KEYS := ["wood", "food", "materials"]


## Level of a building, 0 if it isn't built (or is still a first-time construction site).
static func level(s: GameState, building: String) -> int:
	for site in s.sites:
		if site.building == building:
			return site.level
	return 0


static func furnace_level(s: GameState) -> int:
	return s.sites[0].level


static func is_unlocked(s: GameState, building: String) -> bool:
	return furnace_level(s) >= Balance.BUILDINGS[building].unlock


## Building types that can still go on an empty plot (one of each kind).
static func buildable(s: GameState) -> Array:
	var out := []
	for b in Balance.BUILDINGS:
		var def: Dictionary = Balance.BUILDINGS[b]
		if def.start > 0:
			continue
		if MapData.site_of_building(s.sites, b) >= 0:
			continue
		out.append(b)
	return out


## What the next level costs: base × growth^n with n = levels bought so far. Whole units.
static func cost(building: String, current_level: int) -> Dictionary:
	var def: Dictionary = Balance.BUILDINGS[building]
	var n: int = current_level - int(def.start)
	var base: Dictionary = def.cost
	if building == "furnace" and n == 0:
		base = Balance.FURNACE_FIRST_UPGRADE_COST
	var out := {}
	for k in base:
		out[k] = ceilf(base[k] * pow(def.growth, n))
	return out


static func site_cost(s: GameState, index: int) -> Dictionary:
	var site: Dictionary = s.sites[index]
	return cost(site.building, site.level)


static func is_maxed(s: GameState, index: int) -> bool:
	var site: Dictionary = s.sites[index]
	return site.level >= Balance.BUILDINGS[site.building].max


static func heat_cap(s: GameState) -> float:
	return furnace_level(s) * Balance.HEAT_CAP_PER_FURNACE_LEVEL


static func fuel_cap(s: GameState) -> float:
	return furnace_level(s) * Balance.FUEL_CAP_PER_FURNACE_LEVEL


static func heat_per_wood(s: GameState) -> float:
	return Balance.HEAT_PER_WOOD * (1.0 + Balance.HEAT_PER_WOOD_BONUS_PER_LEVEL * (furnace_level(s) - 1))


static func bag_cap(s: GameState) -> float:
	return Balance.BAG_BASE + Balance.BAG_PER_SLED_SHED_LEVEL * level(s, "sled_shed")


static func bag_total(s: GameState) -> float:
	return s.bag.wood + s.bag.food + s.bag.materials


static func caps(s: GameState) -> Dictionary:
	var store := pow(Balance.STOREHOUSE_CAP_GROWTH, level(s, "storehouse"))
	var lumber := maxi(level(s, "lumber_yard") - 1, 0)
	return {
		"wood": (Balance.CAP_WOOD + Balance.WOOD_CAP_PER_LUMBER_LEVEL * lumber) * store,
		"food": Balance.CAP_FOOD * store,
		"materials": Balance.CAP_MATERIALS * store,
	}


static func jan_cap(s: GameState) -> int:
	return furnace_level(s) * Balance.JAN_CAP_PER_FURNACE_LEVEL + level(s, "bunkhouse") * Balance.JAN_CAP_PER_BUNKHOUSE_LEVEL


static func building_levels(s: GameState) -> int:
	var total := 0
	for i in range(1, s.sites.size()):
		total += s.sites[i].level
	return total


static func heat_drain(s: GameState) -> float:
	var drain := Balance.DRAIN_BASE + Balance.DRAIN_PER_JAN * s.jans.size() + Balance.DRAIN_PER_BUILDING_LEVEL * building_levels(s)
	if s.blizzard_active:
		drain *= Balance.BLIZZARD_DRAIN_MULT
	return drain * (1.0 - hot_springs_cut(s))


## The share of the heat drain the Hot Springs take off. [brief]
static func hot_springs_cut(s: GameState) -> float:
	return minf(level(s, "hot_springs") * Balance.HOT_SPRINGS_DRAIN_CUT_PER_LEVEL, 1.0)


## Seconds until the fire goes out at the current drain, or INF while there's fuel to burn.
static func seconds_until_cold(s: GameState) -> float:
	if s.fuel > 0.01:
		return INF
	return s.heat / maxf(heat_drain(s), 0.001)


static func is_cold(s: GameState) -> bool:
	return s.heat < Balance.COLD_THRESHOLD * heat_cap(s)


## Cold and hunger slow every job.
static func output_mult(s: GameState) -> float:
	var m := 1.0
	if is_cold(s):
		m *= Balance.COLD_OUTPUT_MULT
	if s.hungry:
		m *= Balance.HUNGRY_OUTPUT_MULT
	return m


static func job_count(s: GameState, job: String) -> int:
	var n := 0
	for jan in s.jans:
		if jan.job == job:
			n += 1
	return n


static func idle_count(s: GameState) -> int:
	return job_count(s, "")


## A job is open once its building stands.
static func job_open(s: GameState, job: String) -> bool:
	return level(s, Balance.JOBS[job].building) >= 1


## Output per second of a whole job.
static func job_rate(s: GameState, job: String) -> float:
	var def: Dictionary = Balance.JOBS[job]
	var lv := level(s, def.building)
	if lv < 1 or def.base <= 0.0:
		return 0.0
	return job_count(s, job) * def.base * pow(def.growth, lv - 1) * output_mult(s)


static func food_eaten_per_second(s: GameState) -> float:
	return s.jans.size() * food_per_jan_per_second(s)


## What one Jan eats a second, after the Kitchen's cut. [brief]
static func food_per_jan_per_second(s: GameState) -> float:
	var cut := minf(level(s, "kitchen") * Balance.KITCHEN_FOOD_CUT_PER_LEVEL, 1.0)
	return Balance.FOOD_PER_JAN_PER_SECOND * (1.0 - cut)


## Seconds until the next frozen Jan when the city is this full. [brief] 60 s empty, 180 s at the cap.
static func arrival_interval(s: GameState) -> float:
	var cap := jan_cap(s)
	var fill := 0.0 if cap <= 0 else clampf(float(s.jans.size()) / cap, 0.0, 1.0)
	return Balance.ARRIVAL_BASE_INTERVAL * (1.0 + Balance.ARRIVAL_FILL_SLOWDOWN * fill * fill)


## The job a newly thawed Jan takes. [brief] Lumber Yard first, then Fishing while eating
## outruns hunting, then the job furthest below its share.
static func neediest_job(s: GameState) -> String:
	if job_open(s, "chop") and job_count(s, "chop") == 0:
		return "chop"
	if job_open(s, "hunt") and job_rate(s, "hunt") < food_eaten_per_second(s) + Balance.FOOD_PER_JAN_PER_SECOND:
		return "hunt"
	var best := ""
	var best_ratio := INF
	for job in Balance.JOB_SHARES:
		if not job_open(s, job):
			continue
		var ratio: float = job_count(s, job) / Balance.JOB_SHARES[job]
		if ratio < best_ratio:
			best_ratio = ratio
			best = job
	return best



static func guard_damage(s: GameState) -> float:
	var lv := maxi(level(s, "barracks"), 1)
	return Balance.GUARD_DAMAGE_PER_SECOND * Balance.GUARD_NO_KIT_MULT * pow(Balance.GUARD_GROWTH, lv - 1)


## How long before a blizzard it's announced: 3 minutes, plus a minute per Watchtower level. [brief]
static func blizzard_warning(s: GameState) -> float:
	return Balance.BLIZZARD_WARNING + Balance.WATCHTOWER_BLIZZARD_WARNING_PER_LEVEL * level(s, "watchtower")


## How long before an attack it's announced: never without a Watchtower, 15 s per level. [brief]
static func attack_warning(s: GameState) -> float:
	return Balance.WATCHTOWER_ATTACK_WARNING_PER_LEVEL * level(s, "watchtower")


## Wolves get stronger with the Furnace. [brief] ×1.6 per level above 2.
static func wolf_scale(s: GameState) -> float:
	return pow(Balance.WOLF_SCALE_PER_FURNACE_LEVEL, maxi(furnace_level(s) - 2, 0))
