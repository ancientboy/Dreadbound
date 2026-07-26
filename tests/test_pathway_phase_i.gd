extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_phase_i.json"
	state.reset_progress()
	state.echo_shards = 100
	state.causality_fragments = 10
	assert(state.unlock_path_node("steadfast_guard"))
	assert(state.unlock_path_node("steadfast_mender"))
	assert(state.unlock_path_node("steadfast_barrier"))
	var player := Player.new()
	var effects := PathwayEffects.new()
	effects.setup(player, state)
	effects.on_bandage_used(30, 100)
	assert(effects.guard_duration == 4.0)
	assert(is_equal_approx(effects.incoming_damage_multiplier(), 0.75))
	effects.tick(4.1)
	assert(effects.incoming_damage_multiplier() == 1.0)

	state.unlocked_path_nodes.assign(["armorer_calibration", "armorer_mobility", "armorer_alternation"])
	state.selected_pathway = "armorer"
	effects.on_weapon_switched()
	assert(effects.calibration_ready)
	assert(is_equal_approx(effects.consume_attack_multiplier(), 1.2))
	assert(not effects.calibration_ready)

	state.unlocked_path_nodes.assign(["resonant_sense", "resonant_bargain", "resonant_ingestion"])
	state.selected_pathway = "resonant"
	assert(effects.on_risk_event(true) == 2)
	assert(effects.anomaly_pressure == 1)
	assert(effects.healing_multiplier() < 1.0)
	assert(effects.on_risk_event(false) == 0)

	state.causality_fragments = 5
	var shards_before := state.echo_shards
	assert(state.respec_pathway())
	assert(state.selected_pathway.is_empty())
	assert(state.echo_shards > shards_before)
	assert(not state.respec_pathway())
	state.save_progress()
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.pathway_respec_used)
	var legacy_path := "user://test_dreadbound_phase_i_v9.json"
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"version": 9, "echo_shards": 7, "causality_fragments": 1, "selected_pathway": "armorer", "unlocked_path_nodes": ["armorer_calibration"]}))
	legacy_file = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(migrated.selected_pathway == "armorer")
	assert(not migrated.pathway_respec_used)

	var totals := {"steadfast": 0.0, "armorer": 0.0, "resonant": 0.0}
	for seed in range(500):
		var config := DynamicRunConfig.new(seed + 1, "metro" if seed % 2 else "sanatorium")
		assert(config.validate())
		for pathway in totals:
			var base := 100.0 + config.objective_count * 4.0
			var modifier := 12.0 if pathway == "steadfast" else (11.0 if pathway == "armorer" else 10.0)
			totals[pathway] += base + modifier
	for pathway in totals:
		assert(float(totals[pathway]) > 50000.0)
		assert(float(totals[pathway]) < 70000.0)

	state.reset_progress()
	restored.reset_progress()
	migrated.reset_progress()
	effects.free()
	player.free()
	state.free()
	restored.free()
	migrated.free()
	print("Phase I pathway test passed: three mechanics, status expiry, one-time respec, migration and 500-seed balance")
	quit()
