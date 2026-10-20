class_name WolfView
extends Node3D
## An enemy drawn where the engine says it is: any of `Balance.ENEMIES` (the class keeps the
## wolf's name, as `state.wolves` does).
##
## Wolves use the Tripo wolf (`wolf.glb`) when it's there, posed bone by bone: a trot while it runs
## and a lunge while it fights. Foxes are the same wolf, smaller and recoloured, with a big tail.
## Bears, trolls and raiders are greybox until their models are made, each built silhouette first
## (ChatGPT's steer, fight_v2: broad shoulders, a tall lopsided ice back, an upright hood and
## satchel) and posed by its attack. Every attack shows its tell on the snow while it winds up: a
## wedge for a bite or swipe, a ring for a slam, a target where a shard will land.

const MODEL_PATH := "res://assets/models/blender/wolf.glb"
## Drawn larger than life (1.3 m long in the file), so it reads from the game camera.
const MODEL_SCALE := 1.5
## Sizes by kind, as a wolf's footprint (fight_v2 review 1): fox 0.8, wolf 1, bear 1.5, troll
## 1.8, so a crowd sorts itself at a glance. A fox is a smaller, lower wolf, painted rust-orange
## over the wolf's grey; a wolf is a little broad in the shoulder.
const FOX_SCALE := 0.8
const FOX_LOW := 0.82
const WOLF_BROAD := 1.12
const BEAR_SCALE := 1.15
const TROLL_SCALE := 1.08
const FOX_TINT := Color(1.0, 0.58, 0.32)
const FOX_FUR := Color(0.85, 0.45, 0.2)
## The bones the trot and lunge move, by the end of their names (Tripo's auto-rig names them
## `tripo::…` or `bone_N`; Godot turns the colons into underscores). The model faces +Z.
const BONES := {
	"leg_fl": "bone_13", "leg_fr": "bone_19", "leg_hl": "bone_1", "leg_hr": "bone_6",
	"knee_fl": "0_Left_Limb_1", "knee_fr": "0_Right_Limb_1",
	"knee_hl": "1_Left_Limb_1", "knee_hr": "1_Right_Limb_1",
	"back": "Spine_0", "neck": "Spine_3", "tail": "bone_36",
}
## Trot: diagonal pairs move together, so the front left steps with the hind right.
const GAIT_PHASE := {"fl": 0.0, "hr": 0.0, "fr": PI, "hl": PI}
const LEG_SWING := 28.0
const KNEE_LIFT := 35.0
const TAIL_WAG := 18.0
## Trot cycle speed (radians per second): one full stride in about half a second.
const TROT_SPEED := 13.0
## An attack follows the engine's (Combat._attack): its tell (a crouch or a wind-up, the time to
## step away), a quick strike, a few frames held, then recover. Heavy hitters hold their strike
## pose for most of their recovery, slumped, so the opening to step in reads (fight_v2 review 1;
## review 3: bear 0.35 s, troll 0.45 s).
const ATTACK_HOLD := 0.05
const HEAVY_HOLD := {"bear": 0.42, "troll": 0.55}
## How far it leans back while crouching to strike, in degrees.
const ATTACK_LEAN_BACK := 12.0
## Tells (fight_v2 reviews 1 and 2): one muted terracotta treatment (ink/tell.gdshader), a light
## wash over the whole danger zone with a soft-edged fill advancing from the attacker to the edge
## as the strike comes (15-20% in all), and a dark-rust boundary, about 2 px on a 540-wide phone
## while the aim follows and 3 px once it locks. Rust is for tells only.
const TELL_SHADER := preload("res://scripts/game/ink/tell.gdshader")
const TELL_COLOR := Color(0.66, 0.3, 0.2)
const TELL_LINE := Color(0.38, 0.12, 0.07, 1.0)
const TELL_LINE_THIN := 0.05
const TELL_LINE_WIDTH := 0.075
## A struck enemy: a warm rim flash this long (no white-out, so its shape reads through the hit),
## and a recoil away from the hit, by the blow (review 2: about 4 px for a snowball or a guard's
## spear, 7 px for her sweep, 10 px for a heavy blow), out and back over RECOIL_TIME.
const FLASH_TIME := 0.08
const FLASH_STRENGTH := 0.7
const RECOIL := {"light": 0.11, "sweep": 0.14, "heavy": 0.16}
const RECOIL_TIME := 0.17
## Struck, it freezes this long (its own hit-stop; the game keeps running, review 4).
const HIT_FREEZE := 0.06
const RIM_FLASH := preload("res://scripts/game/ink/rim_flash.gdshader")
## Where each kind's health bar and sack sit, and how far back it stands from whoever it fights
## (so its front, not its middle, is at the engine's fight distance; view only). [proto]
const LOOK := {
	"fox": {"bar": 0.95, "back_off": 0.3},
	"wolf": {"bar": 1.62, "back_off": 0.5},
	"bear": {"bar": 2.0, "back_off": 0.7},
	"troll": {"bar": 3.4, "back_off": 0.6},
	"raider": {"bar": 2.1, "back_off": 0.0},
}

