extends RefCounted

func run(game: Node2D, check: Callable) -> void:
	var original_sheep: Array[FeltAnimal] = game.sheep
	var original_wolves: Array[FeltAnimal] = game.wolves
	var dog_position: Vector2 = game.dog.position
	var cooldown: float = game.cooldown
	var empty_sheep: Array[FeltAnimal] = []
	var test_wolves: Array[FeltAnimal] = []
	game.sheep = empty_sheep
	game.wolves = test_wolves
	game.dog.position = Vector2(430, 790)
	var wolf: FeltAnimal = game.spawn_wolf()
	wolf.position = Vector2(430, 700)
	await game.get_tree().physics_frame
	var start := wolf.position
	game.cooldown = 0.0
	game.bark()
	var goal: Vector2 = wolf.bark_retreat_goal
	check.call(wolf.bark_retreat and goal.distance_to(start) > 30.0 and goal.distance_to(start) <= 85.01, "bark chooses a short local retreat instead of sending the wolf to the forest")
	check.call(goal.distance_to(game.dog.position) > start.distance_to(game.dog.position) and game.level.clear_for_actor(goal), "bark retreat increases distance from the dog and stays on dry ground")
	var fastest := 0.0
	var furthest := 0.0
	var on_ground := true
	for tick in range(95):
		var before := wolf.position
		game.update_wolf(wolf, 1.0 / 60.0)
		if wolf.bark_retreat:
			fastest = maxf(fastest, wolf.position.distance_to(before) * 60.0)
			furthest = maxf(furthest, wolf.position.distance_to(start))
			on_ground = on_ground and game.level.clear_for_actor(wolf.position)
		await game.get_tree().physics_frame
	check.call(fastest > wolf.speed * 1.8, "barking wolf runs away at twice its normal speed")
	check.call(furthest <= 85.01 and on_ground, "barking wolf stops nearby without crossing the river or obstacles")
	check.call(not wolf.bark_retreat and is_zero_approx(wolf.scared) and wolf in game.wolves, "short bark retreat ends without removing the wolf from the field")
	# Holding the dog close must not turn the short burst into a long forest escape.
	wolf.position = start
	game.dog.position = start + Vector2(0, 30)
	game.scare_wolf(wolf, true)
	var retreat_clock: float = wolf.scared
	game.update_wolf(wolf, 0.1)
	check.call(wolf.bark_retreat and wolf.scared < retreat_clock, "dog proximity does not overwrite or extend the bark retreat")
	game.wolves = original_wolves
	game.sheep = original_sheep
	game.dog.position = dog_position
	game.cooldown = cooldown
	wolf.free()
