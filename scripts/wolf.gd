extends FeltAnimal

const VIEWS: Array[int] = [0, 0, 2, 0, 0, 1, 3, 1]
const MIRROR: Array[bool] = [false, false, false, true, true, false, false, true]
const TROT_NAMES: Array[StringName] = [&"trot_down_diagonal", &"trot_up_diagonal", &"trot_down", &"trot_up"]
@export var stride_length: float = 46.0
@export var turn_speed_degrees: float = 480.0
@export var trot_scales := PackedFloat32Array([0.3, 0.3, 0.3, 0.3])
@export var idle_offsets_x := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var stride_distance := 0.0
var heading := PI / 4.0
var sector := 1
var moving := false
@onready var trot: AnimatedSprite2D = $Visual/Trot

func _ready() -> void:
	super._ready()
	stride_distance = fposmod(get_index() * stride_length * 0.381966, stride_length)
	show_pose()

func set_facing(direction: int, flip: bool) -> void:
	super.set_facing(direction, flip)
	sector = ([3 if flip else 1, 7 if flip else 5, 2, 6] as Array[int])[direction]
	heading = sector * PI / 4.0

func travel(motion: Vector2, delta: float) -> void:
	var before := position
	velocity = motion
	move_and_slide()
	# Steps follow actual displacement, including when a collision stops us.
	velocity = (position - before) / maxf(delta, 0.00001)
	animate_motion(delta)

func animate_motion(delta: float) -> void:
	var actual_speed := velocity.length()
	moving = actual_speed > (3.0 if moving else 6.0)
	if moving:
		last_motion = velocity
		heading = rotate_toward(heading, velocity.angle(), deg_to_rad(turn_speed_degrees) * delta)
		if absf(angle_difference(sector * PI / 4.0, heading)) > deg_to_rad(32.5):
			sector = posmod(roundi(heading / (PI / 4.0)), 8)
		stride_distance = fmod(stride_distance + actual_speed * delta, stride_length)
	show_pose()

func show_pose() -> void:
	var direction := VIEWS[sector]
	super.set_facing(direction, MIRROR[sector])
	sprite.position.x = idle_offsets_x[direction] * (-1.0 if MIRROR[sector] else 1.0)
	# One fully opaque pose avoids pale flashes during turns and stop/start.
	sprite.visible = not moving
	trot.visible = moving
	trot.animation = TROT_NAMES[direction]
	trot.flip_h = MIRROR[sector]
	trot.scale = Vector2.ONE * trot_scales[direction]
	trot.position = Vector2(0, -204.0 * trot_scales[direction])
	trot.frame = int(stride_distance / stride_length * 6.0) % 6
	# Paw contacts and body motion are in the art, with no whole-sprite hopping.
	visual.position = Vector2.ZERO
	visual.rotation = 0.0
	$Reaction.visible = false
