extends Node
## Autoload "Audio": the music loop, sound effects and the blizzard wind, each on its own bus.
## Effects are named after their files in assets/audio/sfx (made by tools/audio/make_audio.py);
## SOUNDS sets how loud each plays, how much its pitch varies and how often it may repeat.
## Effects with a position fade with distance from `listener` (Meagan).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/winter_town.wav"
const WIND_PATH := "res://assets/audio/sfx/wind_loop.wav"
const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 16
## Positional effects play at full volume within NEAR metres of Meagan and fade out by FAR.
const NEAR := 7.0
const FAR := 24.0
const MUSIC_DB := -10.0
const WIND_DB := -4.0
## In a blizzard the music is muffled down to this cutoff.
const STORM_CUTOFF_HZ := 1100.0

## name -> [volume dB, pitch spread (±fraction), minimum seconds between plays]
const SOUNDS := {
	"chop": [-5.0, 0.08, 0.05], "pick": [-8.0, 0.06, 0.05], "hammer": [-8.0, 0.08, 0.05],
	"splash": [-7.0, 0.1, 0.1], "swing_hit": [-6.0, 0.1, 0.05], "pop": [-11.0, 0.03, 0.035],
	"whoosh": [-16.0, 0.15, 0.05], "drop": [-12.0, 0.12, 0.05], "fire": [-8.0, 0.1, 0.12],
	"build_done": [-3.0, 0.0, 0.2], "thaw": [-4.0, 0.05, 0.2], "breath": [-10.0, 0.08, 0.3],
	"howl": [-6.0, 0.08, 1.0], "yelp": [-8.0, 0.12, 0.1], "crash": [-4.0, 0.05, 0.3],
	"warning": [-6.0, 0.0, 1.0], "step": [-20.0, 0.15, 0.1], "tap": [-10.0, 0.05, 0.05],
	"error": [-8.0, 0.0, 0.3], "full": [-8.0, 0.0, 0.5], "coin": [-6.0, 0.05, 0.1],
	"blip": [-14.0, 0.15, 0.3], "milestone": [-5.0, 0.0, 1.0],
}

## What positional effects are heard from: Meagan, set by main.
var listener: Node3D
var music_on := true
var sfx_on := true

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _streams := {}
var _last_played := {}
var _music: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _storm := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	_load_settings()
	for name in SOUNDS:
		_streams[name] = load(SFX_DIR + name + ".wav")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = _looping_player(MUSIC_PATH, "Music", MUSIC_DB)
	_wind = _looping_player(WIND_PATH, "SFX", -80.0)
	_apply_mutes()


## Plays an effect. `at` (a world position) makes it fade with distance from Meagan.
func play(name: String, at := Vector3.INF, pitch := 1.0, volume_db := 0.0) -> void:
	if not sfx_on or not _streams.has(name):
		return
	var spec: Array = SOUNDS[name]
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(name, -10.0)) < spec[2]:
		return
	var db: float = spec[0] + volume_db
	if at != Vector3.INF and is_instance_valid(listener):
		var d := listener.global_position.distance_to(at)
		if d >= FAR:
			return
		if d > NEAR:
			db += linear_to_db(1.0 - (d - NEAR) / (FAR - NEAR))
	_last_played[name] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[name]
	p.volume_db = db
	p.pitch_scale = pitch * (1.0 + randf_range(-spec[1], spec[1]))
	p.play()


func toggle_music() -> void:
	music_on = not music_on
	_apply_mutes()
	_save_settings()


func toggle_sfx() -> void:
	sfx_on = not sfx_on
	_apply_mutes()
	_save_settings()


func _process(delta: float) -> void:
	# Blizzards, and the fire going out, muffle the music and bring in the wind.
	var s := Game.engine.state
	_storm = move_toward(_storm, 1.0 if s.blizzard_active or s.game_over else 0.0, delta * 0.4)
	_lowpass.cutoff_hz = lerpf(20000.0, STORM_CUTOFF_HZ, sqrt(_storm))
	_wind.volume_db = WIND_DB + linear_to_db(_storm) if _storm > 0.001 else -80.0
	# Silence while the game is paused (the app is in the background).
	AudioServer.set_bus_mute(0, Game.engine.paused)


## Stops the loops and takes the muffling filter off the Music bus, so nothing is left
## playing or attached when the game quits.
func _exit_tree() -> void:
	_music.stop()
	_wind.stop()
	var bus := AudioServer.get_bus_index("Music")
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		if AudioServer.get_bus_effect(bus, i) == _lowpass:
			AudioServer.remove_bus_effect(bus, i)


func _looping_player(path: String, bus: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = bus
	p.volume_db = db
	add_child(p)
	# Headless runs (the test runner) have no speakers; starting the loops there only leaks them at exit.
	if DisplayServer.get_name() != "headless":
		p.play()
	return p


func _make_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), _lowpass)


func _apply_mutes() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not music_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not sfx_on)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_on = cfg.get_value("audio", "music", true)
		sfx_on = cfg.get_value("audio", "sfx", true)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sfx", sfx_on)
	cfg.save(SETTINGS_PATH)
