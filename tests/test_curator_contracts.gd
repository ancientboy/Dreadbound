extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_curator_contracts.json"
	state.reset_progress()
	state.selected_world = "metro"
	state.player_profile.noise_actions = 8
	var offers := state.get_curator_contract_offers()
	assert(offers.size() == 3)
	var kinds: Array[String] = []
	for offer in offers:
		kinds.append(str(offer.kind))
	assert(kinds.has("world") and kinds.has("behavior") and kinds.has("risk"))
	assert(state.choose_curator_contract("metro_reverse_tide"))
	assert(state.get_curator_trial().id == "metro_reverse_tide")
	assert(is_equal_approx(float(state.get_active_contract_effects().floodgate_bonus), 16.0))
	assert(not state.choose_curator_contract("metro_quiet"))
	state.settle_run(true, 3, 0, 2, 0, [], {"world": "metro", "action_code": "MET-CONTRACT-1", "curator_floodgate_used": true})
	assert(state.player_profile.completed_trials.has("metro_reverse_tide"))
	assert(state.causality_fragments == 4) # Metro first clear + reverse-tide contract.
	var global_state := root.get_node("GameState") as GameProgress
	var prior_active := str(global_state.player_profile.get("active_trial", ""))
	global_state.player_profile.active_trial = "metro_zero_priority"
	var forced := DynamicRunConfig.new(1, "metro")
	assert(forced.mission_id == "switch_zero")
	global_state.player_profile.active_trial = prior_active
	state.reset_progress()
	state.free()
	print("Curator contract test passed: explicit offers, one active contract, real world rule and reward claim")
	quit()
