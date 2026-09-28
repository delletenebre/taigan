extends FeltAnimal

const VIEWS: Array[int] = [0, 0, 2, 0, 0, 1, 3, 1]
const MIRROR: Array[bool] = [false, false, false, true, true, false, false, true]
const TROT_NAMES: Array[StringName] = [&"trot_down_diagonal", &"trot_up_diagonal", &"trot_down", &"trot_up"]

@export var stride_length: float = 38.0
@export var trot_scales := PackedFloat32Array([0.2, 0.2, 0.2, 0.2])
@export var idle_offsets_x := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var stride_distance := 0.0
var heading := PI / 4.0
var sector := 1
var moving := false
@onready var trot: AnimatedSprite2D = $Visual/Trot

func _ready() -> void:
	super._ready()
	# Different starts keep the flock from marching or bouncing in unison.
	stride_distance = fposmod(get_index() * stride_length * 0.381966, stride_length)
	show_pose(0.0)

func set_facing(direction: int, flip: bool) -> void:
	super.set_facing(direction, flip)
	sector = ([3 if flip else 1, 7 if flip else 5, 2, 6] as Array[int])[direction]
	heading = sector * PI / 4.0

func travel(motion: Vector2, delta: float) -> void:
	var before := position
	velocity = motion
	move_and_slide()
	velocity = (position - before) / maxf(delta, 0.00001)
	animate_motion(delta)

func animate_motion(delta: float) -> void:
	var actual_speed := velocity.length()
	moving = actual_speed > (0.6 if moving else 1.5) and state != "carried" and state != "lost"
	if moving:
		last_motion = velocity
		heading = rotate_toward(heading, velocity.angle(), deg_to_rad(480.0) * delta)
		if absf(angle_difference(sector * PI / 4.0, heading)) > deg_to_rad(32.5):
			sector = posmod(roundi(heading / (PI / 4.0)), 8)
		stride_distance = fmod(stride_distance + actual_speed * delta, stride_length)
	show_pose(actual_speed)

func show_pose(actual_speed: float) -> void:
	var direction := VIEWS[sector]
	super.set_facing(direction, MIRROR[sector])
	sprite.position.x = idle_offsets_x[direction] * (-1.0 if MIRROR[sector] else 1.0)
	# Exactly one opaque sprite; no transparency flashes between poses.
	sprite.visible = not moving
	trot.visible = moving
	trot.scale = Vector2.ONE * trot_scales[direction]
	trot.position = Vector2(0, -204.0 * trot_scales[direction])
	trot.animation = TROT_NAMES[direction]
	trot.flip_h = MIRROR[sector]
	trot.frame = int(stride_distance / stride_length * 6.0) % 6
	# Tiny hops at a trot; slow grazing steps remain grounded.
	var hop := maxf(0.0, sin((stride_distance / stride_length - 0.2) * TAU))
	visual.position.y = -2.4 * hop * clampf((actual_speed - 20.0) / 42.0, 0.0, 1.0) if moving else 0.0
	visual.rotation = 0.0
	$Reaction.visible = panic > 0.1 and state == "grazing"
	$Shadow.visible = state != "carried" and state != "lost"
