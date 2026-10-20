extends TestCase
## Which trees and buildings count as hiding Meagan from the game camera.


## The game camera looking at Meagan standing at `at` (as CameraRig places it).
func _camera(at: Vector3) -> Transform3D:
	var pitch := deg_to_rad(CameraRig.PITCH_DEGREES)
	var offset := Vector3(0, sin(pitch) * CameraRig.DISTANCE, cos(pitch) * CameraRig.DISTANCE)
	return Transform3D(Basis.from_euler(Vector3(-pitch, 0, 0)), at + offset)


func test_a_tree_just_in_front_of_her_covers_her() -> void:
	var her := Vector3(5, 0, -20)
	check(FadeCover.covers(_camera(her), her, her + Vector3(0, 0, 1.5), 3.5, 0.9), "tree 1.5 m nearer the camera")
	check(FadeCover.covers(_camera(her), her, her + Vector3(0.8, 0, 1.0), 3.0, 0.9), "slightly to the side")


func test_trees_behind_beside_or_far_ahead_dont() -> void:
	var her := Vector3(5, 0, -20)
	var cam := _camera(her)
	check(not FadeCover.covers(cam, her, her + Vector3(0, 0, -1.5), 3.5, 0.9), "behind her")
	check(not FadeCover.covers(cam, her, her + Vector3(3.0, 0, 1.0), 3.5, 0.9), "well to the side")
	check(not FadeCover.covers(cam, her, her + Vector3(0, 0, 12.0), 3.5, 0.9), "far nearer the camera, below her on screen")


func test_an_ink_painted_mesh_gets_a_see_through_twin() -> void:
	var ink := ShaderMaterial.new()
	ink.shader = FadeCover.INK_TOON
	ink.set_shader_parameter("albedo", Color(0.2, 0.4, 0.3))
	var copy := FadeCover.see_through_copy(ink) as ShaderMaterial
	check(copy != null and copy != ink, "a copy, not the shared material")
	check_eq(copy.shader, FadeCover.INK_TOON_FADE, "on the see-through shader")
	check_eq(copy.get_shader_parameter("albedo"), Color(0.2, 0.4, 0.3), "same paint")
	FadeCover.set_opacity(copy, ink, 0.3)
	check_near(copy.get_shader_parameter("opacity"), 0.3, 0.0001, "opacity")


func test_a_plain_material_still_fades_through_its_alpha() -> void:
	var plain := StandardMaterial3D.new()
	var copy := FadeCover.see_through_copy(plain) as StandardMaterial3D
	check_eq(copy.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS, "see-through")
	FadeCover.set_opacity(copy, plain, 0.3)
	check_near(copy.albedo_color.a, 0.3, 0.0001, "alpha")
	var other := ShaderMaterial.new()
	check(FadeCover.see_through_copy(other) == null, "an unknown shader is left alone")

