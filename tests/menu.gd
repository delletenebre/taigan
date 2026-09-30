extends Node
var failures: Array[String] = []
func check(condition: bool, message: String) -> void:
	if condition: print("PASS MENU: " + message)
	else:
		failures.append(message)
		push_error("FAIL MENU: " + message)

func run(menu: Control) -> void:
	Session.testing = true
	# Use a unique temporary path; never overwrite actual player preferences.
	Session.save_path = "/tmp/taigan-menu-test-%d.cfg" % OS.get_process_id()
	Session.best = {}
	check(menu.page == "home" and menu.screen.has_node("Play"), "startup opens main menu before gameplay")
	menu.show_page("settings", false)
	var settings = menu.screen.get_node("Settings")
	for code in ["ky", "en", "ru"]:
		settings.content.get_node("Language_" + code).pressed.emit()
		check(Session.language == code and settings.content.get_node("Language_" + code).text != "", "language switches and rebuilds settings: " + code)
	var music_slider: HSlider = settings.content.get_node("MusicVolume")
	await tap(music_slider, menu, Vector2(0.22, 0.5))
	check(music_slider.value > 15 and music_slider.value < 30, "native touch moves the music slider")
	for bus in ["Master", "Music", "Effects"]:
		settings.content.get_node(bus + "Volume").value = 27
		check(is_equal_approx(Session.volumes[bus], 0.27) and is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))), 0.27), "slider controls actual audio bus: " + bus)
	settings.content.get_node("EffectsVolume").value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "zero effects mutes effects independently of music")
	Session.set_language("ky")
	Session.selected_level = 0
	Session.record_result(9)
	Session.record_result(5)
	check(Session.best.get("0") == 9, "a worse replay cannot replace the best score")
	Session.save_settings()
	Session.language = "ru"
	Session.selected_level = 0
	Session.volumes["Music"] = 1.0
	Session.best.clear()
	Session.load_settings()
	Session.apply_audio()
	check(Session.language == "ky" and Session.selected_level == 0 and Session.best.get("0") == 9 and is_equal_approx(Session.volumes.Music, 0.27), "language, audio, selected level and results survive reload")
	DirAccess.remove_absolute(Session.save_path)
	Session.save_path = "user://taigan.cfg"
	Session.language = "ru"
	Session.volumes = {"Master": 0.8, "Music": 0.5, "Effects": 0.8}
	Session.apply_audio()
	for index in Session.LEVELS.size():
		Session.selected_level = index
		var game = load("res://scenes/main.tscn").instantiate()
		menu.get_parent().add_child(game)
		game.set_physics_process(false)
		var config: Dictionary = Session.LEVELS[index]
		check(game.sheep.size() == config.sheep and game.evening_seconds == config.day and game.wolf_interval == config.interval, "level parameters change the actual round: %d" % index)
		var bark_button: Button = game.hud.get_node("Bark")
		await tap(bark_button, menu)
		game._physics_process(0.0)
		await get_tree().create_timer(0.22).timeout
		check(game.cooldown > 0 and bark_button.disabled and bark_button.get_node("Cooldown").visible and float(bark_button.get_node("Wool").material.get_shader_parameter("inactive")) > 0.99, "native bark tap starts cooldown with visibly inactive felt button")
		var remaining: float = game.cooldown
		await tap(bark_button, menu)
		check(game.cooldown == remaining and not game.has_target and not game.pointer_down, "cooldown button blocks repeat bark and movement from native touch")
		game._physics_process(3.0)
		await get_tree().create_timer(0.22).timeout
		check(not bark_button.disabled and not bark_button.get_node("Cooldown").visible and float(bark_button.get_node("Wool").material.get_shader_parameter("inactive")) < 0.01, "cooldown expiry restores the ready felt button")
		await tap(game.hud.get_node("Pause"), menu)
		check(game.paused and not game.has_target and not game.pointer_down, "native pause tap freezes gameplay without moving the dog")
		game.hud.get_node("Overlay/Card/Settings").pressed.emit()
		check(game.paused and is_instance_valid(game.hud.settings_window), "pause settings keep the round frozen")
		game.hud.close_settings()
		game.hud.get_node("Overlay/Card/Resume").pressed.emit()
		check(not game.paused and not game.hud.get_node("Overlay").visible, "resume returns to the same round")
		check(game.hud.get_node("Pause").size.x >= 100 and game.hud.get_node("Overlay/Card/Resume").size.y >= 100, "pause and primary action have mobile-sized touch targets")
		Session.set_language("en")
		check(game.hud.get_node("Overlay/Card/Resume").text == "Continue", "language switch reaches the pause UI")
		Session.set_language("ru")
		game.queue_free()
		await menu.get_tree().process_frame
	Session.selected_level = 0
	Session.best.clear()
	menu.show_page("home", false)
	var tree := menu.get_tree()
	await tap(menu.screen.get_node("Play"), menu)
	await tree.process_frame
	check(tree.current_scene.scene_file_path == "res://scenes/main.tscn" and tree.current_scene.sheep.size() == 12, "native tap on Play starts Level 1 immediately")
	print("ALL MENU CHECKS PASSED" if failures.is_empty() else "MENU FAILURES: %s" % str(failures))
	tree.quit(0 if failures.is_empty() else 1)

func tap(control: Control, owner: Node, fraction := Vector2(0.5, 0.5)) -> void:
	var tree := owner.get_tree()
	var point: Vector2 = owner.get_viewport().get_final_transform() * control.get_global_transform_with_canvas() * (control.size * fraction)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	Input.parse_input_event(touch)
	await tree.process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = point
	release.pressed = false
	Input.parse_input_event(release)
	await tree.process_frame
