extends Node2D

var elapsed := 0.0
var night := 0.0
@onready var smoke_material: ShaderMaterial = $Smoke.material
@onready var doorway: Polygon2D = $Doorway
@onready var doorstep: Sprite2D = $DoorstepGlow
@onready var warmth: PointLight2D = $Warmth

func _process(delta: float) -> void:
	elapsed += delta
	smoke_material.set_shader_parameter("clock", elapsed)
	update_warmth()

func set_night(amount: float) -> void:
	night = clampf(amount, 0.0, 1.0)
	update_warmth()

func update_warmth() -> void:
	# Unequal slow waves suggest a small indoor fire without sharp flashes.
	var flicker := 0.95 + 0.035 * sin(elapsed * 1.7) + 0.015 * sin(elapsed * 3.13 + 1.1)
	doorway.visible = night > 0.0
	doorway.material.set_shader_parameter("glow", night * 0.90 * flicker)
	doorstep.visible = night > 0.0
	doorstep.material.set_shader_parameter("glow", night * flicker)
	doorstep.position.x = 816.0 + 1.4 * sin(elapsed * 0.9)
	doorstep.rotation = 0.015 * sin(elapsed * 0.7)
	warmth.enabled = night > 0.0
	warmth.energy = night * 0.95 * flicker
	warmth.position = Vector2(816.0 + 1.4 * sin(elapsed * 0.9), 323.0 + 0.6 * sin(elapsed * 1.3))
