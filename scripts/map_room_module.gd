class_name MapRoomModule
extends Node2D

@export var room_id: StringName
@export var room_kind := "combat"
@export var difficulty_tier := 1
@export var camera_bounds := Rect2()
@export var walkable_outline := PackedVector2Array()
@export var door_directions := PackedStringArray()


func contains_world_point(point: Vector2) -> bool:
	return walkable_outline.size() >= 3 and Geometry2D.is_point_in_polygon(
		to_local(point),
		walkable_outline,
	)


func nearest_walkable_world_point(point: Vector2) -> Vector2:
	if walkable_outline.size() < 3:
		return point
	var local_point := to_local(point)
	if Geometry2D.is_point_in_polygon(local_point, walkable_outline):
		return point
	var nearest := walkable_outline[0]
	var nearest_distance := INF
	for index in walkable_outline.size():
		var start := walkable_outline[index]
		var finish := walkable_outline[(index + 1) % walkable_outline.size()]
		var candidate := Geometry2D.get_closest_point_to_segment(local_point, start, finish)
		var distance := candidate.distance_squared_to(local_point)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	var center := _polygon_center()
	return to_global(nearest + nearest.direction_to(center) * 12.0)


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


func _polygon_center() -> Vector2:
	var total := Vector2.ZERO
	for point in walkable_outline:
		total += point
	return total / maxf(float(walkable_outline.size()), 1.0)
