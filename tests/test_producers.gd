extends TestCase
## Producers (Lumber Yard, Fishing Lodge, Workshop) hold 3 Jans each, so growing means building
## more of them (agreed 2026-10-20).


func _jan(e: GameEngine) -> Dictionary:
	var jan := {"id": e.state.new_id(), "job": "", "site": -1, "hp": Balance.GUARD_HP, "ko": false, "pos": Vector2.ZERO}
	e.state.jans.append(jan)
	return jan


func test_a_producer_holds_three_jans() -> void:
	var e := engine()
	e.state.sites[0].level = 3  # room for 12 Jans in town
	for i in 3:
		check(JobRules.assign(e.state, _jan(e), "chop"), "Jan %d chops" % (i + 1))
	check_eq(Economy.site_jans(e.state, 1), 3, "the Lumber Yard is full")
	check(not Economy.job_has_room(e.state, "chop"), "no room left chopping")
	check(not JobRules.assign(e.state, _jan(e), "chop"), "a fourth can't chop")
	check(Economy.neediest_job(e.state) != "chop", "and isn't sent to chop")


## Levels are shared (agreed 2026-10-20): the new yard works at the same level as the first.
func test_a_second_lumber_yard_makes_room_and_adds_its_rate_at_the_shared_level() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	for i in 3:
		JobRules.assign(e.state, _jan(e), "chop")
	var second := give_building(e, "lumber_yard", 3, true)
	check(Economy.job_has_room(e.state, "chop"), "room again")
	var jan := _jan(e)
	check(JobRules.assign(e.state, jan, "chop"), "he chops")
	check_eq(jan.site, second, "at the new Lumber Yard")
	check_eq(e.state.sites[1].level, 3, "the first yard is at the shared level too")
	check_near(Economy.site_rate(e.state, 1), 3.0 * pow(1.15, 2), 0.0001, "3 Jans at Lv 3")
	check_near(Economy.site_rate(e.state, second), 1.0 * pow(1.15, 2), 0.0001, "1 Jan at Lv 3")
	check_near(Economy.job_rate(e.state, "chop"), 4.0 * pow(1.15, 2), 0.0001, "the job adds them up")


func test_jans_go_to_the_emptiest_producer() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	var second := give_building(e, "lumber_yard", 1, true)
	var a := _jan(e)
	var b := _jan(e)
	JobRules.assign(e.state, a, "chop")
	JobRules.assign(e.state, b, "chop")
	check(a.site != b.site, "one each")
	check([a.site, b.site].has(second), "the new one gets a Jan")


func test_moving_jans_in_and_out_of_one_producer() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	var second := give_building(e, "lumber_yard", 1, true)
	_jan(e)
	_jan(e)
	check(e.add_to_site(second), "an idle Jan to the second Lumber Yard")
	check(e.add_to_site(second), "and another")
	check_eq(Economy.site_jans(e.state, second), 2, "two there")
	check_eq(Economy.site_jans(e.state, 1), 0, "none at the first")
	check(e.remove_from_site(second), "one leaves")
	check_eq(Economy.site_jans(e.state, second), 1, "one left")
	check_eq(Economy.idle_count(e.state), 1, "he's idle")
	check(not e.add_to_site(0), "nobody works at the furnace")


func test_add_to_job_stops_when_every_producer_is_full() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	for i in 4:
		_jan(e)
	for i in 3:
		check(e.add_to_job("chop"), "chopper %d" % (i + 1))
	check(not e.add_to_job("chop"), "the Lumber Yard is full")
	check_eq(Economy.idle_count(e.state), 1, "the fourth stays idle")


func test_a_wolf_scares_jans_from_the_producer_it_reaches() -> void:
	var e := engine()
	e.state.sites[0].level = 3
	e.state.attack_at = -1.0
	var second := give_building(e, "lumber_yard", 1, true)
	var near := _jan(e)
	JobRules.assign(e.state, near, "chop")
	near.site = second
	var far := _jan(e)
	JobRules.assign(e.state, far, "chop")
	far.site = 1
	e.state.fuel = 1000.0
	e.spawn_wolves(1)
	e.state.wolves[0].pos = MapData.site_pos(e.state, second) + Vector2(0, -6)
	e.skip(6.0)
	check(not e.state.jans.has(near), "the Jan at the Lumber Yard it reached fled")
	check(e.state.jans.has(far), "the other one kept working")
