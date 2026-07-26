extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_living_world.json"
	state.reset_progress()
	state.selected_world = "metro"
	state.begin_run(4242)
	var action_code := state.last_action_code
	assert(action_code == "MET-00001092")
	var risk_event := state.record_action("risk_choice", "player", "help_carriage", "risk", {"took_risk": true}, {"summary": "opened"})
	assert(not risk_event.is_empty())
	assert(state.action_ledger.events_for_run(action_code).size() == 2)
	assert(int(state.world_state.regions.metro.corruption) == 57)
	assert(int(state.world_state.factions.resonance.player_trust) == 1)

	state.settle_run(true, 3, 4, 2, 1, [], {"world": "metro", "action_code": action_code})
	assert(state.world_state.cycle == 1)
	assert(state.action_ledger.events_for_run(action_code).size() == 3)
	assert(state.last_run.action_events.size() == 3)
	var safety_after_settlement := int(state.world_state.regions.metro.safety)
	var fragments_after_settlement := state.echo_shards
	state.settle_run(true, 3, 4, 2, 1, [], {"world": "metro", "action_code": action_code})
	assert(state.world_state.cycle == 1)
	assert(int(state.world_state.regions.metro.safety) == safety_after_settlement)
	assert(state.echo_shards == fragments_after_settlement)

	state.save_progress()
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.world_state.cycle == 1)
	assert(restored.action_ledger.events_for_run(action_code).size() == 3)
	assert(restored.world_state.processed_event_ids.size() == 3)

	var legacy_path := "user://test_dreadbound_living_world_legacy.json"
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"version": 15, "echo_shards": 7, "selected_world": "sanatorium"}))
	legacy_file = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(migrated.echo_shards == 7)
	assert(migrated.world_state.cycle == 0)
	assert(migrated.world_state.regions.has("sanatorium"))
	assert(migrated.action_ledger.events.is_empty())

	state.reset_progress()
	restored.reset_progress()
	migrated.reset_progress()
	state.free()
	restored.free()
	migrated.free()
	print("Living world foundation test passed: ledger, deterministic consequences, idempotency and v15 migration")
	quit()
