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
var asleep := false
var sleep_remaining := 0.0
var sleep_delay := 0.0
var sleep_at_night := false
var pen_sleep_started := false
var sleep_blend := 0.0
var sleep_clock := 0.0
@onready var trot: AnimatedSprite2D = $Visual/Trot

func _ready() -> void:
	super._ready()
	# Different starts keep the flock from marching or bouncing in unison.
	stride_distance = fposmod(get_index() * stride_length * 0.381966, stride_length)
	reset_sleep_timer()
	show_pose(0.0)

func reset_sleep_timer() -> void:
	sleep_delay = randf_range(2.0, 5.0) if sleep_at_night else randf_range(5.0, 10.0)
	sleep_remaining = sleep_delay

func update_sleep(delta: float, night: bool, allowed: bool) -> void:
	if night != sleep_at_night:
		sleep_at_night = night
		pen_sleep_started = false
		reset_sleep_timer()
	# Proximity and the day/night transition never wake an already sleeping sheep.
	if asleep or state == "carried" or state == "lost": return
	if night and state == "safe" and not pen_sleep_started:
		pen_sleep_started = true
		fall_asleep()
		return
	if not allowed:
		sleep_remaining = sleep_delay
		return
	sleep_remaining -= delta
	if sleep_remaining <= 0.0: fall_asleep()

func fall_asleep() -> void:
	asleep = true
	velocity = Vector2.ZERO
	panic = 0.0
	sleep_clock = 0.0

func wake_from_bark() -> void:
	asleep = false
	# Even sheep in the pen stay awake for a fresh delay after a bark.
	pen_sleep_started = state == "safe"
	reset_sleep_timer()

func set_facing(direction: int, flip: bool) -> void:
	super.set_facing(direction, flip)
	sector = ([3 if flip else 1, 7 if flip else 5, 2, 6] as Array[int])[direction]
	heading = sector * PI / 4.0

func travel(motion: Vector2, delta: float) -> void:
	var before := position
	velocity = Vector2.ZERO if asleep else motion
	move_and_slide()
	velocity = (position - before) / maxf(delta, 0.00001)
	animate_motion(delta)

func animate_motion(delta: float) -> void:
	var resting := asleep and state != "carried" and state != "lost"
	sleep_blend = move_toward(sleep_blend, 1.0 if resting else 0.0, delta * 2.5)
	if resting or sleep_blend > 0.0: sleep_clock += delta
	var actual_speed := 0.0 if asleep else velocity.length()
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
	# Feet stay planted; only a very small, slow breathing motion changes the outline.
	var breath := sin(sleep_clock * TAU / 3.4)
	visual.scale = Vector2(1.0 + breath * 0.006 * sleep_blend, 1.0 + breath * 0.012 * sleep_blend)
	visual.rotation = 0.0
	$Sleep.visible = sleep_blend > 0.001 and state != "carried" and state != "lost"
	$Sleep.animate_sleep(sleep_clock, sleep_blend)
	$Reaction.visible = not asleep and panic > 0.1 and state == "grazing"
	$Shadow.visible = state != "carried" and state != "lost"
