class_name PastureCamera
extends Camera3D

@export var follow_speed: float = 4.5
@export var look_ahead: float = 1.35
@export var portrait_vertical_span: float = 12.5
@export var desktop_vertical_span: float = 12.0
@export var resting_offset := Vector3(-1.2, 0, -1.2)
@export var minimum_focus := Vector2(-5.2, -8.2)
@export var maximum_focus := Vector2(5.2, 8.0)

var target: Node3D
var focus := Vector3.ZERO
var camera_offset := Vector3.ZERO
var lead := Vector3.ZERO
var previous_target_position := Vector3.ZERO

func _ready() -> void:
	# Following translates the authored isometric transform, never rotates it.
	camera_offset = position
	get_viewport().size_changed.connect(_update_framing)
	_update_framing()

func follow(actor: Node3D) -> void:
	target = actor
	previous_target_position = target.global_position
	lead = Vector3.ZERO
	focus = _bounded_focus(target.global_position + resting_offset)
	global_position = focus + camera_offset

func _update_framing() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	size = portrait_vertical_span if viewport_size.x < viewport_size.y else desktop_vertical_span

func _bounded_focus(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, minimum_focus.x, maximum_focus.x), 0, clampf(point.z, minimum_focus.y, maximum_focus.y))

func advance(delta: float) -> void:
	if not is_instance_valid(target): return
	if delta <= 0:
		follow(target)
		return
	var velocity: Vector3 = (target.global_position - previous_target_position) / delta
	previous_target_position = target.global_position
	velocity.y = 0
	var desired_lead: Vector3 = velocity.limit_length(5.3) * (look_ahead / 5.3)
	lead = lead.lerp(desired_lead, 1.0 - exp(-delta * 2.5))
	var desired: Vector3 = _bounded_focus(target.global_position + resting_offset + lead)
	focus = focus.lerp(desired, 1.0 - exp(-delta * follow_speed))
	global_position = focus + camera_offset
