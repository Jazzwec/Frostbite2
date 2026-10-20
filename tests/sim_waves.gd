extends SceneTree
## A headless defence simulation for tuning the waves against the Armory (2026-10-20):
## `godot --headless --path . -s res://tests/sim_waves.gd`. Meagan stands by the furnace with
## two guards, the store is kept full, and each wave's thefts are counted, once with the Armory
## left at level 1 and once upgraded on ChatGPT's schedule (5 by 15:00, 7 by 22:00, 10 by 30:00).
## Not a test (the runner only takes test_*.gd); `test_balance.gd` checks the targets.


func _init() -> void:
	for setup in [["none", false], ["none", true], ["schedule", true]]:
		print("--- Armory: %s, %s ---" % [setup[0], "active" if setup[1] else "standing"])
		for row in WaveSim.run(setup[0], 16, 7, setup[1]):
			print("wave %2d at %5s  lv %2d  enemies %2d  thieves %2d  stolen %4d  Meagan down: %s" % [row.wave, row.clock, row.armory, row.enemies, row.thieves, row.stolen, row.injured])
	quit()
