extends SceneTree
var viewport: SubViewport
func _initialize() -> void: run.call_deferred()
func capture(path: String) -> void:
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if path.ends_with("felt-digit-palettes.png"):
		image = image.get_region(Rect2i(0, 40, 819, 500))
	image.save_png(path)
	print("SAVED ", path)
func run() -> void:
	root.get_node("Session").testing = true
	root.get_node("Session").language = "ru"
	root.get_node("Session").music.stop()
	viewport = SubViewport.new()
	viewport.size = Vector2i(819,1456)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	game.set_physics_process(false)
	game.hud.update_values(0,12,60,0,0)
	await capture("res://docs/felt-hud-day.png")
	viewport.get_texture().get_image().get_region(Rect2i(0,0,819,145)).save_png("res://docs/felt-counter-day-preview.png")
	game.level.set_night(1.0)
	game.hud.update_values(12,12,0,1.1,0,1.0)
	await capture("res://docs/felt-hud-night-cooldown.png")
	var top := viewport.get_texture().get_image().get_region(Rect2i(0,0,819,145))
	top.save_png("res://docs/felt-counter-preview.png")
	var bark := viewport.get_texture().get_image().get_region(Rect2i(635,1200,175,180))
	bark.save_png("res://docs/felt-bark-disabled.png")
	game.hud.update_values(12,12,0,0,0,1.0)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().get_region(Rect2i(635,1200,175,180)).save_png("res://docs/felt-bark-ready.png")
	# Match project.godot's canvas_items / expand stretch at phone aspect ratio.
	viewport.size_2d_override = Vector2i(819, 1769)
	viewport.size_2d_override_stretch = true
	viewport.size = Vector2i(320, 691)
	game.layout_window()
	game.hud.update_values(12,12,0,1.1,0,1.0)
	await capture("res://docs/felt-hud-mobile.png")
	game.free()
	viewport.size_2d_override_stretch = false
	viewport.size_2d_override = Vector2i.ZERO
	viewport.size = Vector2i(819, 1456)
	var samples := Control.new()
	viewport.add_child(samples)
	FeltUI.panel(samples,Rect2(35,50,749,235))
	for light in [false,true]:
		var digits := FeltNumber.new()
		digits.light = light
		digits.text = "0123456789:/"
		digits.position = Vector2(60,115 if not light else 405)
		digits.size = Vector2(700,95)
		samples.add_child(digits)
	await capture("res://docs/felt-digit-palettes.png")
	quit()
