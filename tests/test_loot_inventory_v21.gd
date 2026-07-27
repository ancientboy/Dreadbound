extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var crawler_drop := LootDatabase.roll_enemy("sanatorium", "crawler", 0.10, 0.0, 0.0, 0)
	assert(str(crawler_drop.kind) == "ammo")
	assert(int(crawler_drop.amount) == 3)
	var patient_material := LootDatabase.roll_enemy("sanatorium", "patient", 0.20, 0.0, 0.0, 0)
	assert(str(patient_material.kind) == "material")
	assert(str(patient_material.id) == "tissue_sample")
	var pity_drop := LootDatabase.roll_enemy("sanatorium", "orderly", 0.05, 0.0, 0.0, LootDatabase.RARE_PITY_KILLS)
	assert(str(pity_drop.id) == "medical_record")
	assert(str(pity_drop.source) == "rare_pity")
	var elite_bonus := LootDatabase.roll_enemy("metro", "drowned", 0.52, 0.10, 0.12, 0)
	assert(str(elite_bonus.kind) == "material")
	assert(str(elite_bonus.id) == "flooded_circuit")
	assert(str(LootDatabase.boss_reward("metro").material) == "conductor_coil")

	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_loot_v21.json"
	state.reset_progress()
	state.selected_world = "sanatorium"
	state.begin_run(210021)
	var banked := state.settle_run(true, 3, 0, 4, 0, [], {
		"world": "sanatorium",
		"boss_defeated": true,
		"action_code": state.last_action_code,
		"material_rewards": {"tissue_sample": 2, "medical_record": 1, "stitch_core": 1},
		"loot_log": [{"kind": "material", "id": "medical_record", "amount": 1, "source": "enemy"}],
	})
	assert(banked > 0)
	assert(int(state.world_materials.tissue_sample) == 3) # two carried + extraction sample
	assert(int(state.world_materials.medical_record) == 1)
	assert(int(state.world_materials.stitch_core) == 1)
	assert(state.loot_history.size() == 1)

	var unique_before := state.equipment_inventory.size()
	state.equipment_inventory.append("director_reaper")
	assert(state.equipment_inventory.size() == unique_before + 1)
	assert(state.begin_synthesis(["director_reaper", "director_reaper", "director_reaper"]).is_empty())

	var legacy_path := "user://test_dreadbound_loot_v20.json"
	var legacy := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version": 20, "world_materials": {"tissue_sample": 4}, "equipment_inventory": ["service_crowbar", "medical_tag"]}))
	legacy = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(migrated.save_health().migrations.any(func(text): return str(text).contains("v21")))
	assert(int(migrated.world_materials.tissue_sample) == 4)
	assert(migrated.loot_history.is_empty())

	var corridor: Control = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	assert(corridor.get_node("IndependentHubNavigation") != null)
	assert(corridor.get_node("IndependentHubNavigation").get_child_count() == 8)
	corridor._open_hub_section("materials")
	assert(corridor.section_panel.visible)
	assert(corridor.section_title.text.contains("材料背包"))
	corridor._open_hub_section("collection")
	assert(corridor.section_title.text.contains("唯一藏品"))
	corridor._open_hub_section("career")
	assert(corridor.section_title.text.contains("职业锚点"))
	corridor._open_hub_section("dungeons")
	assert(corridor.section_title.text.contains("灾难副本"))
	corridor._open_hub_section("terminal")
	assert(corridor.section_title.text.contains("异常兑换"))
	corridor._open_hub_section("avatar")
	assert(corridor.section_title.text.contains("角色切换"))

	corridor.queue_free()
	state.reset_progress()
	migrated.reset_progress()
	state.free()
	migrated.free()
	print("V21 passed: typed enemy pools, difficulty/affix material bonus, rare pity, guaranteed boss core, extraction banking, unique protection, save migration and eight independent hub entries")
	quit()
