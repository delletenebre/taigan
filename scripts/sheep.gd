extends FeltAnimal

const VIEWS: Array[int] = [0, 0, 2, 0, 0, 1, 3, 1]
const MIRROR: Array[bool] = [false, false, false, true, true, false, false, true]
const TROT_NAMES: Array[StringName] = [&"trot_down_diagonal", &"trot_up_diagonal", &"trot_down", &"trot_up"]
const WAKE_HOP_DURATION := 0.64
const WAKE_CROUCH_DURATION := 0.08
const WAKE_FLIGHT_DURATION := 0.34

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
var sleep_in_pen := false
var sleep_blend := 0.0
var sleep_clock := 0.0
var sleep_material := ShaderMaterial.new()
var wake_hop_clock := WAKE_HOP_DURATION
var wake_hop_height := 17.0
var wake_hop_tilt := 0.0
@onready var trot: AnimatedSprite2D = $Visual/Trot
@onready var shadow: Sprite2D = $Shadow
@onready var shadow_scale := shadow.scale
@onready var shadow_alpha := shadow.modulate.a

func _ready() -> void:
	super._ready()
	sleep_material.shader = preload("res://assets/shaders/sheep_sleep.gdshader")
	sprite.material = sleep_material
	# Different starts keep the flock from marching or bouncing in unison.
	stride_distance = fposmod(get_index() * stride_length * 0.381966, stride_length)
	reset_sleep_timer()
	show_pose(0.0)

func reset_sleep_timer() -> void:
	if state == "safe":
		sleep_delay = randf_range(3.0, 10.0)
	else:
		sleep_delay = randf_range(5.0, 8.0) if sleep_at_night else randf_range(8.0, 14.0)
	sleep_remaining = sleep_delay

func update_sleep(delta: float, night: bool, allowed: bool) -> void:
	var in_pen := state == "safe"
	if night != sleep_at_night or in_pen != sleep_in_pen:
		sleep_at_night = night
		sleep_in_pen = in_pen
		reset_sleep_timer()
	if in_pen and not night:
		asleep = false
		sleep_remaining = sleep_delay
		return
	# Outside the pen, proximity and dawn never wake an already sleeping sheep.
	if asleep or state == "carried" or state == "lost": return
	if not allowed:
		sleep_remaining = sleep_delay
		return
	sleep_remaining -= delta
	if sleep_remaining <= 0.0: fall_asleep()

func fall_asleep() -> void:
	asleep = true
	wake_hop_clock = WAKE_HOP_DURATION
	velocity = Vector2.ZERO
	panic = 0.0
	sleep_clock = 0.0

func wake_from_bark() -> void:
	if asleep and state in ["grazing", "safe"]:
		wake_hop_clock = 0.0
		wake_hop_height = randf_range(15.0, 19.0)
		wake_hop_tilt = deg_to_rad(randf_range(3.0, 5.0)) * (-1.0 if get_index() % 2 == 0 else 1.0)
	asleep = false
	# Even sheep in the pen stay awake for a fresh delay after a bark.
	reset_sleep_timer()

func set_facing(direction: int, flip: bool) -> void:
	super.set_facing(direction, flip)
	sector = ([3 if flip else 1, 7 if flip else 5, 2, 6] as Array[int])[direction]
	heading = sector * PI / 4.0

func travel(motion: Vector2, delta: float) -> void:
	var before := position
	var planted := wake_hop_clock < WAKE_CROUCH_DURATION or (wake_hop_clock >= WAKE_CROUCH_DURATION + WAKE_FLIGHT_DURATION and wake_hop_clock < WAKE_HOP_DURATION)
	velocity = Vector2.ZERO if asleep or planted else motion
	move_and_slide()
	velocity = (position - before) / maxf(delta, 0.00001)
	animate_motion(delta)

func animate_motion(delta: float) -> void:
	if asleep or state in ["carried", "lost"]:
		wake_hop_clock = WAKE_HOP_DURATION
	else:
		wake_hop_clock = minf(WAKE_HOP_DURATION, wake_hop_clock + delta)
	var resting := asleep and state != "carried" and state != "lost"
	var sleep_speed := 12.5 if wake_hop_clock < WAKE_HOP_DURATION else 2.5
	sleep_blend = move_toward(sleep_blend, 1.0 if resting else 0.0, delta * sleep_speed)
	if resting or sleep_blend > 0.0: sleep_clock += delta
	var actual_speed := 0.0 if asleep else velocity.length()
	moving = actual_speed > (0.6 if moving else 1.5) and state != "carried" and state != "lost" and wake_hop_clock >= WAKE_HOP_DURATION
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
	# Tuck the feet into the fleece and settle the belly onto the ground.
	visual.position.y += 7.0 * sleep_blend
	sleep_material.set_shader_parameter("sleep_amount", sleep_blend)
	var breath := sin(sleep_clock * TAU / 3.4)
	visual.scale = Vector2(1.0 + breath * 0.006 * sleep_blend, 1.0 + breath * 0.012 * sleep_blend)
	visual.rotation = 0.0
	show_wake_hop()
	$Sleep.visible = sleep_blend > 0.001 and state != "carried" and state != "lost"
	$Sleep.animate_sleep(sleep_clock, sleep_blend)
	$Reaction.visible = not asleep and panic > 0.1 and state == "grazing"
	$Reaction.position.y = -65.0 + visual.position.y
	shadow.visible = state != "carried" and state != "lost"

func show_wake_hop() -> void:
	# The body springs from its feet; the shadow stays on the pasture.
	shadow.scale = shadow_scale
	shadow.modulate.a = shadow_alpha
	if wake_hop_clock >= WAKE_HOP_DURATION: return
	var lift := 0.0
	if wake_hop_clock < WAKE_CROUCH_DURATION:
		var squeeze := sin(wake_hop_clock / WAKE_CROUCH_DURATION * PI * 0.5)
		visual.scale *= Vector2(1.0 + 0.10 * squeeze, 1.0 - 0.16 * squeeze)
	elif wake_hop_clock < WAKE_CROUCH_DURATION + WAKE_FLIGHT_DURATION:
		var flight := (wake_hop_clock - WAKE_CROUCH_DURATION) / WAKE_FLIGHT_DURATION
		lift = wake_hop_height * 4.0 * flight * (1.0 - flight)
		var stretch := Vector2(0.94, 1.10)
		if flight < 0.18:
			visual.scale *= Vector2(1.10, 0.84).lerp(stretch, smoothstep(0.0, 0.18, flight))
		else:
			visual.scale *= stretch.lerp(Vector2.ONE, smoothstep(0.18, 0.60, flight))
		visual.rotation = wake_hop_tilt * sin(flight * PI)
	else:
		var landing := (wake_hop_clock - WAKE_CROUCH_DURATION - WAKE_FLIGHT_DURATION) / (WAKE_HOP_DURATION - WAKE_CROUCH_DURATION - WAKE_FLIGHT_DURATION)
		var settle := sin(landing * TAU) * exp(-3.0 * landing)
		visual.scale *= Vector2(1.0 + 0.10 * settle, 1.0 - 0.16 * settle)
		visual.rotation = wake_hop_tilt * 0.4 * settle
		lift = maxf(0.0, -settle) * 2.0
	visual.position.y -= lift
	var airborne := lift / wake_hop_height
	shadow.scale *= 1.0 - 0.22 * airborne
	shadow.modulate.a *= 1.0 - 0.28 * airborne
