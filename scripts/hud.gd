extends Control
signal pause_requested
signal bark_requested
signal restart_requested
signal resume_requested
signal timer_skip_requested
signal home_requested
var result_mode := false
var result_count := 0
var result_total := 12
var result_lost := 0
var current_values: Array = [0, 12, 60.0, 0.0, 0, 0.0]
var settings_window: Control
var bark_state_tween: Tween
var bark_recharging := false

func _ready() -> void:
	build_pause_ui()
	build_felt_counters()
	$WolfTimer/Skip.pressed.connect(func(): timer_skip_requested.emit())
	$Pause.pressed.connect(func(): pause_requested.emit())
	$Bark.pressed.connect(func(): bark_requested.emit())
	$Overlay/Card/Resume.pressed.connect(func(): resume_requested.emit())
	$Overlay/Card/Restart.pressed.connect(func(): restart_requested.emit())
	$Overlay/Card/Home.pressed.connect(func(): home_requested.emit())
	$Overlay/Card/Settings.pressed.connect(open_settings)
	Session.language_changed.connect(refresh_language)
	refresh_language()

func build_pause_ui() -> void:
	for child in $Pause.get_children(): child.queue_free()
	$Pause.text = ""
	$Pause.position = Vector2(687, 15)
	$Pause.size = Vector2(116, 116)
	FeltUI.icon($Pause, preload("res://assets/ui/pause-button-felt.png"), Rect2(0, 0, 116, 116))
	FeltUI.animate_button($Pause)
	$SheepCount.size = Vector2(260, 104)
	$SheepCount.get_node("Icon").size.y = 98
	$SheepCount.get_node("Text").size.y = 85
	$WolfTimer.position.x = 416
	$WolfTimer.size = Vector2(260, 104)
	$WolfTimer.get_node("Icon").position.y = 20
	$WolfTimer.get_node("Text").size.y = 85
	var old_bark := $Bark
	remove_child(old_bark)
	old_bark.queue_free()
	var bark_button := FeltUI.button(self, "", Rect2(664, 1225, 140, 140), Callable())
	bark_button.name = "Bark"
	move_child(bark_button, $Overlay.get_index())
	bark_button.add_theme_font_size_override("font_size", 35)
	var old_surface := bark_button.get_child(0)
	bark_button.remove_child(old_surface)
	old_surface.queue_free()
	var surface := FeltUI.icon(bark_button, preload("res://assets/ui/bark-button-felt.png"), Rect2(0, 0, 140, 140))
	surface.name = "Wool"
	surface.show_behind_parent = true
	var state_material := ShaderMaterial.new()
	state_material.shader = preload("res://assets/shaders/felt_button_state.gdshader")
	surface.material = state_material
	var cooldown_digits := FeltNumber.new()
	cooldown_digits.name = "Cooldown"
	cooldown_digits.light = true
	cooldown_digits.position = Vector2(24, 45)
	cooldown_digits.size = Vector2(92, 48)
	cooldown_digits.width_template = "0.0"
	cooldown_digits.hide()
	bark_button.add_child(cooldown_digits)
	var old := $Overlay/Card
	$Overlay.remove_child(old)
	old.queue_free()
	var card := FeltUI.panel($Overlay, Rect2(48, 318, 723, 858))
	card.name = "Card"
	FeltUI.label(card, "", Rect2(54, 63, 615, 80), 56, FeltUI.INK, true).name = "Title"
	var description := FeltUI.label(card, "", Rect2(72, 163, 579, 82), 31, FeltUI.MUTED, true)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	FeltUI.button(card, "", Rect2(76, 288, 571, 114), Callable()).name = "Resume"
	FeltUI.button(card, "", Rect2(76, 425, 571, 114), Callable(), false).name = "Restart"
	FeltUI.button(card, "", Rect2(76, 555, 571, 114), Callable(), false).name = "Settings"
	FeltUI.button(card, "", Rect2(76, 687, 571, 114), Callable(), false).name = "Home"

func refresh_language() -> void:
	$Overlay/Card/Resume.text = Session.t("resume")
	$Overlay/Card/Restart.text = Session.t("restart")
	$Overlay/Card/Settings.text = Session.t("settings")
	$Overlay/Card/Home.text = Session.t("home")
	$WolfTimer/Skip.tooltip_text = ""
	if result_mode: render_result()
	else:
		$Overlay/Card/Title.text = Session.t("pause")
		$Overlay/Card/Description.text = Session.t("pause_note")
	update_values.callv(current_values)

