extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var manager := LocalProfileManager.new()
	manager.index_path = "user://test_dreadbound_profiles.json"
	manager.legacy_path = "user://test_dreadbound_profiles_legacy.json"
	manager.load_index()
	var first := manager.create_profile("夜航者")
	var second := manager.create_profile("守门人")
	assert(not first.is_empty() and not second.is_empty())
	assert(first.id != second.id)
	assert(manager.rename_profile(str(first.id), "潮汐行者"))
	assert(manager.select_profile(str(first.id)))
	assert(manager.active_profile().nickname == "潮汐行者")
	assert(manager.save_path_for(str(first.id)) != manager.save_path_for(str(second.id)))

	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_milestones.json"
	state.reset_progress()
	state.settle_run(true, 3, 0, 4, 0, [], {"world": "sanatorium", "boss_defeated": true})
	assert(state.causality_fragments == 2)
	assert(state.last_run.milestone_rewards.size() == 2)
	state.settle_run(true, 3, 0, 4, 0, [], {"world": "sanatorium", "boss_defeated": true})
	assert(state.causality_fragments == 2)
	assert(state.last_run.milestone_rewards.is_empty())
	state.settle_run(true, 3, 0, 4, 0, [], {"world": "metro", "boss_defeated": true})
	assert(state.causality_fragments == 5)
	assert(state.claimed_milestones.size() == 4)
	state.save_progress()
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.claimed_milestones.size() == 4)
	restored.settle_run(true, 3, 0, 4, 0, [], {"world": "metro", "boss_defeated": true})
	assert(restored.causality_fragments == 5)

	var trials := GameProgress.new()
	trials.save_path = "user://test_dreadbound_trial_worlds.json"
	trials.reset_progress()
	trials.selected_world = "sanatorium"
	assert(trials.accept_curator_trial())
	assert(str(trials.get_curator_trial().world) == "sanatorium")
	var san_trial_id := str(trials.get_curator_trial().id)
	trials.settle_run(true, 3, 0, 2, 0, [], {"world": "sanatorium", "boss_defeated": true})
	assert(trials.last_run.trial_rewards.size() == 1)
	assert(trials.player_profile.completed_trials.has(san_trial_id))
	assert(trials.player_profile.trial_reward_claims.has(san_trial_id))
	# A duplicate UI event for the same mission must never settle the run twice.
	trials.settle_run(true, 3, 0, 2, 0, [], {"world": "sanatorium", "action_code": "SAN-ONCE"})
	var first_action_fragments := trials.causality_fragments
	trials.settle_run(true, 3, 0, 2, 0, [], {"world": "sanatorium", "action_code": "SAN-ONCE"})
	assert(trials.causality_fragments == first_action_fragments)
	trials.selected_world = "metro"
	assert(trials.accept_curator_trial())
	assert(str(trials.get_curator_trial().world) in ["metro", "any"])
	assert(str(trials.get_curator_trial().id) != san_trial_id)
	var completed_before_reset: Array = trials.player_profile.completed_trials.duplicate()
	trials.reset_curator_profile()
	assert(trials.player_profile.completed_trials == completed_before_reset)
	assert(trials.player_profile.trial_reward_claims.has(san_trial_id))

	var corrupt := GameProgress.new()
	corrupt.save_path = "user://test_dreadbound_cross_path.json"
	var corrupt_file := FileAccess.open(corrupt.save_path, FileAccess.WRITE)
	corrupt_file.store_string(JSON.stringify({"version": 11, "echo_shards": 0, "selected_pathway": "steadfast", "unlocked_path_nodes": ["steadfast_guard", "armorer_calibration", "resonant_sense"]}))
	corrupt_file = null
	corrupt.load_progress()
	assert(corrupt.unlocked_path_nodes == ["steadfast_guard"])
	assert(corrupt.echo_shards == 10)
	assert(corrupt.pathway_migration_refund == 10)

	assert(manager.delete_profile(str(first.id)))
	assert(manager.profiles.size() == 1)
	state.reset_progress()
	restored.reset_progress()
	trials.reset_progress()
	corrupt.reset_progress()
	if FileAccess.file_exists(manager.index_path): DirAccess.remove_absolute(manager.index_path)
	manager.free()
	state.free()
	restored.free()
	trials.free()
	corrupt.free()
	print("Profiles and milestones test passed: isolated nicknames, four first-clear rewards and duplicate prevention")
	quit()
