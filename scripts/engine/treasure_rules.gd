class_name TreasureRules
extends RefCounted
## Chests in opened tiles (agreed 2026-10-20). She opens one by walking onto it:
## - a resource cache pays straight into the Stockpile;
## - a boon chest offers 2 (rare) or 3 (epic) run-long boons to choose from;
## - a gear chest offers an item for one of her three slots, to equip or leave.
## While a choice is open the world waits (GameEngine.advance).


## Opens the first unopened chest she's standing at, one at a time.
static func open_near(s: GameState, rng: RandomNumberGenerator, events: Array) -> void:
	if not s.offer.is_empty() or s.meagan_injured:
		return
	for i in s.chests.size():
		var chest: Dictionary = s.chests[i]
		if chest.opened or s.meagan_pos.distance_to(chest.pos) > Balance.CHEST_RANGE:
			continue
		chest.opened = true
		events.append({"type": "chest_opened", "chest": i, "kind": chest.kind, "rarity": chest.rarity, "pos": chest.pos})
		match chest.kind:
			"cache":
				_cache(s, chest, rng, events)
			"spoils":
				# An outpost's chest (agreed 2026-10-20): what it held, into the store.
				var caps := Economy.caps(s)
				for res in chest.pay:
					s.piles[res] = minf(caps[res], s.piles[res] + chest.pay[res])
				events.append({"type": "spoils", "pay": chest.pay, "pos": chest.pos})
			"boon":
				s.offer = {"kind": "boon", "chest": i, "options": boon_options(s, rng, Balance.BOON_CHOICES[chest.rarity])}
			"gear":
				var slots := Balance.GEAR.keys()
				s.offer = {"kind": "gear", "chest": i, "slot": slots[rng.randi_range(0, slots.size() - 1)], "tier": chest.rarity}
		return


## `count` different boons, ones she hasn't taken first.
static func boon_options(s: GameState, rng: RandomNumberGenerator, count: int) -> Array:
	var fresh := Balance.BOONS.keys().filter(func(id): return not s.boons.has(id))
	var taken := Balance.BOONS.keys().filter(func(id): return s.boons.has(id))
	var out := []
	for pool in [fresh, taken]:
		while out.size() < count and not pool.is_empty():
			out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out


static func choose_boon(s: GameState, index: int, events: Array) -> bool:
	if s.offer.get("kind", "") != "boon" or index < 0 or index >= s.offer.options.size():
		return false
	var id: String = s.offer.options[index]
	var boon: Dictionary = Balance.BOONS[id]
	s.mods[boon.mod] = s.mods.get(boon.mod, 0.0) + boon.value
	s.boons.append(id)
	s.offer = {}
	events.append({"type": "boon_taken", "boon": id})
	return true


## Equips the offered item (or leaves it, keeping what she has).
static func choose_gear(s: GameState, equip: bool, events: Array) -> bool:
	if s.offer.get("kind", "") != "gear":
		return false
	if equip:
		s.gear[s.offer.slot] = s.offer.tier
		events.append({"type": "gear_equipped", "slot": s.offer.slot, "tier": s.offer.tier})
	s.offer = {}
	return true


## What one gear item adds to its modifier.
static func gear_value(slot: String, tier: String) -> float:
	return 0.0 if tier == "" else Balance.GEAR[slot].tiers[tier]


static func _cache(s: GameState, chest: Dictionary, rng: RandomNumberGenerator, events: Array) -> void:
	var res := WorldGen.pick(rng, Balance.CACHE_WEIGHTS)
	var ring := WorldGen.ring(chest.tile)
	var amount: float = Balance.CACHE_AMOUNTS[res] * (1.0 + Balance.CACHE_RING_GROWTH * maxi(ring - 1, 0)) * (1.0 + Economy.mod(s, "cache_mult"))
	var room: float = Economy.caps(s)[res] - s.piles[res]
	var got := floorf(minf(amount, maxf(room, 0.0)))
	s.piles[res] += got
	events.append({"type": "cache", "resource": res, "amount": got, "pos": chest.pos})
