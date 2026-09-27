extends Node3D

@export_file("*.json") var level_data_path: String = "res://data/level_01.json"

const Actor = preload("res://scripts/herd_actor.gd")
const Level = preload("res://scripts/level_builder.gd")
const Controls = preload("res://scripts/touch_controls.gd")
var config: Dictionary
var level: PastureLevel
var dog: HerdActor
var sheep: Array[HerdActor] = []
var wolves: Array[HerdActor] = []
var camera: PastureCamera
var sun: DirectionalLight3D
var environment: Environment
var controls: PastureControls
var herd_label: Label
var time_label: Label
var hint: Label
var goal_label: Label
var result_panel: PanelContainer
var result_label: Label
var elapsed: float = 0.0
var night: bool = false
var next_wolf: float = 0.0
var rescued: int = 0
var lost: int = 0
var bark_cooldown: float = 0
var bark_ring: MeshInstance3D
var paused: bool = false
var complete: bool = false
var message_time: float = 0
var random := RandomNumberGenerator.new()

func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string(level_data_path)) as Dictionary
	random.seed = int(config.seed)
	level = $Level
	level.build(config)
	dog = $Level/Dog
	for child in $Level/Herd.get_children():
		sheep.append(child as HerdActor)
	camera = $Camera
	camera.follow(dog)
	sun = $Lighting/EveningSun
	environment = $Lighting/WorldEnvironment.environment
	controls = $HUD/Controls
	herd_label = $HUD/Controls/Top/HerdPanel/Herd
	time_label = $HUD/Controls/Top/TimePanel/Time
	goal_label = $HUD/Controls/Goal
	hint = $HUD/Controls/Hint
	result_panel = $HUD/Controls/Result
	result_label = $HUD/Controls/Result/Column/Summary
	bark_ring = $BarkRing
	controls.bark_requested.connect(bark)
	$HUD/Controls/Top/Pause.pressed.connect(_toggle_pause)
	$HUD/Controls/Result/Column/Restart.pressed.connect(func(): get_tree().reload_current_scene())
	set_message("Веди овец в загон. До ночи — одна минута.", 8)
	if "--camera-review" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		var review := preload("res://scripts/dev/camera_review.gd").new()
		add_child(review)
		review.begin.call_deferred(self)
	if "--smoke-test" in OS.get_cmdline_user_args():
		_run_smoke_test.call_deferred()

func _toggle_pause() -> void:
	if complete: return
	paused = not paused
	controls.reset_gestures()
	$HUD/Controls/Top/Pause.text = "▶" if paused else "Ⅱ"
	set_message("Пауза" if paused else "Возвращаемся к стаду", 3)

func set_message(text: String, seconds: float = 4.0) -> void:
	hint.text = text
	message_time = seconds

func _physics_process(delta: float) -> void:
	if paused or complete: return
	elapsed += delta
	bark_cooldown = maxf(0, bark_cooldown - delta)
	controls.cooldown = bark_cooldown
	message_time -= delta
	if message_time <= 0: hint.text = "Джойстик — идти   •   Двойной тап — лай" if DisplayServer.is_touchscreen_available() else "WASD / стрелки — идти   •   Пробел — лай"
	_update_night(delta)
	_move_dog(delta)
	for animal in sheep:
		_move_sheep(animal, delta)
	for wolf in wolves.duplicate():
		_move_wolf(wolf, delta)
	_update_camera(delta)
	_update_hud()
	if rescued + lost == sheep.size(): _finish()

