extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_progress.json"
	state.reset_progress()
	assert(state.settle_run(false, 2, 5, 1) == 0)
	assert(not state.corridor_unlocked)
	assert(state.echo_shards == 0)
	assert(state.last_run.records == 2)
	assert(state.settle_run(true, 3, 5, 4) == 14)
	assert(state.corridor_unlocked)
	assert(state.echo_shards == 14)
	assert(state.purchase_upgrade("vitality"))
	assert(state.echo_shards == 10)
	assert(state.get_player_stats().max_health == 110)
	assert(not state.purchase_upgrade("unknown"))
	assert(state.select_loadout("marksman"))
	assert(state.get_selected_loadout().ammo == 14)
	assert(not state.select_loadout("unknown"))
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.echo_shards == 10)
	assert(restored.upgrades.vitality == 1)
	assert(restored.selected_loadout == "marksman")
	assert(restored.corridor_unlocked)
	restored.reset_progress()
	state.free()
	restored.free()
	print("Progression test passed: settlement, failure loss, upgrade effects, persistence")
	quit()
