extends Node2D
var elapsed := 0.0
var night_amount := 0.0
@onready var mist: ShaderMaterial = $Mist.material
@onready var deep_mist: ShaderMaterial = $DeepAtmosphere/Mist.material
@onready var rays: ShaderMaterial = $DeepAtmosphere/MoonRays.material
@onready var rolling_mist: ShaderMaterial = $RollingMist.material
@onready var crowns: ShaderMaterial = $Tree0/Crown.material

func _process(delta: float) -> void:
	elapsed += delta
	for effect in [mist, deep_mist, rolling_mist, rays]:
		effect.set_shader_parameter("clock", elapsed)
	update_moonlight()

func set_night(amount: float) -> void:
	var night := clampf(amount,0.0,1.0)
	for effect in [mist, deep_mist, rolling_mist, rays, crowns]:
		effect.set_shader_parameter("night",night)
	night_amount = night
	update_moonlight()

func update_moonlight() -> void:
	var breath := 0.96 + 0.025 * sin(elapsed * 0.53) + 0.015 * sin(elapsed * 0.91 + 0.7)
	$Moonlight.enabled = night_amount > 0.0
	$Moonlight.energy = 0.46 * smoothstep(0.0,1.0,night_amount) * breath
	$Moonlight.position = Vector2(166 + 2.4 * sin(elapsed * 0.37), 154 + 1.5 * sin(elapsed * 0.23))
