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

	assert(manager.delete_profile(str(first.id)))
	assert(manager.profiles.size() == 1)
	state.reset_progress()
	restored.reset_progress()
	if FileAccess.file_exists(manager.index_path): DirAccess.remove_absolute(manager.index_path)
	manager.free()
	state.free()
	restored.free()
	print("Profiles and milestones test passed: isolated nicknames, four first-clear rewards and duplicate prevention")
	quit()
