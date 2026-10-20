class_name HintRules
extends RefCounted
## The first-minute hints' rules: their order, when each counts as done, and where each happens.
## The Hints UI (scripts/ui/hints.gd) shows them; the text is in data/tips.json under "hints".

## In order.
const ORDER := ["move", "chop", "fuel", "thaw", "store"]


## Whether the player has done hint `id` in this state. Meagan started the winter at `start`.
static func is_done(id: String, s: GameState, start: Vector2) -> bool:
	match id:
		"move":
			return s.meagan_pos.distance_to(start) >= Balance.HINT_MOVED_ENOUGH
		"chop":
			return s.bag.wood > 0.0 or s.meagan_activity == "fuel"
		"fuel":
			return s.meagan_activity == "fuel"
		"thaw":
			return s.rescued_total > 0
		"store":
			return s.meagan_activity == "store"
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
		"fuel":
			return MapData.site_pos(s, 0)
		"thaw":
			var best := Vector2.INF
			for arrival in s.arrivals:
				var pos: Vector2 = arrival.pos
				if s.meagan_pos.distance_to(pos) < s.meagan_pos.distance_to(best):
					best = pos
			return best
		"store":
			return MapData.stockpile_pad()
	return Vector2.INF
