extends TestCase
## Health bars: whose is whose, and the fill shrinking from the right.


func test_meagans_bar_is_wider_and_green() -> void:
	var hers := HpBar.new(HpBar.MEAGAN_GREEN, 1.8, 0.22)
	var guard := HpBar.new(HpBar.GUARD_BLUE)
	check(hers.width > guard.width, "wider than a guard's")
	check(HpBar.MEAGAN_GREEN != HpBar.GUARD_BLUE and HpBar.MEAGAN_GREEN != HpBar.WOLF_RED, "her own colour")
	hers.free()
	guard.free()


func test_the_fill_stays_left_aligned() -> void:
	var bar := HpBar.new(HpBar.MEAGAN_GREEN, 2.0)
	bar.set_value(0.5)
	check(bar.visible, "shown when hurt")
	check_near(bar.fill_transform().x, 0.5, 0.0001, "half the width")
	check_near(bar.fill_transform().y, -0.5, 0.0001, "pinned to the left end")
	bar.set_value(1.0)
	check(not bar.visible, "hidden when full")
	bar.free()
