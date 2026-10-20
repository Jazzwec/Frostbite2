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
