class_name MilestoneRules
extends RefCounted
## When a milestone (data/milestones.json, from Frostbite 1) counts as reached. Only the triggers
## the game can detect so far are supported: building levels, Jans in the city, Jans rescued,
## blizzards survived and attacks repelled. The rest (Jan variants, research, the secret date)
## wait until those systems exist.

const SUPPORTED := ["building", "jans", "rescued", "blizzards", "attacksRepelled"]


static func supported(milestone: Dictionary) -> bool:
	var trigger: Dictionary = milestone.get("trigger", {})
	if not SUPPORTED.has(trigger.get("type", "")):
		return false
	# A building the game doesn't have yet (say the Research Hut) can't be reached either.
	return trigger.type != "building" or Balance.BUILDINGS.has(building_id(trigger.get("key", "")))


static func reached(milestone: Dictionary, s: GameState) -> bool:
	if not supported(milestone):
		return false
	var trigger: Dictionary = milestone.trigger
	match trigger.type:
		"building":
			return Economy.level(s, building_id(trigger.key)) >= int(trigger.get("level", 1))
		"jans":
			return s.jans.size() >= int(trigger.count)
		"rescued":
			return s.rescued_total >= int(trigger.count)
		"blizzards":
			return s.blizzards_survived >= int(trigger.count)
		"attacksRepelled":
			return s.attacks_repelled >= int(trigger.count)
	return false


## Frostbite 1's building keys are camelCase ("sledShed"); ours are snake_case ("sled_shed").
static func building_id(key: String) -> String:
	var out := ""
	for ch in key:
		out += ("_" + ch.to_lower()) if ch != ch.to_lower() else ch
	return out
