extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_three_visit_story()
	_test_unique_registry_and_save()
	_test_game_progress_integration()
	print("Persistent dungeon test passed: visits, NPC memory, branching chapters, hidden map and unique rewards")
	quit()


func _test_three_visit_story() -> void:
	var state := WorldStateStore.new()
	var dungeon := PersistentDungeonState.new()
	var first := dungeon.begin_visit("metro", "MET-ONE", state)
	assert(int(first.visit) == 1)
	assert(str(first.chapter) == "first_arrival")
	assert(not bool(first.hidden_open))
	var promise := dungeon.resolve_metro_choice("promise_return", state, "MET-ONE")
	assert(bool(promise.accepted))
	assert(str(promise.event_type) == "promise_made")
	assert(str(state.npcs.linye.promise) == "return_for_linye")
	assert(str(state.npcs.linye.first_met_run) == "MET-ONE")
	assert(state.npcs.linye.memories.size() == 1)
	dungeon.settle_visit("metro", true, "MET-ONE", false)

	var second := dungeon.begin_visit("metro", "MET-TWO", state)
	assert(int(second.visit) == 2)
	assert(str(second.chapter) == "promise_due")
	assert(str(second.cause).contains("答应"))
	var kept := dungeon.resolve_metro_choice("keep_promise", state, "MET-TWO")
	assert(bool(kept.hidden_opened))
	assert(str(kept.event_type) == "promise_kept")
	assert(dungeon.has_opened_area("metro", "lost_passenger_level"))
	assert(str(state.npcs.linye.last_outcome) == "rescued_guide")
	assert(str(state.npcs.linye.last_met_run) == "MET-TWO")
	assert(state.npcs.linye.memories.size() == 2)
	dungeon.settle_visit("metro", true, "MET-TWO", true)

	var third := dungeon.begin_visit("metro", "MET-THREE", state)
	assert(int(third.visit) == 3)
	assert(str(third.chapter) == "guided_aftermath")
	assert(bool(third.hidden_open))
	var manifest := dungeon.resolve_metro_choice("preserve_manifest", state, "MET-THREE")
	assert(str(manifest.unique_offer) == "linye_pass")
	assert(str(state.npcs.linye.last_outcome) == "manifest_guardian")
	assert(dungeon.history_for("metro").size() >= 5)

	var config := DynamicRunConfig.new(31, "metro")
	assert(config.map_regions().all(func(region): return str(region.id) != "lost_passenger_level"))
	config.revealed_secret_regions.append("lost_passenger_level")
	assert(config.map_regions().any(func(region): return str(region.id) == "lost_passenger_level"))


func _test_unique_registry_and_save() -> void:
	var dungeon := PersistentDungeonState.new()
	assert(dungeon.claim_unique("conductor_railgun", "MET-ONE", "metro"))
	assert(not dungeon.claim_unique("conductor_railgun", "MET-TWO", "metro"))
	assert(not dungeon.filter_reward_pool(["conductor_railgun", "echo_edge"]).has("conductor_railgun"))
	assert(dungeon.filter_reward_pool(["conductor_railgun", "echo_edge"]).has("echo_edge"))
	var restored := PersistentDungeonState.new()
	restored.load_dict(dungeon.to_dict())
	assert(restored.is_claimed("conductor_railgun"))
	assert(str(restored.unique_registry.conductor_railgun.claimed_run) == "MET-ONE")


func _test_game_progress_integration() -> void:
	var save_file := "user://test_dreadbound_persistent_dungeon.json"
	var state := GameProgress.new()
	state.save_path = save_file
	state.reset_progress()
	state.selected_world = "metro"
	state.begin_run(101)
	assert(str(state.dungeon_chapter().chapter) == "first_arrival")
	state.resolve_metro_narrative("promise_return")
	state.settle_run(true, 3, 0, 0, 1, ["conductor_railgun"], {
		"world": "metro",
		"action_code": state.last_action_code,
		"boss_defeated": true,
	})
	assert(state.equipment_inventory.count("conductor_railgun") == 1)
	assert(state.persistent_dungeons.is_claimed("conductor_railgun"))

	state.begin_run(102)
	assert(str(state.dungeon_chapter().chapter) == "promise_due")
	state.settle_run(true, 3, 0, 0, 0, ["conductor_railgun"], {
		"world": "metro",
		"action_code": state.last_action_code,
		"boss_defeated": true,
	})
	assert(state.equipment_inventory.count("conductor_railgun") == 1)
	assert(int(state.last_run.overflow_shards) > 0)
	assert(state.get_relic_growth("conductor_railgun") == 2)

	state.save_progress()
	var restored := GameProgress.new()
	restored.save_path = save_file
	restored.load_progress()
	assert(restored.persistent_dungeons.is_claimed("conductor_railgun"))
	assert(int(restored.persistent_dungeons.dungeons.metro.visits) == 2)
	state.reset_progress()
	restored.free()
	state.free()
