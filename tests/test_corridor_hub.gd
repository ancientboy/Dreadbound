extends SceneTree

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := root.get_node("GameState") as GameProgress
	var original_pathway := state.selected_pathway
	var original_style := state.active_combat_style
	var corridor = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	state.selected_pathway = "armorer"
	state.active_combat_style = ""
	assert(corridor._walker_body_texture().resource_path.ends_with("armorer_spritesheet.png"))
	state.active_combat_style = "heavy_suppression"
	assert(corridor._walker_body_texture().resource_path.ends_with("heavy_suppression_spritesheet.png"))
	state.active_combat_style = ""
	state.selected_pathway = original_pathway
	state.active_combat_style = original_style
	var original_avatar := state.player_avatar
	state.player_avatar = "drifter_female"
	assert(corridor._walker_body_texture().resource_path.ends_with("drifter_highres_spritesheet.png"))
	state.player_avatar = original_avatar
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.get_node("HubActions").visible)
	assert(corridor.get_node("OpenArchive").visible)
	assert(corridor.get_node("OpenCorridorAudioSettings").visible)
	corridor._open_run_archive()
	assert(not corridor.run_archive_panel.visible)
	corridor.walker_position = corridor.TERMINAL_POSITION
	await process_frame
	assert(corridor.get_node("HubActions").visible)
	assert(corridor.get_node("HubActions/OpenTerminal").visible)
	corridor._open_terminal()
	assert(corridor.get_node("Margin").visible or corridor.mobile_terminal_panel.visible)
	assert(not corridor.get_node("HubActions").visible)
	corridor._open_warehouse()
	assert(corridor.warehouse_panel.visible)
	assert(corridor.warehouse_panel.z_index > corridor.mobile_terminal_panel.z_index)
	assert(corridor.salvage_reward_panel.z_index > corridor.warehouse_panel.z_index)
	corridor._layout_salvage_reward(Vector2(720, 420))
	assert(corridor.salvage_reward_panel.size.x <= 672)
	assert(corridor.salvage_reward_panel.size.y <= 348)
	corridor.warehouse_panel.visible = false
	corridor._close_terminal()
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.get_node("HubActions").visible)
	corridor._activate_target("curator")
	assert(corridor.curator_contract_panel.visible)
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.hub_navigation.visible)
	corridor._close_top_surface()
	assert(not corridor.curator_contract_panel.visible)
	assert(corridor.hub_navigation.visible)
	corridor.walker_position = corridor.SANATORIUM_GATE_POSITION
	await process_frame
	assert(corridor._nearby_target().id == "sanatorium_gate")
	assert(corridor.get_node("HubActions/Deploy").visible)
	assert(not corridor.get_node("HubActions/OpenTerminal").visible)
	corridor.walker_position = corridor.METRO_GATE_POSITION
	await process_frame
	assert(corridor._nearby_target().id == "metro_gate")
	assert(corridor.active_gate_world == "metro")
	var reflection := {
		"profile": {"dimensions": {}},
		"echo": {"id": "unformed_echo", "name": "未成形的回声"},
		"trailer": "下一集：门后的回声仍在等待。",
	}
	var archive_text: String = corridor._build_run_archive_text({
		"success": true,
		"records": 3,
		"events_resolved": 2,
		"enemies_defeated": 4,
		"carried_shards": 5,
		"mission_reward": 9,
		"banked_shards": 14,
		"equipment_rewards": ["conductor_railgun"],
		"relic_growth": {"name": "末班导轨枪", "level": 2},
		"difficulty": "hazard",
		"dynamic_run": {"action_code": "MET-ARCHIVE", "mission": "末班撤离", "world": "metro"},
		"humanity_reflection": reflection,
		"world_consequences": [],
	})
	assert(archive_text.contains("本次收获"))
	assert(archive_text.contains("末班导轨枪"))
	assert(archive_text.contains("人性洞察"))
	assert(archive_text.contains("下一集预告"))
	print("Corridor hub test passed: terminal, curator contracts, warehouse, and two direct legendary gates")
	quit()
