extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var catalog := ContentCatalog.new()
	assert(catalog.errors.is_empty(), "\n".join(catalog.errors))
	assert(int(catalog.data.schema_version) == 2)
	assert(catalog.data.world_rules.size() == 7)
	assert(catalog.data.factions.size() == 4)
	assert(catalog.squad().roles.size() == 4)
	assert(catalog.main_story().acts.size() == 4)
	assert(catalog.generation_rules().dungeon_template.size() >= 15)
	assert(catalog.generation_rules().forbidden_mutations.has("复制唯一物品"))

	for world_id in ["sanatorium", "metro"]:
		var world := catalog.dungeon(world_id)
		assert(not str(world.short_intro).is_empty())
		assert(not str(world.full_story).is_empty())
		assert(not str(world.anomaly_law).is_empty())
		assert(not str(world.boss_truth).is_empty())
		assert(world.truth_records.size() == 5)
		for item_id in world.unique_items:
			assert(not catalog.unique_item(str(item_id)).is_empty())
			assert(EquipmentDatabase.ITEMS.has(str(item_id)))
		for material_id in world.materials:
			assert(not catalog.material(str(material_id)).is_empty())
			assert(ExchangeEvolution.MATERIALS.has(str(material_id)))

	for item_id in ["director_reaper", "conductor_railgun", "linye_pass"]:
		var item := catalog.unique_item(item_id)
		assert(not str(item.serial).is_empty())
		assert(not str(item.uniqueness).is_empty())
		assert(not str(item.repeat_defeat).is_empty())

	var game_state := root.get_node("/root/GameState")
	game_state.persistent_dungeons.reset()
	var corridor: Control = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	corridor._open_hub_section("archive")
	assert(corridor.section_panel.visible)
	assert(corridor.section_title.text.contains("世界与叙事档案"))
	assert(corridor.section_content.get_child_count() >= 8)
	corridor._open_codex_entry("rules")
	assert(corridor.section_title.text.contains("底层法则"))
	corridor._open_codex_entry("factions")
	assert(corridor.section_title.text.contains("四大阵营"))
	corridor._open_codex_entry("squad")
	assert(corridor.section_title.text.contains("行者编组"))

	var san_visit_record: Dictionary = catalog.dungeon("sanatorium").truth_records[0]
	assert(not corridor._truth_record_unlocked("sanatorium", san_visit_record))
	game_state.persistent_dungeons.dungeons.sanatorium.visits = 1
	assert(corridor._truth_record_unlocked("sanatorium", san_visit_record))
	var san_boss_record: Dictionary = catalog.dungeon("sanatorium").truth_records[3]
	assert(not corridor._truth_record_unlocked("sanatorium", san_boss_record))
	game_state.persistent_dungeons.dungeons.sanatorium.boss_state.defeats = 1
	assert(corridor._truth_record_unlocked("sanatorium", san_boss_record))
	corridor._open_codex_entry("dungeon:sanatorium")
	assert(corridor.section_title.text.contains("废弃疗养院"))

	corridor.queue_free()
	game_state.persistent_dungeons.reset()
	print("N0-N7 passed: identity, world laws, factions, squad, story arc, authored dungeons, unique lore, generation boundaries, unified catalog and unlockable in-game codex")
	quit()
