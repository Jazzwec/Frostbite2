extends TestCase
## The waves against the Armory (2026-10-20), from ChatGPT's tuning targets (steer fight_v2):
## an Armory left at level 1 with two guards suffers decisive breaches by waves 9-11, while one
## upgraded on schedule holds. WaveSim plays it out headless, with Meagan defending actively.


## The steer's target: decisive breaches in waves 9-11 at Armory 1. Here: every one of those
## raids gets something away, and at least one loses 30% of its raiders or more.
func test_an_unupgraded_armory_loses_the_store_by_wave_11() -> void:
	var rows := WaveSim.run("none", 11, 7, true)
	for row in rows.slice(0, 5):
		check_eq(row.thieves, 0, "wave %d is held, even at Armory 1" % row.wave)
	var worst := 0.0
	for row in rows.slice(8, 11):
		check(row.thieves > 0, "wave %d breaks through (%d of %d)" % [row.wave, row.thieves, row.enemies])
		worst = maxf(worst, float(row.thieves) / row.enemies)
	check(worst >= 0.3, "decisively (worst %.0f%%)" % (worst * 100.0))


func test_an_armory_upgraded_on_schedule_holds() -> void:
	for row in WaveSim.run("schedule", 13, 7, true):
		check(float(row.thieves) / row.enemies <= 0.1, "wave %d held at Armory %d (%d of %d got through)" % [row.wave, row.armory, row.thieves, row.enemies])


## Review 1: missed upgrades, not just ideal buying. Three minutes behind the schedule, the
## Armory holds a good while, then breaks once, and catching up wins the next wave back.
func test_an_armory_three_minutes_behind_breaks_once_and_recovers() -> void:
	var rows := WaveSim.run("late", 16, 7, true)
	var worst := -1
	for i in rows.size():
		if worst < 0 or float(rows[i].thieves) / rows[i].enemies > float(rows[worst].thieves) / rows[worst].enemies:
			worst = i
	for row in rows.slice(0, 10):
		check(float(row.thieves) / row.enemies <= 0.1, "wave %d held at Armory %d" % [row.wave, row.armory])
	var ratio: float = float(rows[worst].thieves) / rows[worst].enemies
	check(ratio >= 0.2, "a real breach comes (wave %d, %.0f%%)" % [rows[worst].wave, ratio * 100.0])
	if worst + 1 < rows.size():
		var after: float = float(rows[worst + 1].thieves) / rows[worst + 1].enemies
		check(after <= ratio / 2.0, "and the next wave is mostly held again (%.0f%%)" % (after * 100.0))
