class_name Economy
extends RefCounted
## Pure derived values: levels, caps, costs, drain and rates. Nothing here changes the state.

const PILE_KEYS := ["wood", "food", "materials"]


## A run-long modifier: what boons and gear add to `key` this winter. [agreed 2026-10-20]
static func mod(s: GameState, key: String) -> float:
	var total: float = s.mods.get(key, 0.0)
	for slot in s.gear:
		if Balance.GEAR[slot].mod == key:
			total += TreasureRules.gear_value(slot, s.gear[slot])
	return total


## How fast Meagan walks, in m/s.
static func walk_speed(s: GameState) -> float:
	return Balance.MEAGAN_WALK_SPEED * (1.0 + mod(s, "walk_mult"))


## How fast she gathers `resource` by hand, per second.
static func gather_rate(s: GameState, resource: String) -> float:
	return Balance.GATHER_RATE[resource] * (1.0 + mod(s, "gather_mult"))


## Level of a building, shared by all its built plots (agreed 2026-10-20), 0 if none is built
## yet (a first-time construction site is level 0).
static func level(s: GameState, building: String) -> int:
	var best := 0
	for site in s.sites:
		if site.building == building:
			best = maxi(best, site.level)
	return best


static func furnace_level(s: GameState) -> int:
	return s.sites[0].level


static func is_unlocked(s: GameState, building: String) -> bool:
	return furnace_level(s) >= Balance.BUILDINGS[building].unlock


## What the next level costs: base × growth^n with n = levels bought so far. Whole units.
static func cost(building: String, current_level: int) -> Dictionary:
	var def: Dictionary = Balance.BUILDINGS[building]
	# A second producer (found in an opened tile) costs what the first one's next level does.
	var n: int = maxi(current_level - int(def.start), 0)
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


## What a plot has been paid so far: its own construction, or its building's shared upgrade.
static func site_progress(s: GameState, index: int) -> Dictionary:
	var site: Dictionary = s.sites[index]
	if site.level >= 1:
		return s.upgrades.get(site.building, {})
	return site.progress


## Where a building's upgrade can be paid: the pad of every built plot of it, and for the furnace
## every small furnace's pad too (agreed 2026-10-20). {pos, site} (site -1 for a small furnace).
static func upgrade_pads(s: GameState, building: String) -> Array:
	var out := []
	for i in s.sites.size():
		if s.sites[i].building == building and s.sites[i].level >= 1:
			out.append({"pos": MapData.pad_pos(s, i), "site": i})
	if building == "furnace":
		for k in s.stoves.size():
			out.append({"pos": MapData.stove_pad(s, k), "site": -1})
	return out


static func heat_cap(s: GameState) -> float:
	return furnace_level(s) * Balance.HEAT_CAP_PER_FURNACE_LEVEL


static func fuel_cap(s: GameState) -> float:
	return furnace_level(s) * Balance.FUEL_CAP_PER_FURNACE_LEVEL


static func heat_per_wood(s: GameState) -> float:
	return Balance.HEAT_PER_WOOD * (1.0 + Balance.HEAT_PER_WOOD_BONUS_PER_LEVEL * (furnace_level(s) - 1))


## How fast build pads and gates take what they need from the Stockpile, per second.
static func pay_rate(s: GameState) -> float:
	return Balance.PAD_PAY_PER_SECOND * (1.0 + mod(s, "pay_mult"))


static func caps(s: GameState) -> Dictionary:
	var store := pow(Balance.STOREHOUSE_CAP_GROWTH, level(s, "storehouse")) * (1.0 + mod(s, "cap_mult"))
	# Every Lumber Yard level above the first adds Wood room, across all the Lumber Yards.
	var lumber := 0
	for site in s.sites:
		if site.building == "lumber_yard":
			lumber += maxi(site.level - 1, 0)
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


## `extra_stoves` previews the drain after opening that many more tiles.
static func heat_drain(s: GameState, extra_stoves := 0) -> float:
	var drain := Balance.DRAIN_BASE + Balance.DRAIN_PER_JAN * s.jans.size() + Balance.DRAIN_PER_BUILDING_LEVEL * building_levels(s)
	# Every small furnace burns from the same heat. [agreed 2026-10-20]
	drain += Balance.STOVE_DRAIN * (s.stoves.size() + extra_stoves)
	if s.blizzard_active:
		drain *= Balance.BLIZZARD_DRAIN_MULT
	drain *= 1.0 - minf(mod(s, "drain_cut"), Balance.DRAIN_CUT_MAX)
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
	var m := 1.0 + mod(s, "work_mult")
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


## A job is open once one of its buildings stands.
static func job_open(s: GameState, job: String) -> bool:
	return not job_sites(s, job).is_empty()


## The built plots that work `job` (for guards, the Barracks).
static func job_sites(s: GameState, job: String) -> Array:
	var out := []
	var building: String = Balance.JOBS[job].building
	for i in s.sites.size():
		if s.sites[i].building == building and s.sites[i].level >= 1:
			out.append(i)
	return out


## The job a building's Jans do, or "" for a building nobody works at.
static func site_job(building: String) -> String:
	for job in Balance.JOBS:
		if Balance.JOBS[job].building == building:
			return job
	return ""


## Jans working at plot `i`.
static func site_jans(s: GameState, i: int) -> int:
	var n := 0
	for jan in s.jans:
		if jan.get("site", -1) == i:
			n += 1
	return n


## How many Jans a producer holds. [agreed 2026-10-20]
static func site_slots(s: GameState, _i: int) -> int:
	return Balance.PRODUCER_JAN_CAP + int(mod(s, "producer_slots"))


## The producer of `job` with room for one more Jan (the emptiest), or -1.
static func free_site(s: GameState, job: String) -> int:
	var best := -1
	var fewest := 1 << 30
	for i in job_sites(s, job):
		var n := site_jans(s, i)
		if n < site_slots(s, i) and n < fewest:
			fewest = n
			best = i
	return best


## Room for all of a job's Jans together.
static func job_slots(s: GameState, job: String) -> int:
	var n := 0
	for i in job_sites(s, job):
		n += site_slots(s, i)
	return n


## Whether one more Jan can take `job`: guards just need a Barracks; producers need a free place.
static func job_has_room(s: GameState, job: String) -> bool:
	if job == "guard":
		return job_open(s, job)
	return free_site(s, job) >= 0


## Output per second of one producer: its Jans × the job's rate at its own level.
static func site_rate(s: GameState, i: int) -> float:
	var site: Dictionary = s.sites[i]
	var job := site_job(site.building)
	if job == "" or site.level < 1:
		return 0.0
	var def: Dictionary = Balance.JOBS[job]
	if def.base <= 0.0:
		return 0.0
	return site_jans(s, i) * def.base * pow(def.growth, site.level - 1) * output_mult(s)


## Output per second of a whole job, across all its producers.
static func job_rate(s: GameState, job: String) -> float:
	var total := 0.0
	for i in job_sites(s, job):
		total += site_rate(s, i)
	return total


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
## Only jobs with a free place count (agreed 2026-10-20: producers hold 3 Jans each).
static func neediest_job(s: GameState) -> String:
	if job_has_room(s, "chop") and job_count(s, "chop") == 0:
		return "chop"
	if job_has_room(s, "hunt") and job_rate(s, "hunt") < food_eaten_per_second(s) + Balance.FOOD_PER_JAN_PER_SECOND:
		return "hunt"
	var best := ""
	var best_ratio := INF
	for job in Balance.JOB_SHARES:
		if not job_has_room(s, job):
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