var kind := "wolf"
## An outpost's sleeper lies low: 1 asleep, 0 up and about, in between while it gets up (PeopleLayer
## sets it from the outpost; fight_v2 review 1).
var rest := 0.0
var _def: Dictionary
var _model: Node3D
var _hp_bar: HpBar
var _t := 0.0
## A visual nudge apart from enemies standing too close (PeopleLayer sets it), so a pack never
## reads as one dark mass; the engine's positions don't change (Astra animation review).
var nudge := Vector3.ZERO
var _attack := -1.0
var _flash := 0.0
var _recoil := 0.0
var _recoil_dir := Vector3.ZERO
var _recoil_size := 0.0
var _freeze := 0.0
## The posed wolf model (wolves and foxes), or null for a greybox body.
var _pivot: Node3D
var _skeleton: Skeleton3D
var _bone := {}  # key -> bone index
var _rest := {}  # bone index -> rest Basis in skeleton space
var _skins: Array[MeshInstance3D] = []
var _flash_mat: ShaderMaterial
## Greybox bodies' moving parts, by name.
var _parts := {}
var _tail: Node3D
var _tell: Node3D
var _tell_zone: MeshInstance3D
var _tell_zone_mat: ShaderMaterial
var _tell_line_thin: MeshInstance3D
var _tell_line: MeshInstance3D
## Once locked, a cream keyline just outside the dark boundary (review 4: the lock reads as a
## change of state, not a shade of the warning; review 5: 3 px each).
var _tell_key: MeshInstance3D
const TELL_KEY := Color(0.98, 0.94, 0.86, 1.0)
const TELL_KEY_WIDTH := 0.075
## While it recovers from its strike (the counter window, Balance.RECOVERY_DAMAGE_MULT), a broken
## ochre halo lies under its feet, for exactly that long (review 5).
var _halo: MeshInstance3D
const HALO := Color(0.86, 0.62, 0.22, 0.9)
## How far its health bar is raised to clear a neighbour's (PeopleLayer sets it; review 2), with a
## thin line down to its owner once it's lifted (review 3).
var bar_lift := 0.0
var _bar_height := 0.0
var _bar_link: MeshInstance3D
var _shot_line: MeshInstance3D
var _sack: Sprite3D
var _sack_disc: Sprite3D
var _sack_res := ""
## The stolen load on its back while it runs off (fight_v2 review 1: a laden retreat that reads).
var _load: Node3D
## The nearest thief's badge (fight_v2 review 2, only that one; the rest show their sacks): a cream
## capsule with a terracotta border (review 5: a pursuit objective, not loot), a sack and how
## much it carries, on a stem from its bar.
const BADGE_PIXEL := 0.0045
const LADEN_LEAN := 9.0
static var _disc: Texture2D
## Whether this one wears the badge (PeopleLayer picks the nearest thief).
var badge := false
var _badge_amount: Label3D
var _badge_bag: Sprite3D
var _badge_stem: MeshInstance3D


func _init(enemy_kind := "wolf") -> void:
	kind = enemy_kind
	_def = Balance.ENEMIES[kind]
	_model = Node3D.new()
	add_child(_model)
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = RIM_FLASH
	match kind:
		"wolf", "fox":
			if ResourceLoader.exists(MODEL_PATH):
				_build_model()
			else:
				_build_greybox_wolf()
			if kind == "fox":
				_add_fox_tail()
		"bear":
			_build_bear()
		"troll":
			_build_troll()
		"raider":
			_build_raider()
	if _skins.is_empty():
		for mesh in _model.find_children("*", "MeshInstance3D", true, false):
			_skins.append(mesh)
	# Snow doesn't settle on animals: the ink look's snow caps read as shiny highlights (review 2).
	for mesh in _skins:
		mesh.set_meta("no_snow", true)
	_build_tell()
	var look: Dictionary = LOOK[kind]
	_hp_bar = HpBar.new(HpBar.WOLF_RED)
	_bar_height = look.bar
	_hp_bar.position = Vector3(0, look.bar, 0)
	_bar_link = MeshInstance3D.new()
	var link := BoxMesh.new()
	link.size = Vector3(0.045, 1.0, 0.045)
	_bar_link.mesh = link
	var link_mat := StandardMaterial3D.new()
	link_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	link_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	link_mat.albedo_color = Color(0.17, 0.2, 0.25, 0.7)
	link_mat.no_depth_test = true
	link_mat.render_priority = 19
	_bar_link.material_override = link_mat
	_bar_link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_link.visible = false
	add_child(_bar_link)
	add_child(_hp_bar)
	_sack_disc = Sprite3D.new()
	_sack_disc.texture = _badge_disc()
	_sack_disc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sack_disc.no_depth_test = true
	_sack_disc.render_priority = 10
	_sack_disc.pixel_size = BADGE_PIXEL
	_sack_disc.position = Vector3(0, look.bar + 0.5, 0)
	_sack_disc.visible = false
	add_child(_sack_disc)
	_sack = Sprite3D.new()
	_sack.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sack.no_depth_test = true
	_sack.render_priority = 11
	_sack.pixel_size = BADGE_PIXEL * 0.7
	_sack.position = _sack_disc.position
	_sack.visible = false
	add_child(_sack)
	_badge_amount = Shapes.label("", _sack_disc.position, 64, Color("2c3440"))
	_badge_amount.pixel_size = 0.0062
	_badge_amount.outline_size = 0
	_badge_amount.render_priority = 12
	_badge_amount.visible = false
	add_child(_badge_amount)
	_badge_bag = Sprite3D.new()
	_badge_bag.texture = load("res://assets/ui/icons/bag.png")
	_badge_bag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge_bag.no_depth_test = true
	_badge_bag.render_priority = 11
	_badge_bag.pixel_size = 0.0026
	_badge_bag.visible = false
	add_child(_badge_bag)
	_badge_stem = MeshInstance3D.new()
	var stem := BoxMesh.new()
	stem.size = Vector3(0.045, 1.0, 0.045)
	_badge_stem.mesh = stem
	var stem_mat := StandardMaterial3D.new()
	stem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stem_mat.albedo_color = Color(0.17, 0.2, 0.25)
	stem_mat.no_depth_test = true
	stem_mat.render_priority = 9
	_badge_stem.material_override = stem_mat
	_badge_stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_badge_stem.visible = false
	add_child(_badge_stem)
	_load = Node3D.new()
	_load.visible = false
	_model.add_child(_load)
	var height: float = look.bar * 0.62
	_load.add_child(Shapes.sphere(0.26, Color(0.62, 0.48, 0.3), Vector3(0, height, -0.15)))
	_load.add_child(Shapes.cylinder(0.08, 0.14, Color(0.45, 0.33, 0.2), Vector3(0, height + 0.27, -0.15)))


