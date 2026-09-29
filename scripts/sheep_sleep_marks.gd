extends Node2D

func animate_sleep(clock: float, strength: float) -> void:
	for index in range(get_child_count()):
		var mark: Label = get_child(index)
		var age := clock - index * 0.85
		if age < 0.0:
			mark.modulate.a = 0.0
			continue
		var progress := fposmod(age, 2.8) / 2.8
		mark.position = Vector2(5.0 + progress * 17.0 + sin(progress * PI) * 3.0, -48.0 - progress * 30.0)
		mark.scale = Vector2.ONE * lerpf(0.65, 1.0, progress)
		mark.modulate.a = strength * smoothstep(0.0, 0.18, progress) * (1.0 - smoothstep(0.65, 1.0, progress))
