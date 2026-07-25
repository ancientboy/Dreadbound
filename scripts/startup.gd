extends Node


func _ready() -> void:
	call_deferred("_route_player")


func _route_player() -> void:
	var destination := "res://scenes/corridor.tscn" if GameState.corridor_unlocked else "res://scenes/main.tscn"
	get_tree().change_scene_to_file(destination)
