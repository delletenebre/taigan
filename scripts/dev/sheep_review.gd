extends Node2D

var elapsed := 0.0
const HEADINGS := [PI / 4.0, -3.0 * PI / 4.0, PI / 2.0, -PI / 2.0]

func _ready() -> void:
	for coat in range(3):
		for direction in range(4):
			var sheep: FeltAnimal = get_node("Sheep%d_%d" % [coat, direction])
			sheep.velocity = Vector2.RIGHT.rotated(HEADINGS[direction]) * 62.0
			sheep.animate_motion(0.1)
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/sheep-animation.png")
	get_tree().quit()

func _physics_process(delta: float) -> void:
	elapsed += delta
	for coat in range(3):
		for direction in range(4): get_node("Sheep%d_%d" % [coat, direction]).animate_motion(delta)
	var t := fmod(elapsed, 6.0)
	for index in range(3):
		var sheep: FeltAnimal = get_node("Runner%d" % index)
		var motion := Vector2(62, 6) if t < 2.0 else (Vector2(-62, -6) if t >= 3.0 and t < 5.0 else Vector2.ZERO)
		sheep.travel(motion, delta)
