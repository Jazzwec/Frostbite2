extends Node
## Autoload "Game": owns the engine, ticks it, pauses it when the app is in the background,
## saves the winter so it survives closing the game, fans engine events out as a signal and
## holds the player-facing writing from data/.

signal engine_event(ev: Dictionary)

var engine: GameEngine
var rescue_lines: Dictionary = {}
var chatter: Array = []
var messages: Dictionary = {}
var buildings_text: Dictionary = {}
## data/tips.json: the first-minute hints and the loading tips.
var tips: Dictionary = {}
## data/milestones.json: the milestone cards (titles, messages, triggers).
var milestones: Array = []
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://save.json"

## Pause when the window loses focus, as on a phone. Run with `-- --keep-running` to turn it off for automated testing.
var pause_on_focus_loss := true

var _save_in := Balance.AUTOSAVE_INTERVAL


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	engine = _load_save()
	if engine == null:
		engine = GameEngine.new()
	rescue_lines = _load_json("res://data/rescue_lines.json", {})
	chatter = _load_json("res://data/chatter.json", [])
	messages = _load_json("res://data/messages.json", {})
	buildings_text = _load_json("res://data/buildings.json", {})
	tips = _load_json("res://data/tips.json", {})
	milestones = _load_json("res://data/milestones.json", [])
	if OS.get_cmdline_user_args().has("--keep-running"):
		pause_on_focus_loss = false


func _process(delta: float) -> void:
	engine.advance(delta)
	for ev in engine.drain_events():
		engine_event.emit(ev)
		if ev.type == "game_over":
			save_game()
	if not engine.paused:
		_save_in -= delta
		if _save_in <= 0.0:
			save_game()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			engine.pause()
			save_game()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if pause_on_focus_loss:
				engine.pause()
			save_game()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			engine.resume()


## A fresh winter: a new engine, and the main scene rebuilt from it. The old save goes.
func new_game() -> void:
	engine = GameEngine.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_save_in = Balance.AUTOSAVE_INTERVAL
	get_tree().reload_current_scene()


## Writes the winter to SAVE_PATH. A finished winter is saved too, so its card shows again.
func save_game() -> void:
	_save_in = Balance.AUTOSAVE_INTERVAL
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Couldn't save to %s" % SAVE_PATH)
		return
	f.store_string(engine.to_json())


func _load_save() -> GameEngine:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var e := GameEngine.from_json(FileAccess.get_file_as_string(SAVE_PATH))
	if e == null:
		push_warning("Couldn't read the save in %s; starting a new winter" % SAVE_PATH)
	return e


## The longest the village has been kept warm, in seconds (0 before the first game ends).
func best_time() -> float:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	return cfg.get_value("score", "best", 0.0)


## Records a finished winter's time; true when it's a new best.
func record_time(seconds: float) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	if seconds <= float(cfg.get_value("score", "best", 0.0)):
		return false
	cfg.set_value("score", "best", seconds)
	cfg.save(SETTINGS_PATH)
	return true


func _load_json(path: String, fallback: Variant) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_warning("Couldn't read %s" % path)
		return fallback
	return data


## A weighted line from the main rescue pool.
func random_rescue_line() -> String:
	var pool: Array = rescue_lines.get("main", [])
	if pool.is_empty():
		return "Thank you, Meagan!"
	var total := 0.0
	for line in pool:
		total += float(line.get("weight", 1))
	var roll := randf() * total
	for line in pool:
		roll -= float(line.get("weight", 1))
		if roll <= 0.0:
			return line.text
	return pool.back().text


func random_chatter() -> String:
	return "" if chatter.is_empty() else str(chatter.pick_random())


func random_message(key: String) -> String:
	var value: Variant = messages.get(key, "")
	if value is Array:
		return str(value.pick_random()) if not value.is_empty() else ""
	return str(value)


## Name and effect line for a building id like "lumber_yard" (the JSON uses lumberYard).
func building_text(building: String) -> Dictionary:
	var parts := building.split("_")
	var key := parts[0]
	for i in range(1, parts.size()):
		key += parts[i].capitalize()
	var fallback := {"name": Balance.BUILDINGS[building].name, "effect": ""}
	return buildings_text.get(key, fallback)