func _update_night(_delta: float) -> void:
	var evening: float = float(config.evening_seconds)
	if elapsed >= evening and not night:
		night = true
		$Level/Camp/Campfire/Ignition.play("ignite")
		next_wolf = elapsed
		set_message("Наступила ночь. Волки идут к стаду!", 7)
	if night:
		var t: float = clampf((elapsed - evening) / float(config.night_transition_seconds), 0, 1)
		sun.light_color = Color(1, 0.86, 0.68).lerp(Color("7789bd"), t)
		sun.light_energy = lerpf(0.70, 0.03, t)
		$Lighting/Moon.light_energy = lerpf(0.0, 0.42, t)
		$Lighting/Moon.shadow_enabled = t > 0.5
		sun.shadow_enabled = t <= 0.5
		$Lighting/SkyFill.light_energy = lerpf(0.22, 0.10, t)
		environment.ambient_light_color = Color(0.75, 0.79, 0.85).lerp(Color("6d86c0"), t)
		environment.ambient_light_energy = lerpf(0.65, 0.34, t)
		environment.background_color = Color(0.46, 0.37, 0.27).lerp(Color("17253c"), t)
		for name in ["YurtInside"]:
			var lamp: OmniLight3D = get_node("Lighting/" + name)
			lamp.light_energy = lerpf(0.12, float(lamp.get_meta("night_energy")), t)
		if elapsed >= next_wolf and wolves.size() < int(config.max_wolves):
			_spawn_wolf()
			next_wolf = elapsed + float(config.wolf_interval_seconds) + randf_range(-4.0, 4.0)

func _move_dog(delta: float) -> void:
	var input: Vector2 = controls.movement()
	var right := Vector2(camera.global_basis.x.x, camera.global_basis.x.z).normalized()
	var down := Vector2(camera.global_basis.z.x, camera.global_basis.z.z).normalized()
	dog.motion = (right * input.x + down * input.y).limit_length() * 5.3
	_move(dog, delta, 0.28)
	dog.animate(delta)

