extends Node2D
var elapsed := 0.0
const HEADINGS := [PI/4.0,-3.0*PI/4.0,PI/2.0,-PI/2.0]
func _physics_process(delta: float) -> void:
	elapsed += delta
	for i in range(4):
		var wolf = get_node("Wolf%d"%i)
		wolf.velocity = Vector2.RIGHT.rotated(HEADINGS[i])*51.0
		wolf.animate_motion(delta)
	var runner = $Runner
	var t := fmod(elapsed,8.0)
	runner.travel(Vector2(51,0) if t<3.0 else (Vector2(-51,0) if t>4.0 and t<7.0 else Vector2.ZERO),delta)
