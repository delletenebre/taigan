extends Node2D

@onready var dog: FeltAnimal = $Taigan
var time := 0.0

func _ready() -> void:
	dog.collision_mask = 0
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/taigan-animation.png")
		get_tree().quit()

func _physics_process(delta: float) -> void:
	time += delta
	var t := fmod(time, 6.0)
	# Walk across the stage, stop with paws down, then mirror the same direction.
	var motion := Vector2.ZERO
	if t < 2.0:
		motion = Vector2(175, 9)
	elif t >= 3.0 and t < 5.0:
		motion = Vector2(-175, 9)
	dog.travel(motion, delta)
	if t < delta: dog.position = Vector2(220, 600)