func _move_sheep(animal: HerdActor, delta: float) -> void:
	if animal.state == "lost": return
	if animal.state == "falling":
		_update_fall(animal, delta)
		return
	animal.bark_timer = maxf(0, animal.bark_timer - delta)
	animal.recovery_timer = maxf(0, animal.recovery_timer - delta)
	if animal.state == "carried":
		if is_instance_valid(animal.carried_by):
			animal.position = animal.carried_by.position + Vector3(0, 1.13, 0)
			animal.visual.rotation.z = 0.30
		return
	if animal.state == "safe":
		var to_slot: Vector2 = animal.return_point - animal.planar()
		animal.motion = to_slot.normalized() * minf(0.85, to_slot.length() * 2)
		animal.grazing_head = 1.0 if to_slot.length() < 0.15 else 0.0
		_move(animal, delta, 0.33)
		animal.animate(delta)
		return
	if animal.startle_time > 0:
		animal.startle_time = maxf(0, animal.startle_time - delta)
		var progress: float = smoothstep(0.0, 1.0, 1.0 - animal.startle_time / 0.34)
		var hop_position := animal.startle_origin.lerp(animal.startle_target, progress)
		animal.base_y = level.surface_height(hop_position)
		animal.place(hop_position)
		animal.motion = (animal.startle_target - animal.startle_origin) / 0.34
		animal.animate(delta)
		return
	var p: Vector2 = animal.planar()
	if level.in_pen(p):
		animal.state = "safe"
		animal.return_point = level.pen_center + Vector2((rescued % 3 - 1) * 1.0, (rescued / 3 - 1) * 0.8)
		rescued += 1
		set_message("Овца в загоне — здесь безопасно", 2)
		return
	var away: Vector2 = p - dog.planar()
	animal.react_to_dog(away.length() < 3.8 or animal.bark_timer > 0, animal.bark_timer > 1.30)
	var force := Vector2.ZERO
	var danger: bool = animal.bark_timer > 0
	if animal.bark_timer > 0:
		force += animal.bark_away * 1.2
	if away.length() < 3.8:
		force += away.normalized() * (3.8 - away.length()) * 1.35
		danger = true
	for wolf in wolves:
		var separation: Vector2 = p - wolf.planar()
		if separation.length() < 4.0:
			force += separation.normalized() * (4.0 - separation.length())
			danger = true
	var center := Vector2.ZERO
	var neighbors: int = 0
	for other in sheep:
		if other == animal or other.state != "grazing": continue
		var separation: Vector2 = p - other.planar()
		var distance: float = separation.length()
		if distance < 4.0:
			center += other.planar()
			neighbors += 1
		if distance < 0.92 and distance > 0.01:
			force += separation.normalized() * (0.92 - distance) * 2.1
	if neighbors > 0 and danger:
		force += (center / neighbors - p) * (0.7 if animal.bark_timer > 0 else 0.20)
	var entrance_force: Vector2 = level.pen_entrance_force(p)
	force += entrance_force
	var entering: bool = entrance_force.length() > 0.08
	if danger or entering:
		animal.calm_time = 0
		animal.grazing_head = 0
	else:
		animal.calm_time += delta
		animal.graze_timer -= delta
		if animal.graze_timer <= 0:
			if animal.graze_direction == Vector2.ZERO:
				animal.graze_direction = Vector2.from_angle(random.randf_range(0, TAU))
				animal.graze_timer = random.randf_range(1.3, 3.0)
			else:
				animal.graze_direction = Vector2.ZERO
				animal.graze_timer = random.randf_range(2.5, 5.5)
		force += animal.graze_direction * 0.55
		animal.grazing_head = clampf((animal.calm_time - 1.5) / 2, 0, 1) * (1.0 if animal.graze_direction == Vector2.ZERO else 0.35)
	# Edge avoidance always applies, including during peaceful grazing and bark.
	var edge: Vector2 = level.nearest_edge(p)
	var inward: Vector2 = (p - edge).normalized()
	var edge_distance: float = p.distance_to(edge)
	if _edge_pressure(animal, delta, edge, inward): return
	if edge_distance < 1.25:
		force += inward * (1.25 - edge_distance) * 5.0
	if danger and absf(p.y - level.river_center(p.x)) < 1.6 and absf(force.y) > 0.2:
		var bridge: float = float(level.bridge_x[0])
		for x in level.bridge_x:
			if absf(p.x - float(x)) < absf(p.x - bridge): bridge = float(x)
		if absf(p.x - bridge) > 0.5: force.x += signf(bridge - p.x) * 1.8
	var speed: float = 2.15 if danger else (0.95 if entering else 0.38)
	if animal.bark_timer > 0: speed = 2.65
	animal.motion = animal.motion.lerp(force.limit_length() * speed, minf(delta * 4, 1))
	_move(animal, delta, 0.33)
	animal.animate(delta)

func _spawn_wolf() -> void:
	var entry: Array = config.wolf_spawns[random.randi_range(0, config.wolf_spawns.size() - 1)]
	var p := Vector2(entry[0], entry[1])
	for i in 12:
		if level.passable(p, 0.28): break
		p.y += 0.5
	var wolf := preload("res://scenes/actors/wolf_gray.tscn").instantiate() as HerdActor
	$Wolves.add_child(wolf)
	wolf.place(p)
	wolf.state = "hunting"
	wolf.exit_point = level.edge_exit(p)
	wolves.append(wolf)

