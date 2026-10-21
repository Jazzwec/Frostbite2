extends TestCase
## The waves against the Armory (2026-10-20), from ChatGPT's tuning targets (steer fight_v2):
## an Armory left at level 1 with two guards suffers decisive breaches by waves 9-11, while one
## upgraded on schedule holds. WaveSim plays it out headless, with Meagan defending actively.


## The steer's target: decisive breaches in waves 9-11 at Armory 1. Here: every one of those
## raids gets something away, and at least one loses 30% of its raiders or more.
func test_an_unupgraded_armory_loses_the_store_by_wave_11() -> void:
	var rows := WaveSim.run("none", 11, 7, true)
	# Early waves cost little: a fox or two that waited its turn and went for the store.
	for row in rows.slice(0, 5):
		check(row.stolen < 15.0, "wave %d is held, even at Armory 1 (%d lost)" % [row.wave, row.stolen])
	var worst := 0.0
	for row in rows.slice(8, 11):
		check(row.thieves > 0, "wave %d breaks through (%d of %d)" % [row.wave, row.thieves, row.enemies])
		worst = maxf(worst, float(row.thieves) / row.enemies)
	check(worst >= 0.3, "decisively (worst %.0f%%)" % (worst * 100.0))


func test_an_armory_upgraded_on_schedule_holds() -> void:
	for row in WaveSim.run("schedule", 13, 7, true):
		check(float(row.thieves) / row.enemies <= 0.1, "wave %d held at Armory %d (%d of %d got through)" % [row.wave, row.armory, row.thieves, row.enemies])


## Review 1: missed upgrades, not just ideal buying. Three minutes behind the schedule, the
## Armory holds a good while (nothing lost: thefts get won back), then the late raids break
## through, but only partly: never more than half of one gets away (review 5: thefts that are
## caught don't count as losses).
func test_an_armory_three_minutes_behind_breaks_but_doesnt_collapse() -> void:
	var rows := WaveSim.run("late", 16, 7, true)
	for row in rows.slice(0, 10):
		check(row.stolen < 10.0, "wave %d held at Armory %d (%d lost)" % [row.wave, row.armory, row.stolen])
	var breached := false
	for row in rows:
		var ratio: float = float(row.thieves) / row.enemies
		breached = breached or row.stolen >= 50.0
		check(ratio <= 0.5, "wave %d: at most half get away (%.0f%%)" % [row.wave, ratio * 100.0])
	check(breached, "but being behind does cost something")
