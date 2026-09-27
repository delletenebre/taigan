# Optional developer capture: Godot --path <project> --script res://scripts/dev/capture_level.gd
extends SceneTree

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var game: Node3D = load("res://scenes/pasture.tscn").instantiate()
	root.add_child(game)
	game.paused = true
	game._update_camera(0)
	game._update_hud()
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/godot_evening.png")
	game.elapsed = 66
	game._update_night(0)
	game._update_hud()
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/godot_night.png")
	print("TAIGAN_VISUAL_CAPTURE_OK")
	quit()
