extends AudioStreamPlayer

func play_capture() -> void:
	# A shared small pitch variation keeps the two toy voices in the same register.
	var voice_pitch := randf_range(0.97,1.03)
	pitch_scale = voice_pitch
	$Wolf.pitch_scale = voice_pitch
	play()
	$Wolf.play()
