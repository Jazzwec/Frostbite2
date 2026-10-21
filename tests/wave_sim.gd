class_name WaveSim
extends RefCounted
## The defence simulation behind `sim_waves.gd` and `test_balance.gd`: Meagan by the furnace,
## two guards, the store kept full, waves 1..`waves` on their clock; per wave, how many enemies
## got away with something and how much (net of what kills gave back). With `active`, she plays:
## she runs at the raider nearest the store, as a player defending would.
## Each row also counts what the fight `[proto]` rules did (docs/balance/fight_v2_sims.md): her
## knock-downs, guards falling, hits on recovering enemies, bites landed, thieves caught, the most
## melee enemies attacking her at once (tell, strike or recovery), and her mode swaps.

## How far out from the furnace an active Meagan goes after raiders, and her run speed.
const ACTIVE_RANGE := 14.0
const RUN := 6.0

## Armory levels by play time on ChatGPT's schedule (steer fight_v2: 5 by 15:00, 7 by 22:00,
## 10 by 30:00), in minutes. The "late" plan buys each level LATE minutes after it (fight_v2
## review 1: playtest missed upgrades, not just ideal buying).
const SCHEDULE := [[0.0, 1], [6.0, 2], [9.0, 3], [12.0, 4], [15.0, 5], [18.5, 6], [22.0, 7], [25.0, 8], [27.5, 9], [30.0, 10]]
const LATE := 3.0


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
	var mode := s.meagan_mode
	while s.wave <= waves and s.time < 3600.0:
		# Armory by the clock.
		var lv := 1
		if plan == "schedule" or plan == "late":
			var shift := LATE if plan == "late" else 0.0
			for step in SCHEDULE:
				if s.time / 60.0 >= step[0] + (shift if step[1] > 1 else 0.0):
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
			if not row.is_empty():
				var winding := 0
				for w in s.wolves:
					if w.bite_t >= 0.0 and w.victim == -1 and Balance.ENEMIES[w.kind].shape != "shot":
						winding += 1
				row.most_winding = maxi(row.most_winding, winding)
				if s.meagan_mode != mode:
					row.swaps += 1
				row.alive = maxi(row.alive, s.wolves.size())
			mode = s.meagan_mode
		for ev in e.drain_events():
			match ev.type:
				"wolves_arrived":
					if not row.is_empty():
						rows.append(row)
					row = {"wave": ev.wave, "clock": _clock(s.time), "armory": lv, "enemies": ev.count, "thieves": 0, "stolen": 0.0, "injured": false,
						"downs": 0, "guards_down": 0, "guard_fall": "", "hits": 0, "exposed": 0, "guard_hits": 0, "guard_exposed": 0,
						"bites": 0, "landed": 0, "caught": 0, "most_winding": 0, "swaps": 0, "alive": 0, "over": ""}
				"theft":
					row.thieves += 1
					for res in ev.carry:
						row.stolen += ev.carry[res]
				"wolf_killed":
					if not row.is_empty():
						for res in ev.carry:
							row.stolen -= ev.carry[res]
						if not ev.carry.is_empty():
							row.caught += 1
				"meagan_injured":
					row.injured = true
					row.downs += 1
				"guard_down":
					row.guards_down += 1
					if row.guard_fall == "":
						row.guard_fall = _clock(s.time)
				"wolf_hit":
					if ev.kind == "guard":
						row.guard_hits += 1
						row.guard_exposed += int(ev.exposed)
					else:
						row.hits += 1
						row.exposed += int(ev.exposed)
				"wolf_bite":
					row.bites += 1
					row.landed += int(ev.hit)
				"attack_over":
					if not row.is_empty() and row.over == "":
						row.over = _clock(s.time)
	if not row.is_empty() and row.wave <= waves:
		rows.append(row)
	return rows


static func _clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


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
