extends Node2D

func _ready() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/animal-variants.png")
	print("ART_CAPTURE_SAVED")
	get_tree().quit()
