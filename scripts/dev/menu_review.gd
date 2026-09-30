extends SceneTree
var viewport: SubViewport
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(path)
	print("SAVED ", path)
func run() -> void:
	var session = root.get_node("Session")
	session.testing = true
	session.language = "ru"
	session.music.stop()
	viewport = SubViewport.new()
	viewport.size = Vector2i(819, 1456)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var menu = load("res://scenes/ui/menu.tscn").instantiate()
	viewport.add_child(menu)
	await capture("res://docs/menu-home.png")
	menu.show_page("settings")
	await capture("res://docs/menu-settings-ru.png")
	session.set_language("ky")
	await capture("res://docs/menu-settings-ky.png")
	session.set_language("en")
	await capture("res://docs/menu-settings-en.png")
	session.set_language("ru")
	menu.show_page("home")
	viewport.size = Vector2i(320, 691)
	await capture("res://docs/menu-home-mobile.png")
	menu.show_page("settings")
	await capture("res://docs/menu-settings-mobile.png")
	menu.free()
	viewport.size = Vector2i(819, 1456)
	var game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.set_physics_process(false)
	await capture("res://docs/menu-hud.png")
	game.toggle_pause()
	await capture("res://docs/menu-pause.png")
	game.hud.open_settings()
	await capture("res://docs/menu-pause-settings.png")
	game.hud.close_settings()
	game.hud.get_node("Overlay/Card/Resume").pressed.emit()
	game.lost = 0
	game.rescued = 12
	game.finish()
	await capture("res://docs/menu-result.png")
	game.free()
	quit()
