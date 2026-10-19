extends Node
## Autoload "Game": owns the engine, ticks it, pauses it when the app is in the background,
## fans engine events out as a signal and holds the player-facing writing from data/.

signal engine_event(ev: Dictionary)

var engine: GameEngine
var rescue_lines: Dictionary = {}
var chatter: Array = []
var messages: Dictionary = {}
var buildings_text: Dictionary = {}
## Pause when the window loses focus, as on a phone. Run with `-- --keep-running` to turn it off for automated testing.
var pause_on_focus_loss := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	engine = GameEngine.new()
	rescue_lines = _load_json("res://data/rescue_lines.json", {})
	chatter = _load_json("res://data/chatter.json", [])
	messages = _load_json("res://data/messages.json", {})
	buildings_text = _load_json("res://data/buildings.json", {})
	if OS.get_cmdline_user_args().has("--keep-running"):
		pause_on_focus_loss = false


func _process(delta: float) -> void:
	engine.advance(delta)
	for ev in engine.drain_events():
		engine_event.emit(ev)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			engine.pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if pause_on_focus_loss:
				engine.pause()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			engine.resume()


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
