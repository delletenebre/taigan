class_name FeltSurface
extends Control
var texture: Texture2D
var source_margin := Vector2(130, 130)
var border := Vector2(44, 44)
var tint := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if not texture: return
	var source := texture.get_size()
	var sx := [0.0, source_margin.x, source.x - source_margin.x, source.x]
	var sy := [0.0, source_margin.y, source.y - source_margin.y, source.y]
	var dx := [0.0, border.x, size.x - border.x, size.x]
	var dy := [0.0, border.y, size.y - border.y, size.y]
	for x in 3:
		for y in 3:
			draw_texture_rect_region(texture, Rect2(Vector2(dx[x], dy[y]), Vector2(dx[x+1]-dx[x], dy[y+1]-dy[y])), Rect2(Vector2(sx[x], sy[y]), Vector2(sx[x+1]-sx[x], sy[y+1]-sy[y])), tint)
