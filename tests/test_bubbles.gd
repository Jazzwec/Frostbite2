extends TestCase
## Jan chatter bubbles stay inside the screen.


func test_a_bubble_well_inside_stays_put() -> void:
	check_near(CameraRig.keep_on_screen(540.0, 200.0, 1080.0, 24.0), 0.0, 0.001, "no shift")


func test_a_bubble_off_the_left_edge_slides_right() -> void:
	# Centred 100 px from the left, 200 px either side: its left edge must move to 24.
	check_near(CameraRig.keep_on_screen(100.0, 200.0, 1080.0, 24.0), 124.0, 0.001, "slides right")


func test_a_bubble_off_the_right_edge_slides_left() -> void:
	check_near(CameraRig.keep_on_screen(1000.0, 200.0, 1080.0, 24.0), -144.0, 0.001, "slides left")


func test_a_bubble_wider_than_the_screen_is_centred() -> void:
	check_near(CameraRig.keep_on_screen(200.0, 600.0, 1080.0, 24.0), 340.0, 0.001, "centred")