# ---------- Bodies ----------

func _build_model() -> void:
	_pivot = Node3D.new()
	_pivot.scale = Vector3.ONE * MODEL_SCALE * (FOX_SCALE if kind == "fox" else 1.0)
	if kind == "fox":
		_pivot.scale.y *= FOX_LOW
	else:
		_pivot.scale.x *= WOLF_BROAD
	_model.add_child(_pivot)
	var model: Node3D = load(MODEL_PATH).instantiate()
	_pivot.add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for key in BONES:
		_bone[key] = -1
		for i in _skeleton.get_bone_count():
			var bone_name := _skeleton.get_bone_name(i)
			if bone_name == BONES[key] or bone_name.ends_with("_" + BONES[key]):
				_bone[key] = i
				break
		if _bone[key] < 0:
			push_error("WolfView: %s has no bone %s" % [MODEL_PATH, BONES[key]])
	for i in _skeleton.get_bone_count():
		_rest[i] = _skeleton.get_bone_global_rest(i).basis.orthonormalized()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		_skins.append(mesh)
		if kind == "fox":
			_tint(mesh, FOX_TINT)


## Its own copy of each material, the colour multiplied by `tint` (the ink look keeps it).
func _tint(mesh: MeshInstance3D, tint: Color) -> void:
	for i in mesh.mesh.get_surface_count():
		var m := mesh.mesh.surface_get_material(i) as BaseMaterial3D
		if m == null:
			continue
		var copy := m.duplicate() as BaseMaterial3D
		copy.albedo_color = m.albedo_color * tint
		mesh.set_surface_override_material(i, copy)


func _build_greybox_wolf() -> void:
	var fur := FOX_FUR if kind == "fox" else Color(0.42, 0.42, 0.46)
	var body := Node3D.new()
	body.scale = Vector3.ONE * (FOX_SCALE if kind == "fox" else 1.0)
	_model.add_child(body)
	body.add_child(Shapes.capsule(0.28, 1.2, fur, Vector3(0, 0.55, 0)))
	body.get_child(-1).rotation_degrees.x = 90.0
	body.add_child(Shapes.sphere(0.24, fur, Vector3(0, 0.75, 0.6)))
	body.add_child(Shapes.box(Vector3(0.14, 0.12, 0.3), fur.darkened(0.3), Vector3(0, 0.7, 0.85)))
	body.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(-0.12, 1.0, 0.55)))
	body.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(0.12, 1.0, 0.55)))
	for x in [-0.15, 0.15]:
		for z in [-0.35, 0.35]:
			body.add_child(Shapes.cylinder(0.06, 0.35, fur.darkened(0.2), Vector3(x, 0.17, z)))
	_parts.body = body


## The fox's silhouette is its tail: big, bushy, white-tipped, held up behind it.
func _add_fox_tail() -> void:
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.55, -0.62)
	_model.add_child(_tail)
	var brush := Shapes.capsule(0.17, 0.85, FOX_FUR, Vector3(0, 0.12, -0.34))
	brush.rotation_degrees.x = 60.0
	_tail.add_child(brush)
	_tail.add_child(Shapes.sphere(0.15, Color(0.96, 0.94, 0.9), Vector3(0, 0.33, -0.72)))


## A bear: broad, humped shoulders over a low heavy body; it rears up to swipe.
func _build_bear() -> void:
	var fur := Color(0.4, 0.29, 0.22)
	var dark := fur.darkened(0.3)
	# Wide and low (review 1): the whole bear a size up, and broader than it is tall.
	var size := Node3D.new()
	size.scale = Vector3(1.2, 0.92, 1.0) * BEAR_SCALE
	_model.add_child(size)
	# It rears about its hind legs, so the body hangs off a pivot there.
	var rear := Node3D.new()
	rear.position = Vector3(0, 0, -0.55)
	size.add_child(rear)
	var body := Node3D.new()
	body.position = Vector3(0, 0, 0.55)
	rear.add_child(body)
	var trunk := Shapes.capsule(0.58, 1.8, fur, Vector3(0, 0.82, 0))
	trunk.rotation_degrees.x = 90.0
	body.add_child(trunk)
	body.add_child(Shapes.sphere(0.6, fur, Vector3(0, 1.22, 0.32)))
	body.add_child(Shapes.sphere(0.36, fur, Vector3(0, 1.1, 1.0)))
	body.add_child(Shapes.box(Vector3(0.26, 0.2, 0.3), Color(0.62, 0.5, 0.4), Vector3(0, 1.0, 1.32)))
	body.add_child(Shapes.sphere(0.07, Color(0.1, 0.08, 0.08), Vector3(0, 1.04, 1.48)))
	for x in [-0.22, 0.22]:
		body.add_child(Shapes.sphere(0.11, dark, Vector3(x, 1.42, 0.92)))
	for z in [-0.55]:
		for x in [-0.34, 0.34]:
			rear.add_child(Shapes.cylinder(0.18, 0.62, dark, Vector3(x, 0.31, 0.55 + z)))
	for x in [-0.36, 0.36]:
		var paw := Node3D.new()
		paw.position = Vector3(x, 0.75, 0.55)
		body.add_child(paw)
		paw.add_child(Shapes.cylinder(0.19, 0.75, dark, Vector3(0, -0.37, 0)))
		_parts["paw_r" if x > 0 else "paw_l"] = paw
	_parts.rear = rear


