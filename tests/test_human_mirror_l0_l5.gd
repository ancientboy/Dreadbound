extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_content_catalog_and_knowledge()
	_test_cost_aware_reflection()
	_test_affix_names_and_stats()
	_test_two_persistent_dungeons()
	await _test_mirror_timeline_and_save()
	print("L0-L5 passed: save health, human mirror, knowledge, costly choices, persistent chapters, affixes and content catalog")
	quit()


func _test_content_catalog_and_knowledge() -> void:
	var catalog := ContentCatalog.new()
	assert(catalog.errors.is_empty())
	assert(not catalog.chapter("sanatorium", "patient_return").is_empty())
	assert(catalog.behavior_events_for("sanatorium").size() >= 4)
	assert(catalog.behavior_events_for("metro").size() >= 4)
	assert(catalog.affix_ids_for("nightmare").size() >= 6)
	var knowledge := BehaviorKnowledgeBase.new()
	assert(knowledge.entries.size() >= 40)
	assert(bool(knowledge.audit_summary().auditable))
	assert(int(knowledge.audit_summary().entries) >= 40)


func _test_cost_aware_reflection() -> void:
	var profiler := HumanityProfile.new()
	var low := profiler.analyze([{
		"event_id": "low", "event_type": "costly_rescue", "world_id": "sanatorium",
		"choice": "free", "context": {"cost_level": 1},
	}])
	var high := profiler.analyze([{
		"event_id": "high", "event_type": "costly_rescue", "world_id": "sanatorium",
		"choice": "costly", "context": {"cost_level": 3, "anonymous": true},
	}])
	assert(int(high.dimensions.responsibility.score) > int(low.dimensions.responsibility.score))
	assert(bool(high.dimensions.responsibility.evidence[0].anonymous))


func _test_affix_names_and_stats() -> void:
	var system := EnemyAffixSystem.new()
	var enemy := Patient.new()
	enemy.max_health = 100
	enemy.health = 100
	var result := {}
	for ordinal in range(100):
		result = system.apply(enemy, "nightmare", 991, ordinal, "病患")
		if not str(result.id).is_empty():
			break
	assert(not str(result.id).is_empty())
	assert(str(result.name).ends_with("病患"))
	assert(str(result.name) != "病患")
	assert(enemy.max_health > 100)
	assert(enemy.enemy_label == result.name)
	enemy.free()


func _test_two_persistent_dungeons() -> void:
	var persistent := PersistentDungeonState.new()
	var world := WorldStateStore.new()
	var first := persistent.begin_visit("sanatorium", "SAN-L1", world)
	assert(str(first.chapter) == "first_arrival")
	var rescue := persistent.resolve_choice("sanatorium", "rescue_shenlan", world, "SAN-L1")
	assert(bool(rescue.accepted))
	assert(str(world.npcs.shenlan.last_outcome) == "rescued")
	persistent.settle_visit("sanatorium", true, "SAN-L1", true)
	var second := persistent.begin_visit("sanatorium", "SAN-L2", world)
	assert(str(second.chapter) == "patient_return")
	var records := persistent.resolve_choice("sanatorium", "return_records", world, "SAN-L2")
	assert(bool(records.hidden_opened))
	assert(persistent.has_opened_area("sanatorium", "sealed_archive"))
	var san_config := DynamicRunConfig.new(88, "sanatorium")
	san_config.revealed_secret_regions.append("sealed_archive")
	assert(san_config.map_regions().any(func(region): return str(region.get("id", "")) == "sealed_archive"))
	assert(str(persistent.boss_variant("sanatorium", world).name).contains("病历"))
	var boss := SanatoriumBoss.new()
	boss.configure_history_variant(persistent.boss_variant("sanatorium", world))
	assert(boss.history_damage_multiplier > 1.0)
	assert(not boss.history_effect.is_empty())
	boss.free()
	persistent.begin_visit("metro", "MET-L1", world)
	assert(world.npcs.has("linye"))
	assert(world.npcs.has("xuzhao"))
	assert(world.npcs.has("ticket_echo"))


func _test_mirror_timeline_and_save() -> void:
	var state := GameProgress.new()
	root.add_child(state)
	state.save_path = "user://test_dreadbound_l0_l5.json"
	state.reset_progress()
	state.selected_world = "sanatorium"
	state.begin_run(19001)
	state.record_human_choice("costly_rescue", "shenlan", "救援", {"cost_level": 3, "anonymous": true})
	state.settle_run(true, 3, 0, 1, 1, [], {"world": "sanatorium", "action_code": state.last_action_code})
	assert(state.reflection_timeline().size() == 1)
	var contract := state.dispute_reflection("responsibility")
	assert(not contract.is_empty())
	assert(str(contract.id).begins_with("counter_responsibility"))
	assert(state.save_progress())
	var restored := GameProgress.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.reflection_timeline().size() == 1)
	assert(not restored.active_counter_contract.is_empty())
	assert(str(restored.save_health().status) in ["loaded", "migrated"])
	state.reset_progress()
	state.queue_free()
	restored.free()
	await process_frame
