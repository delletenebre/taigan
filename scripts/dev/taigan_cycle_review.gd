extends Node2D

func _ready() -> void:
	for index in range(8):
		var dog: FeltAnimal = get_node("Pose%d" % (index + 1))
		dog.velocity = Vector2(175, 20)
		dog.animate_motion(0.1)
		dog.get_node("Visual/Run").frame = index
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/taigan-cycle.png")
	get_tree().quit()