func open_settings() -> void:
	if is_instance_valid(settings_window): return
	settings_window = Control.new()
	settings_window.name = "SettingsWindow"
	settings_window.size = Vector2(819, 1456)
	$Overlay.add_child(settings_window)
	var cloth := FeltUI.icon(settings_window, preload("res://assets/ui/main-jailoo-felt-v2.png"), Rect2(0, 0, 819, 1456))
	cloth.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cloth.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/menu_backdrop.gdshader")
	material.set_shader_parameter("shade", 0.65)
	material.set_shader_parameter("blur", 5.0)
	cloth.material = material
	var settings := SettingsPanel.new()
	settings_window.add_child(settings)
	settings.closed.connect(close_settings)

func close_settings() -> void:
	if is_instance_valid(settings_window):
		$Overlay.remove_child(settings_window)
		settings_window.queue_free()
	settings_window = null

func update_values(count: int, total: int, seconds: float, cooldown: float, lost: int, night: float = 0.0) -> void:
	current_values = [count, total, seconds, cooldown, lost, night]
	$SheepCount/Text.text = "%d/%d" % [count, total]
	$WolfTimer/Text.text = "%02d:%02d" % [int(ceil(seconds)) / 60, int(ceil(seconds)) % 60]
	$SheepCount/Digits.text = $SheepCount/Text.text
	$WolfTimer/Digits.text = $WolfTimer/Text.text
	update_day_icon(night)
	update_bark_button(cooldown)

func update_day_icon(night: float) -> void:
	var amount := clampf(night, 0.0, 1.0)
	var sun: TextureRect = $WolfTimer/Icon/Sun
	var moon: TextureRect = $WolfTimer/Icon/Moon
	sun.modulate.a = 1.0 - smoothstep(0.10, 0.75, amount)
	moon.modulate.a = smoothstep(0.25, 0.90, amount)
	sun.visible = sun.modulate.a > 0.001
	moon.visible = moon.modulate.a > 0.001
	sun.position.y = 3.0 + 16.0 * amount
	moon.position.y = 3.0 - 16.0 * (1.0 - amount)
	sun.rotation = amount * 0.45
	moon.rotation = -0.25 * (1.0 - amount)
	sun.scale = Vector2.ONE * (1.0 - 0.12 * amount)
	moon.scale = Vector2.ONE * (0.88 + 0.12 * amount)

func bump_count() -> void:
	var tween := create_tween()
	tween.tween_property($SheepCount, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property($SheepCount, "scale", Vector2.ONE, 0.2)

func show_pause(value: bool) -> void:
	close_settings()
	result_mode = false
	$Overlay.visible = value
	$Overlay/Card/Resume.show()
	refresh_language()
	if value: FeltUI.enter($Overlay/Card)

func show_result(count: int, total: int, lost: int) -> void:
	result_mode = true
	result_count = count
	result_total = total
	result_lost = lost
	$Overlay.show()
	$Overlay/Card/Resume.hide()
	$Overlay/Card/Restart.position.y = 288
	$Overlay/Card/Settings.position.y = 425
	$Overlay/Card/Home.position.y = 555
	$Overlay/Card.size.y = 726
	render_result()
	FeltUI.enter($Overlay/Card)

func render_result() -> void:
	$Overlay/Card/Title.text = Session.t("win" if result_lost == 0 else "result")
	$Overlay/Card/Title.add_theme_font_size_override("font_size", 48)
	$Overlay/Card/Description.text = Session.t("result_count", [result_count, result_total]) + "\n" + Session.t("win_note" if result_lost == 0 else "lose_note")

func blocks_touch(point: Vector2) -> bool:
	if $Overlay.visible: return true
	for control in [$Pause, $Bark, $WolfTimer/Skip]:
		if control.is_visible_in_tree() and Rect2(Vector2.ZERO, control.size).has_point(control.get_global_transform_with_canvas().affine_inverse() * point): return true
	return false

func build_felt_counters() -> void:
	for panel in [$SheepCount, $WolfTimer]:
		panel.get_node("Text").hide()
		var digits := FeltNumber.new()
		digits.name = "Digits"
		digits.position = Vector2(82, 24)
		digits.size = Vector2(160, 58)
		digits.width_template = "00/00" if panel == $SheepCount else "00:00"
		panel.add_child(digits)

func update_bark_button(cooldown: float) -> void:
	var inactive := cooldown > 0.0
	$Bark.disabled = inactive
	$Bark.text = "" if inactive else Session.t("bark")
	$Bark/Cooldown.visible = inactive
	$Bark/Cooldown.text = "%.1f" % cooldown
	if inactive == bark_recharging: return
	bark_recharging = inactive
	if bark_state_tween: bark_state_tween.kill()
	bark_state_tween = create_tween()
	var material: ShaderMaterial = $Bark/Wool.material
	var previous: Variant = material.get_shader_parameter("inactive")
	bark_state_tween.tween_method(func(amount: float): material.set_shader_parameter("inactive", amount), float(previous) if previous != null else 0.0, 1.0 if inactive else 0.0, 0.18)
