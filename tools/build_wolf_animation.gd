extends "res://tools/build_sheep_animation.gd"

func _initialize() -> void:
	var idle: Image = load("res://assets/art/wolf-v5.png").get_image()
	var texture: Texture2D = load("res://assets/art/wolf-trot.png")
	var pixels := texture.get_image()
	assert(pixels.get_pixel(0, 0).a == 0.0, "Wolf atlas must be transparent")
	var regions := [Rect2i(0,0,627,627), Rect2i(627,0,627,650), Rect2i(0,627,627,627), Rect2i(627,650,627,604)]
	var feet := []
	var offsets := []
	var heights := []
	var idle_scale := 80.0 / 627.0
	for region in regions:
		var used := bounds(idle, region)
		feet.append(used.end.y - 1 - region.position.y)
		offsets.append((region.get_center().x - used.get_center().x) * idle_scale)
		heights.append(used.size.y * idle_scale)
	var cuts_y := [0]
	for row in range(1,4):
		var best_y := row * pixels.get_height() / 4
		var best_count := pixels.get_width() + 1
		for y in range(best_y - 28, best_y + 28):
			var count := 0
			for x in range(pixels.get_width()):
				if pixels.get_pixel(x,y).a > 0.1: count += 1
			if count < best_count:
				best_count = count
				best_y = y
		assert(best_count == 0, "Rows must have a transparent separator")
		cuts_y.append(best_y)
	cuts_y.append(pixels.get_height())
	var row_spans: Array[Vector2i] = []
	for row in range(4): row_spans.append(Vector2i(cuts_y[row],cuts_y[row+1]-1))
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var scales := []
	for direction in range(4):
		var cuts_x := [0]
		for column in range(1,6):
			var best_x := column * pixels.get_width() / 6
			var best_count := pixels.get_height() + 1
			for x in range(best_x-40,best_x+40):
				var count := 0
				for y in range(row_spans[direction].x,row_spans[direction].y+1):
					if pixels.get_pixel(x,y).a > 0.1: count += 1
				if count < best_count:
					best_count = count
					best_x = x
			assert(best_count == 0, "Columns must have a transparent separator")
			cuts_x.append(best_x)
		cuts_x.append(pixels.get_width())
		var cuts: Array[Rect2i] = []
		var mean_height := 0.0
		for frame in range(6):
			var area := Rect2i(cuts_x[frame], row_spans[direction].x, cuts_x[frame+1]-cuts_x[frame], row_spans[direction].y-row_spans[direction].x+1)
			var used := bounds(pixels, area)
			assert(used.position.x >= area.position.x and used.end.x <= area.end.x, "Wolf crosses cell edge")
			cuts.append(used)
			mean_height += used.size.y / 6.0
		scales.append(heights[direction] / mean_height)
		frames.add_animation(NAMES[direction])
		frames.set_animation_speed(NAMES[direction], 8.0)
		for used in cuts:
			var rect := Rect2(used.grow(2))
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = rect
			atlas.filter_clip = true
			atlas.margin = Rect2(Vector2((512.0-rect.size.x)/2.0,460.0-(used.end.y-1-rect.position.y)),Vector2(512,512)-rect.size)
			frames.add_frame(NAMES[direction],atlas)
	ResourceSaver.save(frames,"res://assets/animations/wolf_trot.tres")
	var scene := FileAccess.get_file_as_string("res://scenes/actors/wolf.tscn")
	for entry in [["trot_scales",scales],["idle_offsets_x",offsets],["frame_feet_y",feet]]:
		var regex := RegEx.new()
		regex.compile("(?m)^"+entry[0]+" = .*\n")
		scene = regex.sub(scene,"",true)
		scene = scene.replace('art_width = 80.0\n', 'art_width = 80.0\n'+entry[0]+' = PackedFloat32Array'+str(entry[1]).replace("[","(").replace("]",")")+'\n')
	FileAccess.open("res://scenes/actors/wolf.tscn",FileAccess.WRITE).store_string(scene)
	FileAccess.open("res://assets/animations/wolf_alignment.json",FileAccess.WRITE).store_string(JSON.stringify({"scales":scales,"idle_feet":feet,"idle_x":offsets},"\t"))
	print("Wolf scales: ",scales)
	quit()
