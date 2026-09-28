extends Node2D

var time := 0.0
@onready var hero: FeltAnimal = $Hero

func _exit_tree() -> void:
	print("TURN_REVIEW_SECONDS=", time)

func _ready() -> void:
	for index in range(8):
		var dog: FeltAnimal = get_node("View%d" % index)
		dog.velocity = Vector2.RIGHT.rotated(index * PI / 4.0) * 175.0
		for tick in range(36): dog.animate_motion(1.0 / 60.0)
		dog.stride_distance = 0.0
	hero.set_facing(2, false)
	hero.animate_motion(0.1)
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/taigan-directions.png")
		get_tree().quit()

func _physics_process(delta: float) -> void:
	time += delta
	for index in range(8): get_node("View%d" % index).animate_motion(delta)
	var t := fmod(time, 10.0)
	if t >= 1.0 and t < 9.0:
		var angle := (t - 1.0) / 8.0 * TAU
		var target := Vector2(409, 1120) + Vector2(cos(angle) * 190.0, sin(angle) * 95.0)
		hero.travel((target - hero.position) / delta, delta)
	else:
		hero.travel(Vector2.ZERO, delta)
