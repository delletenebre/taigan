extends Node

func _ready() -> void:
	begin.call_deferred()

func begin() -> void:
	var game: Node3D = get_parent()
	game.paused = true
	game.get_node("HUD").hide()
	var window: Window = get_window()
	window.content_scale_size = Vector2i(1200,1000)
	window.size = Vector2i(1200,1000)
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	for i in 10: await get_tree().process_frame
	game.camera.set_process(false)
	game.camera.set_physics_process(false)
	for i in game.sheep.size():
		if i < 3:
			game.sheep[i].place(Vector2(1.7+(i%2)*.9,-4.8+floori(i/2.0)*.9))
			game.sheep[i].rotation.y = .4+i*1.0
		else: game.sheep[i].hide()
	game.camera.size = 3.8
	game.camera.global_position = Vector3(6,5.5,2)
	game.camera.look_at(Vector3(2.1,.4,-4.3))
	await capture("sheep_current_godot.png")
	game.elapsed = 70.0
	game._update_night(0.0)
	game.get_node("Level/Camp/Campfire/Ignition").advance(2.5)
	game.camera.size = 5.1
	game.camera.global_position = Vector3(9.0, 5.6, -1.3)
	game.camera.look_at(Vector3(3.8, .7, -6.8))
	await capture("campfire_night_godot.png")
	print("TAIGAN_CAMPFIRE_REVIEW_OK")
	get_tree().quit()

func capture(filename: String) -> void:
	for i in 40: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://previews/"+filename)