## An ice troll: tall and stooped, a lopsided ridge of ice up its back, long arms with heavy
## fists it raises and brings down in a slam.
func _build_troll() -> void:
	# Three value groups: its hide, a darker hide for legs, fists and jaw, and the pale ice.
	var hide := Color(0.52, 0.6, 0.68)
	var dark := hide.darkened(0.22)
	var ice := Color(0.8, 0.9, 0.98)
	var body := Node3D.new()
	body.scale = Vector3.ONE * TROLL_SCALE
	_model.add_child(body)
	var trunk := Shapes.capsule(0.62, 1.9, hide, Vector3(0, 1.55, -0.05))
	trunk.rotation_degrees.x = 12.0
	body.add_child(trunk)
	body.add_child(Shapes.sphere(0.34, hide, Vector3(0, 2.6, 0.35)))
	body.add_child(Shapes.box(Vector3(0.36, 0.14, 0.12), dark, Vector3(0, 2.48, 0.62)))
	# Broad shoulders that run into the arms, so the joints don't read as separate balls.
	for x in [-0.6, 0.6]:
		body.add_child(Shapes.sphere(0.42, hide, Vector3(x, 2.2, 0.05)))
	# The ice on its back, bigger on the left: its outline is lopsided from every side.
	var spikes := [[Vector3(-0.3, 2.45, -0.45), 0.3, 0.9], [Vector3(-0.42, 2.0, -0.55), 0.25, 0.75],
			[Vector3(0.22, 2.3, -0.48), 0.18, 0.5], [Vector3(-0.1, 2.75, -0.3), 0.2, 0.6]]
	for sp in spikes:
		var c := Shapes.cone(sp[1], sp[2], ice, sp[0])
		c.rotation_degrees.x = -40.0
		body.add_child(c)
	for x in [-0.32, 0.32]:
		body.add_child(Shapes.cylinder(0.26, 0.85, dark, Vector3(x, 0.42, 0)))
	for x in [-0.82, 0.82]:
		var arm := Node3D.new()
		arm.position = Vector3(x, 2.25, 0.1)
		body.add_child(arm)
		# Oversized forearms and fists (review 1): its slam reads from its outline.
		arm.add_child(Shapes.capsule(0.24, 0.9, hide, Vector3(0, -0.38, 0)))
		arm.add_child(Shapes.capsule(0.33, 0.95, hide, Vector3(0, -1.0, 0.03)))
		arm.add_child(Shapes.sphere(0.46, dark, Vector3(0, -1.48, 0.06)))
		_parts["arm_r" if x > 0 else "arm_l"] = arm
	_parts.body = body


## A raider: upright, hooded, a satchel at the hip for what it steals; it raises an ice shard
## behind its head and throws.
func _build_raider() -> void:
	var coat := Color(0.27, 0.29, 0.38)
	var hood := Color(0.2, 0.21, 0.28)
	var body := Node3D.new()
	_model.add_child(body)
	body.add_child(Shapes.capsule(0.3, 1.25, coat, Vector3(0, 0.92, 0)))
	body.add_child(Shapes.cylinder(0.32, 0.12, Color(0.78, 0.6, 0.25), Vector3(0, 1.38, 0)))
	body.add_child(Shapes.sphere(0.22, Color(0.85, 0.72, 0.6), Vector3(0, 1.66, 0.04)))
	var cowl := Shapes.cone(0.3, 0.55, hood, Vector3(0, 1.82, -0.04))
	body.add_child(cowl)
	body.add_child(Shapes.box(Vector3(0.34, 0.3, 0.16), Color(0.5, 0.36, 0.22), Vector3(-0.34, 0.85, 0.02)))
	for x in [-0.13, 0.13]:
		body.add_child(Shapes.cylinder(0.1, 0.4, hood, Vector3(x, 0.2, 0)))
	var arm := Node3D.new()
	arm.position = Vector3(0.36, 1.35, 0)
	body.add_child(arm)
	arm.add_child(Shapes.capsule(0.09, 0.62, coat, Vector3(0, -0.3, 0)))
	var shard := Shapes.cone(0.08, 0.32, Color(0.78, 0.9, 1.0), Vector3(0, -0.68, 0))
	shard.rotation_degrees.x = 180.0
	shard.visible = false
	arm.add_child(shard)
	_parts.arm_r = arm
	_parts.shard = shard
	_parts.body = body


# ---------- Tells ----------

