extends Node2D

@export var evening_seconds: float = 60.0
@export var dusk_duration: float = 10.0
@export var full_night_lead: float = 2.0
@export var wolf_interval: float = 24.0
@export var timer_skip_enabled := true
const WOLF := preload("res://scenes/actors/wolf.tscn")
var elapsed: float = 0.0
var cooldown: float = 0.0
var rescued: int = 0
var lost: int = 0
var complete := false
var paused := false
var next_wolf: float = 60.0
var target := Vector2.ZERO
var has_target := false
var pointer_down := false
var primary_touch: int = -1
var last_tap: float = -10.0
var last_tap_position := Vector2.ZERO
var wolves: Array[FeltAnimal] = []
var sheep: Array[FeltAnimal] = []
@onready var level: FeltLevel = $Pasture
@onready var dog: FeltAnimal = $Pasture/Actors/Taigan
@onready var hud: Control = $HUD/Interface
@onready var bark_effect: Node2D = $Pasture/Bark

func _ready() -> void:
	for child in $Pasture/Actors.get_children():
		if child is FeltAnimal and child.species == "sheep":
			sheep.append(child)
			if child.initially_safe:
				rescued += 1
				child.destination = child.position
	next_wolf = evening_seconds
	hud.timer_skip_requested.connect(skip_to_night)
	hud.get_node("WolfTimer/Skip").visible = timer_skip_enabled
	hud.pause_requested.connect(toggle_pause)
	hud.bark_requested.connect(bark)
	hud.restart_requested.connect(func(): get_tree().reload_current_scene())
	hud.resume_requested.connect(toggle_pause)
	hud.update_values(rescued, sheep.size(), evening_seconds, 0, lost)
	if "--smoke-test" in OS.get_cmdline_user_args():
		var test_runner = load("res://tests/smoke.gd").new()
		await test_runner.run(self)
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_P]: toggle_pause()
		if event.keycode == KEY_SPACE: bark()
		if event.keycode == KEY_R and complete: get_tree().reload_current_scene()
	if paused or complete: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		if event.pressed: aim(event.position)
	if event is InputEventMouseMotion and pointer_down:
		target = event.position
		has_target = true
	if event is InputEventScreenTouch:
		if event.pressed:
			if primary_touch == -1:
				primary_touch = event.index
				pointer_down = true
				aim(event.position)
			else: bark()
		elif event.index == primary_touch:
			primary_touch = -1
			pointer_down = false
	if event is InputEventScreenDrag and event.index == primary_touch:
		target = level.grid.get_point_position(level.nearest_cell(event.position))
		has_target = true

