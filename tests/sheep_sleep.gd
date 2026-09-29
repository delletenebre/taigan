extends RefCounted

func run(game: Node2D, check: Callable) -> void:
	var original_sheep: Array[FeltAnimal] = game.sheep
	var original_wolves: Array[FeltAnimal] = game.wolves
	var dog_position: Vector2 = game.dog.position
	var rescued: int = game.rescued
	var cooldown: float = game.cooldown
	var host := Node2D.new()
	game.add_child(host)
	var test_sheep: Array[FeltAnimal] = []
	game.sheep = test_sheep
	var test_wolves: Array[FeltAnimal] = []
	game.wolves = test_wolves
	game.dog.position = Vector2(-5000, -5000)
	for index in range(6):
		var animal: FeltAnimal = load("res://scenes/actors/sheep_ivory.tscn").instantiate()
		host.add_child(animal)
		animal.position = Vector2(2000 + index * 250, 2000)
		game.sheep.append(animal)
	var sheep: FeltAnimal = game.sheep[0]
	var delays := {}
	var day_range := true
	for animal in game.sheep:
		day_range = day_range and animal.sleep_delay >= 5.0 and animal.sleep_delay <= 10.0
		delays[animal.sleep_delay] = true
	check.call(day_range and delays.size() > 1, "day sleep delays are independently randomized between five and ten seconds")
	sheep.update_sleep(4.9, false, true)
	check.call(not sheep.asleep, "day sheep cannot fall asleep before five quiet seconds")
	for animal in game.sheep:
		animal.update_sleep(10.0, false, game.can_sheep_sleep(animal, false))
	var count := 0
	for animal in game.sheep:
		if animal.asleep: count += 1
	check.call(count == 3, "daytime field admits at most three sleepers")
	for animal in game.sheep: animal.wake_from_bark()
	for index in range(5): game.sheep[index].position = Vector2(2000 + index * 12, 2000)
	for animal in game.sheep:
		animal.update_sleep(10.0, false, game.can_sheep_sleep(animal, false))
	count = 0
	for index in range(5):
		if game.sheep[index].asleep: count += 1
	check.call(count == 1, "large daytime crowd admits only one sleeping sheep")
	for animal in game.sheep: animal.wake_from_bark()
	game.sheep[4].position = Vector2(4000, 2000)
	for animal in game.sheep:
		animal.update_sleep(10.0, false, game.can_sheep_sleep(animal, false))
	check.call(game.sheep[0].asleep and game.sheep[1].asleep and game.sheep[2].asleep, "small group with up to three companions can share the three daytime slots")
	var night_range := true
	for animal in game.sheep:
		animal.wake_from_bark()
		animal.update_sleep(0.0, true, true)
		night_range = night_range and animal.sleep_delay >= 2.0 and animal.sleep_delay <= 5.0
		animal.update_sleep(1.9, true, true)
		night_range = night_range and not animal.asleep
	check.call(night_range, "night resets all delays to two through five seconds")
	for animal in game.sheep:
		animal.update_sleep(5.0, true, game.can_sheep_sleep(animal, true))
	count = 0
	for animal in game.sheep:
		if animal.asleep: count += 1
	check.call(count == 6, "night allows the whole distant flock to sleep including a crowd")
	game.level.set_night(1.0)
	sheep.position = Vector2(430, 700)
	game.dog.position = sheep.position + Vector2(60, 0)
	var start: Vector2 = sheep.position
	game.update_sheep(sheep, 0.25)
	check.call(sheep.asleep and sheep.position == start, "dog proximity does not wake or move sleeping sheep")
	sheep.wake_from_bark()
	sheep.sleep_remaining = 0.1
	sheep.update_sleep(1.0, true, game.can_sheep_sleep(sheep, true))
	check.call(not sheep.asleep and sheep.sleep_remaining == sheep.sleep_delay, "nearby dog resets the quiet countdown")
	game.dog.position = Vector2(-5000, -5000)
	var wolf: FeltAnimal = load("res://scenes/actors/wolf.tscn").instantiate()
	host.add_child(wolf)
	game.wolves.append(wolf)
	wolf.position = sheep.position + Vector2(90, 0)
	sheep.sleep_remaining = 0.1
	sheep.update_sleep(1.0, true, game.can_sheep_sleep(sheep, true))
	check.call(not sheep.asleep and sheep.sleep_remaining == sheep.sleep_delay, "nearby wolf prevents falling asleep")
	sheep.fall_asleep()
	game.update_sheep(sheep, 0.25)
	check.call(sheep.asleep and sheep.position == start, "wolf approach does not wake a sleeping sheep")
	wolf.position = sheep.position
	game.update_wolf(wolf, 0.0)
	check.call(wolf.carrying == sheep and sheep.asleep, "wolf can pick up a sleeping sheep without waking it")
	game.scare_wolf(wolf)
	check.call(sheep.asleep and sheep.state == "grazing", "rescue by dog approach preserves sleep until barking")
	game.wolves.clear()
	game.dog.position = sheep.position + Vector2(60, 0)
	game.cooldown = 0.0
	game.bark()
	check.call(not sheep.asleep and game.sheep[5].asleep, "bark wakes only sheep within hearing range")
	sheep.fall_asleep()
	game.bark()
	check.call(sheep.asleep, "bark cooldown cannot wake sheep without a real bark")
	game.dog.position = Vector2(-5000, -5000)
	sheep.wake_from_bark()
	sheep.position = Vector2(581, 313)
	game.update_sheep(sheep, 0.001)
	check.call(sheep.state == "safe" and sheep.asleep, "entering the pen at night immediately rescues and sleeps")
	game.dog.position = sheep.position + Vector2(60, 0)
	game.cooldown = 0.0
	game.bark()
	game.update_sheep(sheep, 0.001)
	check.call(not sheep.asleep and sheep.sleep_remaining > 1.9, "bark wakes pen sheep for a fresh night delay")
	sheep.fall_asleep()
	sheep.animate_motion(1.4)
	check.call(sheep.get_node("Sleep").visible and sheep.get_node("Sleep/Z1").modulate.a > 0.0 and sheep.sprite.visible and not sheep.trot.visible, "sleep shows floating z marks with an opaque resting pose")
	var clock: float = sheep.sleep_clock
	game.toggle_pause()
	game._physics_process(1.0)
	check.call(sheep.sleep_clock == clock, "pause freezes sleep animation and timers")
	game.toggle_pause()
	sheep.wake_from_bark()
	sheep.animate_motion(1.0)
	check.call(not sheep.get_node("Sleep").visible and sheep.visual.scale == Vector2.ONE, "waking fades z marks and restores the exact original scale")
	game.sheep = original_sheep
	game.wolves = original_wolves
	game.dog.position = dog_position
	game.rescued = rescued
	game.cooldown = cooldown
	game.level.set_night(0.0)
	host.free()
