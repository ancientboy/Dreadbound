extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var conductor := Conductor.new()
	conductor.route_provider = func(): return [Vector2(100, 0), Vector2(300, 0)]
	conductor._choose_intercept_target()
	assert(conductor.is_intercepting())
	assert(conductor.intercept_target() == Vector2(100, 0))
	assert(conductor.intercept_target() not in [DynamicRunConfig.METRO_NORTH_EXIT, DynamicRunConfig.METRO_SOUTH_EXIT])
	conductor.free()

	var boss := LastTrainBoss.new()
	boss.encounter_provider = func(): return {"anchors": 2, "tide": 0, "window": 100.0}
	boss._physics_process(0.01)
	assert(boss.train_phase == LastTrainBoss.TrainPhase.ARRIVAL)
	boss.encounter_provider = func(): return {"anchors": 1, "tide": 0, "window": 100.0}
	boss._physics_process(0.01)
	assert(boss.train_phase == LastTrainBoss.TrainPhase.INSPECTION)
	boss.encounter_provider = func(): return {"anchors": 1, "tide": 2, "window": 20.0}
	boss._physics_process(0.01)
	assert(boss.train_phase == LastTrainBoss.TrainPhase.DEPARTURE)
	boss.free()

	var anchor := SignalAnchor.new()
	anchor._ready()
	anchor.take_damage(25, Vector2.ZERO)
	assert(anchor.health == 50)
	anchor.free()

	var controls := MobileControls.new()
	controls._trait_queued = true
	assert(controls.consume_trait())
	assert(not controls.consume_trait())
	controls.free()

	var state := root.get_node("GameState") as GameProgress
	state.selected_world = "metro"
	state.active_run_seed = 2048
	var metro: Node = load("res://scenes/metro.tscn").instantiate()
	root.add_child(metro)
	await process_frame
	var south_switch: ObjectiveInteractable
	for item in metro.interactables:
		if item.objective_id == "metro_south_switch":
			south_switch = item
			break
	assert(south_switch != null)
	metro._activate_metro_route(south_switch)
	assert(metro.signal_anchors.size() == 2)
	assert(metro.boss is LastTrainBoss)
	assert(metro._metro_intercept_candidates().has(Vector2(1472, 992)))
	assert(not metro._metro_intercept_candidates().has(DynamicRunConfig.METRO_SOUTH_EXIT))
	metro.metro_tide_level = 2
	var floodgate: ObjectiveInteractable
	for item in metro.interactables:
		if item.objective_id == "metro_emergency_floodgate":
			floodgate = item
			break
	assert(floodgate != null)
	assert(metro._metro_water_depth_at(Vector2(1184, 800)) == 2)
	metro._activate_metro_floodgate(floodgate)
	assert(floodgate.completed)
	assert(metro.metro_floodgate_timer > 0.0)
	assert(metro._metro_water_depth_at(Vector2(1184, 800)) == 0)
	metro.queue_free()
	await process_frame

	# Find an authored Zero Switch run and verify that its locks are ordered,
	# that a wrong lock resets progress, and that the successful route drains
	# the central low level for a limited time.
	var zero_seed := 0
	var zero_config: DynamicRunConfig
	for seed in range(1, 96):
		var candidate := DynamicRunConfig.new(seed, "metro")
		if candidate.mission_id == "switch_zero":
			zero_seed = seed
			zero_config = candidate
			break
	assert(zero_seed > 0)
	state.active_run_seed = zero_seed
	var zero_metro: Node = load("res://scenes/metro.tscn").instantiate()
	root.add_child(zero_metro)
	await process_frame
	var wrong_lock: ObjectiveInteractable
	for item in zero_metro.interactables:
		if item.objective_id == "metro_switch_lock_%d" % ((zero_config.metro_switch_order[0] + 1) % 3):
			wrong_lock = item
			break
	assert(wrong_lock != null)
	zero_metro._handle_metro_switch_lock(wrong_lock)
	assert(zero_metro.collected_records.is_empty())
	assert(zero_metro.metro_switch_failures == 1)
	for lock_index in zero_config.metro_switch_order:
		for item in zero_metro.interactables:
			if item.objective_id == "metro_switch_lock_%d" % lock_index:
				zero_metro._handle_metro_switch_lock(item)
				break
	assert(zero_metro.mission_phase == zero_metro.MissionPhase.RESTORE_POWER)
	for item in zero_metro.interactables:
		if item.objective_id == "metro_%s_switch" % zero_config.metro_switch_route:
			zero_metro._activate_metro_route(item)
			break
	assert(zero_metro.metro_zero_route_timer > 0.0)
	zero_metro.metro_tide_level = 2
	assert(zero_metro._metro_water_depth_at(Vector2(1184, 800)) == 0)
	zero_metro.queue_free()
	await process_frame
	print("Metro behavior test passed: safe interception, contextual boss phases, anchors and mobile trait input")
	quit()
