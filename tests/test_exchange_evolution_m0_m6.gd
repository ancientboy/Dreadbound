extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	assert(ExchangeEvolution.validate_catalog().is_empty())
	assert(ExchangeEvolution.COMBAT_STYLES.size() == 12)
	assert(ExchangeEvolution.MATERIALS.size() == 6)

	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_exchange_evolution.json"
	state.reset_progress()
	state.echo_shards = 300
	state.causality_fragments = 20
	state.synthesis_embers = 80

	var offers := state.get_exchange_offers()
	assert(offers.size() == 5)
	assert(state.purchase_exchange_offer("base_weapon"))
	assert(not state.purchase_exchange_offer("base_weapon"))
	assert(state.equipment_inventory.count("service_crowbar") == 2)

	state.equipment_inventory.append("service_crowbar")
	var pending := state.begin_synthesis(["service_crowbar", "service_crowbar", "service_crowbar"])
	assert(pending.get("candidates", []).size() >= 2)
	var synthesized := state.complete_synthesis(0)
	assert(not synthesized.is_empty())
	assert(state.equipment_inventory.has(str(synthesized.item_id)))
	assert(not str(state.equipment_affixes.get(str(synthesized.item_id), "")).is_empty())

	state.equipment_inventory.append_array(["medical_tag", "medical_tag"])
	assert(not state.begin_synthesis(["medical_tag", "medical_tag", "medical_tag"]).is_empty())
	var embers_before := state.synthesis_embers
	assert(state.reject_synthesis() > 0)
	assert(state.synthesis_embers > embers_before)
	assert(int(state.synthesis_pity.charm) == 1)

	state.selected_pathway = "armorer"
	state.unlocked_path_nodes.assign(["armorer_calibration", "armorer_mobility", "armorer_alternation"])
	assert(state.unlock_combat_style("weakpoint_sniper"))
	assert(state.active_combat_style == "weakpoint_sniper")
	assert(state.unlock_combat_style("heavy_suppression"))
	assert(state.select_combat_style("heavy_suppression"))
	assert(state.get_player_stats().shotgun_damage >= 35)

	state.equipment_inventory.append("conductor_railgun")
	assert(state.equip_item("conductor_railgun"))
	for level in range(5):
		assert(state.upgrade_equipment("conductor_railgun"))
	assert(int(state.equipment_levels.conductor_railgun) == 5)
	state.record_equipment_use("conductor_railgun", "ranged_hits", 35)
	var evolutions := state.available_evolutions("conductor_railgun")
	assert(evolutions.any(func(entry): return str(entry.id) == "hunter_form" and bool(entry.available)))
	assert(state.evolve_equipment("conductor_railgun", "hunter_form"))
	assert(str(state.current_equipment_evolution("conductor_railgun").name) == "猎轨形态")

	var aspect := ExchangeEvolution.heart_aspect_for(
		{"echo": {"id": "formed"}},
		[
			{"event_type": "costly_rescue"},
			{"event_type": "promise_kept"},
			{"event_type": "anonymous_help"},
		],
	)
	assert(str(aspect.id) == "watch")
	state.heart_aspect = aspect
	assert(state.get_player_stats().max_health > 100)

	var cycle_before := state.exchange_cycle
	var tissue_before := int(state.world_materials.tissue_sample)
	state.selected_world = "sanatorium"
	state.begin_run(20260726)
	state.settle_run(true, 3, 0, 2, 0, [], {"world": "sanatorium", "boss_defeated": true, "action_code": state.last_action_code})
	assert(state.exchange_cycle == cycle_before + 1)
	assert(int(state.world_materials.tissue_sample) > tissue_before)
	assert(int(state.world_materials.stitch_core) >= 1)
	state.world_materials.stitch_core = 2
	state.save_progress()
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.synthesis_embers == state.synthesis_embers)
	assert(int(restored.world_materials.stitch_core) == 2)
	assert(restored.unlocked_combat_styles.has("weakpoint_sniper"))
	assert(str(restored.equipment_evolutions.conductor_railgun) == "hunter_form")
	assert(not restored.heart_aspect.is_empty())
	assert(str(restored.heart_aspect.id) == str(state.heart_aspect.id))

	var legacy_path := "user://test_dreadbound_exchange_v19.json"
	var legacy := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"version": 19, "echo_shards": 7, "equipment_inventory": ["service_crowbar", "medical_tag"]}))
	legacy = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(migrated.save_health().status == "migrated")
	assert(migrated.save_health().migrations.any(func(text): return str(text).contains("v20")))
	assert(migrated.world_materials.size() == 6)

	state.reset_progress()
	restored.reset_progress()
	migrated.reset_progress()
	state.free()
	restored.free()
	migrated.free()
	print("M0-M6 passed: exchange, materials, deterministic synthesis, pity, twelve styles, upgrades, evolution, heart aspect, economy and migration")
	quit()
