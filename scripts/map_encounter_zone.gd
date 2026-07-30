class_name MapEncounterZone
extends Node2D

@export var zone_id: StringName
@export var trigger_bounds := Rect2()
@export var starts_active := false
@export var enemy_labels := PackedStringArray()

var activated := false


func contains_world_point(point: Vector2) -> bool:
	return trigger_bounds.has_point(to_local(point))


func activate() -> void:
	activated = true


func get_spawn_points() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var spawns := get_node_or_null("EnemySpawns")
	if spawns == null:
		return result
	for child in spawns.get_children():
		var marker := child as Marker2D
		if marker != null:
			result.append(marker)
	return result
