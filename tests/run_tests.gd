extends SceneTree
## Headless test runner, no addon needed:
##   godot --headless --path . -s res://tests/run_tests.gd
## Runs every test_* method in every tests/test_*.gd file and exits non-zero on any failure.


func _init() -> void:
	var failed := 0
	var passed := 0
	var files := DirAccess.get_files_at("res://tests")
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load("res://tests/" + file)
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			var case: TestCase = script.new()
			case.call(name)
			if case.failures.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s :: %s" % [file, name])
				for f in case.failures:
					print("    " + f)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
