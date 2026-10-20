class_name StockpileView
extends Node3D
## A stockpile: the main one by the furnace, or a small one beside a small furnace (agreed
## 2026-10-20). Each is a door into the one town store: heaps of logs, fish and crates that grow
## with it, the pad where Meagan drops off, and a label with the shared level.

const HEAP_PIECES := 8
const HEAPS := {"wood": -1.05, "food": 0.0, "materials": 1.05}
const ITEMS := {"wood": "log", "food": "fish", "materials": "crate"}
const PAD_COLOR := Color(0.55, 0.78, 0.6, 0.25)
## A small furnace's stockpile is the main one's model, smaller.
const SMALL_SCALE := 0.6

var _heaps := {}  # resource -> Array of Node3D, bottom first
var _shown := {"wood": 0, "food": 0, "materials": 0}
var _pad: MeshInstance3D
var _pad_label: Label3D
var index := 0
## Whether the Stockpile is the one thing nearest Meagan, which alone shows its label (main.gd).
var focused := false


func setup(stockpile_index: int, s: GameState) -> void:
	index = stockpile_index
	var pos: Vector2 = s.stockpiles[index].pos
	position = Vector3(pos.x, 0, pos.y)
	var scale_k := 1.0 if index == 0 else SMALL_SCALE
	var body := Node3D.new()
	body.scale = Vector3.ONE * scale_k
	add_child(body)
	# The pipeline's log platform and rack, or a greybox board.
	var model := Props.make("prop_stockpile")
	if model:
		Props.use_vertex_colours(model)
		body.add_child(model)
	else:
		body.add_child(Shapes.box(Vector3(3.3, 0.14, 1.3), Color(0.55, 0.4, 0.24), Vector3(0, 0.07, 0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# The heaps start on the deck: the Meshy platform's is about 0.31 m up (measured on the mesh).
	var base := 0.44 if model and model.scene_file_path.contains("/models/blender/") else 0.26
	for res in HEAPS:
		var pieces := []
		for i in HEAP_PIECES:
			var piece := Tools.make(ITEMS[res])
			if res == "materials":
				piece.scale = Vector3.ONE * 0.75
			piece.position = Vector3(HEAPS[res] + (i % 2 - 0.5) * 0.4, base + (i / 2) * 0.22, rng.randf_range(-0.15, 0.15))
			piece.rotation.y = rng.randf_range(-0.3, 0.3)
			piece.visible = false
			body.add_child(piece)
			pieces.append(piece)
		_heaps[res] = pieces

	var pad_at := MapData.stockpile_pad(s, index) - pos
	_pad = Shapes.cylinder(1.1, 0.03, PAD_COLOR, Vector3(pad_at.x, 0.02, pad_at.y))
	add_child(_pad)
	_pad_label = Shapes.label("Stockpile", Vector3(pad_at.x, 0.08, pad_at.y), 30)
	_pad_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_pad_label.rotation_degrees.x = -90.0
	add_child(_pad_label)
	add_child(Shapes.tap_area(Vector3(3.4 * scale_k, 2.0, 2.0 + 1.8), "stockpile", index, Vector3(0, 0, 0.9)))
	# Jans and Meagan walk round it, not across its deck (AFK N2).
	var solid := StaticBody3D.new()
	solid.collision_layer = Layers.OBSTACLE
	solid.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.3, 1.2, 1.3) * scale_k
	cs.shape = shape
	cs.position = Vector3(0, 0.6, 0)
	solid.add_child(cs)
	add_child(solid)


func refresh(s: GameState) -> void:
	# Its pad and name show only as she comes near, like the plots' (ink_v3 review).
	var d := s.meagan_pos.distance_to(MapData.stockpile_pad(s, index))
	_pad.visible = d <= SiteView.PAD_SHOW
	# Hidden while she empties her bag here, so it doesn't compete with the deposit (AFK V5).
	_pad_label.visible = focused and s.meagan_activity != "store"
	if focused:
		# The level is shared by every stockpile; the sheet says so (Astra review, 2026-10-20).
		_pad_label.text = "Stockpile · Lv %d" % s.stockpile_level
	var caps := Economy.caps(s)
	for res in HEAPS:
		var amount: float = s.piles[res]
		# Square root, so a little stock already shows a little heap.
		var want := ceili(sqrt(amount / caps[res]) * HEAP_PIECES) if amount >= 0.5 else 0
		if want != _shown[res]:
			for i in HEAP_PIECES:
				var piece: Node3D = _heaps[res][i]
				var show := i < want
				if show and not piece.visible:
					var full_scale := piece.scale
					piece.scale = full_scale * 1.4
					create_tween().tween_property(piece, "scale", full_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				piece.visible = show
			_shown[res] = want



## A small pulse as a piece lands on it (AFK N6).
func bump() -> void:
	var body := get_child(0) as Node3D
	var base := Vector3.ONE * (1.0 if index == 0 else SMALL_SCALE)
	body.scale = base * Vector3(1.06, 0.95, 1.06)
	create_tween().tween_property(body, "scale", base, 0.15).set_ease(Tween.EASE_OUT)


## Where pieces emptied from her bag land.
func drop_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)
