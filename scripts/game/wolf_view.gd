class_name WolfView
extends Node3D
## A wolf drawn where the engine says it is.

var _model: Node3D
var _hp_bar: HpBar
var _t := 0.0
var _flash: MeshInstance3D
var _knock := 0.0


func _init() -> void:
	_model = Node3D.new()
	add_child(_model)
	var fur := Color(0.42, 0.42, 0.46)
	_model.add_child(Shapes.capsule(0.28, 1.2, fur, Vector3(0, 0.55, 0)))
	_model.get_child(-1).rotation_degrees.x = 90.0
	_model.add_child(Shapes.sphere(0.24, fur, Vector3(0, 0.75, 0.6)))
	_model.add_child(Shapes.box(Vector3(0.14, 0.12, 0.3), Color(0.3, 0.3, 0.33), Vector3(0, 0.7, 0.85)))
	_model.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(-0.12, 1.0, 0.55)))
	_model.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(0.12, 1.0, 0.55)))
	_model.add_child(Shapes.sphere(0.04, Color(1, 0.85, 0.2), Vector3(-0.1, 0.8, 0.8), 3.0))
	_model.add_child(Shapes.sphere(0.04, Color(1, 0.85, 0.2), Vector3(0.1, 0.8, 0.8), 3.0))
	for x in [-0.15, 0.15]:
		for z in [-0.35, 0.35]:
			_model.add_child(Shapes.cylinder(0.06, 0.35, fur.darkened(0.2), Vector3(x, 0.17, z)))
	# A white shell over the body, shown for a moment when it's hit.
	_flash = Shapes.capsule(0.32, 1.3, Color(1, 1, 1, 0.8), Vector3(0, 0.55, 0))
	_flash.rotation_degrees.x = 90.0
	_flash.visible = false
	_model.add_child(_flash)
	_hp_bar = HpBar.new(Color(0.95, 0.25, 0.2))
	_hp_bar.position = Vector3(0, 1.5, 0)
	add_child(_hp_bar)


## Struck: a white flash and a small hop back.
func hit() -> void:
	_knock = 1.0
	Fx.burst("snow", global_position + Vector3(0, 0.6, 0))


func sync(wolf: Dictionary, delta: float) -> void:
	var target := Vector3(wolf.pos.x, 0, wolf.pos.y)
	var step := target - global_position
	if step.length() > 0.01:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(step.x, step.z), 10.0 * delta)
	global_position = global_position.lerp(target, minf(1.0, 12.0 * delta))
	_t += delta * (14.0 if wolf.mode == "fight" else 9.0)
	_knock = move_toward(_knock, 0.0, delta * 5.0)
	_flash.visible = _knock > 0.6
	_model.position = -_model.basis.z * 0.25 * _knock
	_model.position.y = absf(sin(_t)) * (0.05 if wolf.mode == "fight" else 0.12)
	_hp_bar.set_value(wolf.hp / wolf.max_hp)