func aim(p: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_tap < 0.30 and p.distance_to(last_tap_position) < 50:
		bark()
		last_tap = -10
	else:
		last_tap = now
	last_tap_position = p
	target = level.grid.get_point_position(level.nearest_cell(p))
	has_target = true
	$Pasture/Target.position = target
	$Pasture/Target.show()
	$Pasture/Target/AnimationPlayer.play("pulse")

func skip_to_night() -> void:
	if not timer_skip_enabled or paused or complete or elapsed >= evening_seconds: return
	elapsed = maxf(elapsed, evening_seconds - 4.0)
	level.set_night(night_amount())
	hud.update_values(rescued, sheep.size(), maxf(0.0, evening_seconds - elapsed), cooldown, lost)

func night_amount() -> float:
	var full_night_at := maxf(0.0, evening_seconds - full_night_lead)
	var dusk_start := maxf(0.0, full_night_at - dusk_duration)
	return smoothstep(dusk_start, maxf(dusk_start + 0.001, full_night_at), elapsed)

func toggle_pause() -> void:
	if complete: return
	paused = not paused
	level.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	pointer_down = false
	primary_touch = -1
	has_target = false
	hud.show_pause(paused)

func _physics_process(delta: float) -> void:
	if paused or complete: return
	elapsed += delta
	# Finish dusk before the countdown reaches zero and wolves are spawned.
	level.set_night(night_amount())
	cooldown = maxf(0.0, cooldown - delta)
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := input.normalized()
	if not input.is_zero_approx():
		has_target = false
		$Pasture/Target.hide()
	elif has_target:
		if dog.position.distance_to(target) < 12:
			has_target = false
			$Pasture/Target.hide()
		else: direction = level.steer(dog.position, target)
	dog.travel(level.safe_motion(dog.position, direction * dog.speed, delta), delta)
	for animal in sheep: update_sheep(animal, delta)
	for wolf in wolves.duplicate(): update_wolf(wolf, delta)
	if elapsed >= next_wolf and wolves.size() < 2:
		spawn_wolf()
		next_wolf = elapsed + wolf_interval
	hud.update_values(rescued, sheep.size(), maxf(0, evening_seconds - elapsed), cooldown, lost)
	if rescued + lost == sheep.size(): finish()

func update_sheep(animal: FeltAnimal, delta: float) -> void:
	if animal.state == "lost": return
	if animal.state == "carried":
		animal.velocity = Vector2.ZERO
		animal.animate_motion(delta)
		return
	animal.panic = maxf(0, animal.panic - delta)
	if animal.state != "safe" and level.in_pen(animal.position):
		animal.state = "safe"
		animal.destination = Vector2(523 + (rescued % 4) * 28, 230 + (rescued / 4) * 27)
		rescued += 1
		$PenSound.play()
		hud.bump_count()
	var night := level.night_strength >= 0.999
	animal.update_sleep(delta, night, can_sheep_sleep(animal, night))
	if animal.asleep:
		animal.velocity = Vector2.ZERO
		animal.animate_motion(delta)
		return
	if animal.state == "safe":
		animal.travel((animal.destination - animal.position).limit_length(16), delta)
		return
	var away := animal.position - dog.position
	var danger := away.length() < 115 or animal.panic > 0
	var force := animal.bark_direction * 1.4 if animal.panic > 0.3 else Vector2.ZERO
	if away.length() < 115:
		force += away.normalized() * (115 - away.length()) / 42.0
		animal.panic = maxf(animal.panic, 0.25)
	for wolf in wolves:
		var from_wolf := animal.position - wolf.position
		if from_wolf.length() < 105:
			force += from_wolf.normalized() * 2.0
			danger = true
	var center := Vector2.ZERO
	var neighbors := 0
	for other in sheep:
		if other == animal or other.state != "grazing": continue
		var offset := animal.position - other.position
		if offset.length() < 105:
			center += other.position
			neighbors += 1
		if offset.length() < 32 and offset.length() > 0.1:
			force += offset.normalized() * (32 - offset.length()) / 14.0
	if neighbors > 0 and danger: force += (center / neighbors - animal.position) * 0.008
	# Near the river a frightened sheep seeks the bridge; it never crosses water.
	if danger and animal.position.y > 500 and animal.position.y < 650 and force.y < 0:
		force = force.lerp(level.steer(animal.position, Vector2(438, 439)) * 2.0, 0.8)
	# A gentle approach assist only activates in front of the open gate.
	if animal.position.distance_to(level.entrance.position) < 115 and animal.position.y > 320:
		force += level.steer(animal.position, level.pen_center.position) * 1.8
		danger = true
	if not danger:
		animal.wander_time -= delta
		if animal.wander_time <= 0:
			animal.wander_time = randf_range(2, 5)
			animal.wander = Vector2.from_angle(randf() * TAU) * randf_range(0, 0.35)
		force += animal.wander
	var speed := animal.speed if danger else 11.0
	if animal.panic > 0.5: speed *= 1.25
	var motion := force.limit_length() * speed
	if not level.walkable(animal.position + motion.normalized() * 18):
		motion = level.safe_motion(animal.position, motion, 0.35)
	animal.travel(level.safe_motion(animal.position, motion, delta), delta)

func can_sheep_sleep(animal: FeltAnimal, night: bool) -> bool:
	if animal.state == "safe": return night
	if animal.state != "grazing": return false
	if animal.panic > 0.0 or animal.position.distance_to(dog.position) < 170.0: return false
	for wolf in wolves:
		if animal.position.distance_to(wolf.position) < 190.0: return false
	if not night:
		var sleeping := 0
		for other in sheep:
			if other.state == "grazing" and other.asleep: sleeping += 1
		if sleeping >= 3: return false
	# Connected neighbours count as one crowd, even in a long line.
	var group: Array[FeltAnimal] = [animal]
	var index := 0
	while index < group.size():
		for other in sheep:
			if other.state != "grazing" or other in group: continue
			if other.position.distance_to(group[index].position) < 75.0:
				if other.asleep: return false
				group.append(other)
		index += 1
	return true

func bark() -> void:
	if paused or complete or cooldown > 0: return
	cooldown = 2.4
	$BarkSound.play()
	bark_effect.position = dog.position
	bark_effect.get_node("AnimationPlayer").play("bark")
	for animal in sheep:
		if animal.state != "lost" and animal.position.distance_to(dog.position) < 165:
			animal.wake_from_bark()
			if animal.state == "grazing":
				animal.panic = 1.35
				animal.bark_direction = (animal.position - dog.position).normalized()
	for wolf in wolves:
		if wolf.position.distance_to(dog.position) < 180: scare_wolf(wolf)

func spawn_wolf() -> FeltAnimal:
	var wolf: FeltAnimal = WOLF.instantiate()
	$Pasture/Actors.add_child(wolf)
	wolf.position = level.wolf_spawn.position
	wolf.state = "hunting"
	wolf.set_night(level.night_strength)
	wolves.append(wolf)
	$HowlSound.play()
	return wolf

func scare_wolf(wolf: FeltAnimal) -> void:
	wolf.scared = 4.5
	if is_instance_valid(wolf.carrying):
		wolf.carrying.state = "grazing"
		wolf.carrying.position = level.grid.get_point_position(level.nearest_cell(wolf.position + Vector2(25, 25)))
		wolf.carrying.show()
		wolf.carrying = null

func update_wolf(wolf: FeltAnimal, delta: float) -> void:
	wolf.set_night(level.night_strength)
	wolf.scared = maxf(0, wolf.scared - delta)
	if wolf.position.distance_to(dog.position) < 75: scare_wolf(wolf)
	var goal := level.wolf_spawn.position
	if not is_instance_valid(wolf.carrying) and wolf.scared <= 0:
		var closest: FeltAnimal
		var distance := INF
		for animal in sheep:
			if animal.state != "grazing": continue
			var d := animal.position.distance_to(wolf.position)
			if d < distance:
				distance = d
				closest = animal
		if is_instance_valid(closest):
			goal = closest.position
			if distance < 25:
				wolf.carrying = closest
				closest.state = "carried"
				$CaptureVoices.play_capture()
	if is_instance_valid(wolf.carrying):
		goal = level.wolf_spawn.position
		wolf.carrying.position = wolf.position + Vector2(0, -24)
		wolf.carrying.velocity = Vector2.ZERO
		if wolf.position.distance_to(goal) < 18:
			wolf.carrying.state = "lost"
			wolf.carrying.hide()
			wolf.carrying = null
			lost += 1
			$CaptureVoices.play_escape()
			remove_wolf(wolf)
			return
	elif wolf.scared > 0 and wolf.position.distance_to(goal) < 18:
		remove_wolf(wolf)
		return
	wolf.travel(level.safe_motion(wolf.position, level.steer(wolf.position, goal) * wolf.speed, delta), delta)

func remove_wolf(wolf: FeltAnimal) -> void:
	wolves.erase(wolf)
	wolf.queue_free()

func finish() -> void:
	complete = true
	pointer_down = false
	if lost == 0: $WinSound.play()
	else: $LoseSound.play()
	hud.show_result(rescued, sheep.size(), lost)

func _capture() -> void:
	paused = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/gameplay.png")
	print("CAPTURE_SAVED")
	get_tree().quit()
