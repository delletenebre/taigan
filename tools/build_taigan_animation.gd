extends SceneTree

# Inspect alpha only. AtlasTexture margins align the source PNGs without editing them.
const CANVAS := Vector2(512, 512)
const GROUND := 460.0
const LIFT := [0.0, 0.0, 1.0, 4.0, 5.0, 0.0, 0.0, 0.0]

func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var atlases := {
		"run_down_diagonal": ["res://assets/art/taigan-run-v3.png", 0.253],
		"run_up_diagonal": ["res://assets/art/taigan-run-up-diagonal.png", 0.253],
		"run_down": ["res://assets/art/taigan-run-down.png", 0.235],
		"run_up": ["res://assets/art/taigan-run-up.png", 0.253],
		"run_side": ["res://assets/art/taigan-run-side.png", 0.29],
	}
	for animation_name in atlases:
		var path: String = atlases[animation_name][0]
		if not FileAccess.file_exists(path):
			push_error("Missing Taigan animation atlas: " + path)
			quit(1)
			return
		var texture: Texture2D = load(path)
		var pixels := texture.get_image()
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 16.0)
		for row in range(2):
			var row_top := row * pixels.get_height() / 2
			var row_end := (row + 1) * pixels.get_height() / 2
			var spans: Array[Vector2i] = []
			var last_occupied := -100
			for x in range(pixels.get_width()):
				var occupied := false
				for y in range(row_top, row_end):
					if pixels.get_pixel(x, y).a > 0.1:
						occupied = true
						break
				if not occupied: continue
				if x - last_occupied > 14: spans.append(Vector2i(x, x))
				else: spans[-1].y = x
				last_occupied = x
			assert(spans.size() == 4, "%s row %d: expected four isolated sprites, got %s" % [path, row, spans])
			for column in range(4):
				var span := spans[column]
				var top := row_end
				var foot := row_top
				for x in range(span.x, span.y + 1):
					for y in range(row_top, row_end):
						if pixels.get_pixel(x, y).a > 0.1:
							top = mini(top, y)
							foot = maxi(foot, y)
				var rect := Rect2(Vector2(span.x - 2, top - 2), Vector2(span.y - span.x + 5, foot - top + 5))
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = rect
				atlas.filter_clip = true
				var left := (CANVAS.x - rect.size.x) * 0.5
				var frame_top: float = GROUND - (foot - rect.position.y) - LIFT[row * 4 + column] / float(atlases[animation_name][1])
				atlas.margin = Rect2(Vector2(left, frame_top), CANVAS - rect.size)
				frames.add_frame(animation_name, atlas)
				print(animation_name, " ", row * 4 + column, " region=", rect)
	var result := ResourceSaver.save(frames, "res://assets/animations/taigan_run.tres")
	quit(result)
