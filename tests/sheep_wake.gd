extends RefCounted

func run(game: Node2D, check: Callable) -> void:
	var host := Node2D.new()
	game.add_child(host)
	var crouches := true
	var flights := true
	var landings := true
	var restores := true
	for coat in ["ivory", "cream", "spotted"]:
		for direction in range(4):
			var sheep: FeltAnimal = load("res://scenes/actors/sheep_%s.tscn" % coat).instantiate()
			host.add_child(sheep)
			sheep.position = Vector2(-2000, -2000)
			sheep.set_facing(direction, direction == 1)
			var ground := sheep.position
			var shadow: Sprite2D = sheep.get_node("Shadow")
			var original_shadow_scale := shadow.scale
			var original_shadow_color := shadow.modulate
			var shadow_position := shadow.position
			sheep.fall_asleep()
			sheep.animate_motion(1.0)
			sheep.wake_from_bark()
			sheep.animate_motion(0.04)
			crouches = crouches and sheep.visual.scale.x > 1.04 and sheep.visual.scale.y < 0.91
			sheep.animate_motion(0.21)
			flights = flights and sheep.visual.position.y <= -15.0 and sheep.visual.position.y >= -19.0 and sheep.position == ground
			flights = flights and sheep.sprite.visible and not sheep.trot.visible and not sheep.get_node("Sleep").visible
			flights = flights and is_zero_approx(sheep.sleep_material.get_shader_parameter("sleep_amount")) and shadow.position == shadow_position
			flights = flights and shadow.scale.x < original_shadow_scale.x and shadow.modulate.a < original_shadow_color.a
			sheep.animate_motion(0.21)
			landings = landings and absf(sheep.visual.position.y) < 0.01 and sheep.visual.scale.y < 0.94 and sheep.visual.scale.x > 1.04
			sheep.animate_motion(0.20)
			restores = restores and sheep.visual.position == Vector2.ZERO and sheep.visual.scale == Vector2.ONE and is_zero_approx(sheep.visual.rotation)
			restores = restores and shadow.scale == original_shadow_scale and shadow.modulate == original_shadow_color
			sheep.wake_from_bark()
			restores = restores and sheep.wake_hop_clock == sheep.WAKE_HOP_DURATION
	check.call(crouches, "all coats and views briefly squash before a wake hop")
	check.call(flights, "wake hop lifts the open-eyed sheep above a fixed shrinking shadow without moving its collision body")
	check.call(landings, "wake hop lands with a soft fleece squash in every view")
	check.call(restores, "wake hop restores the exact body and shadow transforms and does not restart for awake sheep")
	var animal: FeltAnimal = host.get_child(0)
	animal.fall_asleep()
	animal.wake_from_bark()
	var ground := animal.position
	animal.travel(Vector2(62, 0), 0.04)
	check.call(animal.position == ground and animal.velocity == Vector2.ZERO, "wake crouch plants the paws before fleeing")
	animal.velocity = Vector2(62, 0)
	animal.animate_motion(0.21)
	check.call(animal.sprite.visible and not animal.trot.visible, "wake hop keeps one steady pose while fleeing")
	animal.animate_motion(0.21)
	ground = animal.position
	animal.travel(Vector2(62, 0), 0.01)
	check.call(animal.position == ground and animal.velocity == Vector2.ZERO, "wake landing plants the paws while the fleece settles")
	animal.velocity = Vector2(62, 0)
	animal.animate_motion(0.4)
	check.call(animal.trot.visible and not animal.sprite.visible, "fleeing sheep resumes its trot after landing")
	animal.fall_asleep()
	animal.wake_from_bark()
	animal.state = "carried"
	animal.animate_motion(0.1)
	check.call(animal.wake_hop_clock == animal.WAKE_HOP_DURATION and not animal.get_node("Shadow").visible and is_zero_approx(animal.visual.position.y), "capture cancels a wake hop without leaving a suspended sheep")
	host.free()
