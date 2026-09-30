class_name FeltUI
extends RefCounted
const INK = Color("493127")
const MUTED = Color("806951")
const CREAM = Color("fff0d4")
const BOLD = preload("res://assets/fonts/Nunito-Bold.ttf")
const REGULAR = preload("res://assets/fonts/PT_Sans-Web-Regular.ttf")
const PANEL = preload("res://assets/ui/menu-panel-felt.png")
const BUTTON = preload("res://assets/ui/menu-button-felt.png")
static var button_texture: AtlasTexture

static func label(parent: Node, text: String, box: Rect2, font_size := 32, color := INK, centered := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = box.position
	node.size = box.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", BOLD if font_size >= 36 else REGULAR)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered: node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(node)
	return node

static func panel(parent: Node, box: Rect2) -> FeltSurface:
	var node := FeltSurface.new()
	node.texture = PANEL
	node.position = box.position
	node.size = box.size
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, box: Rect2, action: Callable, primary := true) -> Button:
	var node := Button.new()
	node.text = text
	node.position = box.position
	node.size = box.size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", BOLD)
	node.add_theme_font_size_override("font_size", 38)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, CREAM)
	parent.add_child(node)
	var surface := FeltSurface.new()
	if not button_texture:
		button_texture = AtlasTexture.new()
		button_texture.atlas = BUTTON
		button_texture.region = Rect2(20, 80, 2132, 530)
	surface.texture = button_texture
	surface.tint = Color.WHITE if primary else Color(0.74, 0.70, 0.62)
	surface.source_margin = Vector2(280, 260)
	surface.border = Vector2(box.size.y * 0.5, box.size.y * 0.5)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.show_behind_parent = true
	node.add_child(surface)
	animate_button(node)
	if action.is_valid(): node.pressed.connect(action)
	return node

static func animate_button(node: Button) -> void:
	node.resized.connect(func(): node.pivot_offset = node.size * 0.5)
	node.pivot_offset = node.size * 0.5
	var state := {"tween": null}
	var move := func(amount: Vector2, duration: float, spring: bool):
		if state.tween: state.tween.kill()
		state.tween = node.create_tween()
		state.tween.set_trans(Tween.TRANS_BACK if spring else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		state.tween.tween_property(node, "scale", amount, duration)
	node.button_down.connect(func(): move.call(Vector2(0.96, 0.93), 0.09, false))
	node.button_up.connect(func(): move.call(Vector2.ONE, 0.28, true))
	node.mouse_entered.connect(func():
		if not node.button_pressed: move.call(Vector2.ONE * 1.018, 0.18, false))
	node.mouse_exited.connect(func(): move.call(Vector2.ONE, 0.2, false))
	node.focus_entered.connect(func(): node.modulate = Color(1.07, 1.07, 1.07))
	node.focus_exited.connect(func(): node.modulate = Color.WHITE)

static func enter(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	node.modulate.a = 0.0
	node.scale = Vector2.ONE * 0.95
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 1.0, 0.22)
	tween.tween_property(node, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func icon(parent: Node, texture: Texture2D, box: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = texture
	node.position = box.position
	node.size = box.size
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
