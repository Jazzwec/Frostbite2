extends TestCase
## Building nameplates fit over their buildings.


func test_every_building_name_fits_its_plot() -> void:
	var font := ThemeDB.fallback_font
	for b in Balance.BUILDINGS:
		var name: String = Balance.BUILDINGS[b].name
		var size := SiteView.fit_font(name, SiteView.PLATE_FONT, SiteView.PLATE_MIN_FONT, SiteView.PLATE_WIDTH, 0.016)
		var width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.016
		check(width <= SiteView.PLATE_WIDTH + 0.001, "%s is %.2f m wide at size %d" % [name, width, size])
		check(size >= SiteView.PLATE_MIN_FONT, "%s stays readable" % name)


func test_short_names_keep_the_full_size() -> void:
	check_eq(SiteView.fit_font("Furnace", 36, 24, 3.4, 0.016), 36, "Furnace")
