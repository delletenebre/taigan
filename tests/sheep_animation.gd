extends RefCounted

func run(game: Node2D, check: Callable) -> void:
	var host := Node2D.new()
	game.add_child(host)
	var variants: Array[FeltAnimal] = []
	for coat in ["ivory", "cream", "spotted"]:
		var sheep: FeltAnimal = load("res://scenes/actors/sheep_%s.tscn" % coat).instantiate()
		sheep.position = Vector2(-2000, -2000)
		host.add_child(sheep)
		variants.append(sheep)
	var complete := true
	for sheep in variants:
		for animation_name in sheep.TROT_NAMES:
			complete = complete and sheep.trot.sprite_frames.get_frame_count(animation_name) == 6
	check.call(complete, "all three sheep coats have four complete six-frame trot views")
	check.call(not is_equal_approx(variants[0].stride_distance, variants[1].stride_distance) and not is_equal_approx(variants[1].stride_distance, variants[2].stride_distance), "sheep start at different stride phases")
	var grounded_and_opaque := true
	for sheep in variants:
		for direction in range(8):
			sheep.velocity = Vector2.RIGHT.rotated(direction * PI / 4.0) * 62.0
			for tick in range(30):
				sheep.animate_motion(1.0 / 60.0)
				grounded_and_opaque = grounded_and_opaque and sheep.trot.visible and not sheep.sprite.visible and sheep.trot.modulate.a == 1.0 and sheep.visual.position.y >= -2.4
	check.call(grounded_and_opaque, "sheep turn with one opaque animated pose and a bounded little hop")
	var animal: FeltAnimal = variants[0]
	animal.velocity = Vector2(10, 0)
	animal.animate_motion(0.1)
	check.call(animal.trot.visible and is_zero_approx(animal.visual.position.y), "slow grazing steps stay on the ground")
	animal.velocity = Vector2.ZERO
	animal.animate_motion(0.1)
	var resting_phase: float = animal.stride_distance
	animal.animate_motion(1.0)
	check.call(animal.sprite.visible and not animal.trot.visible and animal.visual.position == Vector2.ZERO and animal.stride_distance == resting_phase, "resting sheep stop their hooves and hop")
	animal.state = "carried"
	animal.velocity = Vector2(62, 0)
	animal.animate_motion(0.1)
	check.call(not animal.trot.visible and not animal.get_node("Shadow").visible, "carried sheep stop trotting and hide their ground shadow")
	animal.state = "grazing"
	animal.animate_motion(0.1)
	check.call(animal.trot.visible and animal.get_node("Shadow").visible, "rescued sheep resume normal animation and ground shadow")
	host.free()
