extends SceneTree

func _init() -> void:
 call_deferred("_run_test")

func _run_test() -> void:
 var mission = load("res://scenes/main.tscn").instantiate()
 root.add_child(mission)
 await process_frame
 assert(mission.run_config.validate())
 assert(mission.interactables.size() == mission.total_records + 2)
 assert(mission.risk_events.size() == 2)
 assert(mission.abandon_button.visible)
 var power = mission.interactables[mission.total_records]
 var exit = mission.interactables[mission.total_records + 1]
 mission._handle_interaction(power)
 assert(not mission.power_restored)
 for index in range(mission.total_records):
  mission._handle_interaction(mission.interactables[index])
 assert(mission.collected_records.size() == mission.total_records)
 assert(mission.mission_phase == mission.MissionPhase.RESTORE_POWER)
 mission._handle_interaction(power)
 assert(mission.power_restored)
 assert(mission.mission_phase == mission.MissionPhase.EVACUATE)
 mission._handle_interaction(exit)
 assert(mission.mission_phase == mission.MissionPhase.COMPLETE)
 assert(mission.complete_panel.visible)
 assert(mission.return_button.visible)
 assert(not mission.abandon_button.visible)
 print("Mission flow test passed: seeded objectives -> power -> extraction")
 quit()
