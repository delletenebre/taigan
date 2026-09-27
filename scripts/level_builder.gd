class_name PastureLevel
extends Node3D

@export_group("Pen entrance assistance")
@export_range(0.0, 6.0, 0.1) var pen_assist_radius: float = 1.8
@export_range(0.3, 3.0, 0.05) var pen_assist_half_width: float = 0.95
@export var pen_assist_strength: float = 0.85

var config: Dictionary
var models: Dictionary = {}
var obstacles: Array[Rect2] = []
var river_z: float = -4.0
var bridge_x: Array = [-6.0, 6.0]
var navigation := AStarGrid2D.new()
var pen_center := Vector2(0, -15)
var half_width: float = 12.0
var half_depth: float = 20.0
var contour := PackedVector2Array()
var torch: OmniLight3D
var gate_left: Node3D
var gate_right: Node3D

func build(data: Dictionary) -> void:
	# All visible objects, characters and collisions are authored in level_01.tscn.
	config = data
	obstacles.clear()
	contour.clear()
	var raw: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/landform_contour.json"))
	for point in raw:
		contour.append(Vector2(float(point[0]) * data.landform_scale[0], float(point[1]) * data.landform_scale[1]))
	half_width = float(data.bounds[0]) / 2.0
	half_depth = float(data.bounds[1]) / 2.0
	river_z = float(data.river_z)
	bridge_x = data.bridge_x
	pen_center = Vector2(data.pen_center[0], data.pen_center[1])
	for obstacle in $CollisionMap.get_children():
		var extent: Vector2 = obstacle.get_meta("extent")
		add_obstacle(Vector2(obstacle.position.x, obstacle.position.z), extent)
	gate_left = find_part($Camp/Gate, "GateLeft")
	gate_right = find_part($Camp/Gate, "GateRight")
	if gate_left: gate_left.rotation.y = -1.35
	if gate_right: gate_right.rotation.y = 1.35
	_rebuild_navigation()

func find_part(node: Node, prefix: String) -> Node3D:
	for child in node.get_children():
		if str(child.name).begins_with(prefix): return child as Node3D
		var found: Node3D = find_part(child, prefix)
		if found: return found
	return null

func add_obstacle(center: Vector2, extent: Vector2) -> void:
	obstacles.append(Rect2(center - extent / 2, extent))

func _ground_passable(p: Vector2, radius: float) -> bool:
	if not Geometry2D.is_point_in_polygon(p, contour) or edge_distance(p) < radius: return false
	if absf(p.y - river_center(p.x)) < float(config.river_half_width) + radius:
		var on_bridge: bool = false
		for x in bridge_x:
			if absf(p.x - float(x)) < float(config.bridge_half_width) - radius: on_bridge = true
		if not on_bridge: return false
	return true

func passable(p: Vector2, radius: float = 0.35) -> bool:
	if not _ground_passable(p, radius): return false
	for rect in obstacles:
		if rect.grow(radius).has_point(p): return false
	return true

func slide(from: Vector2, displacement: Vector2, radius: float = 0.35) -> Vector2:
	var next: Vector2 = from + displacement
	if passable(next, radius): return next
	if passable(from + Vector2(displacement.x, 0), radius): return from + Vector2(displacement.x, 0)
	if passable(from + Vector2(0, displacement.y), radius): return from + Vector2(0, displacement.y)
	return from

func bark_escape_target(from: Vector2, away: Vector2) -> Vector2:
	# Permit exit from an initial shallow overlap, but never cross a new obstacle.
	var initial: Array[Rect2] = []
	for rect in obstacles:
		if rect.grow(0.33).has_point(from): initial.append(rect)
	var direction := away.normalized() if away.length_squared() > 0.001 else Vector2.DOWN
	for distance in [0.48, 0.65, 0.30]:
		for angle in [0.0, 0.45, -0.45, 0.9, -0.9, 1.5, -1.5, PI]:
			var target: Vector2 = from + direction.rotated(angle) * distance
			if not passable(target, 0.33): continue
			var clear := true
			for step in range(1, 17):
				var point := from.lerp(target, float(step) / 16.0)
				if not _ground_passable(point, 0.33):
					clear = false
					break
				for rect in obstacles:
					if rect not in initial and rect.grow(0.33).has_point(point): clear = false
			if clear: return target
	return from

