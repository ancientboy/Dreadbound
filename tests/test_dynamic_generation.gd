extends SceneTree

func _init() -> void:
 call_deferred("_run_test")

func _run_test() -> void:
 var signatures := {}
 for seed in range(1, 501):
  var config := DynamicRunConfig.new(seed)
  assert(config.validate())
  assert(config.objective_positions.size() >= 2 and config.objective_positions.size() <= 4)
  assert(config.side_contracts.size() == 2)
  for spawn in config.patient_spawns + config.crawler_spawns + config.orderly_spawns:
   assert(spawn.distance_to(Vector2(224, 360)) > 340.0)
  var replay := DynamicRunConfig.new(seed)
  assert(config.action_code == replay.action_code)
  assert(config.room_order == replay.room_order)
  assert(config.objective_positions == replay.objective_positions)
  assert(config.mission_id == replay.mission_id)
  signatures["%s|%s|%d" % [config.room_order, config.mission_id, config.objective_count]] = true
 assert(signatures.size() > 40)
 var director := DreadDirector.new()
 var relief := director.update(1.0, 0.2, 0.1, 5, 0.8, false)
 assert(relief == "relief")
 assert(not director.decision_log.is_empty())
 var hunter := DreadDirector.new()
 hunter.elapsed = 80.0
 hunter.pacing_debt = 0.6
 var escalation := hunter.update(1.0, 1.0, 1.0, 1, 0.0, false)
 assert(escalation == "escalate")
 print("Dynamic generation test passed: 500 valid deterministic seeds and director decisions")
 quit()
