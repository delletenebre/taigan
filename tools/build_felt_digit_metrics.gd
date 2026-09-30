extends SceneTree
func _initialize() -> void:
	var data := {}
	for palette in ["dark", "light"]:
		var image := Image.load_from_file("res://assets/ui/felt-digits-%s.png" % palette)
		var cell := Vector2i(image.get_width() / 4, image.get_height() / 3)
		var glyphs := {}
		var cap_height := 0
		var advance := 0
		var symbols := "0123456789:/"
		for index in symbols.length():
			var origin := Vector2i((index % 4) * cell.x, (index / 4) * cell.y)
			var columns := PackedInt32Array()
			var rows := PackedInt32Array()
			columns.resize(cell.x)
			rows.resize(cell.y)
			for y in cell.y:
				for x in cell.x:
					if image.get_pixel(origin.x + x, origin.y + y).a > 0.3:
						columns[x] += 1
						rows[y] += 1
			var left := cell.x
			var right := 0
			var top := cell.y
			var bottom := 0
			for x in cell.x:
				if columns[x] >= 12:
					left = mini(left, x)
					right = maxi(right, x)
			for y in cell.y:
				if rows[y] >= 12:
					top = mini(top, y)
					bottom = maxi(bottom, y)
			# Generated rows can overlap a cell by a few pixels. Keep the
			# continuous body of each digit, excluding a neighbour's loose fibres.
			if index < 10:
				var run_start := 0
				var longest := 0
				for y in cell.y + 1:
					if y < cell.y and rows[y] >= 12: continue
					if y - run_start > longest:
						longest = y - run_start
						top = run_start
						bottom = y - 1
					run_start = y + 1
			var box := Rect2i(origin + Vector2i(left, top), Vector2i(right-left+1, bottom-top+1)).grow(4)
			glyphs[symbols[index]] = [box.position.x, box.position.y, box.size.x, box.size.y]
			if index < 10:
				cap_height = maxi(cap_height, box.size.y)
				advance = maxi(advance, box.size.x)
		var colon: Array = glyphs[":"]
		glyphs["."] = [colon[0], colon[1] + colon[3] * 0.52, colon[2], colon[3] * 0.48]
		data[palette] = {"glyphs": glyphs, "cap_height": cap_height, "advance": advance + 20}
	var file := FileAccess.open("res://assets/ui/felt-digit-metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	print("FELT GLYPH METRICS SAVED")
	quit()
