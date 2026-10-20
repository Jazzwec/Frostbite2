#!/bin/bash
# The fight review's screenshots (fight_v2 rounds), from the running game:
#   tools/capture/fight_caps.sh source_art/direction/fight_v2/r2
# Needs the game playing (swallowtail scene play). Each scenario clears the field, fills the
# store, stops the wave and blizzard clocks and puts Meagan in the open, then sets up a fight;
# strips are 6 frames (some slowed down so the tells show).
OUT=${1:?usage: fight_caps.sh OUTDIR}
STRIP="$(dirname "$0")/strip.sh"
mkdir -p "$OUT"

PRE='Engine.time_scale = 1.0
var e = Game.engine
var s = e.state
var main = get_tree().current_scene
main._hud.sheet.close()
# Waves come mid-game: the first-minute hints are long done by then.
for id in HintRules.ORDER:
	main._hud.hints._done[id] = true
s.wolves.clear()
s.wave_queue.clear()
s.shots.clear()
s.enemy_shots.clear()
s.next_wave = {}
s.raid_on = false
s.attack_warned = false
s.meagan_injured = false
s.meagan_hp = Balance.MEAGAN_HP
s.attack_at = s.time + 9999.0
s.blizzard_at = s.time + 9999.0
e.fill()
s.bag = {"wood": 0.0, "food": 0.0, "materials": 0.0}
var p = Vector2(0, 16)
var m = main._meagan
s.meagan_pos = p
m.global_position = Vector3(p.x, 0, p.y)
m.walk_to(Vector3(p.x, 0, p.y))
var add = func(kind, at, tough):
	var en = Combat.make_enemy(s, kind, at, Vector2(0, 40))
	en.hp *= tough
	en.max_hp *= tough
	s.wolves.append(en)
	return en
'

swallowtail runtime eval --code 'Game.new_game()
emit(1)' >/dev/null 2>&1
sleep 4

bash "$STRIP" "$OUT" mixed_wave 6 0.45 "$PRE
s.wave = 7
s.raid_on = true
var kinds = [\"fox\", \"fox\", \"fox\", \"wolf\", \"wolf\", \"wolf\", \"raider\", \"bear\"]
for i in kinds.size():
	add.call(kinds[i], p + Vector2.RIGHT.rotated(i * 0.8) * 6.5, 3.0)
emit(1)"

bash "$STRIP" "$OUT" melee_close 6 0.25 "$PRE
for i in 3:
	add.call(\"wolf\", p + Vector2.RIGHT.rotated(0.4 + i * 0.5) * 2.2, 30.0)
emit(1)"

bash "$STRIP" "$OUT" bear_swipe 6 0.3 "$PRE
add.call(\"bear\", p + Vector2(1.5, 1.5), 30.0)
Engine.time_scale = 0.3
emit(1)"

bash "$STRIP" "$OUT" troll_slam 6 0.35 "$PRE
add.call(\"troll\", p + Vector2(1.2, 1.6), 30.0)
Engine.time_scale = 0.3
emit(1)"

bash "$STRIP" "$OUT" raider_throw 6 0.3 "$PRE
add.call(\"raider\", p + Vector2(4.5, 1.5), 30.0)
add.call(\"raider\", p + Vector2(-4.5, 2.5), 30.0)
Engine.time_scale = 0.3
emit(1)"

bash "$STRIP" "$OUT" theft 6 0.6 "$PRE
s.meagan_injured = true
var f = MapData.site_pos(s, 0)
p = f + Vector2(0, 5)
s.meagan_pos = p
m.global_position = Vector3(p.x, 0, p.y)
m.walk_to(Vector3(p.x, 0, p.y))
s.raid_on = true
for i in 3:
	add.call([\"wolf\", \"fox\", \"raider\"][i], f + Vector2(-2.5 + 2.5 * i, 3.0), 30.0)
emit(1)"

# A raider camp asleep in view; she walks in after the first frames and it wakes.
bash "$STRIP" "$OUT" outpost 6 0.7 "$PRE
Combat.add_outpost(s, \"raider_camp\", p + Vector2(4.5, -3), Vector2i(0, 1), 3)
main._add_outpost_view(s.outposts.size() - 1)
var to = Vector3(p.x + 1.5, 0, p.y - 1.0)
get_tree().create_timer(3.2).timeout.connect(func(): m.walk_to(to))
emit(1)"

swallowtail runtime eval --code 'var s = Game.engine.state
for w in s.wolves:
	if w.outpost >= 0:
		w.hp = 0.0
emit(1)' >/dev/null 2>&1
sleep 0.6
swallowtail runtime screenshot --save_path "$OUT/outpost_cleared.png" >/dev/null 2>&1

# The HUD as a wave is announced: wave 8 due in 12 s, the last wave's stragglers off screen.
swallowtail runtime eval --code "$PRE
s.wave = 7
s.raid_on = true
for i in 4:
	add.call(\"wolf\", p + Vector2(22 + i, -4 + i), 1.0)
s.attack_at = s.time + Balance.WAVE_WARNING - 3.0
emit(1)" >/dev/null 2>&1
sleep 1.2
swallowtail runtime screenshot --save_path "$OUT/wave_hud.png" >/dev/null 2>&1

# The Armory sheet at level 3.
swallowtail runtime eval --code "$PRE
var i = -1
for k in s.sites.size():
	if s.sites[k].type == \"armory\":
		i = k
if s.sites[i].building == \"\":
	e.start_construction(i)
	e.dev_level_up(i)
e.dev_level_up(i)
e.dev_level_up(i)
s.piles.materials = 8.0
emit(i)" >/dev/null 2>&1
sleep 1.5
swallowtail runtime eval --code 'var s = Game.engine.state
for k in s.sites.size():
	if s.sites[k].building == "armory":
		get_tree().current_scene._hud.sheet.open_site(k)
emit(1)' >/dev/null 2>&1
sleep 1.0
swallowtail runtime screenshot --save_path "$OUT/armory_sheet.png" >/dev/null 2>&1
swallowtail runtime eval --code 'get_tree().current_scene._hud.sheet.close()
Engine.time_scale = 1.0
emit(1)' >/dev/null 2>&1
echo "all done"
