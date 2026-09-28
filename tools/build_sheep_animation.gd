extends SceneTree

const COATS := ["ivory", "cream", "spotted"]
const WIDTHS := [64.0, 61.0, 66.0]
const NAMES := ["trot_down_diagonal", "trot_up_diagonal", "trot_down", "trot_up"]

func bounds(pixels: Image, area: Rect2i) -> Rect2i:
	var low := area.end
	var high := area.position
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if pixels.get_pixel(x, y).a > 0.1:
				low.x = mini(low.x, x)
				low.y = mini(low.y, y)
				high.x = maxi(high.x, x)
				high.y = maxi(high.y, y)
	return Rect2i(low, high - low + Vector2i.ONE)

func _initialize() -> void:
	var idle: Image = load("res://assets/art/sheep-variants.png").get_image()
	var metadata := {}
	for coat_index in range(3):
		var coat: String = COATS[coat_index]
		var texture: Texture2D = load("res://assets/art/sheep-%s-trot.png" % coat)
		var pixels := texture.get_image()
		assert(pixels.get_pixel(0, 0).a == 0.0, "Sprite atlas must have transparent background")
		var idle_scale: float = WIDTHS[coat_index] / 362.0
		var idle_foot := []
		var idle_offset := []
		var idle_heights := []
		for direction in range(4):
			var region := Rect2i(direction * 362, coat_index * 362, 362, 362)
			var used := bounds(idle, region)
			idle_foot.append(used.end.y - 1 - region.position.y)
			idle_offset.append((region.get_center().x - used.get_center().x) * idle_scale)
			idle_heights.append(used.size.y * idle_scale)
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		# Generated rows are not exactly at quarter-height: find transparent gaps
		# so the next row's crown cannot appear underneath a front-facing sheep.
		var row_spans: Array[Vector2i] = []
		var last_y := -100
		for y in range(pixels.get_height()):
			var occupied := false
			for x in range(pixels.get_width()):
				if pixels.get_pixel(x, y).a > 0.1:
					occupied = true
					break
			if not occupied: continue
			if y - last_y > 8: row_spans.append(Vector2i(y, y))
			else: row_spans[-1].y = y
			last_y = y
		assert(row_spans.size() == 4, "Expected four isolated sheep rows")
		var render_scales := []
		for direction in range(4):
			var mean_height := 0.0
			for frame in range(6):
				var area := Rect2i(frame * pixels.get_width() / 6, row_spans[direction].x, pixels.get_width() / 6, row_spans[direction].y - row_spans[direction].x + 1)
				mean_height += bounds(pixels, area).size.y / 6.0
			# Preserve standing height per view; one fixed scale for the whole stride.
			render_scales.append(idle_heights[direction] / mean_height)
			frames.add_animation(NAMES[direction])
			frames.set_animation_speed(NAMES[direction], 10.0)
			for frame in range(6):
				var area := Rect2i(frame * pixels.get_width() / 6, row_spans[direction].x, pixels.get_width() / 6, row_spans[direction].y - row_spans[direction].x + 1)
				var used := bounds(pixels, area)
				assert(used.position.x > area.position.x and used.end.x < area.end.x, "Sheep crosses cell boundary")
				var rect := Rect2(used.grow(2))
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = rect
				atlas.filter_clip = true
				atlas.margin = Rect2(Vector2((512.0 - rect.size.x) / 2.0, 460.0 - (used.end.y - 1 - rect.position.y)), Vector2(512, 512) - rect.size)
				frames.add_frame(NAMES[direction], atlas)
		ResourceSaver.save(frames, "res://assets/animations/sheep_%s_trot.tres" % coat)
		metadata[coat] = {"scales": render_scales, "idle_feet": idle_foot, "idle_x": idle_offset}
		print(coat, " scales=", render_scales, " idle feet=", idle_foot)
		var scene := '[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/actors/sheep.tscn" id="1"]\n'
		scene += '[ext_resource type="SpriteFrames" path="res://assets/animations/sheep_%s_trot.tres" id="2"]\n' % coat
		scene += '[node name="Sheep%s" instance=ExtResource("1")]\n' % coat.capitalize()
		scene += 'atlas_row = %d\nart_width = %s\ntrot_scales = PackedFloat32Array%s\n' % [coat_index, WIDTHS[coat_index], str(render_scales).replace("[", "(").replace("]", ")")]
		scene += 'frame_feet_y = PackedFloat32Array%s\nidle_offsets_x = PackedFloat32Array%s\n' % [str(idle_foot).replace("[", "(").replace("]", ")"), str(idle_offset).replace("[", "(").replace("]", ")")]
		scene += '[node name="Sprite" parent="Visual" index="0"]\nposition = Vector2(0, %s)\nscale = Vector2(%s, %s)\nregion_rect = Rect2(0, %d, 362, 362)\n' % [(181.0-idle_foot[0])*idle_scale, idle_scale, idle_scale, coat_index*362]
		scene += '[node name="Trot" parent="Visual" index="1"]\nsprite_frames = ExtResource("2")\n'
		FileAccess.open("res://scenes/actors/sheep_%s.tscn" % coat, FileAccess.WRITE).store_string(scene)
	FileAccess.open("res://assets/animations/sheep_alignment.json", FileAccess.WRITE).store_string(JSON.stringify(metadata, "\t"))
	quit()
