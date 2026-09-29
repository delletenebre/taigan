extends RefCounted
func run(game: Node, check: Callable) -> void:
	var wolf: FeltAnimal = load("res://scenes/actors/wolf.tscn").instantiate()
	game.add_child(wolf)
	wolf.position = Vector2(-2000,-2000)
	wolf.set_night(1.0)
	check.call(wolf.sprite.material == wolf.trot.material and is_equal_approx(wolf.sprite.material.get_shader_parameter("night"),1.0),"wolf eyes share night illumination across idle and walking")
	wolf.set_night(0.0)
	check.call(is_zero_approx(wolf.sprite.material.get_shader_parameter("night")),"wolf eye glow switches off in daytime")
	var complete := true
	for name in wolf.TROT_NAMES:
		complete = complete and wolf.trot.sprite_frames.get_frame_count(name) == 6
	check.call(complete,"wolf has four complete six-frame movement views")
	var turns := true
	for direction in range(8):
		wolf.velocity = Vector2.RIGHT.rotated(direction*PI/4.0)*51.0
		for tick in range(40): wolf.animate_motion(1.0/60.0)
		turns = turns and wolf.sector == direction and wolf.trot.visible and not wolf.sprite.visible and wolf.trot.modulate.a == 1.0 and wolf.visual.position == Vector2.ZERO
	check.call(turns,"wolf turns through all headings with one opaque grounded pose")
	wolf.set_facing(0,false)
	var before: float = wolf.stride_distance
	wolf.velocity = Vector2(-51,0)
	wolf.animate_motion(1.0/60.0)
	check.call(wolf.sector != 4 and is_equal_approx(wolf.stride_distance,fmod(before+51.0/60.0,wolf.stride_length)),"wolf reversal is gradual and preserves step phase")
	wolf.velocity = Vector2.ZERO
	wolf.animate_motion(0.1)
	before = wolf.stride_distance
	wolf.animate_motion(1.0)
	check.call(wolf.sprite.visible and not wolf.trot.visible and wolf.stride_distance == before,"stopped wolf rests without sliding its paws")
	var forest: Node = game.level.get_node("Actors/WolfForest")
	forest.set_night(0.0)
	check.call(not forest.get_node("Moonlight").enabled,"forest moonlight is off by day")
	forest.set_night(1.0)
	check.call(forest.get_node("Moonlight").enabled and forest.get_node("Moonlight").energy < 0.5,"night softly illuminates the forest interior")
	forest.set_night(0.0)
	wolf.free()
