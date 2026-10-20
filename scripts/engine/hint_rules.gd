class_name HintRules
extends RefCounted
## The first-minute hints' rules: their order, when each counts as done, and where each happens.
## The Hints UI (scripts/ui/hints.gd) shows them; the text is in data/tips.json under "hints".

## In order.
const ORDER := ["move", "chop", "store", "thaw", "open"]


## Whether the player has done hint `id` in this state. Meagan started the winter at `start`.
static func is_done(id: String, s: GameState, start: Vector2) -> bool:
	match id:
		"move":
			return s.meagan_pos.distance_to(start) >= Balance.HINT_MOVED_ENOUGH
		"chop":
			return s.gathered.wood > 0.0
		"store":
			return s.meagan_activity == "store"
		"thaw":
			return s.rescued_total > 0
		"open":
			return not s.stoves.is_empty() or s.gates.any(func(g): return g.paying)
	return true


## Where hint `id` happens on the ground, or Vector2.INF for nowhere in particular.
static func target(id: String, s: GameState) -> Vector2:
	match id:
		"chop":
			var best := Vector2.INF
			for node in s.node_defs:
				if node.kind == "forest" and s.meagan_pos.distance_to(node.pos) < s.meagan_pos.distance_to(best):
					best = node.pos
			return best
		"store":
			return MapData.stockpile_pad(s, MapData.nearest_stockpile(s, s.meagan_pos))
		"thaw":
			var best := Vector2.INF
			for arrival in s.arrivals:
				var pos: Vector2 = arrival.pos
				if s.meagan_pos.distance_to(pos) < s.meagan_pos.distance_to(best):
					best = pos
			return best
		"open":
			var best := Vector2.INF
			for gate in s.gates:
				if s.meagan_pos.distance_to(gate.pad) < s.meagan_pos.distance_to(best):
					best = gate.pad
			return best
	return Vector2.INF
