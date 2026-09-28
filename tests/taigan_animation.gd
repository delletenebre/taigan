extends RefCounted

func run(dog: FeltAnimal, check: Callable) -> void:
	var run_sprite: AnimatedSprite2D = dog.get_node("Visual/Run")
	var all_views := true
	for name in dog.RUN_ANIMATIONS:
		all_views = all_views and run_sprite.sprite_frames.has_animation(name) and run_sprite.sprite_frames.get_frame_count(name) == 8
	check.call(all_views, "all eight headings have complete eight-frame run cycles")

	var headings_work := true
	var opaque_transitions := true
	for index in range(8):
		dog.velocity = Vector2.RIGHT.rotated(index * PI / 4.0) * 175.0
		for tick in range(36):
			dog.animate_motion(1.0 / 60.0)
			opaque_transitions = opaque_transitions and has_one_opaque_pose(dog)
		headings_work = headings_work and dog.sector == index and run_sprite.visible and not dog.sprite.visible
		headings_work = headings_work and run_sprite.animation == dog.RUN_ANIMATIONS[index] and run_sprite.flip_h == dog.MIRROR[index]
	check.call(headings_work, "every heading settles to the correct animated view and mirror")

	# The old sign test alternated front/back when y fluctuated around zero.
	dog.velocity = Vector2(175, 0)
	for tick in range(36): dog.animate_motion(1.0 / 60.0)
	var stable := true
	for tick in range(120):
		dog.velocity = Vector2.RIGHT.rotated(deg_to_rad(22.5 + (3.0 if tick % 2 else -3.0))) * 175.0
		dog.animate_motion(1.0 / 60.0)
		stable = stable and dog.sector == 0
	check.call(stable, "direction noise around a sector boundary does not flicker views")

	var phase_before: float = dog.stride_distance
	var heading_before: float = dog.heading
	var position_before := dog.position
	dog.velocity = Vector2(-175, 0)
	dog.animate_motion(1.0 / 60.0)
	check.call(absf(angle_difference(heading_before, dog.heading)) <= deg_to_rad(dog.turn_speed_degrees) / 60.0 + 0.0001 and dog.sector != 4, "a reversal turns through intermediate views instead of snapping")
	var expected_phase: float = fmod(phase_before + 175.0 / 60.0, dog.stride_length)
	check.call(is_equal_approx(dog.stride_distance, expected_phase) and run_sprite.frame == int(expected_phase / dog.stride_length * 8.0), "turning preserves the distance-based stride phase")
	check.call(dog.position == position_before, "visual turn smoothing does not change physical movement")
	for tick in range(36): dog.animate_motion(1.0 / 60.0)
	check.call(dog.sector == 4 and run_sprite.flip_h, "reversal completes in the mirrored left view")

	dog.velocity = Vector2.ZERO
	dog.animate_motion(0.1)
	var stopped_sector: int = dog.sector
	check.call(dog.sprite.visible and not run_sprite.visible and dog.visual.position == Vector2.ZERO, "stopped Taigan uses its grounded standing view")
	for tick in range(30):
		dog.velocity = Vector2(-4 if tick % 2 else 4, 0)
		dog.animate_motion(1.0 / 60.0)
	check.call(dog.sprite.visible and dog.sector == stopped_sector, "tiny stationary corrections do not restart running or reverse the dog")
	# Check the first rendered tick of stop/start as well as all direction changes.
	for speed_value in [0.0, 175.0, 0.0, 175.0]:
		dog.velocity = Vector2(speed_value, 0)
		dog.animate_motion(1.0 / 60.0)
		opaque_transitions = opaque_transitions and has_one_opaque_pose(dog)
	check.call(opaque_transitions, "turns and stop/start keep exactly one fully opaque pose, without bright-ground flashes")
	dog.set_facing(0, false)
	dog.velocity = Vector2.ZERO
	dog.animate_motion(0.1)

func has_one_opaque_pose(dog: FeltAnimal) -> bool:
	var visible_poses := 0
	for pose in dog.visual.get_children():
		if not pose.visible: continue
		visible_poses += 1
		if not is_equal_approx(pose.modulate.a * pose.self_modulate.a, 1.0): return false
	return visible_poses == 1
