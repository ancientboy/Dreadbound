extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _tree_text(node: Node) -> String:
	var lines: Array[String] = []
	if node is Label or node is Button:
		lines.append(str(node.text))
	for child in node.get_children():
		lines.append(_tree_text(child))
	return "\n".join(lines)


func _run_test() -> void:
	var home: Control = load("res://scenes/startup.tscn").instantiate()
	root.add_child(home)
	await process_frame
	assert(home.get_node("HomeScroll/HomeMargin/HomeContent/FeatureGrid").get_child_count() == 3)
	assert(home.get_node("HomeScroll/HomeMargin/HomeContent/WorldGrid").get_child_count() == 2)
	assert(home.primary_button != null)
	assert(home.profile_button != null)
	assert(home.theme != null)
	assert(home.theme.default_font == home.UI_FONT)
	assert(home.primary_button.text.contains("进入终末回廊"))
	assert(home.primary_button.has_theme_stylebox_override("normal"))
	assert(_tree_text(home).contains("恐惧会记住"))
	assert(_tree_text(home).contains("持续灾难世界"))
	home.queue_free()
	await process_frame

	var game_state := root.get_node("/root/GameState")
	game_state.reset_progress()
	game_state.echo_shards = 100
	game_state.causality_fragments = 5
	game_state.synthesis_embers = 20
	game_state.equipment_inventory.assign(["service_crowbar", "service_crowbar", "service_crowbar", "service_crowbar", "conductor_railgun"])
	game_state.equipment_levels.conductor_railgun = 5
	game_state.equipment_mastery.conductor_railgun = {"ranged_hits": 35, "multi_hits": 2, "low_health_hits": 1}
	game_state.persistent_dungeons.dungeons.metro.visits = 2
	game_state.persistent_dungeons.dungeons.metro.completed_runs = 1

	var corridor: Control = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	corridor._open_hub_section("terminal")
	var terminal_text := _tree_text(corridor.section_content)
	assert(terminal_text.contains("成本：消耗 3 件"))
	assert(terminal_text.contains("制式 → 改装"))
	assert(terminal_text.contains("/3]"))
	assert(terminal_text.contains("候选池"))

	corridor._open_warehouse()
	corridor._select_equipment("conductor_railgun")
	assert(corridor.warehouse_detail.text.contains("进化前置"))
	assert(corridor.warehouse_detail.text.contains("猎轨形态"))
	assert(corridor.progress_button.text.contains("选择进化路径"))
	corridor._show_evolution_paths("conductor_railgun")
	var evolution_text := _tree_text(corridor.section_content)
	assert(corridor.section_title.text.contains("三条进化路径"))
	assert(evolution_text.contains("行为条件"))
	assert(evolution_text.contains("消耗 1 因果残片"))

	corridor._open_codex_entry("dungeon:metro")
	var story_text := _tree_text(corridor.section_content)
	assert(story_text.contains("当前剧情走向"))
	assert(story_text.contains("已经发生的选择") or story_text.contains("逐步解锁的真相档案"))
	assert(story_text.contains("末班列车"))

	corridor.queue_free()
	game_state.reset_progress()
	print("Homepage and guidance passed: attractive entry surface, dungeon story route, synthesis costs and explicit equipment evolution choices")
	quit()
