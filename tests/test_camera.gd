extends TestCase
## Zooming the camera: pinch and mouse wheel, within the allowed range.


func test_pinching_apart_zooms_in_and_together_zooms_out() -> void:
	check_near(CameraRig.pinch_size(22.0, 200.0, 220.0), 20.0, 0.01, "fingers 10% wider")
	check_near(CameraRig.pinch_size(22.0, 200.0, 160.0), 27.5, 0.01, "fingers closer")
	check_near(CameraRig.pinch_size(22.0, 200.0, 200.0), 22.0, 0.01, "no change")


func test_zoom_stays_in_range() -> void:
	check_near(CameraRig.pinch_size(22.0, 100.0, 1000.0), CameraRig.VIEW_HEIGHT_MIN, 0.01, "pinched far apart")
	check_near(CameraRig.pinch_size(22.0, 1000.0, 10.0), CameraRig.VIEW_HEIGHT_MAX, 0.01, "pinched together")
	check_near(CameraRig.wheel_size(16.5, -3), CameraRig.VIEW_HEIGHT_MIN, 0.01, "wheel in past the limit")
	check_near(CameraRig.wheel_size(33.0, 3), CameraRig.VIEW_HEIGHT_MAX, 0.01, "wheel out past the limit")


func test_the_wheel_steps_by_ten_percent() -> void:
	check_near(CameraRig.wheel_size(22.0, 1), 24.2, 0.01, "one notch out")
	check_near(CameraRig.wheel_size(22.0, -1), 20.0, 0.01, "one notch in")


func test_a_pinch_without_a_spread_changes_nothing() -> void:
	check_near(CameraRig.pinch_size(22.0, 0.0, 150.0), 22.0, 0.01, "no starting spread")
