class_name Clips
extends RefCounted
## The greybox animation clips, as keyframes. They mirror AnimationPlayer tracks, so a rigged
## model can replace them clip for clip.
##
## Each clip has:
## - `length`: seconds per cycle.
## - `loop`: whether it loops.
## - `tool`: what the hands hold, from `Tools`.
## - `socket`: "hand" or "chest". Optional, defaults to the hand.
## - `impact`: the hit moment as a fraction of the cycle, or -1 for none.
## - `throws`: optional; the held item leaves the hand at the impact and is back next cycle.
## - `keys`: poses at fractions of the cycle, eased into from the previous key. A key's `ease` is
##   `smooth` (the default), `in` (speeding up, for blows) or `out` (slowing down).
##
## The joints a key can set, and any it leaves out stay at REST:
## - `arm_r`, `arm_l`: Euler degrees at the shoulder. x < 0 raises the arm forward (-90 points
##   it straight ahead, -180 straight up); z > 0 swings it outward. The rig mirrors the right arm.
## - `tool`: Euler degrees of the held tool in the hand.
## - `lean` (forward), `roll` (sideways), `turn` (twist): degrees for the whole body, about the feet.
## - `rise`: metres the body moves up; below zero crouches.
## - `head`: degrees of nod, forward.
## - `leg_l`, `leg_r`: degrees a leg swings forward. Only rigged models have legs; the greybox
##   ignores them.

const REST := {
	"arm_r": Vector3(-6, 0, 8), "arm_l": Vector3(-6, 0, 8), "tool": Vector3.ZERO,
	"lean": 0.0, "roll": 0.0, "turn": 0.0, "rise": 0.0, "head": 0.0, "leg_l": 0.0, "leg_r": 0.0,
}

## Seconds to blend from one clip into the next.
const BLEND := 0.15

