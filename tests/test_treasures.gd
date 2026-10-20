extends TestCase
## Chests (agreed 2026-10-20): resource caches, boon chests (a choice of 2 or 3) and gear.


func _chest(e: GameEngine, kind: String, rarity: String, tile := Vector2i(2, 0)) -> Dictionary:
	var chest := {"pos": Vector2(40, 0), "kind": kind, "rarity": rarity, "tile": tile, "opened": false}
	e.state.chests.append(chest)
	return chest


func _walk_onto(e: GameEngine, chest: Dictionary) -> void:
	e.state.fuel = 1000.0
	put_meagan(e, chest.pos)
	e.skip(0.1)


func test_a_cache_pays_into_the_stockpile() -> void:
	var e := engine()
	var chest := _chest(e, "cache", "common")
	put_meagan(e, chest.pos + Vector2(3, 0))
	e.skip(0.1)
	check(not chest.opened, "not yet: she isn't there")
	_walk_onto(e, chest)
	check(chest.opened, "opened")
	var events := e.drain_events()
	var cache: Array = events.filter(func(ev): return ev.type == "cache")
	check_eq(cache.size(), 1, "a cache event")
	var res: String = cache[0].resource
	check_near(cache[0].amount, Balance.CACHE_AMOUNTS[res], 0.01, "first ring: the base amount")
	check(e.state.piles[res] >= Balance.CACHE_AMOUNTS[res] - 1.0, "it's in the Stockpile")
	check(e.state.offer.is_empty(), "nothing to choose")


func test_caches_grow_further_out() -> void:
	var e := engine()
	var chest := _chest(e, "cache", "common", Vector2i(0, 4))
	_walk_onto(e, chest)
	var cache: Array = e.drain_events().filter(func(ev): return ev.type == "cache")
	var res: String = cache[0].resource
	check_near(cache[0].amount, floorf(minf(Balance.CACHE_AMOUNTS[res] * 2.0, Economy.caps(e.state)[res])), 0.01, "three rings out: twice as much")


func test_a_boon_chest_offers_a_choice_and_the_world_waits() -> void:
	var e := engine()
	var chest := _chest(e, "boon", "epic")
	_walk_onto(e, chest)
	check_eq(e.state.offer.kind, "boon", "a boon offer")
	var options: Array = e.state.offer.options
	check_eq(options.size(), 3, "epic: a choice of 3")
	var distinct := {}
	for id in options:
		distinct[id] = true
	check_eq(distinct.size(), 3, "all different")
	var time := e.state.time
	e.advance(5.0)
	check_eq(e.state.time, time, "the world waits while she chooses")
	check(not e.can_meagan_move(), "and she waits too")
	var id: String = options[0]
	check(e.choose_boon(0), "she takes one")
	check(e.state.offer.is_empty(), "the offer is closed")
	check(e.state.boons.has(id), "it's hers")
	e.advance(1.0)
	check(e.state.time > time, "the world goes on")


func test_a_rare_boon_chest_offers_two() -> void:
	var e := engine()
	_walk_onto(e, _chest(e, "boon", "rare"))
	check_eq(e.state.offer.options.size(), 2, "rare: a choice of 2")


func test_every_boon_does_what_it_says() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	var before := {
		"pay": Economy.pay_rate(e.state), "walk": Economy.walk_speed(e.state),
		"gather": Economy.gather_rate(e.state, "wood"), "drain": Economy.heat_drain(e.state),
		"work": Economy.output_mult(e.state), "slots": Economy.site_slots(e.state, 1),
		"caps": Economy.caps(e.state).wood,
	}
	for id in Balance.BOONS:
		var boon: Dictionary = Balance.BOONS[id]
		e.state.mods[boon.mod] = e.state.mods.get(boon.mod, 0.0) + boon.value
	check_near(Economy.pay_rate(e.state), before.pay * 1.5, 0.001, "quick builds")
	check_near(Economy.walk_speed(e.state), before.walk * 1.15, 0.001, "fast feet")
	check_near(Economy.gather_rate(e.state, "wood"), before.gather * 1.2, 0.001, "quick hands")
	check_near(Economy.heat_drain(e.state), before.drain * 0.9, 0.001, "slow burn")
	check_near(Economy.output_mult(e.state), before.work * 1.15, 0.001, "eager Jans")
	check_eq(Economy.site_slots(e.state, 1), before.slots + 1, "roomy huts")
	check_near(Economy.caps(e.state).wood, before.caps * 1.25, 0.001, "deep stores")
	check_near(Economy.mod(e.state, "cache_mult"), 0.5, 0.001, "lucky finds")


func test_boons_already_taken_come_last() -> void:
	var e := engine()
	for id in Balance.BOONS.keys().slice(0, Balance.BOONS.size() - 2):
		e.state.boons.append(id)
	var options := TreasureRules.boon_options(e.state, e.rng, 3)
	var fresh: Array = Balance.BOONS.keys().slice(Balance.BOONS.size() - 2)
	check(options.has(fresh[0]) and options.has(fresh[1]), "the two she hasn't got are offered")
	check_eq(options.size(), 3, "topped up with one she has")


func test_gear_is_equipped_or_left() -> void:
	var e := engine()
	_walk_onto(e, _chest(e, "gear", "rare"))
	check_eq(e.state.offer.kind, "gear", "a gear offer")
	var slot: String = e.state.offer.slot
	var key: String = Balance.GEAR[slot].mod
	var base := Economy.mod(e.state, key)
	check(e.choose_gear(true), "equipped")
	check_eq(e.state.gear[slot], "rare", "in its slot")
	check_near(Economy.mod(e.state, key), base + Balance.GEAR[slot].tiers.rare, 0.001, "it counts")
	var chest := _chest(e, "gear", "common")
	chest.pos = Vector2(45, 0)
	_walk_onto(e, chest)
	var slot2: String = e.state.offer.slot
	var tier_before: String = e.state.gear[slot2]
	check(e.choose_gear(false), "left it")
	check_eq(e.state.gear[slot2], tier_before, "kept what she had")


func test_treasure_survives_a_save() -> void:
	var e := engine()
	e.state.mods = {"pay_mult": 0.5}
	e.state.boons = ["quick_builds"]
	e.state.gear.boots = "epic"
	var loaded := GameEngine.from_json(e.to_json())
	check_near(Economy.pay_rate(loaded.state), Economy.pay_rate(e.state), 0.001, "boons kept")
	check_eq(loaded.state.gear.boots, "epic", "gear kept")