func _build_tell() -> void:
	# Pinned to the snow where the engine judges the strike from (Combat._attack's tell_from and
	# aim), not to the drawn body, so what it shows is exactly what it hits.
	_tell = Node3D.new()
	_tell.top_level = true
	_tell.visible = false
	add_child(_tell)
	var full: Mesh
	var thin: Mesh
	var line: Mesh
	match _def.shape:
		"wedge":
			full = sector(0.0, _def.reach, _def.arc)
			thin = _wedge_outline(_def.reach, _def.arc, TELL_LINE_THIN)
			line = _wedge_outline(_def.reach, _def.arc, TELL_LINE_WIDTH)
			var widen: float = rad_to_deg(TELL_KEY_WIDTH * 1.4 / _def.reach) * 2.0
			_tell_key = _ground_mesh(_wedge_outline(_def.reach + TELL_KEY_WIDTH, _def.arc + widen, TELL_KEY_WIDTH * 1.6), TELL_KEY)
		_:
			# A slam's ring round it, or a shard's target where it will land.
			full = sector(0.0, _def.reach, 360.0)
			thin = sector(_def.reach - TELL_LINE_THIN, _def.reach, 360.0)
			line = sector(_def.reach - TELL_LINE_WIDTH, _def.reach, 360.0)
			_tell_key = _ground_mesh(sector(_def.reach, _def.reach + TELL_KEY_WIDTH, 360.0), TELL_KEY)
	_tell_zone = MeshInstance3D.new()
	_tell_zone.mesh = full
	_tell_zone_mat = ShaderMaterial.new()
	_tell_zone_mat.shader = TELL_SHADER
	_tell_zone_mat.set_shader_parameter("color", TELL_COLOR)
	_tell_zone_mat.set_shader_parameter("reach", _def.reach)
	_tell_zone.material_override = _tell_zone_mat
	_tell_zone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tell_line_thin = _ground_mesh(thin, TELL_LINE)
	_tell_line = _ground_mesh(line, TELL_LINE)
	for mi in [_tell_zone, _tell_key, _tell_line_thin, _tell_line]:
		_tell.add_child(mi)
	_tell_key.position.y = 0.005
	_halo = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.orientation = PlaneMesh.FACE_Y
	quad.size = Vector2.ONE * _def.width * 1.9
	_halo.mesh = quad
	var halo_mat := StandardMaterial3D.new()
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.albedo_texture = Fx.broken_ring_texture()
	halo_mat.albedo_color = HALO
	_halo.material_override = halo_mat
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position.y = 0.05
	_halo.visible = false
	add_child(_halo)
	_tell_line_thin.position.y = 0.01
	_tell_line.position.y = 0.01
	if _def.shape == "shot":
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.01, 1.0)
		_shot_line = _ground_mesh(box, Color(TELL_LINE, 0.3))
		_shot_line.top_level = true
		_shot_line.visible = false
		add_child(_shot_line)