func river_center(x: float) -> float:
	return river_z + 0.385 * sin(x / 0.65 * 0.42)

func surface_height(p: Vector2) -> float:
	for x in bridge_x:
		var z: float = river_center(float(x))
		if absf(p.y - z) < 1.19 and absf(p.x - float(x)) < float(config.bridge_half_width):
			return 0.30 + 0.20 * (1.0 - pow((p.y - z) / 1.19, 2))
	var hill_radius: float = pow((p.x + 2.0) / 3.5, 2) + pow((p.y - 4.6) / 3.8, 2)
	return 0.035 + 0.56 * pow(maxf(0, 1.0 - hill_radius), 3)

func in_pen(p: Vector2) -> bool:
	return absf(p.x - pen_center.x) < config.pen_half_size[0] and absf(p.y - pen_center.y) < config.pen_half_size[1]

func pen_entrance_force(p: Vector2) -> Vector2:
	# Assistance only in front of the authored doorway, never through a wall.
	var gate := Vector2($Camp/Gate.position.x, $Camp/Gate.position.z)
	var inward := (pen_center - gate).normalized()
	var lateral := Vector2(-inward.y, inward.x)
	var offset := p - gate
	var depth := offset.dot(inward)
	var side := offset.dot(lateral)
	if depth < -pen_assist_radius or depth > 0.8 or absf(side) > pen_assist_half_width: return Vector2.ZERO
	var proximity := smoothstep(-pen_assist_radius, -0.25, depth)
	var centering := smoothstep(pen_assist_half_width, pen_assist_half_width * 0.6, absf(side))
	var target := gate - inward * 0.65 if absf(side) > 0.48 and depth < 0.0 else gate + inward * 1.25
	var aim := target - p
	if not passable(p + aim.normalized() * 0.3, 0.33): return Vector2.ZERO
	return aim.normalized() * pen_assist_strength * proximity * centering

func nearest_edge(p: Vector2) -> Vector2:
	var closest := Vector2.INF
	var distance: float = INF
	for i in contour.size():
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, contour[i], contour[(i + 1) % contour.size()])
		if p.distance_squared_to(q) < distance:
			distance = p.distance_squared_to(q)
			closest = q
	return closest

func edge_distance(p: Vector2) -> float:
	return p.distance_to(nearest_edge(p))

func safe_near(p: Vector2) -> Vector2:
	if passable(p, 0.6): return p
	for ring in range(1, 24):
		for i in 24:
			var q: Vector2 = p + Vector2.from_angle(i * TAU / 24) * ring * 0.25
			if passable(q, 0.6): return q
	return Vector2(0, 5)

func _rebuild_navigation() -> void:
	var w: int = ceili(half_width * 2)
	var h: int = ceili(half_depth * 2)
	navigation.region = Rect2i(-w, -h, w * 2 + 1, h * 2 + 1)
	navigation.cell_size = Vector2(0.5, 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(-w, w + 1):
		for y in range(-h, h + 1):
			navigation.set_point_solid(Vector2i(x, y), not passable(Vector2(x, y) * 0.5, 0.28))

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := Vector2i(roundi(from.x * 2), roundi(from.y * 2))
	var b := Vector2i(roundi(to.x * 2), roundi(to.y * 2))
	if not navigation.is_in_boundsv(a) or not navigation.is_in_boundsv(b): return PackedVector2Array()
	if navigation.is_point_solid(a) or navigation.is_point_solid(b): return PackedVector2Array()
	return navigation.get_point_path(a, b)

func edge_exit(from: Vector2) -> Vector2:
	# Use an actual traversable boundary grid cell, including on irregular islands.
	var closest: Vector2 = from
	var best: float = INF
	for x in range(navigation.region.position.x, navigation.region.end.x):
		for y in range(navigation.region.position.y, navigation.region.end.y):
			var cell := Vector2i(x,y)
			if navigation.is_point_solid(cell): continue
			var p: Vector2 = Vector2(cell) * 0.5
			if p.distance_squared_to(from) >= best: continue
			if edge_distance(p) < 0.75:
				closest = p
				best = p.distance_squared_to(from)
	return closest
