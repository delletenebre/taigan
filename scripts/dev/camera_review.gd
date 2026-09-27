extends Node

@export var autorun: bool = false

func _ready() -> void:
	if autorun: begin.call_deferred(get_parent())

func begin(game: Node3D) -> void:
	game.paused = true
	game._update_hud()
	var window: Window = game.get_window()
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.size = Vector2i(1200, 800)
	window.content_scale_size = Vector2i(720,1280)
	game.get_viewport().size = Vector2i(1200,800)
	game.dog.place(Vector2(0, 6.5))
	game.camera.follow(game.dog)
	await _capture(game, "camera_desktop_start.png")
	# Advance through real follow logic, preserving rotation throughout the route.
	var original_basis: Basis = game.camera.global_basis
	game.dog.place(Vector2(0, -2.2))
	for i in 180: game.camera.advance(1.0 / 60.0)
	assert(game.camera.global_basis.is_equal_approx(original_basis))
	await _capture(game, "camera_desktop_bridge.png")
	game.dog.place(Vector2(-1.8, -5.2))
	for i in 180: game.camera.advance(1.0 / 60.0)
	await _capture(game, "camera_desktop_pen.png")
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.size = Vector2i(450, 800)
	window.content_scale_size = Vector2i(720,1280)
	game.get_viewport().size = Vector2i(450,800)
	game.controls.preview_touch_controls = true
	game.dog.place(Vector2(0, 6.5))
	game.camera.follow(game.dog)
	await _capture(game, "camera_phone_start.png")
	game.dog.place(Vector2(0, -2.2))
	for i in 180: game.camera.advance(1.0 / 60.0)
	await _capture(game, "camera_phone_bridge.png")
	game.elapsed = 70
	game._update_night(0)
	game.dog.place(Vector2(-1.8,-5.2))
	game.camera.follow(game.dog)
	await _capture(game, "camera_phone_night.png")
	game.get_node("Level").hide()
	game.get_node("HUD").hide()
	game.get_node("Lighting").hide()
	game.get_node("Lighting/WorldEnvironment").environment = null
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = Vector2i(1200,800)
	var study := preload("res://scenes/art/felt_material_study.tscn").instantiate()
	game.add_child(study)
	study.position = Vector3(100,0,100)
	study.get_node("Camera").make_current()
	await _capture(game, "felt_material_study_godot.png")
	print("TAIGAN_CAMERA_REVIEW_OK")
	get_tree().quit()

func _capture(game: Node3D, filename: String) -> void:
	game._update_hud()
	for i in 30: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print(filename, ": ", game.get_viewport().get_visible_rect().size)
	game.get_viewport().get_texture().get_image().save_png("res://previews/" + filename)