## A flat ring sector on the snow (radius `inner` to `outer`, `arc` degrees about +Z).
static func sector(inner: float, outer: float, arc: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(10, int(arc / 8.0))
	for i in steps:
		var a0 := deg_to_rad(-arc / 2.0 + arc * i / steps)
		var a1 := deg_to_rad(-arc / 2.0 + arc * (i + 1) / steps)
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		st.add_vertex(d0 * inner)
		st.add_vertex(d1 * outer)
		st.add_vertex(d0 * outer)
		if inner > 0.0:
			st.add_vertex(d0 * inner)
			st.add_vertex(d1 * inner)
			st.add_vertex(d1 * outer)
	return st.commit()


## A wedge's outline, `w` wide: its arc and its two straight sides.
func _wedge_outline(reach: float, arc: float, w: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := maxi(10, int(arc / 8.0))
	for i in steps:
		var a0 := deg_to_rad(-arc / 2.0 + arc * i / steps)
		var a1 := deg_to_rad(-arc / 2.0 + arc * (i + 1) / steps)
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		for tri in [[d0 * (reach - w), d1 * reach, d0 * reach], [d0 * (reach - w), d1 * (reach - w), d1 * reach]]:
			for v in tri:
				st.add_vertex(v)
	for sgn in [-1.0, 1.0]:
		var a := deg_to_rad(sgn * arc / 2.0)
		var d := Vector3(sin(a), 0, cos(a))
		var side := d.cross(Vector3.UP) * w * 0.5
		for v in [-side, d * reach - side, d * reach + side, -side, d * reach + side, side]:
			st.add_vertex(v)
	return st.commit()


func _ground_mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Shown while it winds up, fading in: the wash marks the whole zone, the fill advances from the
## attacker to the edge as the strike comes, and the boundary firms up when the aim locks.
func _update_tell(enemy: Dictionary) -> void:
	var t: float = enemy.get("bite_t", -1.0)
	var strike: float = _def.tell + (Balance.ENEMY_LUNGE if _def.shape == "wedge" else 0.0)
	var on: bool = t >= 0.0 and t < strike and enemy.has("aim")
	_tell.visible = on
	if _shot_line:
		_shot_line.visible = on
	if not on:
		return
	var fade := clampf(t / 0.1, 0.0, 1.0)
	var locked := t >= strike - Combat.lock_of(_def)
	_tell_zone_mat.set_shader_parameter("fade", fade)
	# The fill advances until the lock, then holds (review 4).
	var lock_at: float = strike - Combat.lock_of(_def)
	_tell_zone_mat.set_shader_parameter("progress", clampf(minf(t, lock_at) / strike, 0.0, 1.0) * 1.25)
	_tell_line_thin.visible = not locked
	_tell_line.visible = locked
	_tell_key.visible = locked
	(_tell_line_thin.material_override as StandardMaterial3D).albedo_color.a = 0.85 * fade
	var from: Vector2 = enemy.get("tell_from", enemy.pos)
	var at := Vector3(from.x, 0.04, from.y)
	var aim := Vector3(enemy.aim.x, 0.04, enemy.aim.y)
	match _def.shape:
		"wedge":
			_tell.global_position = at
			var to := aim - at
			if to.length() > 0.01:
				_tell.rotation.y = atan2(to.x, to.z)
		"ring":
			_tell.global_position = at
		"shot":
			_tell.global_position = aim
			var hand := global_position + Vector3(0, 0.04, 0)
			_shot_line.global_position = (hand + aim) / 2.0
			_shot_line.scale = Vector3(1, 1, maxf(0.01, hand.distance_to(aim)))
			if hand.distance_to(aim) > 0.05:
				_shot_line.look_at(aim, Vector3.UP)


# ---------- Life ----------

## Where a blow from `from` meets its body: on its outline facing the blow, at chest height.
func contact_point(from: Vector3) -> Vector3:
	var to := from - global_position
	to.y = 0.0
	var reach: float = _def.width * 0.5
	return global_position + (to.normalized() * reach if to.length() > 0.01 else Vector3.ZERO) + Vector3(0, LOOK[kind].bar * 0.45, 0)


## The badge's look, for the thief's edge arrow (ThreatArrows draws the same disc and number).
static func badge_disc() -> Texture2D:
	return _badge_disc()


## Meagan has picked it: its health bar's border lights up a moment (review 2: the chosen target
## shows where it already looks, no extra ground ring).
func accent() -> void:
	_hp_bar.accent()


## Struck from `from`: a short warm rim flash and a recoil away from the hit (fight_v2 review 1;
## the ink flecks are main's).
func hit(from := Vector3.INF, blow := "light") -> void:
	_flash = FLASH_TIME
	_recoil = RECOIL_TIME
	_recoil_size = RECOIL[blow]
	_freeze = HIT_FREEZE
	var away := global_position - from if from != Vector3.INF else -_model.basis.z
	away.y = 0.0
	_recoil_dir = away.normalized() if away.length() > 0.01 else Vector3.BACK


## Beaten (agreed 2026-10-20): it tumbles, scrambles up and runs off, fading. No corpse.
func die() -> void:
	_hp_bar.visible = false
	_tell.visible = false
	_sack.visible = false
	_sack_disc.visible = false
	_badge_amount.visible = false
	_badge_bag.visible = false
	_badge_stem.visible = false
	_load.visible = false
	if _shot_line:
		_shot_line.visible = false
	Fx.burst("snow_big", global_position + Vector3(0, 0.4, 0))
	var away := -_model.basis.z
	var t := create_tween()
	t.tween_property(_model, "rotation:z", 1.4, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(_model, "rotation:z", 0.0, 0.3).set_delay(0.1)
	t.tween_property(self, "global_position", global_position + away * 4.0, 0.6)
	t.parallel().tween_property(self, "scale", Vector3.ONE * 0.2, 0.6).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func sync(enemy: Dictionary, delta: float) -> void:
	# Its hit-stop: a beat with nothing moving but the flash.
	if _freeze > 0.0:
		_freeze -= delta
		_flash_mat.set_shader_parameter("strength", FLASH_STRENGTH)
		return
	var target := Vector3(enemy.pos.x, 0, enemy.pos.y)
	var fighting: bool = enemy.mode == "fight"
	if fighting and enemy.has("foe_pos"):
		var away := Vector3(enemy.pos.x - enemy.foe_pos.x, 0, enemy.pos.y - enemy.foe_pos.y)
		if away.length() > 0.01:
			target += away.normalized() * LOOK[kind].back_off
	var step := target - global_position
	if fighting and enemy.has("foe_pos"):
		# Face whoever it's fighting, not the way it last stepped.
		step = Vector3(enemy.foe_pos.x, 0, enemy.foe_pos.y) - global_position
	var moving := step.length() > 0.02
	if step.length() > 0.01:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(step.x, step.z), 10.0 * delta)
	global_position = global_position.lerp(target + nudge, minf(1.0, 12.0 * delta))
	if _attack < 0.0 and _t == 0.0:
		# Each one's stride starts at its own point in the cycle, so a pack doesn't trot in unison.
		_t = float(enemy.id) * 1.7
	_attack = enemy.get("bite_t", -1.0)
	_flash = maxf(0.0, _flash - delta)
	_recoil = maxf(0.0, _recoil - delta)
	# Out and back: half a sine over the recoil's time.
	# A quick shove out, an easier return.
	var u := 1.0 - _recoil / RECOIL_TIME
	var recoil := _recoil_dir * _recoil_size * (sin(PI * minf(u * 2.5, 1.0) / 2.0) * (1.0 - smoothstep(0.3, 1.0, u))) if _recoil > 0.0 else Vector3.ZERO
	var asleep := rest > 0.99
	_t += delta * (0.0 if asleep else (14.0 if fighting else TROT_SPEED * _def.speed / 2.5))
	var lunge := _lunge() if fighting else 0.0
	_model.position = recoil
	# Laden, it runs off head down (the engine also slows it, Balance.CARRY_SPEED).
	var laden: bool = not enemy.get("carry", {}).is_empty()
	_model.rotation.x = lerp_angle(_model.rotation.x, deg_to_rad(LADEN_LEAN if laden else 0.0), 8.0 * delta)
	if _pivot:
		_pose(fighting, lunge)
	else:
		_pose_greybox(fighting, lunge, moving)
	if rest > 0.0:
		_lie_down(rest)
	if _tail:
		_tail.rotation.y = deg_to_rad(16.0 * sin(_t)) if not fighting else deg_to_rad(5.0 * sin(_t))
		_tail.rotation.x = deg_to_rad(-12.0 if fighting else 0.0)
	var flashing := _flash > 0.0
	_flash_mat.set_shader_parameter("strength", FLASH_STRENGTH * _flash / FLASH_TIME)
	for mesh in _skins:
		mesh.material_overlay = _flash_mat if flashing else null
	_hp_bar.set_value(enemy.hp / enemy.max_hp)
	_hp_bar.position.y = lerpf(_hp_bar.position.y, _bar_height + bar_lift, minf(1.0, 10.0 * delta))
	var lifted := _hp_bar.position.y - _bar_height
	_bar_link.visible = _hp_bar.visible and lifted > 0.2
	if _bar_link.visible:
		_bar_link.position.y = _bar_height - 0.1 + lifted / 2.0
		_bar_link.scale.y = lifted
	# The thief's badge hangs just above its bar on a short stem, a sack beside the amount.
	_sack_disc.position = Vector3(0.0, _hp_bar.position.y + 0.5, 0)
	_badge_amount.position = _sack_disc.position + Vector3(0.16, 0, 0)
	_badge_bag.position = _sack_disc.position + Vector3(-0.2, 0, 0)
	_badge_stem.position = Vector3(0, _hp_bar.position.y + 0.2, 0)
	_badge_stem.scale.y = 0.28
	_update_tell(enemy)
	_update_sack(enemy)
	var t: float = enemy.get("bite_t", -1.0)
	_halo.visible = t >= _def.tell + (Balance.ENEMY_LUNGE if _def.shape == "wedge" else 0.0)
	if _halo.visible:
		_halo.rotation.y += delta * 1.5


## A carrier shows what it took: a sack-sized icon of the resource it carries most of.
func _update_sack(enemy: Dictionary) -> void:
	var carry: Dictionary = enemy.get("carry", {})
	var most := ""
	for res in carry:
		if most == "" or carry[res] > carry[most]:
			most = res
	_load.visible = most != ""
	_sack.visible = false
	_sack_disc.visible = most != "" and badge
	_badge_amount.visible = _sack_disc.visible
	_badge_bag.visible = _sack_disc.visible
	_badge_stem.visible = _sack_disc.visible
	if _sack_disc.visible:
		var total := 0.0
		for res in carry:
			total += carry[res]
		_badge_amount.text = Fmt.num(total)
	if most != "" and most != _sack_res:
		_sack_res = most
		_sack.texture = load("res://assets/ui/icons/%s.png" % most)


## The capsule behind a thief's badge: cream with a terracotta border, drawn once.
static func _badge_disc() -> Texture2D:
	if _disc == null:
		var w := 200
		var h := 100
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var r := h / 2.0 - 2.0
		for y in h:
			for x in w:
				# Distance outside a horizontal segment, so the ends are round.
				var px := clampf(x + 0.5, r + 2.0, w - r - 2.0)
				var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(px, h / 2.0))
				var col := Color(0, 0, 0, 0)
				if d <= r:
					col = Color(0.66, 0.3, 0.2) if d > r - 9.0 else Color(0.99, 0.95, 0.87)
					col.a = clampf(r + 0.5 - d, 0.0, 1.0)
				img.set_pixel(x, y, col)
		_disc = ImageTexture.create_from_image(img)
	return _disc


## A quick pulse on the badge (twice over 600 ms, review 5), when she's back up to chase it.
func pulse_badge() -> void:
	var t := create_tween()
	for i in 2:
		t.tween_property(_sack_disc, "scale", Vector3.ONE * 1.35, 0.15)
		t.tween_property(_sack_disc, "scale", Vector3.ONE, 0.15)


## An outpost's sleeper: low to the ground, head down (a raider sits, its shard put away); by
## `amount` (1 asleep), so waking up is a visible stand-up.
func _lie_down(amount: float) -> void:
	match kind:
		"wolf", "fox":
			if _pivot:
				for leg in GAIT_PHASE:
					_turn_bone(_bone["leg_" + leg], Basis(Vector3.RIGHT, deg_to_rad((-50.0 if leg.begins_with("f") else 45.0) * amount)))
					_turn_bone(_bone["knee_" + leg], Basis(Vector3.RIGHT, deg_to_rad(80.0 * amount)))
				_turn_bone(_bone.neck, Basis(Vector3.RIGHT, deg_to_rad(25.0 * amount)))
				_turn_bone(_bone.tail, Basis(Vector3.UP, deg_to_rad(40.0 * amount)))
				_pivot.position.y -= 0.32 * amount * _pivot.scale.y / MODEL_SCALE
			else:
				_model.position.y -= 0.3 * amount
		"raider":
			_model.position.y -= 0.42 * amount
			_parts.arm_r.rotation_degrees.x = lerpf(_parts.arm_r.rotation_degrees.x, 0.0, amount)
			_parts.shard.visible = _parts.shard.visible and amount < 0.5
			_parts.body.rotation_degrees.x = 14.0 * amount
		"bear":
			_model.position.y -= 0.35 * amount
			_parts.rear.rotation_degrees.x = 8.0 * amount
		"troll":
			_model.position.y -= 0.6 * amount
			_parts.body.rotation_degrees.x = 22.0 * amount


## Poses the wolf model: a trot while it runs, a lunge and snap while it fights.
func _pose(fighting: bool, lunge: float) -> void:
	for leg in GAIT_PHASE:
		var swing := 0.0
		var lift := 0.0
		if fighting:
			# Front paws reach out and hind legs push off as it strikes.
			swing = (-35.0 if leg.begins_with("f") else 25.0) * lunge
			# Crouching back bends every knee.
			lift = 25.0 * maxf(0.0, -lunge)
		else:
			var phase: float = _t + GAIT_PHASE[leg]
			swing = -LEG_SWING * sin(phase)
			# The paw lifts while the leg swings forward.
			lift = KNEE_LIFT * maxf(0.0, -cos(phase))
		# Rotating about +X swings a hanging leg backwards, so forward is negative.
		_turn_bone(_bone["leg_" + leg], Basis(Vector3.RIGHT, deg_to_rad(swing)))
		_turn_bone(_bone["knee_" + leg], Basis(Vector3.RIGHT, deg_to_rad(lift)))
	var bob := absf(sin(_t))
	if fighting:
		_turn_bone(_bone.back, Basis(Vector3.RIGHT, deg_to_rad(6.0 * lunge)))
		_turn_bone(_bone.neck, Basis(Vector3.RIGHT, deg_to_rad(-10.0 + 30.0 * absf(lunge))))
		# Tail up and stiff (rotating about +X lifts a tail that points back).
		_turn_bone(_bone.tail, Basis(Vector3.RIGHT, deg_to_rad(15.0)) * Basis(Vector3.UP, deg_to_rad(8.0 * sin(_t))))
		_pivot.position = Vector3(0, 0.02 * bob - 0.06 * maxf(0.0, -lunge), 0.3 * lunge)
		# Crouching it rears back (lunge -0.4 gives the full lean), stretching it dips forward.
		_pivot.rotation_degrees.x = 8.0 * lunge if lunge >= 0.0 else ATTACK_LEAN_BACK * lunge / 0.4
	else:
		_turn_bone(_bone.back, Basis(Vector3.RIGHT, deg_to_rad(3.0 * sin(_t * 2.0))))
		_turn_bone(_bone.neck, Basis(Vector3.RIGHT, deg_to_rad(4.0 * sin(_t * 2.0 + 0.6))))
		_turn_bone(_bone.tail, Basis(Vector3.UP, deg_to_rad(TAIL_WAG * sin(_t))))
		_pivot.position = Vector3(0, 0.03 * bob, 0)
		_pivot.rotation_degrees.x = 0.0


## Poses a greybox body by its attack: `lunge` is -0.4 wound up, 1 at the strike, 0 at rest.
func _pose_greybox(fighting: bool, lunge: float, moving: bool) -> void:
	var bob := absf(sin(_t)) if moving or fighting else 0.0
	var wound := maxf(0.0, -lunge) / 0.4
	var strike := maxf(0.0, lunge)
	var slump := _slump()
	match kind:
		"bear":
			# The tell: it rears a little, twists its shoulders and draws its right paw well back
			# (review 2: the swipe reads from the pose); then it comes down swiping across. Its
			# recovery is its own shape: low, head down, the paw planted out in front.
			# Recovering, head and shoulders right down (review 4: 8-10 px), the paw stays planted.
			_parts.rear.rotation_degrees.x = -24.0 * wound + 10.0 * strike + 20.0 * slump
			_parts.rear.rotation_degrees.y = 26.0 * wound - 18.0 * strike
			_parts.rear.position.y = 0.04 * bob - 0.22 * slump
			_parts.paw_r.rotation_degrees.x = 60.0 * wound - 85.0 * strike + (0.0 if fighting else 18.0 * sin(_t))
			_parts.paw_r.rotation_degrees.y = -30.0 * wound + 45.0 * strike
			# Drawn out to the side, clear of its body (review 3: 15-20 px).
			_parts.paw_r.rotation_degrees.z = 42.0 * wound
			_parts.paw_l.rotation_degrees.x = -35.0 * wound + (0.0 if fighting else -18.0 * sin(_t))
		"troll":
			# The tell: both fists up over its head and spread apart, clear of its head (review 2);
			# the slam brings them down and drops its whole body; its recovery is hunched over,
			# fists on the ground.
			for arm in ["arm_l", "arm_r"]:
				var side := -1.0 if arm == "arm_l" else 1.0
				var sway := 0.0 if fighting else 14.0 * sin(_t + (0.0 if arm == "arm_l" else PI))
				_parts[arm].rotation_degrees.x = -160.0 * wound - 30.0 * strike + 45.0 * slump + sway
				_parts[arm].rotation_degrees.z = side * (34.0 * wound + 26.0 * slump)
			_parts.body.rotation_degrees.x = -8.0 * wound + 12.0 * strike + 26.0 * slump
			# Review 3: the slam drops it 12-16 px.
			_parts.body.position.y = 0.05 * bob - 0.32 * strike - 0.08 * slump
		"raider":
			# The shard goes up behind its head (the tell), then forward in the throw.
			_parts.arm_r.rotation_degrees.x = 150.0 * wound - 70.0 * strike + (0.0 if fighting else 20.0 * sin(_t))
			_parts.shard.visible = wound > 0.05
			_parts.body.rotation_degrees.x = -6.0 * wound + 8.0 * strike
			_parts.body.position.y = 0.05 * bob
		_:
			_parts.body.position.y = absf(sin(_t)) * (0.05 if fighting else 0.12)
			_parts.body.rotation_degrees.x = 10.0 * lunge


## How far into a heavy hitter's recovery slump it is: 0 until the strike, 1 through most of
## the recovery (HEAVY_HOLD), easing back to 0 by its end.
func _slump() -> float:
	var t := _attack
	if t < 0.0 or (kind != "bear" and kind != "troll"):
		return 0.0
	var after: float = t - _def.tell - (Balance.ENEMY_LUNGE if _def.shape == "wedge" else 0.0)
	if after < 0.0:
		return 0.0
	var hold: float = HEAVY_HOLD[kind]
	if after < 0.1:
		return smoothstep(0.0, 1.0, after / 0.1)
	if after < hold:
		return 1.0
	return 1.0 - smoothstep(0.0, 1.0, (after - hold) / maxf(0.01, _def.recover - hold))


## How far into an attack it is: -0.4 wound up, 1 at the strike, 0 at rest.
func _lunge() -> float:
	var t := _attack
	if t < 0.0:
		return 0.0
	var tell: float = _def.tell
	var thrust := Balance.ENEMY_LUNGE
	if t < tell:
		return -0.4 * smoothstep(0.0, 1.0, t / tell)
	t -= tell
	if t < thrust:
		return lerpf(-0.4, 1.0, smoothstep(0.0, 1.0, t / thrust))
	t -= thrust
	var hold: float = HEAVY_HOLD.get(kind, ATTACK_HOLD)
	if t < hold:
		return 1.0
	t -= hold
	var recover: float = _def.recover - hold
	if t < recover:
		return 1.0 - smoothstep(0.0, 1.0, t / recover)
	return 0.0


## Turns a bone by `delta` (in the wolf's space) from its rest pose, relative to its parent's rest,
## as `ModelRig` does, so the auto-rig's bone axes don't matter.
func _turn_bone(bone: int, delta: Basis) -> void:
	if bone < 0:
		return
	var parent := _skeleton.get_bone_parent(bone)
	var parent_rest: Basis = _rest[parent] if parent >= 0 else Basis.IDENTITY
	var local: Basis = parent_rest.inverse() * delta * _rest[bone]
	_skeleton.set_bone_pose_rotation(bone, local.get_rotation_quaternion())
