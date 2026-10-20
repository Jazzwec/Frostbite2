class_name CarryRules
extends RefCounted
## Jans haul their work (agreed 2026-10-20): a producer Jan works at his post until he has a load,
## walks it to the nearest stockpile (it counts in the store only then), and walks back. So a
## stockpile near a producer, like the small one in each opened tile, gets more out of it.
## Each producer Jan keeps `pos`, `load`, `trip` ("" at his post, "out" to a stockpile, "back"),
## `dest` (the stockpile he's taking it to) and `working` (whether he worked this tick).

## Close enough to count as there.
const ARRIVE := 0.05


static func haul(s: GameState, dt: float, events: Array) -> void:
	var caps := Economy.caps(s)
	var slots := {}
	for jan in s.jans:
		jan.working = false
		var site: int = jan.get("site", -1)
		if site < 0 or not Balance.CARRY_LOAD.has(jan.job):
			continue
		var slot: int = slots.get(site, 0)
		slots[site] = slot + 1
		var post := MapData.jan_post(s, site, slot)
		var res: String = Balance.JOBS[jan.job].resource
		match jan.get("trip", ""):
			"out":
				var dest: int = jan.dest
				if _walk(jan, MapData.stockpile_pad(s, dest), dt):
					# What doesn't fit stays in his arms for next time.
					var into := clampf(caps[res] - s.piles[res], 0.0, jan.load)
					s.piles[res] += into
					jan.load -= into
					jan.trip = "back"
					if into > 0.0:
						events.append({"type": "jan_delivered", "jan": jan.id, "resource": res, "amount": into, "stockpile": dest})
			"back":
				if _walk(jan, post, dt):
					jan.trip = ""
			_:
				if jan.pos.distance_to(post) > ARRIVE:
					_walk(jan, post, dt)
					continue
				# He works while his producer produces and the store has room for it; otherwise he rests.
				var rate := Economy.site_rate(s, site) / maxf(Economy.site_jans(s, site), 1.0)
				if rate <= 0.0 or s.piles[res] >= caps[res] - 0.01:
					continue
				jan.working = true
				var full: float = Balance.CARRY_LOAD[jan.job]
				jan.load = minf(jan.get("load", 0.0) + rate * dt, full)
				if jan.load >= full - 0.0001:
					jan.trip = "out"
					jan.dest = MapData.nearest_stockpile(s, post)


## Moves a Jan towards `to` at walking pace (slowed for the way round buildings). True once there.
static func _walk(jan: Dictionary, to: Vector2, dt: float) -> bool:
	var pos: Vector2 = jan.pos
	jan.pos = pos.move_toward(to, Balance.JAN_WALK_SPEED / Balance.JAN_PATH_FACTOR * dt)
	return jan.pos.distance_to(to) <= ARRIVE


## A Jan put on a new job or producer drops what he was doing.
static func reset(jan: Dictionary) -> void:
	jan.load = 0.0
	jan.trip = ""
	jan.working = false
