class_name HerdActor
extends Node3D

@export var kind: String = "sheep"
var state: String = "grazing"
var heading: Vector2 = Vector2.DOWN
var motion: Vector2 = Vector2.ZERO
var phase: float = 0.0
var fear_timer: float = 0.0
var target: HerdActor
var carried_by: HerdActor
var exit_point: Vector2
var visual: Node3D
var limbs: Array[Node3D] = []
var tail: Node3D
var body: Node3D
var route: PackedVector2Array = PackedVector2Array()
var route_timer: float = 0.0
var base_y: float = 0.03
var calm_time: float = 0.0
var graze_timer: float = 0.0
var graze_direction := Vector2.ZERO
var grazing_head: float = 0.0
var head: Node3D
var startle_time: float = 0.0
var startle_origin := Vector2.ZERO
var startle_target := Vector2.ZERO
var bark_timer: float = 0.0
var bark_away := Vector2.ZERO
var edge_pressure: float = 0.0
var fall_timer: float = 0.0
var fall_origin := Vector2.ZERO
var fall_outward := Vector2.ZERO
var return_point := Vector2.ZERO
var recovery_timer: float = 0.0
var reacting_to_dog: bool = false
@onready var reaction: Node3D = get_node_or_null("Reaction")

func react_to_dog(active: bool, bark: bool = false) -> void:
	if reaction and active and (not reacting_to_dog or bark):
		reaction.get_node("AnimationPlayer").play("notice")
	reacting_to_dog = active


func startle(destination: Vector2) -> void:
	startle_time = 0.34
	startle_origin = planar()
	startle_target = destination
	$Startle/AnimationPlayer.play("hop")
	react_to_dog(true, true)

func stop_startle() -> void:
	startle_time = 0.0
	if has_node("Startle"):
		$Startle/AnimationPlayer.stop()
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE

func _ready() -> void:
	visual = $Visual
	_collect_parts(visual)
	phase = randf() * TAU

func _collect_parts(node: Node) -> void:
	for child in node.get_children():
		var label: String = str(child.name)
		if child is Node3D:
			if label.begins_with("Front") or label.begins_with("Rear"):
				limbs.append(child)
			if label.begins_with("Tail"):
				tail = child
			if label.begins_with("Head"):
				head = child
			if label.begins_with("Body"):
				body = child
		_collect_parts(child)

func planar() -> Vector2:
	return Vector2(position.x, position.z)

func place(p: Vector2) -> void:
	position = Vector3(p.x, base_y, p.y)

func animate(delta: float) -> void:
	if reaction:
		if state != "grazing": reaction.hide()
		elif reaction.visible:
			var camera := get_viewport().get_camera_3d()
			if camera: reaction.quaternion = global_basis.get_rotation_quaternion().inverse() * camera.global_basis.get_rotation_quaternion()
	var speed: float = motion.length()
	if head:
		head.rotation.x = lerpf(head.rotation.x, grazing_head * 0.48, minf(delta * 3, 1))
	if state != "falling":
		visual.rotation.z = sin(phase * 4) * minf(edge_pressure * 0.035, 0.08)
	phase += delta * (3.0 + speed * 4.5)
	if speed > 0.08:
		heading = motion.normalized()
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(heading.x, heading.y), minf(delta * 10.0, 1.0))
	for i in limbs.size():
		limbs[i].rotation.x = sin(phase + (PI if i == 1 or i == 2 else 0.0)) * minf(speed * 0.13, 0.52)
	if tail:
		tail.rotation.y = sin(phase * 0.6) * 0.14
	if body:
		body.position.y = sin(phase * 2.0) * minf(speed * 0.008, 0.025)