func _move_wolf(wolf: HerdActor, delta: float) -> void:
	wolf.fear_timer = maxf(0, wolf.fear_timer - delta)
	if wolf.planar().distance_to(dog.planar()) < 2.5:
		_scare(wolf)
	var destination: Vector2 = wolf.exit_point
	if wolf.state == "hunting" and wolf.fear_timer <= 0:
		if not is_instance_valid(wolf.target) or wolf.target.state != "grazing":
			wolf.target = _nearest_sheep(wolf.planar())
		if wolf.target:
			destination = wolf.target.planar()
			if destination.distance_to(wolf.planar()) < 0.67:
				wolf.target.stop_startle()
				wolf.target.state = "carried"
				wolf.target.carried_by = wolf
				wolf.state = "escaping"
				wolf.route_timer = 0
				set_message("Волк схватил овцу! Догони его или лай рядом.", 5)
		else:
			wolf.state = "scared"
	if wolf.state == "scared" or wolf.state == "escaping":
		destination = wolf.exit_point
		if wolf.planar().distance_to(wolf.exit_point) < 0.35:
			if wolf.state == "escaping" and is_instance_valid(wolf.target) and wolf.target.state == "carried":
				wolf.target.state = "lost"
				wolf.target.hide()
				lost += 1
				set_message("Волк унёс овцу. Остальных ещё можно спасти.", 5)
			wolves.erase(wolf)
			wolf.queue_free()
			return
	wolf.route_timer -= delta
	if wolf.route_timer <= 0:
		wolf.route = level.route(wolf.planar(), destination)
		wolf.route_timer = 0.65
	var waypoint: Vector2 = destination
	while wolf.route.size() > 0 and wolf.route[0].distance_to(wolf.planar()) < 0.45:
		wolf.route.remove_at(0)
	if wolf.route.size() > 0: waypoint = wolf.route[0]
	var speed: float = 1.55 if wolf.state == "escaping" else (3.0 if wolf.state == "scared" else 2.2)
	wolf.motion = (waypoint - wolf.planar()).normalized() * speed
	_move(wolf, delta, 0.28)
	wolf.animate(delta)

func _nearest_sheep(p: Vector2) -> HerdActor:
	var nearest: HerdActor
	var distance: float = INF
	for animal in sheep:
		if animal.state == "grazing" and animal.planar().distance_squared_to(p) < distance:
			nearest = animal
			distance = animal.planar().distance_squared_to(p)
	return nearest

func _scare(wolf: HerdActor) -> void:
	if wolf.state == "escaping" and is_instance_valid(wolf.target) and wolf.target.state == "carried":
		var animal: HerdActor = wolf.target
		animal.state = "grazing"
		animal.carried_by = null
		animal.visual.rotation.z = 0
		animal.base_y = level.surface_height(wolf.planar())
		animal.place(wolf.planar())
		set_message("Успел! Овца спасена.", 3)
	wolf.target = null
	wolf.state = "scared"
	wolf.fear_timer = 6
	wolf.route_timer = 0

func bark() -> void:
	if paused or complete or bark_cooldown > 0: return
	bark_cooldown = 2.4
	if DisplayServer.get_name() != "headless": $BarkAudio.play()
	bark_ring.position = dog.position + Vector3(0, 0.07, 0)
	bark_ring.get_node("AnimationPlayer").play("bark")
	for wolf in wolves:
		if wolf.planar().distance_to(dog.planar()) < 5.0: _scare(wolf)
	var nearest: HerdActor
	var nearest_distance: float = 4.8
	for animal in sheep:
		if animal.state == "grazing" and animal.planar().distance_to(dog.planar()) < 4.8:
			animal.bark_timer = 1.35
			animal.bark_away = (animal.planar() - dog.planar()).normalized()
			animal.calm_time = 0
			animal.grazing_head = 0

			var distance := animal.planar().distance_to(dog.planar())
			if distance < nearest_distance:
				nearest = animal
				nearest_distance = distance
	if nearest:
		nearest.startle(level.bark_escape_target(nearest.planar(), nearest.bark_away))

func _move(actor: HerdActor, delta: float, radius: float) -> void:
	var p: Vector2 = level.slide(actor.planar(), actor.motion * delta, radius)
	actor.base_y = level.surface_height(p)
	actor.place(p)

