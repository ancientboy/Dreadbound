extends SceneTree

func _init() -> void:
 call_deferred("_run_test")

func _run_test() -> void:
 var mission = load("res://scenes/main.tscn").instantiate()
 root.add_child(mission)
 await process_frame
 for enemy in get_nodes_in_group("enemies"):
  enemy.set_physics_process(false)
 assert(mission.risk_events.size() == 2)
 for risk_event in mission.risk_events:
  var before_results: int = mission.event_results.size()
  mission._open_risk_event(risk_event)
  assert(mission.event_panel.visible)
  mission._resolve_active_event(true)
  assert(risk_event.resolved)
  assert(mission.event_results.size() == before_results + 1)
 assert(mission.run_config.side_contracts.size() == 2)
 assert(DynamicRunConfig.SIDE_CONTRACTS.has(mission.run_config.side_contracts[0]))
 print("Risk event test passed: seeded contracts, modal pause, dynamic outcomes")
 quit()
