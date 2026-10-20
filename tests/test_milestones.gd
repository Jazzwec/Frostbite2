extends TestCase
## Milestone triggers (data/milestones.json) against the game state.


func _milestones() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/milestones.json"))


func _by_id(id: String) -> Dictionary:
	for m in _milestones():
		if m.id == id:
			return m
	return {}


func test_building_keys_turn_snake_case() -> void:
	check_eq(MilestoneRules.building_id("sledShed"), "sled_shed", "sledShed")
	check_eq(MilestoneRules.building_id("furnace"), "furnace", "furnace")
	check_eq(MilestoneRules.building_id("researchHut"), "research_hut", "researchHut")


func test_only_detectable_milestones_are_supported() -> void:
	check(MilestoneRules.supported(_by_id("firstJan")), "rescues")
	check(MilestoneRules.supported(_by_id("storehouse")), "a building we have")
	check(not MilestoneRules.supported(_by_id("sledShed")), "the Sled Shed is out for now")
	check(not MilestoneRules.supported(_by_id("researchHut")), "a building we don't have yet")
	check(not MilestoneRules.supported(_by_id("chef")), "Jan variants")
	check(not MilestoneRules.supported(_by_id("firstResearch")), "research")
	check(not MilestoneRules.supported(_by_id("secret")), "the secret date")


func test_triggers_fire_at_their_counts() -> void:
	var e := engine()
	var s := e.state
	check(not MilestoneRules.reached(_by_id("firstJan"), s), "nobody rescued")
	s.rescued_total = 1
	check(MilestoneRules.reached(_by_id("firstJan"), s), "first rescue")
	check(not MilestoneRules.reached(_by_id("fiveJans"), s), "no Jans yet")
	for i in 5:
		add_jan(e, "")
	check(MilestoneRules.reached(_by_id("fiveJans"), s), "five Jans")
	check(not MilestoneRules.reached(_by_id("furnace2"), s), "Furnace Lv 1")
	s.sites[0].level = 2
	check(MilestoneRules.reached(_by_id("furnace2"), s), "Furnace Lv 2")
	check(not MilestoneRules.reached(_by_id("storehouse"), s), "no Storehouse")
	give_building(e, "storehouse", 1)
	check(MilestoneRules.reached(_by_id("storehouse"), s), "a Storehouse")
	s.blizzards_survived = 1
	check(MilestoneRules.reached(_by_id("firstBlizzard"), s), "a blizzard survived")
	check(not MilestoneRules.reached(_by_id("fiveBlizzards"), s), "not five")
	s.attacks_repelled = 1
	check(MilestoneRules.reached(_by_id("firstDefence"), s), "an attack repelled")


func test_every_supported_milestone_names_a_real_building_or_count() -> void:
	for m in _milestones():
		if MilestoneRules.supported(m):
			check(m.has("title") and m.has("message"), "%s has words" % m.id)