func _edge_pressure(animal: HerdActor, delta: float, edge: Vector2, inward: Vector2) -> bool:
	var dog_distance: float = animal.planar().distance_to(dog.planar())
	var toward_edge: Vector2 = (animal.planar() - dog.planar()).normalized()
	var pressing: bool = animal.planar().distance_to(edge) < 0.85 and dog_distance < 1.55 and toward_edge.dot(-inward) > 0.78 and animal.recovery_timer <= 0
	animal.edge_pressure = clampf(animal.edge_pressure + delta * (1 if pressing else -2), 0, 2.5)
	if animal.edge_pressure > 0.8 and message_time <= 0:
		set_message("Осторожно: отступи от овцы у обрыва!", 1.2)
	if animal.edge_pressure < 2.5: return false
	animal.stop_startle()
	animal.state = "falling"
	animal.fall_timer = 0
	animal.fall_origin = animal.planar()
	animal.fall_outward = -inward
	animal.return_point = level.safe_near(animal.planar() + inward * 1.5)
	animal.motion = Vector2.ZERO
	animal.grazing_head = 0
	set_message("Кувырок! Дай овце отойти от края.", 3)
	return true

func _update_fall(animal: HerdActor, delta: float) -> void:
	animal.fall_timer += delta
	var t: float = animal.fall_timer
	var p: Vector2 = animal.fall_origin + animal.fall_outward * minf(t, 0.8)
	animal.position = Vector3(p.x, 0.1 + sin(minf(t / 0.35, 1) * PI) * 0.25 - pow(maxf(t - 0.3, 0), 2) * 3, p.y)
	animal.visual.rotation.z = maxf(t - 0.15, 0) * 8.0
	animal.visual.rotation.x = sin(t * 17) * 0.3
	for i in animal.limbs.size(): animal.limbs[i].rotation.x = sin(t * 30 + i) * 0.8
	if t >= 1.25:
		animal.state = "grazing"
		animal.edge_pressure = 0
		animal.recovery_timer = 4.0
		animal.visual.rotation = Vector3.ZERO
		animal.base_y = level.surface_height(animal.return_point)
		animal.place(animal.return_point)
		var puff := preload("res://scenes/effects/wool_puff.tscn").instantiate()
		add_child(puff)
		puff.position = animal.position + Vector3(0, 0.3, 0)
		puff.emitting = true
		puff.finished.connect(puff.queue_free)

func _update_camera(delta: float) -> void:
	camera.advance(delta)

func _update_hud() -> void:
	herd_label.text = "СТАДО  %d / %d" % [rescued, sheep.size()]
	var left: int = maxi(0, ceili(float(config.evening_seconds) - elapsed))
	time_label.text = "НОЧЬ  •  ВОЛКИ" if night else "ВЕЧЕР  %02d:%02d" % [left / 60, left % 60]
	var distance: int = roundi(dog.planar().distance_to(level.pen_center))
	var projected: Vector2 = camera.unproject_position(Vector3(level.pen_center.x, 0, level.pen_center.y)) - camera.unproject_position(dog.position)
	var directions: Array[String] = ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	var direction_index: int = posmod(roundi(projected.angle() / (PI / 4)), 8)
	goal_label.text = "%s  ЗАГОН · %d м" % [directions[direction_index], distance]
	if lost > 0: goal_label.text += "   |   Потеряно: %d" % lost

func _finish() -> void:
	complete = true
	var ratio: float = float(rescued) / sheep.size()
	var stars: String = "★ ★ ★" if lost == 0 else ("★ ★ ☆" if ratio >= 0.7 else "★ ☆ ☆")
	if rescued == 0: stars = "☆ ☆ ☆"
	result_label.text = "%s\n\nВыпас завершён\nСпасено: %d из %d\nУнесено волками: %d\nОценка: %d%%" % [stars, rescued, sheep.size(), lost, roundi(ratio * 100)]
	result_panel.show()

