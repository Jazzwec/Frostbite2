extends TestCase
## Global levels (agreed 2026-10-20): every plot of a building shares its level, and an upgrade,
## paid on the pad of any of them (the furnace's on a small furnace's too), raises them all.


func _pay_at(e: GameEngine, pad: Vector2, seconds: float) -> void:
	put_meagan(e, pad)
	for k in int(seconds):
		e.state.fuel = 1000.0
		e.state.piles = {"wood": 300.0, "food": 150.0, "materials": 100.0}
		e.skip(1.0)


func test_an_upgrade_started_at_one_yard_and_paid_at_another_raises_both() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	var second := give_building(e, "lumber_yard", 1, true)
	check(e.start_upgrade(1), "upgrade started at the first yard")
	check(e.state.sites[second].upgrading, "the second yard shows it too")
	_pay_at(e, MapData.pad_pos(e.state, second), 10.0)
	check_eq(e.state.sites[1].level, 2, "the first yard went up")
	check_eq(e.state.sites[second].level, 2, "and the one she paid at")
	check(not e.state.upgrades.has("lumber_yard"), "the upgrade is done")
	check(not e.state.sites[1].upgrading and not e.state.sites[second].upgrading, "neither shows it any more")
	var levelled := e.drain_events().filter(func(ev): return ev.type == "levelled")
	check_eq(levelled.size(), 1, "one levelled event for the building")


func test_an_upgrade_cant_start_twice() -> void:
	var e := engine()
	var second := give_building(e, "lumber_yard", 1, true)
	check(e.start_upgrade(1), "started")
	check(not e.start_upgrade(second), "already under way, from the other yard too")
	check(not e.start_upgrade_of("lumber_yard"), "or by name")


func test_the_furnace_upgrade_can_be_paid_on_a_small_furnaces_pad() -> void:
	var e := engine()
	e.state.stoves.append({"tile": Vector2i(2, 0), "pos": Vector2(30, 0)})
	var pad := MapData.stove_pad(e.state, 0)
	check(pad.x > 30.0 and absf(pad.y) < 0.01, "the pad is a little way into the stove's tile")
	check(e.start_upgrade_of("furnace"), "furnace upgrade started")
	_pay_at(e, pad, 10.0)
	check_eq(Economy.furnace_level(e.state), 2, "paid at the small furnace, the furnace went up")


func test_a_yard_built_after_an_upgrade_starts_at_the_shared_level() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	give_building(e, "lumber_yard", 3)
	var i := e.state.sites.size()
	e.state.sites.append({"type": "lumber_yard", "pos": Vector2(70, 60), "building": "", "level": 0, "upgrading": false, "progress": {}})
	check(e.start_construction(i), "a new yard's construction")
	_pay_at(e, MapData.pad_pos(e.state, i), 10.0)
	check_eq(e.state.sites[i].level, 3, "built straight at the shared Lv 3")


func test_a_yard_finished_during_an_upgrade_joins_it() -> void:
	var e := engine()
	var i := e.state.sites.size()
	e.state.sites.append({"type": "lumber_yard", "pos": Vector2(70, 60), "building": "", "level": 0, "upgrading": false, "progress": {}})
	check(e.start_construction(i), "construction")
	check(e.start_upgrade(1), "the yards' upgrade")
	e.dev_level_up(i)
	check_eq(e.state.sites[i].level, 1, "built at Lv 1")
	check(e.state.sites[i].upgrading, "and shows the shared upgrade")
	e.dev_level_up(1)
	check_eq(e.state.sites[i].level, 2, "which raises it with the rest")


func test_an_upgrade_survives_a_save() -> void:
	var e := engine()
	check(e.start_upgrade(0), "started")
	e.state.upgrades.furnace["wood"] = 12.0
	var loaded := GameEngine.from_json(e.to_json())
	check_near(Economy.site_progress(loaded.state, 0).get("wood", 0.0), 12.0, 0.001, "its progress is kept")
	check(loaded.state.sites[0].upgrading, "and still under way")