const CLIPS := {
	"idle": {
		"length": 3.0, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0},
			{"t": 0.5, "arm_r": Vector3(-3, 0, 11), "arm_l": Vector3(-3, 0, 11), "rise": 0.015, "head": -3.0},
		],
	},
	"walk": {
		"length": 0.63, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-32, 0, 8), "arm_l": Vector3(26, 0, 8), "lean": 6.0, "leg_l": 28.0, "leg_r": -28.0},
			{"t": 0.25, "arm_r": Vector3(-3, 0, 8), "arm_l": Vector3(-3, 0, 8), "rise": 0.12, "lean": 6.0},
			{"t": 0.5, "arm_r": Vector3(26, 0, 8), "arm_l": Vector3(-32, 0, 8), "lean": 6.0, "leg_l": -28.0, "leg_r": 28.0},
			{"t": 0.75, "arm_r": Vector3(-3, 0, 8), "arm_l": Vector3(-3, 0, 8), "rise": 0.12, "lean": 6.0},
		],
	},
	# Walking with a heavy bag (AFK N4, from Astra's animation review): a slower, shorter stride,
	# leaning into the load, less bounce, arms swinging less.
	"walk_loaded": {
		"length": 0.72, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-20, 0, 10), "arm_l": Vector3(14, 0, 10), "lean": 9.0, "leg_l": 21.0, "leg_r": -21.0, "rise": -0.01},
			{"t": 0.25, "arm_r": Vector3(-4, 0, 10), "arm_l": Vector3(-4, 0, 10), "rise": 0.04, "lean": 9.0, "head": -3.0},
			{"t": 0.5, "arm_r": Vector3(14, 0, 10), "arm_l": Vector3(-20, 0, 10), "lean": 9.0, "leg_l": -21.0, "leg_r": 21.0, "rise": -0.01},
			{"t": 0.75, "arm_r": Vector3(-4, 0, 10), "arm_l": Vector3(-4, 0, 10), "rise": 0.04, "lean": 9.0, "head": -3.0},
		],
	},
	# A Jan splitting logs on his stump (AFK N8, Astra's second review): both hands raise the axe
	# over his head (0.25 s anticipation), bring it down onto the middle of the stump in 0.1 s,
	# hold (the rig's hit-stop) and recover.
	"split": {
		"length": 0.9, "loop": true, "tool": "axe", "impact": 0.42,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-70, 0, -16), "arm_l": Vector3(-70, 0, -16), "lean": 6.0},
			{"t": 0.3, "arm_r": Vector3(-165, 0, -10), "arm_l": Vector3(-165, 0, -10), "lean": -8.0, "rise": 0.04, "head": -8.0, "ease": "out"},
			{"t": 0.42, "arm_r": Vector3(-52, 0, -16), "arm_l": Vector3(-52, 0, -16), "lean": 18.0, "rise": -0.08, "head": 10.0, "ease": "in"},
			{"t": 0.7, "arm_r": Vector3(-58, 0, -16), "arm_l": Vector3(-58, 0, -16), "lean": 14.0, "rise": -0.05, "head": 6.0},
		],
	},
	# Felling: two hands on the axe, wound back over the shoulder, then swung flat into the trunk.
	# A flat swing reads as a wide arc from the camera above.
	"chop": {
		"length": 1.0, "loop": true, "tool": "axe", "impact": 0.6,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-68, 0, -22), "arm_l": Vector3(-68, 0, -22), "turn": 0.0, "tool": Vector3(0, 90, 0)},
			{"t": 0.4, "arm_r": Vector3(-80, 0, -14), "arm_l": Vector3(-80, 0, -14), "turn": 75.0, "lean": -6.0, "rise": 0.03, "tool": Vector3(0, 90, 0), "ease": "out"},
			{"t": 0.6, "arm_r": Vector3(-62, 0, -26), "arm_l": Vector3(-62, 0, -26), "turn": -15.0, "lean": 12.0, "rise": -0.06, "tool": Vector3(0, 90, 0), "ease": "in"},
			{"t": 0.75, "arm_r": Vector3(-62, 0, -26), "arm_l": Vector3(-62, 0, -26), "turn": -20.0, "lean": 12.0, "rise": -0.06, "tool": Vector3(0, 90, 0)},
		],
	},
	# Crouched at the ice hole; the line bobs, then a jerk lands a fish.
	"fish": {
		"length": 2.6, "loop": true, "tool": "rod", "impact": 0.8,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-55, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.32, "lean": 14.0, "head": 10.0},
			{"t": 0.2, "arm_r": Vector3(-49, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.32, "lean": 14.0, "head": 10.0},
			{"t": 0.4, "arm_r": Vector3(-56, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.32, "lean": 14.0, "head": 10.0},
			{"t": 0.6, "arm_r": Vector3(-50, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.32, "lean": 14.0, "head": 12.0},
			{"t": 0.72, "arm_r": Vector3(-34, 0, 6), "arm_l": Vector3(-34, 0, -10), "rise": -0.34, "lean": 18.0, "head": 16.0},
			{"t": 0.8, "arm_r": Vector3(-125, 0, 6), "arm_l": Vector3(-70, 0, 10), "rise": -0.18, "lean": -8.0, "head": -10.0, "ease": "in"},
			{"t": 0.9, "arm_r": Vector3(-115, 0, 6), "arm_l": Vector3(-60, 0, 10), "rise": -0.2, "lean": -4.0, "head": -6.0},
		],
	},
	# A Jan ice-fishing sat on his stool, like the agreed visual (AFK V8): knees forward, the rod
	# out over the hole, a lift at the bite.
	"fish_sit": {
		"length": 2.6, "loop": true, "tool": "rod", "impact": 0.8,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-55, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.5, "lean": 8.0, "head": 10.0, "leg_l": 72.0, "leg_r": 72.0},
			{"t": 0.3, "arm_r": Vector3(-49, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.5, "lean": 8.0, "head": 12.0, "leg_l": 72.0, "leg_r": 72.0},
			{"t": 0.6, "arm_r": Vector3(-53, 0, 6), "arm_l": Vector3(-40, 0, -10), "rise": -0.5, "lean": 10.0, "head": 12.0, "leg_l": 72.0, "leg_r": 72.0},
			{"t": 0.72, "arm_r": Vector3(-34, 0, 6), "arm_l": Vector3(-34, 0, -10), "rise": -0.5, "lean": 14.0, "head": 16.0, "leg_l": 72.0, "leg_r": 72.0},
			{"t": 0.8, "arm_r": Vector3(-120, 0, 6), "arm_l": Vector3(-68, 0, 10), "rise": -0.46, "lean": -6.0, "head": -8.0, "leg_l": 70.0, "leg_r": 70.0, "ease": "in"},
			{"t": 0.9, "arm_r": Vector3(-110, 0, 6), "arm_l": Vector3(-58, 0, 10), "rise": -0.48, "lean": -2.0, "head": -4.0, "leg_l": 72.0, "leg_r": 72.0},
		],
	},
	# A pickaxe into the scrap heap: like chopping, but lower and heavier.
	"scavenge": {
		"length": 1.1, "loop": true, "tool": "pickaxe", "impact": 0.6,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-90, 0, -14), "arm_l": Vector3(-90, 0, -14), "lean": 10.0},
			{"t": 0.4, "arm_r": Vector3(-195, 0, -10), "arm_l": Vector3(-195, 0, -10), "lean": -10.0, "rise": 0.05, "ease": "out"},
			{"t": 0.6, "arm_r": Vector3(-35, 0, -16), "arm_l": Vector3(-35, 0, -16), "lean": 28.0, "rise": -0.14, "ease": "in"},
			{"t": 0.8, "arm_r": Vector3(-38, 0, -16), "arm_l": Vector3(-38, 0, -16), "lean": 26.0, "rise": -0.12},
		],
	},
	# Quick hammer blows, kneeling at the frame; the other hand holds the nail.
	"build": {
		"length": 0.45, "loop": true, "tool": "hammer", "impact": 0.7,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-60, 0, 4), "arm_l": Vector3(-48, 0, -22), "rise": -0.25, "lean": 22.0},
			{"t": 0.45, "arm_r": Vector3(-140, 0, 4), "arm_l": Vector3(-48, 0, -22), "rise": -0.23, "lean": 18.0, "ease": "out"},
			{"t": 0.7, "arm_r": Vector3(-45, 0, 4), "arm_l": Vector3(-48, 0, -22), "rise": -0.27, "lean": 24.0, "ease": "in"},
		],
	},
	# Reach back into the bag for a log and toss it overhand into the furnace.
	"fuel": {
		"length": 1.0, "loop": true, "tool": "log", "impact": 0.55, "throws": true,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(20, 0, 14), "lean": -2.0, "turn": 15.0},
			{"t": 0.3, "arm_r": Vector3(45, 0, 18), "lean": -10.0, "turn": 30.0, "ease": "out"},
			{"t": 0.55, "arm_r": Vector3(-150, 0, 4), "arm_l": Vector3(-40, 0, 10), "lean": 14.0, "turn": -8.0, "ease": "in"},
			{"t": 0.75, "arm_r": Vector3(-110, 0, 6), "arm_l": Vector3(-25, 0, 10), "lean": 8.0, "turn": -4.0},
		],
	},
	# Jans walking their work to a stockpile (agreed 2026-10-20): the walk's legs, the load hugged.
	"haul_log": {
		"length": 0.7, "loop": true, "tool": "bundle", "socket": "chest", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": 26.0, "leg_r": -26.0},
			{"t": 0.25, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
			{"t": 0.5, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": -26.0, "leg_r": 26.0},
			{"t": 0.75, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
		],
	},
	"haul_fish": {
		"length": 0.7, "loop": true, "tool": "basket", "socket": "chest", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": 26.0, "leg_r": -26.0},
			{"t": 0.25, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
			{"t": 0.5, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": -26.0, "leg_r": 26.0},
			{"t": 0.75, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
		],
	},
	"haul_materials": {
		"length": 0.7, "loop": true, "tool": "load_crate", "socket": "chest", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": 26.0, "leg_r": -26.0},
			{"t": 0.25, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
			{"t": 0.5, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "lean": 4.0, "leg_l": -26.0, "leg_r": 26.0},
			{"t": 0.75, "arm_r": Vector3(-76, 0, -14), "arm_l": Vector3(-76, 0, -14), "rise": 0.1, "lean": 4.0},
		],
	},
	# Emptying her bag into a stockpile.
	"carry": {
		"length": 0.8, "loop": true, "tool": "crate", "socket": "chest", "impact": 0.5,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-72, 0, -14), "arm_l": Vector3(-72, 0, -14), "turn": 20.0},
			{"t": 0.5, "arm_r": Vector3(-80, 0, -14), "arm_l": Vector3(-80, 0, -14), "turn": -20.0, "rise": 0.05, "lean": 6.0},
		],
	},
	# Rubbing her hands, then blowing warm breath onto a frozen Jan. Played once.
	"warm": {
		"length": 1.6, "loop": false, "tool": "", "impact": 0.55,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-80, 0, -26), "arm_l": Vector3(-80, 0, -26), "lean": 8.0},
			{"t": 0.12, "arm_r": Vector3(-84, 0, -32), "arm_l": Vector3(-76, 0, -20)},
			{"t": 0.24, "arm_r": Vector3(-76, 0, -20), "arm_l": Vector3(-84, 0, -32)},
			{"t": 0.36, "arm_r": Vector3(-84, 0, -32), "arm_l": Vector3(-76, 0, -20)},
			{"t": 0.55, "arm_r": Vector3(-100, 0, -30), "arm_l": Vector3(-100, 0, -30), "lean": 22.0, "head": 12.0, "ease": "in"},
			{"t": 0.85, "arm_r": Vector3(-95, 0, -30), "arm_l": Vector3(-95, 0, -30), "lean": 20.0, "head": 10.0},
			{"t": 1.0},
		],
	},
	# Sideways axe swings at a wolf, twisting from the hips.
	"fight": {
		"length": 0.6, "loop": true, "tool": "axe", "impact": 0.5,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-80, 0, -20), "arm_l": Vector3(-70, 0, -20), "turn": 45.0, "tool": Vector3(0, 90, 0)},
			{"t": 0.3, "arm_r": Vector3(-85, 0, -15), "arm_l": Vector3(-70, 0, -15), "turn": 60.0, "lean": -4.0, "tool": Vector3(0, 90, 0), "ease": "out"},
			{"t": 0.5, "arm_r": Vector3(-75, 0, -30), "arm_l": Vector3(-70, 0, -30), "turn": -50.0, "lean": 12.0, "tool": Vector3(0, 90, 0), "ease": "in"},
			{"t": 0.75, "arm_r": Vector3(-75, 0, -30), "arm_l": Vector3(-70, 0, -30), "turn": -45.0, "lean": 10.0, "tool": Vector3(0, 90, 0)},
		],
	},
	# Stockpile full: a shrug.
	"full": {
		"length": 1.6, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0},
			{"t": 0.25, "arm_r": Vector3(-25, 0, 48), "arm_l": Vector3(-25, 0, 48), "rise": 0.05, "head": -10.0, "ease": "out"},
			{"t": 0.6, "arm_r": Vector3(-25, 0, 46), "arm_l": Vector3(-25, 0, 46), "rise": 0.05, "head": -10.0},
			{"t": 0.85},
		],
	},
	# Injured, lying in the snow.
	"down": {
		"length": 2.0, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "roll": 80.0, "rise": 0.3, "arm_r": Vector3(-160, 0, 20), "arm_l": Vector3(-10, 0, 30), "head": 10.0},
			{"t": 0.5, "roll": 80.0, "rise": 0.3, "arm_r": Vector3(-155, 0, 22), "arm_l": Vector3(-10, 0, 30), "head": 14.0},
		],
	},
	# A Jan with nothing to do, or no room for his output: stamping and rubbing his hands.
	"warm_hands": {
		"length": 1.2, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-72, 0, -28), "arm_l": Vector3(-68, 0, -22), "head": 8.0},
			{"t": 0.25, "arm_r": Vector3(-68, 0, -22), "arm_l": Vector3(-72, 0, -28), "rise": 0.06, "roll": 3.0, "head": 8.0},
			{"t": 0.5, "arm_r": Vector3(-72, 0, -28), "arm_l": Vector3(-68, 0, -22), "head": 8.0},
			{"t": 0.75, "arm_r": Vector3(-68, 0, -22), "arm_l": Vector3(-72, 0, -28), "rise": 0.06, "roll": -3.0, "head": 8.0},
		],
	},
	# Resting Jans, cold or waiting (AFK V8): stamping warmth into their feet, arms hugged...
	"stamp": {
		"length": 0.9, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-30, 0, -40), "arm_l": Vector3(-30, 0, -40), "leg_l": 16.0, "rise": 0.03, "head": 4.0},
			{"t": 0.25, "arm_r": Vector3(-32, 0, -42), "arm_l": Vector3(-32, 0, -42), "rise": -0.03, "head": 4.0},
			{"t": 0.5, "arm_r": Vector3(-30, 0, -40), "arm_l": Vector3(-30, 0, -40), "leg_r": 16.0, "rise": 0.03, "head": 4.0},
			{"t": 0.75, "arm_r": Vector3(-32, 0, -42), "arm_l": Vector3(-32, 0, -42), "rise": -0.03, "head": 4.0},
		],
	},
	# ...or looking round the town, hands behind his back.
	"look_round": {
		"length": 4.0, "loop": true, "tool": "", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(18, 0, 6), "arm_l": Vector3(18, 0, 6), "turn": 0.0, "head": -4.0},
			{"t": 0.3, "arm_r": Vector3(18, 0, 6), "arm_l": Vector3(18, 0, 6), "turn": 35.0, "head": -6.0},
			{"t": 0.5, "arm_r": Vector3(18, 0, 6), "arm_l": Vector3(18, 0, 6), "turn": 30.0, "head": 2.0},
			{"t": 0.8, "arm_r": Vector3(18, 0, 6), "arm_l": Vector3(18, 0, 6), "turn": -30.0, "head": -6.0},
		],
	},
	# Meagan in a fight, between attacks, her stance saying which weapon is next (fight_v2 review
	# 1): up close the stick raised across her shoulder, a little crouched...
	"ready": {
		"length": 1.2, "loop": true, "tool": "stick", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-120, 0, 28), "arm_l": Vector3(-60, 0, -20), "lean": 6.0, "rise": -0.06, "tool": Vector3(150, 0, 0)},
			{"t": 0.5, "arm_r": Vector3(-126, 0, 28), "arm_l": Vector3(-62, 0, -20), "lean": 7.0, "rise": -0.08, "tool": Vector3(150, 0, 0)},
		],
	},
	# ...at range a snowball held up by her ear, ready to throw.
	"ready_throw": {
		"length": 1.2, "loop": true, "tool": "snowball", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-140, 0, 22), "arm_l": Vector3(-45, 0, -14), "lean": 2.0, "turn": 12.0},
			{"t": 0.5, "arm_r": Vector3(-146, 0, 22), "arm_l": Vector3(-47, 0, -14), "lean": 3.0, "turn": 12.0},
		],
	},
	# Her stick sweep: a 0.1 s wind-up, a 0.06 s sweep to the hit at 0.16 s (fight_v2 review 1), 0.28 s
	# recovery, rest. Played over her legs, so she can swing while she walks.
	"sweep": {
		"length": 0.8, "loop": false, "tool": "stick", "impact": 0.2,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-45, 0, 10), "arm_l": Vector3(-35, 0, -14), "turn": 0.0, "tool": Vector3(0, 90, 0)},
			{"t": 0.13, "arm_r": Vector3(-72, 0, -36), "arm_l": Vector3(-60, 0, -30), "turn": 32.0, "lean": -4.0, "tool": Vector3(0, 90, 0), "ease": "out"},
			{"t": 0.2, "arm_r": Vector3(-78, 0, 24), "arm_l": Vector3(-64, 0, 18), "turn": -28.0, "lean": 8.0, "tool": Vector3(0, 90, 0), "ease": "in"},
			{"t": 0.55, "arm_r": Vector3(-55, 0, 20), "arm_l": Vector3(-45, 0, 10), "turn": -15.0, "lean": 4.0, "tool": Vector3(0, 90, 0)},
			{"t": 1.0, "arm_r": Vector3(-40, 0, 10), "arm_l": Vector3(-32, 0, -14), "turn": 0.0, "tool": Vector3(0, 90, 0)},
		],
	},
	# Her snowball throw: 0.12 s hand back and up, a 0.06 s throw to the release at 0.18 s, 0.18 s
	# recovery, rest. The snowball leaves her hand at the release.
	"throw": {
		"length": 0.75, "loop": false, "tool": "snowball", "impact": 0.24, "throws": true,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-30, 0, 10), "arm_l": Vector3(-30, 0, -12), "turn": 0.0},
			{"t": 0.16, "arm_r": Vector3(-160, 0, 16), "arm_l": Vector3(-70, 0, -10), "turn": 28.0, "lean": -6.0, "ease": "out"},
			{"t": 0.24, "arm_r": Vector3(-70, 0, 4), "arm_l": Vector3(-30, 0, -12), "turn": -18.0, "lean": 10.0, "ease": "in"},
			{"t": 0.48, "arm_r": Vector3(-40, 0, 8), "arm_l": Vector3(-28, 0, -12), "turn": -6.0, "lean": 4.0},
			{"t": 1.0, "arm_r": Vector3(-30, 0, 10), "arm_l": Vector3(-30, 0, -12), "turn": 0.0},
		],
	},
	# A guard at rest, spear upright.
	"guard_idle": {
		"length": 3.0, "loop": true, "tool": "spear", "impact": -1.0,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-20, 0, 6), "tool": Vector3(200, 0, 0)},
			{"t": 0.5, "arm_r": Vector3(-22, 0, 6), "tool": Vector3(200, 0, 0), "head": -4.0},
		],
	},
	# A guard thrusting his spear at a wolf.
	"guard_attack": {
		"length": 0.6, "loop": true, "tool": "spear", "impact": 0.5,
		"keys": [
			{"t": 0.0, "arm_r": Vector3(-80, 0, 4), "arm_l": Vector3(-60, 0, -20), "lean": -6.0},
			{"t": 0.3, "arm_r": Vector3(-70, 0, 8), "arm_l": Vector3(-60, 0, -20), "lean": -10.0, "ease": "out"},
			{"t": 0.5, "arm_r": Vector3(-95, 0, 0), "arm_l": Vector3(-80, 0, -20), "lean": 18.0, "rise": -0.05, "ease": "in"},
			{"t": 0.7, "arm_r": Vector3(-93, 0, 0), "arm_l": Vector3(-80, 0, -20), "lean": 16.0},
		],
	},
}