func _run_smoke_test() -> void:
	set_physics_process(false)
	assert(sheep.size() == 8)
	assert(config.wolf_spawns.size() == 1)
	var entry: Vector2 = Vector2(config.wolf_spawns[0][0],config.wolf_spawns[0][1])
	assert(entry.distance_to(level.pen_center) > 10)
	assert(level.surface_height(Vector2(-2,4.6)) > 0.5)
	var original_basis: Basis = camera.global_basis
	var original_position: Vector3 = camera.global_position
	var original_dog_position: Vector3 = dog.position
	dog.place(Vector2(0,-2.2))
	for i in 180: camera.advance(1.0/60.0)
	assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL)
	assert(camera.global_basis.is_equal_approx(original_basis))
	assert(camera.global_position.distance_to(original_position) > 4)
	dog.position = original_dog_position
	camera.follow(dog)
	var reaction_anim: AnimationPlayer = sheep[0].get_node("Reaction/AnimationPlayer")
	sheep[0].react_to_dog(true)
	reaction_anim.advance(0.2)
	assert(sheep[0].reaction.visible)
	reaction_anim.advance(0.5)
	assert(not sheep[0].reaction.visible)
	for animal in sheep:
		assert(level.passable(animal.planar(), 0.33))
		assert(level.route(animal.planar(), level.pen_center).size() > 0)
	assert(not level.passable(Vector2(3, level.river_center(3))))
	assert(level.passable(Vector2(0, level.river_z)))
	assert(level.in_pen(level.pen_center))
	var animal: HerdActor = sheep[0]
	dog.place(animal.planar() + Vector2(0, 2.0))
	bark()
	assert(animal.bark_timer > 1.0 and bark_cooldown > 2.0)
	animal.bark_timer = 0.5
	bark()
	assert(is_equal_approx(animal.bark_timer, 0.5))
	# Bark startles exactly the closest sheep; its short hop cannot cross barriers.
	for member in sheep: member.stop_startle()
	dog.place(animal.planar() + Vector2(0, 0.5))
	bark_cooldown = 0
	bark()
	assert(animal.startle_time > 0)
	var hopping: int = 0
	for member in sheep:
		if member.startle_time > 0: hopping += 1
	assert(hopping == 1)
	var hop_anim: AnimationPlayer = animal.get_node("Startle/AnimationPlayer")
	hop_anim.advance(0.17)
	assert(animal.visual.position.y > 0.15)
	var hop_end := animal.startle_target
	for i in 18: _move_sheep(animal, 0.02)
	assert(animal.planar().distance_to(hop_end) < 0.08 and level.passable(animal.planar(), 0.33))
	hop_anim.advance(0.34)
	assert(animal.visual.position.is_equal_approx(Vector3.ZERO))
	# Recover a shallow overlap on the grazing side of the short wall.
	var overlap := Vector2(3.75, 3.7)
	assert(not level.passable(overlap, 0.33))
	var recovered := level.bark_escape_target(overlap, Vector2.DOWN)
	assert(recovered != overlap and level.passable(recovered, 0.33))
	# A bark at the bank must leave the sheep on this side of the creek.
	var bank := Vector2(3, level.river_center(3) + 0.91)
	var bank_end := level.bark_escape_target(bank, Vector2.UP)
	assert(bank_end.y > level.river_center(bank_end.x) and level.passable(bank_end, 0.33))
	# A pair of taps barks; dragging does not become a tap.
	bark_cooldown = 0
	controls._register_tap(Vector2(400,400), 10.0)
	assert(bark_cooldown == 0)
	controls._register_tap(Vector2(405,405), 10.2)
	assert(bark_cooldown > 0)
	controls.reset_gestures()
	# Leaving sheep alone produces pauses, grazing and bounded wandering.
	dog.place(Vector2(0,-4))
	animal.bark_timer = 0
	animal.stop_startle()
	animal.place(Vector2(0,5))
	var head_lowered: bool = false
	var moved: bool = false
	for i in 600:
		_move_sheep(animal, 0.05)
		head_lowered = head_lowered or animal.grazing_head > 0.8
		moved = moved or animal.planar().distance_to(Vector2(0,5)) > 0.2
		assert(animal.state == "grazing" and level.edge_distance(animal.planar()) >= 0.3)
	assert(head_lowered and moved)
	# Time near an edge is harmless without pressure from the dog's inner side.
	var edge: Vector2 = level.nearest_edge(Vector2(0,11))
	var inward: Vector2 = -edge.normalized()
	animal.place(edge + inward * 0.6)
	dog.place(Vector2(0,0))
	for i in 100: assert(not _edge_pressure(animal, 0.05, edge, inward))
	dog.place(animal.planar() + inward)
	for i in 49: assert(not _edge_pressure(animal, 0.05, edge, inward))
	assert(_edge_pressure(animal, 0.06, edge, inward))
	assert(animal.state == "falling")
	_update_fall(animal, 1.3)
	assert(animal.state == "grazing" and animal.recovery_timer > 0 and level.passable(animal.planar()))
	animal.place(level.pen_center)
	_move_sheep(animal, 0.016)
	assert(animal.state == "safe" and rescued == 1)
	for i in 90: _move_sheep(animal, 0.05)
	assert(animal.planar().distance_to(animal.return_point) < 0.15)
	animal.state = "grazing"
	rescued = 0
	# Sheep brought to the opening continue inside without extra pressure.
	assert(level.pen_entrance_force(level.pen_center + Vector2(2.6,0)) == Vector2.ZERO)
	assert(level.pen_entrance_force(Vector2(0,5)) == Vector2.ZERO)
	var entrant := preload("res://scenes/actors/sheep_ivory.tscn").instantiate() as HerdActor
	$Level/Herd.add_child(entrant)
	dog.place(Vector2(0,8))
	var saved_rescued: int = rescued
	for start in [Vector2(-1.8,-4.6), Vector2(-0.6,-4.0), Vector2(-3.0,-4.0), Vector2(-1.8,-3.65)]:
		assert(level.passable(start, 0.33), "Entrance test start is obstructed: " + str(start))
		assert(level.pen_entrance_force(start).length() > 0.08)
		entrant.state = "grazing"
		entrant.motion = Vector2.ZERO
		entrant.place(start)
		entrant.graze_timer = 10.0
		for i in 480:
			_move_sheep(entrant, 1.0 / 30.0)
			if entrant.state == "safe": break
		assert(entrant.state == "safe", "Wide entrance assistance must guide sheep through the gate from " + str(start))
	entrant.free()
	rescued = saved_rescued
	assert(not night and wolves.is_empty())
	assert(not $Level/Camp/Campfire/FireEffect.visible)
	elapsed = 59.9
	_update_night(0)
	assert(not night)
	elapsed = 60
	_update_night(0)
	assert(night and wolves.size() == 1)
	$Level/Camp/Campfire/Ignition.advance(2.5)
	assert($Level/Camp/Campfire/FireEffect.visible)
	assert($Level/Camp/Campfire/FireEffect.scale.is_equal_approx(Vector3.ONE))
	var wolf: HerdActor = wolves[0]
	assert(level.route(wolf.planar(), Vector2(0,5)).size() > 0)
	assert(level.edge_distance(wolf.exit_point) < 0.8)
	assert(level.route(wolf.planar(), wolf.exit_point).size() > 0)
	animal.state = "carried"
	animal.carried_by = wolf
	wolf.target = animal
	wolf.state = "escaping"
	_scare(wolf)
	assert(animal.state == "grazing" and animal.carried_by == null)
	wolf.place(wolf.exit_point)
	wolf.target = animal
	wolf.state = "escaping"
	animal.state = "carried"
	animal.carried_by = wolf
	dog.place(Vector2(0,8))
	_move_wolf(wolf, 0.016)
	assert(lost == 1 and animal.state == "lost" and not complete)
	print("TAIGAN_SMOKE_OK: compact routes, bridge, double tap, bark cooldown, grazing, edge safety, pressure fall, recovery, dusk 60s, wolf rescue, rating-only loss")
	$BarkAudio.stop()
	for child in get_children():
		if child is CPUParticles3D: child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
