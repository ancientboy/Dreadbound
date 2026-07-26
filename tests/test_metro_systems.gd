extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var rules := WorldRules.new("metro")
	assert(rules.event_ids().size() == 4)
	assert(rules.reward_pool().has("last_ticket"))
	assert(is_equal_approx(rules.water_speed_multiplier(1, false), 0.68))
	assert(rules.water_speed_multiplier(1, true) > 0.68)
	assert(rules.train_window("south", false) == 70.0)
	assert(rules.train_window("south", true, true) == 50.0)

	var drowned: Node = load("res://scenes/entities/drowned.tscn").instantiate()
	var conductor: Node = load("res://scenes/entities/conductor.tscn").instantiate()
	var train: Node = load("res://scenes/entities/last_train_boss.tscn").instantiate()
	root.add_child(drowned)
	root.add_child(conductor)
	root.add_child(train)
	assert(drowned is Drowned)
	assert(conductor is Conductor)
	assert(train is LastTrainBoss)
	assert(drowned.is_in_group("metro_enemies"))
	assert(conductor.is_in_group("metro_enemies"))
	assert(train.is_in_group("metro_enemies"))
	drowned.queue_free()
	conductor.queue_free()
	train.queue_free()

	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_metro_systems.json"
	state.reset_progress()
	state.equipment_inventory.append("waterproof_pulse")
	assert(state.equip_item("waterproof_pulse"))
	assert(state.has_equipment_trait("reduce_water_penalty"))
	state.player_profile.noise_actions = 8
	state.selected_world = "metro"
	assert(state.accept_curator_trial())
	assert(state.get_curator_trial().id == "metro_quiet")
	var before_fragments := state.causality_fragments
	state.settle_run(true, 3, 0, 2, 1, [], {"world": "metro", "noise": 2, "action_code": "MET-TEST"})
	assert(state.causality_fragments == before_fragments + 3) # first Metro clear + curator trial
	assert(state.player_profile.recent_runs.size() == 1)
	assert(state.player_profile.quiet_successes == 1)
	state.reset_curator_profile()
	assert(state.player_profile.recent_runs.is_empty())
	assert(state.equipment_inventory.has("waterproof_pulse"))
	state.reset_progress()
	state.free()
	print("Metro systems test passed: world rules, dedicated enemies, gear traits and curator trials")
	quit()
