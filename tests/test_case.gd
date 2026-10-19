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


func site_pos(i: int) -> Vector2:
	return MapData.SITES[i].pos


func node_index(kind: String) -> int:
	for i in MapData.RESOURCE_NODES.size():
		if MapData.RESOURCE_NODES[i].kind == kind:
			return i
	return -1


## Adds a working Jan directly, for setting up tests.
func add_jan(e: GameEngine, job: String) -> Dictionary:
	var jan := {"id": e.state.new_id(), "job": job, "hp": Balance.GUARD_HP, "ko": false, "pos": Vector2.ZERO}
	e.state.jans.append(jan)
	return jan


## Builds `building` on the first free plot at `level`, for setting up tests.
func give_building(e: GameEngine, building: String, level := 1) -> int:
	var i := MapData.site_of_building(e.state.sites, building)
	if i < 0:
		for j in e.state.sites.size():
			if e.state.sites[j].building == "":
				i = j
				break
	e.state.sites[i].building = building
	e.state.sites[i].level = level
	e.state.sites[i].upgrading = false
	return i
