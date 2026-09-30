extends Control
var canvas: Control
var screen: Control
var page := "home"
var background: TextureRect
var changing := false
var backdrop_amount := 0.0
var backdrop_tween: Tween

func _ready() -> void:
	if "--smoke-test" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
		return
	background = TextureRect.new()
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.texture = preload("res://assets/ui/main-jailoo-felt-v2.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/menu_backdrop.gdshader")
	background.material = material
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	canvas = Control.new()
	canvas.size = Vector2(819, 1456)
	add_child(canvas)
	resized.connect(layout)
	layout()
	Session.language_changed.connect(refresh_language)
	show_page("home")
	if "--menu-test" in OS.get_cmdline_user_args():
		var test_runner = load("res://tests/menu.gd").new()
		get_tree().root.add_child.call_deferred(test_runner)
		test_runner.run.call_deferred(self)

func layout() -> void:
	if not canvas: return
	var amount := minf(size.x / 819.0, size.y / 1456.0)
	canvas.scale = Vector2.ONE * amount
	canvas.position = (size - Vector2(819, 1456) * amount) * 0.5

func refresh_language() -> void:
	if page != "settings": show_page(page, false)

func show_page(value: String, animate := true) -> void:
	if changing: return
	if screen:
		canvas.remove_child(screen)
		screen.queue_free()
	page = value
	if backdrop_tween: backdrop_tween.kill()
	backdrop_tween = create_tween()
	backdrop_tween.tween_method(update_backdrop, backdrop_amount, 0.0 if value == "home" else 0.65, 0.3)
	screen = Control.new()
	screen.name = "Screen"
	screen.size = Vector2(819, 1456)
	canvas.add_child(screen)
	match value:
		"home": build_home()
		"settings":
			var settings := SettingsPanel.new()
			settings.name = "Settings"
			screen.add_child(settings)
			settings.closed.connect(func(): show_page("home"))
	if animate: FeltUI.enter(screen)

func navigate(value: String) -> void:
	if changing: return
	changing = true
	var tween := create_tween().set_parallel()
	tween.tween_property(screen, "modulate:a", 0.0, 0.12)
	tween.tween_property(screen, "position:y", -14.0, 0.12)
	tween.chain().tween_callback(func():
		changing = false
		show_page(value))

func build_home() -> void:
	var title := FeltUI.label(screen, Session.t("brand"), Rect2(48, 86, 723, 125), 98, FeltUI.INK, true)
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.94, 0.78, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_constant_override("shadow_offset_x", 0)
	var play := FeltUI.button(screen, "", Rect2(130, 974, 559, 144), func(): Session.start_level(0))
	play.name = "Play"
	play.tooltip_text = Session.t("play")
	FeltUI.label(play, Session.t("play"), Rect2(20, 12, 519, 64), 46, FeltUI.CREAM, true)
	FeltUI.label(play, Session.t("level_1"), Rect2(20, 77, 519, 40), 28, FeltUI.CREAM, true)
	FeltUI.button(screen, Session.t("settings"), Rect2(130, 1146, 559, 120), func(): navigate("settings"), false).name = "Settings"
	FeltUI.button(screen, Session.t("controls_title"), Rect2(130, 1290, 559, 114), show_controls, false).add_theme_font_size_override("font_size", 32)

func show_controls() -> void:
	var shade := ColorRect.new()
	shade.name = "Help"
	shade.color = Color(0.16, 0.12, 0.09, 0.5)
	shade.size = screen.size
	screen.add_child(shade)
	var card := FeltUI.panel(shade, Rect2(45, 380, 729, 670))
	FeltUI.label(card, Session.t("controls_title"), Rect2(55, 70, 619, 80), 48, FeltUI.INK, true)
	var text := FeltUI.label(card, Session.t("controls"), Rect2(72, 195, 585, 260), 33, FeltUI.INK, true)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FeltUI.button(card, Session.t("back"), Rect2(110, 510, 509, 110), func(): shade.queue_free())
	FeltUI.enter(card)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if screen.has_node("Help"): screen.get_node("Help").queue_free()
		elif page != "home": navigate("home")

func update_backdrop(amount: float) -> void:
	backdrop_amount = amount
	background.material.set_shader_parameter("shade", amount)
	background.material.set_shader_parameter("blur", amount * (5.0 / 0.65))
