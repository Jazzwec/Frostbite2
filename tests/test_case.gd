class_name TestCase
extends RefCounted
## Base for tests: record failures instead of stopping, so one run reports everything.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance := 0.01, message := "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s expected %.3f ± %.3f, got %.3f" % [message, expected, tolerance, actual])


## A fresh engine with a fixed seed.
func engine() -> GameEngine:
	return GameEngine.new(12345)


## Stands Meagan on a spot.
func put_meagan(e: GameEngine, pos: Vector2) -> void:
	e.set_meagan_position(pos)


## Where plot `i` of the starting grid stands.
func site_pos(i: int) -> Vector2:
	return MapData.START_SITES[i].pos


## The first starting-grid resource spot of `kind`.
func node_index(kind: String) -> int:
	for i in MapData.START_NODES.size():
		if MapData.START_NODES[i].kind == kind:
			return i
	return -1


## Adds a working Jan directly, for setting up tests, at the producer with the most room. With
## every producer of the job full, another one is built for him, as an opened tile would give.
func add_jan(e: GameEngine, job: String) -> Dictionary:
	var jan := {"id": e.state.new_id(), "job": job, "site": -1, "hp": Balance.GUARD_HP, "ko": false, "pos": Vector2.ZERO}
	if job != "" and job != "guard" and Economy.job_open(e.state, job) and not Economy.job_has_room(e.state, job):
		give_building(e, Balance.JOBS[job].building, Economy.level(e.state, Balance.JOBS[job].building), true)
	JobRules.assign(e.state, jan, job)
	e.state.jans.append(jan)
	return jan


## Builds `building` at `level` on its plot, for setting up tests. A building with no free plot
## (a producer, found only in opened tiles) gets a new plot well away from the town. Levels are
## shared (agreed 2026-10-20), so every built plot of it ends up at `level`.
func give_building(e: GameEngine, building: String, level := 1, new_plot := false) -> int:
	var i := -1 if new_plot else MapData.site_of_building(e.state.sites, building)
	if i < 0 and not new_plot:
		for j in e.state.sites.size():
			if e.state.sites[j].building == "" and e.state.sites[j].type == building:
				i = j
				break
	if i < 0:
		i = e.state.sites.size()
		e.state.sites.append({"type": building, "pos": Vector2(60 + 10 * i, 60), "building": "", "level": 0, "upgrading": false, "progress": {}})
	e.state.sites[i].building = building
	e.state.sites[i].upgrading = false
	for site in e.state.sites:
		if site.building == building:
			site.level = level
	return i
