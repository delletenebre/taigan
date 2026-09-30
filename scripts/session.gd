extends Node
signal language_changed
const LEVELS = [
	{"name": "level_1", "sheep": 12, "day": 60.0, "interval": 24.0, "wolves": 2}
]
var selected_level := 0
var language := "ru"
var volumes := {"Master": 0.8, "Music": 0.5, "Effects": 0.8}
var best: Dictionary = {}
var save_path := "user://taigan.cfg"
var words: Dictionary = {}
var music: AudioStreamPlayer
var testing := false

func _ready() -> void:
	testing = "--smoke-test" in OS.get_cmdline_user_args() or "--menu-test" in OS.get_cmdline_user_args()
	words = JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/ui.json"))
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if not testing: load_settings()
	apply_audio()
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -12.0
	var stream: AudioStreamWAV = load("res://assets/audio/jailoo-music.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.get_length() * stream.mix_rate
	music.stream = stream
	add_child(music)
	if not testing: music.play()

func t(key: String, args: Array = []) -> String:
	var entry: Dictionary = words.get(key, {})
	var value: String = entry.get(language, entry.get("ru", key))
	return value % args if not args.is_empty() else value

func set_language(value: String) -> void:
	if value not in ["ru", "ky", "en"]: return
	language = value
	save_settings()
	language_changed.emit()

func set_volume(bus: String, value: float) -> void:
	if not volumes.has(bus): return
	volumes[bus] = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()

func apply_audio() -> void:
	for bus in volumes:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, volumes[bus] <= 0.001)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, volumes[bus])))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK: return
	var saved_language: String = cfg.get_value("ui", "language", "ru")
	language = saved_language if saved_language in ["ru", "ky", "en"] else "ru"
	selected_level = clampi(int(cfg.get_value("progress", "level", 0)), 0, LEVELS.size() - 1)
	best = cfg.get_value("progress", "best", {})
	for bus in volumes:
		volumes[bus] = clampf(float(cfg.get_value("audio", bus, volumes[bus])), 0.0, 1.0)

func save_settings() -> void:
	if testing and save_path.begins_with("user://"): return
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "language", language)
	cfg.set_value("progress", "level", selected_level)
	cfg.set_value("progress", "best", best)
	for bus in volumes: cfg.set_value("audio", bus, volumes[bus])
	var error := cfg.save(save_path)
	if error != OK: push_warning("Could not save Taigan settings: %s" % error)

func record_result(rescued: int) -> void:
	var key := str(selected_level)
	best[key] = maxi(int(best.get(key, 0)), rescued)
	save_settings()

func start_level(index: int) -> void:
	selected_level = clampi(index, 0, LEVELS.size() - 1)
	save_settings()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func home() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")
