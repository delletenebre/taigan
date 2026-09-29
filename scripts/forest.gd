extends Node2D
var elapsed := 0.0
@onready var mist: ShaderMaterial = $Mist.material
func _process(delta: float) -> void:
	elapsed += delta
	mist.set_shader_parameter("clock", elapsed)
func set_night(amount: float) -> void:
	var night := clampf(amount,0.0,1.0)
	mist.set_shader_parameter("night",night)
	$Moonlight.enabled = night > 0.0
	$Moonlight.energy = 0.48 * smoothstep(0.0,1.0,night)
