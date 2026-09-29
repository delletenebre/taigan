extends AudioStreamPlayer

func play_capture() -> void:
	pitch_scale = randf_range(0.97, 1.03)
	play()

func play_escape() -> void:
	$Wolf.pitch_scale = randf_range(0.97, 1.03)
	$Wolf.play()
