class_name StockpileView
extends Node3D
## The Stockpile by the furnace: heaps of logs, fish and crates that grow with the town's stores,
## the pad where Meagan drops off, and a label with what's stored.

const HEAP_PIECES := 8
const HEAPS := {"wood": -1.05, "food": 0.0, "materials": 1.05}
const ITEMS := {"wood": "log", "food": "fish", "materials": "crate"}
const PAD_COLOR := Color(0.45, 0.85, 0.5, 0.5)

var _heaps := {}  # resource -> Array of Node3D, bottom first
var _shown := {"wood": 0, "food": 0, "materials": 0}
var _pad: MeshInstance3D
var _pad_label: Label3D
## Whether the Stockpile is the one thing nearest Meagan, which alone shows its label (main.gd).
var focused := false


func setup() -> void:
	position = Vector3(MapData.STOCKPILE_POS.x, 0, MapData.STOCKPILE_POS.y)
	add_child(Shapes.box(Vector3(3.3, 0.14, 1.3), Color(0.55, 0.4, 0.24), Vector3(0, 0.07, 0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for res in HEAPS:
		var pieces := []
		for i in HEAP_PIECES:
			var piece := Tools.make(ITEMS[res])
			if res == "materials":
				piece.scale = Vector3.ONE * 0.75
			piece.position = Vector3(HEAPS[res] + (i % 2 - 0.5) * 0.4, 0.26 + (i / 2) * 0.22, rng.randf_range(-0.15, 0.15))
			piece.rotation.y = rng.randf_range(-0.3, 0.3)
			piece.visible = false
			add_child(piece)
			pieces.append(piece)
		_heaps[res] = pieces

	var pad_at := MapData.stockpile_pad() - MapData.STOCKPILE_POS
	_pad = Shapes.cylinder(1.1, 0.03, PAD_COLOR, Vector3(pad_at.x, 0.02, pad_at.y))
	add_child(_pad)
	_pad_label = Shapes.label("Stockpile", Vector3(pad_at.x, 0.08, pad_at.y), 42)
	_pad_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_pad_label.rotation_degrees.x = -90.0
	add_child(_pad_label)
	add_child(Shapes.tap_area(Vector3(3.4, 2.0, 3.8), "stockpile", 0, Vector3(0, 0, 0.9)))


func refresh(s: GameState) -> void:
	# Its pad and name show only as she comes near, like the plots' (ink_v3 review).
	var d := s.meagan_pos.distance_to(MapData.stockpile_pad())
	_pad.visible = d <= SiteView.PAD_SHOW
	_pad_label.visible = focused
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



## Where dropped-off pieces land, and where bank payments fly from.
func drop_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)
