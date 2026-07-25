extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	GameState.reset_progress()
	GameState.echo_shards = 20
	assert(GameState.unlock_path_node("steadfast_guard"))
	assert(GameState.unlock_path_node("armorer_calibration"))
	var stats := GameState.get_player_stats()
	assert(stats.max_health == 117) # medical tag +5, steadfast guard +12
	assert(stats.melee_damage == 41) # crowbar +3, armorer calibration +3
	assert(not GameState.unlock_path_node("steadfast_guard"))
	GameState.reset_progress()
	print("Pathway test passed: persistent nodes apply transparent stat bonuses")
	quit()
