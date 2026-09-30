class_name SettingsPanel
extends Control
signal closed
var session: Node
var content: Control

func _ready() -> void:
	session = get_node("/root/Session")
	session.language_changed.connect(build)
	build()

func build() -> void:
	if content:
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.size = Vector2(819, 1456)
	add_child(content)
	FeltUI.button(content, "‹  " + session.t("back"), Rect2(48, 45, 220, 114), func(): closed.emit(), false).name = "Back"
	FeltUI.label(content, session.t("settings"), Rect2(48, 175, 723, 90), 62, FeltUI.CREAM, true)
	FeltUI.label(content, session.t("saved"), Rect2(48, 275, 723, 60), 30, FeltUI.CREAM, true)
	FeltUI.panel(content, Rect2(40, 370, 739, 890))
	FeltUI.label(content, session.t("language"), Rect2(100, 425, 619, 60), 38)
	var names := ["Русский", "Кыргызча", "English"]
	var codes := ["ru", "ky", "en"]
	for i in 3:
		var code: String = codes[i]
		var button := FeltUI.button(content, names[i], Rect2(94 + i * 214, 510, 203, 114), func(): session.set_language(code), session.language == code)
		button.name = "Language_" + code
		button.add_theme_font_size_override("font_size", 29)
		button.tooltip_text = names[i]
	FeltUI.label(content, session.t("sound"), Rect2(100, 665, 619, 55), 38)
	var buses := ["Master", "Music", "Effects"]
	var keys := ["master", "music", "effects"]
	for i in 3:
		var bus: String = buses[i]
		var y := 745.0 + 160.0 * i
		FeltUI.label(content, session.t(keys[i]), Rect2(100, y, 475, 48), 32)
		var percent := FeltUI.label(content, "%d%%" % roundi(session.volumes[bus] * 100), Rect2(582, y, 134, 48), 32, FeltUI.MUTED)
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var slider := HSlider.new()
		slider.name = bus + "Volume"
		slider.position = Vector2(105, y + 52)
		slider.size = Vector2(608, 114)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = roundi(session.volumes[bus] * 100)
		slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var track := StyleBoxFlat.new()
		track.bg_color = Color("92795c")
		track.set_corner_radius_all(8)
		track.content_margin_top = 7
		track.content_margin_bottom = 7
		var fill := track.duplicate()
		fill.bg_color = Color("ad5c35")
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
		var empty := GradientTexture2D.new()
		empty.width = 1
		empty.height = 1
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color.TRANSPARENT, Color.TRANSPARENT])
		empty.gradient = gradient
		slider.add_theme_icon_override("grabber", empty)
		slider.add_theme_icon_override("grabber_highlight", empty)
		content.add_child(slider)
		var knob := FeltUI.icon(slider, preload("res://assets/ui/button_round.png"), Rect2(0, 26, 62, 62))
		var update := func(): knob.position.x = lerpf(0, slider.size.x - 62, slider.value / 100.0)
		slider.value_changed.connect(func(value):
			session.set_volume(bus, value / 100.0)
			percent.text = "%d%%" % roundi(value)
			update.call())
		update.call()
	# The containing screen animates on entry; language changes keep controls still.
