extends TestCase
## The waves against the Armory (2026-10-20), from ChatGPT's tuning targets (steer fight_v2):
## an Armory left at level 1 with two guards suffers decisive breaches by waves 9-11, while one
## upgraded on schedule holds. WaveSim plays it out headless, with Meagan defending actively.


func test_an_unupgraded_armory_loses_the_store_by_wave_11() -> void:
	var rows := WaveSim.run("none", 11, 7, true)
	for row in rows.slice(0, 7):
		check_eq(row.thieves, 0, "wave %d is held, even at Armory 1" % row.wave)
	var worst := 0.0
	for row in rows:
		worst = maxf(worst, float(row.thieves) / row.enemies)
	check(worst >= 0.4, "by wave 11 most raiders get through (worst %.0f%%)" % (worst * 100.0))


func test_an_armory_upgraded_on_schedule_holds() -> void:
	for row in WaveSim.run("schedule", 13, 7, true):
		check(float(row.thieves) / row.enemies <= 0.1, "wave %d held at Armory %d (%d of %d got through)" % [row.wave, row.armory, row.thieves, row.enemies])
