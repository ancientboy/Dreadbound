class_name MapRoomModule
extends Node2D

enum RoomSizeClass {
	STANDARD,
	LARGE,
	BOSS,
}

@export var room_id: StringName
@export var room_kind := "combat"
@export var difficulty_tier := 1
@export var size_class := RoomSizeClass.STANDARD
@export var camera_zoom := Vector2(1.28, 1.28)
@export var camera_overscan := 1.0
@export var camera_bounds := Rect2()
@export var walkable_outline := PackedVector2Array()
@export var blocked_outlines: Array[PackedVector2Array] = []
@export var camera_guide_outline := PackedVector2Array()
@export var door_directions := PackedStringArray()
var door_anchor_overrides: Dictionary = {}


func apply_built_spec(spec: Dictionary, builder: RoomBuilder) -> void:
	room_id = spec["room_id"]
	room_kind = spec["room_kind"]
	size_class = spec["size_class"]
	camera_zoom = spec["camera_zoom"]
	camera_overscan = float(spec.get("camera_overscan", 1.0))
	camera_bounds = builder.map_bounds
	walkable_outline = builder.walkable_outline
	blocked_outlines.clear()
	for blocked_outline in builder.blocked_outlines:
		blocked_outlines.append(blocked_outline)
	camera_guide_outline = spec["camera_guide_outline"]
	door_directions = builder.door_directions()
	door_anchor_overrides = builder.door_anchor_points.duplicate()
	_rebuild_navigation_region()


func apply_legacy_spec(spec: Dictionary) -> void:
	room_id = spec["room_id"]
	room_kind = spec["room_kind"]
	size_class = spec["size_class"]
	camera_zoom = spec["camera_zoom"]
	camera_overscan = float(spec.get("camera_overscan", 1.0))
	camera_bounds = spec.get("map_bounds", Rect2(Vector2.ZERO, Vector2(1536, 1024)))
	walkable_outline = spec["walkable_outline"]
	blocked_outlines.clear()
	for blocked_outline in spec.get("blocked_outlines", []):
		blocked_outlines.append(blocked_outline)
	camera_guide_outline = spec["camera_guide_outline"]
	door_directions = spec["door_directions"]
	door_anchor_overrides.clear()
	_rebuild_navigation_region()


func contains_world_point(point: Vector2) -> bool:
	if not _polygon_contains_world_point(walkable_outline, point):
		return false
	for blocked_outline in blocked_outlines:
		if _polygon_contains_world_point(blocked_outline, point):
			return false
	return true


func nearest_walkable_world_point(point: Vector2) -> Vector2:
	if not _polygon_contains_world_point(walkable_outline, point):
		return _nearest_world_point_in_polygon(walkable_outline, point, 12.0)
	for blocked_outline in blocked_outlines:
		if _polygon_contains_world_point(blocked_outline, point):
			return _nearest_world_point_outside_polygon(blocked_outline, point, 12.0)
	return point


func guided_camera_world_point(target: Vector2) -> Vector2:
	if camera_guide_outline.size() < 3:
		return camera_bounds.get_center() if camera_bounds.has_area() else target
	return _nearest_world_point_in_polygon(camera_guide_outline, target)


func is_multi_screen() -> bool:
	return size_class != RoomSizeClass.STANDARD


func get_spawn_points(container_name: StringName) -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var container := get_node_or_null(NodePath(String(container_name)))
	if container == null:
		return result
	for child in container.get_children():
		var marker := child as Marker2D
		if marker != null:
			result.append(marker)
	return result


func get_obstacles() -> Array[MapRoomObstacle]:
	var result: Array[MapRoomObstacle] = []
	var container := get_node_or_null("Obstacles")
	if container == null:
		return result
	for child in container.get_children():
		var obstacle := child as MapRoomObstacle
		if obstacle != null:
			result.append(obstacle)
	return result


