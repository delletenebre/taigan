class_name PastureControls
extends Control
signal bark_requested

@export var preview_touch_controls: bool = false

var direction: Vector2 = Vector2.ZERO
var stick_center: Vector2
var stick_tip: Vector2
var finger: int = -1
var mouse_drag: bool = false
var stick_radius: float = 70.0
var bark_center: Vector2
var cooldown: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	bark_center = Vector2(size.x - 102.0, size.y - 136.0)
	if finger < 0 and not mouse_drag:
		stick_center = Vector2(128.0, size.y - 144.0)
		stick_tip = stick_center
	queue_redraw()

var touches: Dictionary = {}
var last_tap_time: float = -1.0
var last_tap_position := Vector2.ZERO
var mouse_press_position := Vector2.ZERO
var mouse_press_time: float = 0.0
var mouse_tap_valid: bool = false

func _unhandled_input(event: InputEvent) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(bark_center) < 65.0:
				bark_requested.emit()
				return
			touches[event.index] = {"position": event.position, "time": now, "valid": true}
			if event.position.y > size.y * 0.45 and event.position.x < size.x * 0.6 and finger < 0:
				finger = event.index
				stick_center = event.position
				_update_stick(event.position)
		else:
			if touches.has(event.index):
				var tap: Dictionary = touches[event.index]
				if tap.valid and now - float(tap.time) < 0.25:
					_register_tap(event.position, now)
				touches.erase(event.index)
			if event.index == finger:
				finger = -1
				direction = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if touches.has(event.index) and event.position.distance_to(touches[event.index].position) > 22:
			touches[event.index].valid = false
		if event.index == finger: _update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.distance_to(bark_center) < 65:
				bark_requested.emit()
				return
			mouse_press_position = event.position
			mouse_press_time = now
			mouse_tap_valid = true
			if event.position.y > size.y * 0.45 and event.position.x < size.x * 0.6:
				mouse_drag = true
				stick_center = event.position
				_update_stick(event.position)
		else:
			if mouse_tap_valid and now - mouse_press_time < 0.25:
				_register_tap(event.position, now)
			mouse_tap_valid = false
			mouse_drag = false
			direction = Vector2.ZERO
	elif event is InputEventMouseMotion:
		if event.position.distance_to(mouse_press_position) > 22: mouse_tap_valid = false
		if mouse_drag: _update_stick(event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		bark_requested.emit()

func _register_tap(p: Vector2, now: float) -> void:
	if last_tap_time >= 0 and now - last_tap_time <= 0.32 and p.distance_to(last_tap_position) <= 64:
		last_tap_time = -1.0
		bark_requested.emit()
	else:
		last_tap_time = now
		last_tap_position = p

func reset_gestures() -> void:
	touches.clear()
	finger = -1
	mouse_drag = false
	mouse_tap_valid = false
	direction = Vector2.ZERO
	last_tap_time = -1

func _update_stick(p: Vector2) -> void:
	var offset: Vector2 = (p - stick_center).limit_length(stick_radius)
	stick_tip = stick_center + offset
	direction = offset / stick_radius

func movement() -> Vector2:
	var keys := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	return keys.limit_length() if keys.length() > 0.0 else direction

func _draw() -> void:
	if not DisplayServer.is_touchscreen_available() and not preview_touch_controls and not mouse_drag: return
	var gold := Color("d5bd89")
	draw_circle(stick_center, stick_radius + 6.0, Color(0.16, 0.14, 0.10, 0.5))
	draw_arc(stick_center, stick_radius, 0, TAU, 64, Color(gold, 0.5), 2.0, true)
	draw_circle(stick_tip, 27.0, Color(gold, 0.65))
	draw_circle(bark_center, 59.0, Color("332c23"))
	draw_arc(bark_center, 55.0, 0, TAU, 64, gold, 2.0, true)
	for i in 3:
		draw_arc(bark_center + Vector2(-13, 0), 12.0 + i * 12.0, -0.9, 0.9, 16, gold, 3.0, true)
	if cooldown > 0:
		draw_arc(bark_center, 62.0, -PI / 2, -PI / 2 + TAU * cooldown / 2.4, 48, Color("dc8c58"), 4.0, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_gestures()
