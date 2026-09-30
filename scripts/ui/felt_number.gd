class_name FeltNumber
extends Control
const DARK = preload("res://assets/ui/felt-digits-dark.png")
const LIGHT = preload("res://assets/ui/felt-digits-light.png")
static var metrics: Dictionary = {}
var text := "":
	set(value):
		if text == value: return
		text = value
		queue_redraw()
var light := false:
	set(value):
		light = value
		queue_redraw()
var width_template := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if metrics.is_empty(): metrics = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/felt-digit-metrics.json"))
	resized.connect(queue_redraw)

func advance(character: String, data: Dictionary) -> float:
	if character == ":": return float(data.advance) * 0.48
	if character == "/": return float(data.advance) * 0.60
	if character == ".": return float(data.advance) * 0.35
	return float(data.advance)

func measure(value: String, data: Dictionary) -> float:
	var width := 0.0
	for character in value: width += advance(character, data)
	return width

func _draw() -> void:
	if text.is_empty() or metrics.is_empty(): return
	var data: Dictionary = metrics["light" if light else "dark"]
	var atlas: Texture2D = LIGHT if light else DARK
	var reference := width_template if not width_template.is_empty() else text
	var amount := minf(size.y / float(data.cap_height), size.x / maxf(1.0, measure(reference, data)))
	var x := (size.x - measure(text, data) * amount) * 0.5
	for character in text:
		var width := advance(character, data) * amount
		if data.glyphs.has(character):
			var box: Array = data.glyphs[character]
			var region := Rect2(box[0], box[1], box[2], box[3])
			var glyph_size := region.size * amount
			var position := Vector2(x + (width - glyph_size.x) * 0.5, (size.y - glyph_size.y) * 0.5)
			if character == ".": position.y = (size.y + float(data.cap_height) * amount) * 0.5 - glyph_size.y
			draw_texture_rect_region(atlas, Rect2(position, glyph_size), region)
		x += width
