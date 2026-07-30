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
@export var camera_bounds := Rect2()
@export var walkable_outline := PackedVector2Array()
@export var camera_guide_outline := PackedVector2Array()
@export var door_directions := PackedStringArray()


func contains_world_point(point: Vector2) -> bool:
	return _polygon_contains_world_point(walkable_outline, point)


func nearest_walkable_world_point(point: Vector2) -> Vector2:
	return _nearest_world_point_in_polygon(walkable_outline, point, 12.0)


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


func _polygon_center(polygon: PackedVector2Array) -> Vector2:
	var total := Vector2.ZERO
	for point in polygon:
		total += point
	return total / maxf(float(polygon.size()), 1.0)
