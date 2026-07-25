extends Node


func _ready() -> void:
	call_deferred("_route_player")


func _route_player() -> void:
	if not GameState.corridor_unlocked and GameState.active_run_seed == 0:
		GameState.begin_run()
	var destination := "res://scenes/corridor.tscn" if GameState.corridor_unlocked else "res://scenes/main.tscn"
	get_tree().change_scene_to_file(destination)
