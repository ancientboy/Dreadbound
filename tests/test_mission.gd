extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	assert(mission.interactables.size() == 5)
	assert(mission.abandon_button.visible)
	mission._handle_interaction(mission.interactables[3])
	assert(not mission.power_restored)
	for index in range(3):
		mission._handle_interaction(mission.interactables[index])
	assert(mission.collected_records.size() == 3)
	assert(mission.mission_phase == mission.MissionPhase.RESTORE_POWER)
	mission._handle_interaction(mission.interactables[3])
	assert(mission.power_restored)
	assert(mission.mission_phase == mission.MissionPhase.EVACUATE)
	mission._handle_interaction(mission.interactables[4])
	assert(mission.mission_phase == mission.MissionPhase.COMPLETE)
	assert(mission.complete_panel.visible)
	assert(mission.return_button.visible)
	assert(not mission.abandon_button.visible)
	print("Mission flow test passed: records -> power -> extraction")
	quit()
