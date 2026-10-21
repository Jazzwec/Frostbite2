extends SceneTree
## A headless defence simulation for tuning the waves against the Armory (2026-10-20):
## `godot --headless --path . -s res://tests/sim_waves.gd`. Meagan stands by the furnace with
## two guards, the store is kept full, and each wave's thefts are counted, for four Armory plans:
## left at level 1 (her standing still, then defending), three minutes behind ChatGPT's schedule,
## and on it (5 by 15:00, 7 by 22:00, 10 by 30:00). It prints Markdown: the waves, then
## time-to-kill per enemy kind at every Armory level. `docs/balance/fight_v2_sims.md` is its
## output with the reading. Not a test (the runner only takes test_*.gd); `test_balance.gd`
## checks the targets.

const WAVES := 20
const PLANS := [["none", false], ["none", true], ["late", true], ["schedule", true]]


func _init() -> void:
	_waves_table()
	for setup in PLANS:
		_plan(setup[0], setup[1])
	_kill_tables()
	quit()


## The clock, budget and strength of every wave, and its make-up as the sim's seed draws it.
func _waves_table() -> void:
	print("## The waves\n")
	print("| Wave | Starts | Gap to next | Budget | Spent | Strength (HP ×) | Make-up (seed 7) |")
	print("|---:|---:|---:|---:|---:|---:|---|")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var t := Balance.WAVE_FIRST
	for n in range(1, WAVES + 1):
		var mix := Combat.wave_mix(n, rng)
		var parts := []
		for kind in ["troll", "bear", "raider", "wolf", "fox"]:
			if mix.has(kind):
				parts.append("%d %s" % [mix[kind], kind])
		var strength := maxf(1.0, Combat.wave_budget(n) / Balance.WAVE_SPEND_MAX)
		print("| %d | %s | %d s | %d | %d | %.2f | %s |" % [n, _clock(t), Combat.wave_gap(n), Combat.wave_budget(n), minf(Balance.WAVE_SPEND_MAX, Combat.wave_budget(n)), strength, ", ".join(parts)])
		t += Combat.wave_gap(n)
	print("")


func _plan(plan: String, active: bool) -> void:
	print("## Armory: %s, Meagan %s\n" % [plan, "defending" if active else "standing by the furnace"])
	print("| Wave | At | Armory | Enemies | Most alive | Thefts | Lost | Caught | Her downs | Guards down (first) | Her hits (on recovery) | Guard hits (on recovery) | Bites landed | Most attacking her at once | Mode swaps | Over |")
	print("|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|")
	for row in WaveSim.run(plan, WAVES, 7, active):
		var fall: String = "%d (%s)" % [row.guards_down, row.guard_fall] if row.guards_down > 0 else "0"
		print("| %d | %s | %d | %d | %d | %d | %d | %d | %d | %s | %d (%s) | %d (%s) | %d of %d | %d | %d | %s |" % [
			row.wave, row.clock, row.armory, row.enemies, row.alive, row.thieves, maxf(row.stolen, 0.0), row.caught, row.downs, fall,
			row.hits, _share(row.exposed, row.hits), row.guard_hits, _share(row.guard_exposed, row.guard_hits),
			row.landed, row.bites, row.most_winding, row.swaps, row.over if row.over != "" else "—"])
	print("")


## Hits to kill each kind at each Armory level, at the HP it comes with before the spending cap
## (strength 1), as the Armory sheet's "a wolf in N sweeps" counts them, and the time from her
## first swing to the kill. Then the guards, with a level 1 Barracks.
func _kill_tables() -> void:
	var kinds := ["fox", "wolf", "raider", "bear", "troll"]
	var head := "| Armory | " + " | ".join(kinds.map(func(k): return Balance.ENEMIES[k].name)) + " |"
	var rule := "|---:|" + "---|".repeat(kinds.size())
	print("## Time to kill (strength 1)\n")
	print("### Stick sweeps: hits, seconds (hits on a recovering enemy, ×%.1f)\n" % Balance.RECOVERY_DAMAGE_MULT)
	print(head)
	print(rule)
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		var w := Economy.meagan_weapon(GameState.new(), lv)
		var cells := []
		for k in kinds:
			var hp: float = Balance.ENEMIES[k].hp
			var n := ceili(hp / w.stick_damage)
			var n_exposed := ceili(hp / (w.stick_damage * Balance.RECOVERY_DAMAGE_MULT))
			cells.append("%d, %.1f s (%d)" % [n, (n - 1) * w.stick_every + Balance.MEAGAN_MELEE_IMPACT, n_exposed])
		print("| %d | %s |" % [lv, " | ".join(cells)])
	print("\n### Snowballs: hits, seconds at 5 m\n")
	print(head)
	print(rule)
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		var w := Economy.meagan_weapon(GameState.new(), lv)
		var cells := []
		for k in kinds:
			var n := ceili(Balance.ENEMIES[k].hp / w.snow_damage)
			cells.append("%d, %.1f s" % [n, (n - 1) * w.snow_every + Balance.MEAGAN_RANGED_RELEASE + 5.0 / Balance.SNOWBALL_SPEED])
		print("| %d | %s |" % [lv, " | ".join(cells)])
	print("\n### One guard's strikes (one a second, Barracks Lv 1), and the guard's HP\n")
	print("| Armory | Guard HP | " + " | ".join(kinds.map(func(k): return Balance.ENEMIES[k].name)) + " |")
	print("|---:|---:|" + "---:|".repeat(kinds.size()))
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		var kit: Array = Balance.ARMORY_LEVELS[lv - 1].guard
		var cells := []
		for k in kinds:
			cells.append("%d" % ceili(Balance.ENEMIES[k].hp / kit[0]))
		print("| %d | %d | %s |" % [lv, kit[1], " | ".join(cells)])
	print("\n### Past the spending cap: stick sweeps at Armory 10 as the waves' strength grows\n")
	print("| Wave | Strength | " + " | ".join(kinds.map(func(k): return Balance.ENEMIES[k].name)) + " |")
	print("|---:|---:|" + "---:|".repeat(kinds.size()))
	var top := Economy.meagan_weapon(GameState.new(), Balance.ARMORY_LEVELS.size())
	for n in range(12, WAVES + 1):
		var strength := maxf(1.0, Combat.wave_budget(n) / Balance.WAVE_SPEND_MAX)
		var cells := []
		for k in kinds:
			cells.append("%d" % ceili(Balance.ENEMIES[k].hp * strength / top.stick_damage))
		print("| %d | %.2f | %s |" % [n, strength, " | ".join(cells)])
	print("\n### What each kind does to a defender: hits to knock down Meagan (%d HP) and a guard (Armory 1 / 10)\n" % Balance.MEAGAN_HP)
	print("| Kind | Damage | About every | Meagan | Guard Lv 1 | Guard Lv 10 |")
	print("|---|---:|---:|---:|---:|---:|")
	for k in kinds:
		var def: Dictionary = Balance.ENEMIES[k]
		print("| %s | %d | %.1f s | %d | %d | %d |" % [def.name, def.damage, def.cooldown + def.tell, ceili(Balance.MEAGAN_HP / def.damage),
			ceili(Balance.ARMORY_LEVELS[0].guard[1] / def.damage), ceili(Balance.ARMORY_LEVELS[9].guard[1] / def.damage)])
	print("")


static func _share(part: int, whole: int) -> String:
	return "—" if whole == 0 else "%d%%" % roundi(100.0 * part / whole)


static func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]
