extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var fog: FogOfWar = mission.fog_of_war
	fog._process(0.01)
	assert(fog.get_reveal_progress("entrance") > 0.0)
	assert(fog.get_reveal_progress("patient_wing") == 0.0)
	fog._process(fog.reveal_duration)
	assert(fog.get_reveal_progress("entrance") == 1.0)
	mission.player.global_position = Vector2(672, 256)
	fog._process(fog.reveal_duration * 0.5)
	assert(fog.get_reveal_progress("patient_wing") >= 0.49)
	assert(fog.get_reveal_progress("archive") == 0.0)
	mission.minimap.set_expanded(true)
	assert(mission.minimap.expanded)
	assert(not mission.player.is_physics_processing())
	mission.minimap.set_expanded(false)
	assert(mission.player.is_physics_processing())
	print("Map test passed: room reveal progression, unexplored state, expanded-map pause")
	quit()
