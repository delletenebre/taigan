extends RefCounted
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if condition: print("PASS: " + message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func run(game: Node2D) -> void:
	game.set_physics_process(false)
	var level: FeltLevel = game.level
	var dog: FeltAnimal = game.dog
	var day_wolves := 0
	for actor in level.get_node("Actors").get_children():
		if actor is FeltAnimal and actor.species == "wolf": day_wolves += 1
	check(day_wolves == 0 and game.wolves.is_empty(), "daytime has no visible or colliding wolves")
	var trail_light: PointLight2D = level.get_node("Markers/WolfSpawn/TrailLight")
	check(not trail_light.enabled, "wolf trail light is off during daytime")
	check(not level.get_node("YurtAtmosphere/Warmth").enabled and not level.get_node("YurtAtmosphere/Doorway").visible, "yurt fire glow is off during daytime")
	load("res://tests/taigan_animation.gd").new().run(dog, check)
	load("res://tests/sheep_animation.gd").new().run(game, check)
	load("res://tests/wolf_animation.gd").new().run(game, check)
	check(game.sheep.size() == 12 and game.rescued == 0, "12 sheep to collect and an empty starting enclosure")
	check(not level.walkable(Vector2(250, 482)), "river outside bridge is blocked")
	check(level.walkable(Vector2(430, 491)), "wooden bridge is walkable")
	check(not level.walkable(Vector2(450, 1000)), "boulder footprint is blocked")
	var all_routes := true
	for sheep in game.sheep:
		var path: PackedVector2Array = level.route(sheep.position, level.pen_center.position)
		if path.size() < 2: all_routes = false
	check(all_routes, "every sheep has a route into the open gate")
	var route: PackedVector2Array = level.route(Vector2(320, 850), level.pen_center.position)
	var crossed_bridge := false
	for p in route:
		if p.y > 470 and p.y < 510 and p.x > 375 and p.x < 495: crossed_bridge = true
	check(crossed_bridge, "route to pen uses bridge")
	game.dog.position = Vector2(430, 700)
	var sheep: FeltAnimal = game.sheep[3]
	sheep.position = Vector2(430, 640)
	var start := sheep.position
	# Flush the teleported collision transform before measuring actual travel.
	await game.get_tree().physics_frame
	game.update_sheep(sheep, 1.0/60.0)
	check(sheep.velocity.y < 0 and sheep.position.y < start.y, "sheep actually flees away from Taigan")
	game.bark()
	check(game.cooldown > 2 and sheep.panic > 1, "bark agitates nearby sheep")
	var cooldown: float = game.cooldown
	game.bark()
	check(is_equal_approx(game.cooldown, cooldown), "bark cooldown prevents repeat")
	game.toggle_pause()
	var elapsed: float = game.elapsed
	game._physics_process(1)
	check(is_equal_approx(game.elapsed, elapsed), "pause stops gameplay clock")
	game.toggle_pause()
	game.dog.position = Vector2(350, 850)
	sheep.position = Vector2(581, 313)
	game.update_sheep(sheep, 1.0/60.0)
	check(sheep.state == "safe" and game.rescued == 1, "entering enclosure rescues sheep")
	var wolf: FeltAnimal = game.spawn_wolf()
	check(wolf.visible and wolf.position == level.wolf_spawn.position, "wolf arrives from the same trail used to carry sheep away")
	var victim: FeltAnimal = game.sheep[4]
	victim.position = Vector2(430, 690)
	wolf.position = victim.position
	game.update_wolf(wolf, 1.0/60.0)
	check(victim.state == "carried" and wolf.carrying == victim, "wolf takes an unprotected sheep")
	game.dog.position = wolf.position + Vector2(20, 0)
	game.update_wolf(wolf, 1.0/60.0)
	check(victim.state == "grazing" and wolf.carrying == null, "Taigan approach rescues carried sheep")
	game.dog.position = Vector2(400, 850)
	wolf.scared = 0
	wolf.carrying = victim
	victim.state = "carried"
	wolf.position = level.wolf_spawn.position
	game.update_wolf(wolf, 1.0/60.0)
	check(game.lost == 1 and victim.state == "lost", "wolf departure records loss")
	check(not game.complete, "one lost sheep does not end the round")
	# Follow the actual navigation route with collision movement, not just path existence.
	game.dog.position = Vector2(320, 850)
	var steps := 0
	while game.dog.position.distance_to(level.pen_center.position) > 20 and steps < 2400:
		game.dog.travel(level.steer(game.dog.position, level.pen_center.position) * game.dog.speed, 1.0/60.0)
		await game.get_tree().physics_frame
		steps += 1
	check(game.dog.position.distance_to(level.pen_center.position) <= 20, "Taigan actually traverses bridge and open gate with collisions")
	game.elapsed = game.evening_seconds - 0.01
	game.next_wolf = game.evening_seconds
	var wolves_before: int = game.wolves.size()
	game._physics_process(0.02)
	check(game.wolves.size() == wolves_before + 1, "wolves begin hunting when countdown ends")
	check(trail_light.enabled and trail_light.energy > 0.0 and trail_light.energy < 0.25, "trail glow fades in when night starts")
	level.set_night(1.0)
	check(is_equal_approx(trail_light.energy, 0.25), "night trail glow stays subtle")
	check(level.get_node("YurtAtmosphere/Warmth").energy > 0.0 and level.get_node("YurtAtmosphere/Doorway").visible, "night lights the yurt interior and doorstep")
	level.set_night(0.0)
	check(not trail_light.enabled and is_zero_approx(trail_light.energy), "daytime resets the trail glow")
	game.rescued = game.sheep.size() - game.lost
	game.finish()
	check(game.complete and game.hud.get_node("Overlay").visible, "completed round shows results")
	game.lost = 0
	game.rescued = game.sheep.size()
	game.finish()
	check(game.hud.get_node("Overlay/Card/Title").text == "Вся отара дома!", "perfect rescue shows victory")
	if failures.is_empty(): print("ALL GAMEPLAY CHECKS PASSED")
	else: print("FAILED: ", failures)
	game.get_tree().quit(0 if failures.is_empty() else 1)
