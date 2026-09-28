class_name FeltAnimal
extends CharacterBody2D

@export_enum("sheep", "dog", "wolf") var species: String = "sheep"
@export var speed: float = 62.0
@export var atlas_row: int = 0
@export var atlas_columns: int = 4
@export var atlas_rows: int = 3
@export var art_width: float = 62.0
@export var frame_regions: Array[Rect2] = []
@export var frame_feet_y: PackedFloat32Array = []
@export var initial_direction: int = 0
@export var initially_safe: bool = false
var state: String = "grazing"
var destination := Vector2.ZERO
var panic: float = 0.0
var bark_direction := Vector2.ZERO
var phase: float = 0.0
var carrying: FeltAnimal
var wander := Vector2.ZERO
var wander_time: float = 0.0
var scared: float = 0.0
var last_motion := Vector2.ZERO
var facing: int = 0
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var visual: Node2D = $Visual

func _ready() -> void:
	phase = float(get_index()) * 1.83
	state = "safe" if initially_safe else "grazing"
	set_facing(initial_direction, false)

func set_facing(direction: int, flip: bool) -> void:
	facing = direction
	var size := sprite.texture.get_size()
	var cell := Vector2(size.x / atlas_columns, size.y / atlas_rows)
	var frame := atlas_row * atlas_columns + direction
	sprite.region_rect = Rect2(Vector2((frame % atlas_columns) * cell.x, (frame / atlas_columns) * cell.y), cell)
	# The generated dog's running poses extend beyond uniform grid cells.
	# Explicit regions prevent a neighboring paw appearing beside another view.
	if species == "dog":
		var frames: Array[Rect2] = [Rect2(10, 420, 328, 352), Rect2(360, 420, 287, 352), Rect2(670, 420, 240, 352), Rect2(995, 420, 245, 352)]
		sprite.region_rect = frames[direction]
	# Some generated poses cross the nominal grid line. Keep their complete
	# silhouettes and place each pose's feet on the same ground point.
	if direction < frame_regions.size():
		sprite.region_rect = frame_regions[direction]
	if direction < frame_feet_y.size():
		sprite.position.y = (sprite.region_rect.size.y * 0.5 - frame_feet_y[direction]) * sprite.scale.y
	sprite.flip_h = flip

func animate_motion(delta: float) -> void:
	var moving := velocity.length() > 4.0
	phase += delta * (12.0 if moving else 2.0)
	if moving:
		last_motion = velocity
		if absf(velocity.x) > absf(velocity.y) * 0.6:
			set_facing(0 if velocity.y >= -8.0 else 1, velocity.x < 0 if velocity.y >= -8.0 else velocity.x > 0)
		else:
			set_facing(2 if velocity.y > 0 else 3, false)
	visual.position.y = -absf(sin(phase)) * (3.0 if moving else 0.35)
	visual.rotation = sin(phase) * (0.025 if moving else 0.008)
	$Reaction.visible = panic > 0.1 and state == "grazing"
	$Shadow.modulate.a = 0.65 if state == "carried" else 1.0

func travel(motion: Vector2, delta: float) -> void:
	velocity = motion
	move_and_slide()
	animate_motion(delta)
