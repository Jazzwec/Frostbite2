extends SceneTree
## Headless test runner, no addon needed:
##   godot --headless --path . -s res://tests/run_tests.gd
## Runs every test_* method in every tests/test_*.gd file and exits non-zero on any failure.
## A test also fails if a script error is raised while it runs (say a class it uses doesn't
## compile headless), and a test file that won't load fails as a whole; otherwise those would
## slip through as passes.


## Collects script and engine errors raised while a test runs.
class ErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		errors.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function])

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _init() -> void:
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var failed := 0
	var passed := 0
	var files := DirAccess.get_files_at("res://tests")
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		catcher.errors.clear()
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAIL %s :: doesn't load" % file)
			for err in catcher.errors:
				print("    " + err)
			continue
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			catcher.errors.clear()
			var case: TestCase = script.new()
			case.call(name)
			var problems: Array = case.failures + catcher.errors.map(func(err): return "error: " + err)
			if problems.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL %s :: %s" % [file, name])
				for p in problems:
					print("    " + p)
	OS.remove_logger(catcher)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
