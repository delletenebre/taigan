class_name FeltLevel
extends Node2D

const CELL := 10
var grid := AStarGrid2D.new()
var night_strength := 0.0
@onready var ground: Node2D = $Walkable
@onready var obstacles: Node2D = $Obstacles
@onready var entrance: Marker2D = $Markers/Entrance
@onready var pen_center: Marker2D = $Markers/PenCenter
@onready var wolf_spawn: Marker2D = $Markers/WolfSpawn

func _ready() -> void:
	grid.region = Rect2i(0, 0, 82, 146)
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL / 2.0, CELL / 2.0)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in 82:
		for y in 146:
			grid.set_point_solid(Vector2i(x, y), not clear_for_actor(Vector2(x * CELL + 5, y * CELL + 5)))
	ground.hide()

func set_night(amount: float) -> void:
	var night := clampf(amount, 0.0, 1.0)
	night_strength = night
	modulate = Color.WHITE.lerp(Color(0.38, 0.46, 0.64), night)
	var light: PointLight2D = $Markers/WolfSpawn/TrailLight
	light.enabled = night > 0.0
	light.energy = 0.25 * smoothstep(0.0, 0.25, night)
	$YurtAtmosphere.set_night(night)
	$Actors/WolfForest.set_night(night)

func walkable(p: Vector2) -> bool:
	var inside := false
	for area in ground.get_children():
		if Geometry2D.is_point_in_polygon(p - area.position, area.polygon):
			inside = true
			break
	if not inside: return false
	for obstacle in obstacles.get_children():
		var shape: CollisionPolygon2D = obstacle.get_node("Shape")
		if Geometry2D.is_point_in_polygon(p - obstacle.position, shape.polygon): return false
	return true

func clear_for_actor(p: Vector2) -> bool:
	if not walkable(p): return false
	for offset in [Vector2(12, 0), Vector2(-12, 0), Vector2(0, 12), Vector2(0, -12)]:
		if not walkable(p + offset): return false
	return true

func nearest_cell(p: Vector2) -> Vector2i:
	var cell := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	cell = cell.clamp(Vector2i.ZERO, Vector2i(81, 145))
	if not grid.is_point_solid(cell): return cell
	for radius in range(1, 30):
		var best := Vector2i(-1, -1)
		var distance := INF
		for x in range(maxi(0, cell.x - radius), mini(82, cell.x + radius + 1)):
			for y in range(maxi(0, cell.y - radius), mini(146, cell.y + radius + 1)):
				var test := Vector2i(x, y)
				if grid.is_point_solid(test): continue
				var d := Vector2(test).distance_squared_to(Vector2(cell))
				if d < distance:
					distance = d
					best = test
		if best.x >= 0: return best
	return cell

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	return grid.get_point_path(nearest_cell(from), nearest_cell(to))

func steer(from: Vector2, to: Vector2) -> Vector2:
	var path := route(from, to)
	if path.size() < 2: return (to - from).normalized() if from.distance_to(to) > 8 else Vector2.ZERO
	return (path[1] - from).normalized()

func safe_motion(p: Vector2, motion: Vector2, delta: float) -> Vector2:
	var next := p + motion * delta
	if walkable(next): return motion
	if walkable(p + Vector2(motion.x, 0) * delta): return Vector2(motion.x, 0)
	if walkable(p + Vector2(0, motion.y) * delta): return Vector2(0, motion.y)
	return Vector2.ZERO

func in_pen(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, $Pen/Shape.polygon)
