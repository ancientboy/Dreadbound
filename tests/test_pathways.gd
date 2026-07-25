extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_pathways.json"
	state.reset_progress()
	assert(state.equip_item("service_crowbar"))
	assert(state.equip_item("medical_tag"))
	state.echo_shards = 20
	assert(state.unlock_path_node("steadfast_guard"))
	assert(state.unlock_path_node("armorer_calibration"))
	var stats := state.get_player_stats()
	assert(stats.max_health == 117) # medical tag +5, steadfast guard +12
	assert(stats.melee_damage == 41) # crowbar +3, armorer calibration +3
	assert(not state.unlock_path_node("steadfast_guard"))
	state.reset_progress()
	state.free()
	print("Pathway test passed: persistent nodes apply transparent stat bonuses")
	quit()