func door_anchor_world(direction: StringName) -> Vector2:
	if door_anchor_overrides.has(direction):
		return to_global(door_anchor_overrides[direction])
	if walkable_outline.size() < 2:
		return global_position
	var extreme := 0.0
	match direction:
		&"north":
			extreme = _outline_extreme(false, true)
		&"south":
			extreme = _outline_extreme(false, false)
		&"west":
			extreme = _outline_extreme(true, true)
		&"east":
			extreme = _outline_extreme(true, false)
		_:
			return to_global(_polygon_center(walkable_outline))
	var anchors := PackedVector2Array()
	for point in walkable_outline:
		var coordinate := point.x if direction == &"west" or direction == &"east" else point.y
		if absf(coordinate - extreme) <= 2.0:
			anchors.append(point)
	if anchors.is_empty():
		return to_global(_polygon_center(walkable_outline))
	var anchor := Vector2.ZERO
	for point in anchors:
		anchor += point
	return to_global(anchor / float(anchors.size()))


func _outline_extreme(use_x: bool, find_minimum: bool) -> float:
	var result := INF if find_minimum else -INF
	for point in walkable_outline:
		var coordinate := point.x if use_x else point.y
		result = minf(result, coordinate) if find_minimum else maxf(result, coordinate)
	return result


func _polygon_contains_world_point(polygon: PackedVector2Array, point: Vector2) -> bool:
	return polygon.size() >= 3 and Geometry2D.is_point_in_polygon(to_local(point), polygon)


func _nearest_world_point_in_polygon(
	polygon: PackedVector2Array,
	point: Vector2,
	inset := 0.0,
) -> Vector2:
	if polygon.size() < 3:
		return point
	var local_point := to_local(point)
	if Geometry2D.is_point_in_polygon(local_point, polygon):
		return point
	var nearest := polygon[0]
	var nearest_distance := INF
	for index in polygon.size():
		var start := polygon[index]
		var finish := polygon[(index + 1) % polygon.size()]
		var candidate := Geometry2D.get_closest_point_to_segment(local_point, start, finish)
		var distance := candidate.distance_squared_to(local_point)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if inset > 0.0:
		nearest += nearest.direction_to(_polygon_center(polygon)) * inset
	return to_global(nearest)


func _nearest_world_point_outside_polygon(
	polygon: PackedVector2Array,
	point: Vector2,
	outset: float,
) -> Vector2:
	var local_point := to_local(point)
	var nearest := polygon[0]
	var nearest_distance := INF
	for index in polygon.size():
		var start := polygon[index]
		var finish := polygon[(index + 1) % polygon.size()]
		var candidate := Geometry2D.get_closest_point_to_segment(local_point, start, finish)
		var distance := candidate.distance_squared_to(local_point)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	nearest += _polygon_center(polygon).direction_to(nearest) * outset
	return to_global(nearest)


func _polygon_center(polygon: PackedVector2Array) -> Vector2:
	var total := Vector2.ZERO
	for point in polygon:
		total += point
	return total / maxf(float(polygon.size()), 1.0)


func _rebuild_navigation_region() -> void:
	var existing := get_node_or_null("NavigationRegion2D")
	if existing != null:
		existing.free()
	if walkable_outline.size() < 3:
		return
	var navigation_polygon := NavigationPolygon.new()
	var source_geometry := NavigationMeshSourceGeometryData2D.new()
	source_geometry.add_traversable_outline(walkable_outline)
	for blocked_outline in blocked_outlines:
		source_geometry.add_obstruction_outline(blocked_outline)
	NavigationServer2D.bake_from_source_geometry_data(
		navigation_polygon,
		source_geometry,
	)
	if navigation_polygon.get_polygon_count() == 0:
		push_error("Could not build room navigation polygon for %s" % room_id)
		return
	var region := NavigationRegion2D.new()
	region.name = "NavigationRegion2D"
	region.navigation_polygon = navigation_polygon
	add_child(region)
