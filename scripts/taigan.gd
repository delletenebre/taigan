extends FeltAnimal

const RUN_ANIMATIONS: Array[StringName] = [
	&"run_side", &"run_down_diagonal", &"run_down", &"run_down_diagonal",
	&"run_side", &"run_up_diagonal", &"run_up", &"run_up_diagonal",
]
const IDLE_VIEWS: Array[int] = [0, 0, 2, 0, 0, 1, 3, 1]
const MIRROR: Array[bool] = [false, false, false, true, true, false, false, true]

@export var stride_length: float = 86.0
## Visual turning only: steering and collision movement remain immediate.
@export var turn_speed_degrees: float = 540.0
@export var direction_margin_degrees: float = 9.0
@export var idle_offsets_x := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var run_scales: Dictionary = {"run_down_diagonal": 0.253}
@export var run_offsets: Dictionary = {"run_down_diagonal": Vector2(0, -51.612)}
var stride_distance: float = 0.0
var heading: float = PI / 4.0
var sector: int = 1
var moving: bool = false
@onready var run_sprite: AnimatedSprite2D = $Visual/Run

func _ready() -> void:
	super._ready()
	show_pose(false)

func set_facing(direction: int, flip: bool) -> void:
	super.set_facing(direction, flip)
	sector = ([3 if flip else 1, 7 if flip else 5, 2, 6] as Array[int])[direction]
	heading = sector * PI / 4.0

func travel(motion: Vector2, delta: float) -> void:
	var before := position
	velocity = motion
	move_and_slide()
	# Collision may cancel the requested motion. Only actual travel drives steps.
	velocity = (position - before) / maxf(delta, 0.00001)
	animate_motion(delta)

func animate_motion(delta: float) -> void:
	var actual_speed := velocity.length()
	# Separate start/stop thresholds prevent tiny navigation corrections flickering idle.
	moving = actual_speed > (3.0 if moving else 8.0)
	if moving:
		last_motion = velocity
		heading = rotate_toward(heading, velocity.angle(), deg_to_rad(turn_speed_degrees) * delta)
		var sector_center := sector * PI / 4.0
		# Keep the current view a little past its boundary before choosing another.
		if absf(angle_difference(sector_center, heading)) > PI / 8.0 + deg_to_rad(direction_margin_degrees):
			sector = posmod(roundi(heading / (PI / 4.0)), 8)
		stride_distance = fmod(stride_distance + actual_speed * delta, stride_length)
	else:
		stride_distance = stride_length / 8.0
	show_pose(moving)

func show_pose(is_running: bool) -> void:
	super.set_facing(IDLE_VIEWS[sector], MIRROR[sector])
	sprite.position.x = idle_offsets_x[IDLE_VIEWS[sector]] * (-1.0 if MIRROR[sector] else 1.0)
	visual.position = Vector2.ZERO
	visual.rotation = 0.0
	# Draw one opaque pose: crossfading two alpha sprites exposed the bright
	# ground through the black coat. Heading smoothing and stride stay continuous.
	run_sprite.visible = is_running
	sprite.visible = not is_running
	var animation_name := RUN_ANIMATIONS[sector]
	run_sprite.animation = animation_name
	run_sprite.flip_h = MIRROR[sector]
	run_sprite.scale = Vector2.ONE * float(run_scales.get(String(animation_name), 0.253))
	run_sprite.position = run_offsets.get(String(animation_name), Vector2(0, -51.612))
	# All views sample the same distance-based phase, including during a turn.
	run_sprite.frame = int(stride_distance / stride_length * 8.0) % 8
	$Reaction.visible = false
