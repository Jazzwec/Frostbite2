class_name WaveSim
extends RefCounted
## The defence simulation behind `sim_waves.gd` and `test_balance.gd`: Meagan by the furnace,
## two guards, the store kept full, waves 1..`waves` on their clock; per wave, how many enemies
## got away with something and how much (net of what kills gave back). With `active`, she plays:
## she runs at the raider nearest the store, as a player defending would.

## How far out from the furnace an active Meagan goes after raiders, and her run speed.
const ACTIVE_RANGE := 14.0
const RUN := 6.0

## Armory levels by play time on ChatGPT's schedule (steer fight_v2: 5 by 15:00, 7 by 22:00,
## 10 by 30:00), in minutes.
const SCHEDULE := [[0.0, 1], [6.0, 2], [9.0, 3], [12.0, 4], [15.0, 5], [18.5, 6], [22.0, 7], [25.0, 8], [27.5, 9], [30.0, 10]]


static func run(plan: String, waves: int, seed := 7, active := false) -> Array:
	var e := GameEngine.new(seed)
	var s := e.state
	s.arrivals.clear()
	s.next_arrival_in = 1e9
	s.blizzard_at = 1e9
	_build(s, "barracks")
	_build(s, "armory")
	for i in 2:
		var jan := {"id": s.new_id(), "job": "", "site": -1, "hp": 30.0, "ko": false, "pos": Vector2.ZERO}
		s.jans.append(jan)
		JobRules.assign(s, jan, "guard")
		jan.hp = Economy.guard_hp(s)
	var stand := MapData.site_pos(s, 0) + Vector2(0, 3.0)
	var rows := []
	var row := {}
	var stolen := 0.0
	while s.wave <= waves and s.time < 3600.0:
		# Armory by the clock.
		var lv := 1
		if plan == "schedule":
			for step in SCHEDULE:
				if s.time / 60.0 >= step[0]:
					lv = step[1]
		_set_armory(s, lv)
		e.fill()
		for k in 5:
			if active and not s.meagan_injured:
				var to := _hunt(s, stand)
				e.set_meagan_position(s.meagan_pos.move_toward(to, RUN * 0.1))
			elif not active:
				e.set_meagan_position(stand)
			e.skip(0.1)
		for ev in e.drain_events():
			match ev.type:
				"wolves_arrived":
					if not row.is_empty():
						rows.append(row)
					row = {"wave": ev.wave, "clock": "%d:%02d" % [int(s.time) / 60, int(s.time) % 60], "armory": lv, "enemies": ev.count, "thieves": 0, "stolen": 0.0, "injured": false}
				"theft":
					row.thieves += 1
					for res in ev.carry:
						row.stolen += ev.carry[res]
				"wolf_killed":
					if not row.is_empty():
						for res in ev.carry:
							row.stolen -= ev.carry[res]
				"meagan_injured":
					row.injured = true
	if not row.is_empty() and row.wave <= waves:
		rows.append(row)
	return rows


## Where an active Meagan heads: a couple of metres short of the raider nearest the store, or
## back to her spot.
static func _hunt(s: GameState, stand: Vector2) -> Vector2:
	var furnace := MapData.site_pos(s, 0)
	var best := {}
	for w in s.wolves:
		if w.outpost >= 0 or w.hp <= 0.0 or (w.mode == "leave" and w.carry.is_empty()):
			continue
		if w.pos.distance_to(furnace) > ACTIVE_RANGE:
			continue
		if best.is_empty() or w.pos.distance_to(furnace) < best.pos.distance_to(furnace):
			best = w
	if best.is_empty():
		return stand
	var away: Vector2 = s.meagan_pos - best.pos
	return best.pos + (away.normalized() if away.length() > 0.01 else Vector2.DOWN) * 2.0


static func _build(s: GameState, building: String) -> void:
	for site in s.sites:
		if site.type == building and site.building == "":
			site.building = building
			site.level = 1
			return


static func _set_armory(s: GameState, lv: int) -> void:
	for site in s.sites:
		if site.building == "armory":
			site.level = lv
