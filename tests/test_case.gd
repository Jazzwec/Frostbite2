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


## Adds a working Jan directly, for setting up tests.
func add_jan(e: GameEngine, job: String) -> Dictionary:
	var jan := {"id": e.state.new_id(), "job": job, "hp": Balance.GUARD_HP, "ko": false, "pos": Vector2.ZERO}
	e.state.jans.append(jan)
	return jan


## Builds `building` at `level` on its plot, for setting up tests. A building with no free plot
## (a producer, found only in opened tiles) gets a new plot well away from the town.
func give_building(e: GameEngine, building: String, level := 1) -> int:
	var i := MapData.site_of_building(e.state.sites, building)
	if i < 0:
		for j in e.state.sites.size():
			if e.state.sites[j].building == "" and e.state.sites[j].type == building:
				i = j
				break
	if i < 0:
		i = e.state.sites.size()
		e.state.sites.append({"type": building, "pos": Vector2(60 + 10 * i, 60), "building": "", "level": 0, "upgrading": false, "progress": {}})
	e.state.sites[i].building = building
	e.state.sites[i].level = level
	e.state.sites[i].upgrading = false
	return i
