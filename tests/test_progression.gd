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
	var legacy_path := "user://test_dreadbound_legacy.json"
	var legacy := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version": 1, "echo_shards": 9, "upgrades": {"vitality": 2}, "selected_loadout": "scavenger", "corridor_unlocked": true}))
	legacy = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(migrated.echo_shards == 9)
	assert(migrated.upgrades.vitality == 2)
	assert(migrated.corridor_unlocked)
	assert(migrated.selected_loadout == "scavenger")
	migrated.reset_progress()
	restored.reset_progress()
	state.free()
	restored.free()
	migrated.free()
	print("Progression test passed: settlement, failure loss, upgrade effects, persistence, v1 migration")
	quit()
