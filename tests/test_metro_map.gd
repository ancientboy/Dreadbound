extends SceneTree

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var game_state := root.get_node("GameState") as GameProgress
	game_state.selected_world = "metro"
	game_state.active_run_seed = 2468
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var fog: FogOfWar = mission.fog_of_war
	fog._process(0.01)
	assert(fog.get_reveal_progress("ticket_hall") > 0.0)
	assert(fog.get_world_reveal_at(Vector2(1900, 1100)) == 0.0)
	# The gap between the market and signal room is a complete central link, not
	# an unassigned black strip or a local flashlight reveal.
	mission.player.global_position = Vector2(944, 560)
	fog._process(fog.corridor_reveal_duration)
	assert(fog.get_reveal_progress("metro_central_link") == 1.0)
	assert(fog.get_world_reveal_at(Vector2(944, 560)) > 0.0)
	assert(fog.get_world_reveal_at(Vector2(1900, 1100)) == 0.0)
	print("Metro map test passed: whole-area fog reveal and unexplored sections")
	quit()
