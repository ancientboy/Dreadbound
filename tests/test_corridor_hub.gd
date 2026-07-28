extends SceneTree

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := root.get_node("GameState") as GameProgress
	var original_pathway := state.selected_pathway
	var original_style := state.active_combat_style
	state.selected_pathway = ""
	state.active_combat_style = ""
	var corridor = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	for frame in range(4):
		await process_frame
	assert(corridor.walker_avatar != null)
	var hub_atlas := (
		corridor.walker_avatar.get_node("RenderedAtlasCharacter")
		as RenderedAtlasCharacter
	)
	assert(hub_atlas != null and hub_atlas.visible)
	assert(not corridor.walker_avatar._body_sprite.visible)
	var hub_sprite := hub_atlas.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(hub_sprite != null)
	for required_animation in [
		&"idle_front",
		&"idle_back",
		&"idle_left",
		&"idle_right",
		&"walk_front",
		&"walk_back",
		&"walk_left",
		&"walk_right",
		&"attack_melee_front",
		&"attack_melee_back",
		&"attack_melee_left",
		&"attack_melee_right",
		&"hit_front",
		&"hit_back",
		&"hit_left",
		&"hit_right",
		&"death_front",
		&"death_back",
		&"death_left",
		&"death_right",
	]:
		assert(hub_sprite.sprite_frames.has_animation(required_animation))
	corridor.set_process(false)
	corridor.walker_velocity = Vector2.RIGHT * corridor.WALK_SPEED
	corridor.walker_facing = Vector2.RIGHT
	corridor.walk_phase = TAU * 0.25
	corridor._sync_walker_avatar()
	assert(corridor.walker_avatar.velocity.length() > 2.0)
	hub_atlas._process(1.0 / 30.0)
	assert(hub_sprite.animation == &"walk_right")
	corridor.walker_velocity = Vector2.ZERO
	corridor._sync_walker_avatar()
	corridor.set_process(true)
	state.selected_pathway = "armorer"
	state.active_combat_style = ""
	assert(corridor._walker_body_texture().resource_path.ends_with("armorer_spritesheet.png"))
	await process_frame
	assert(hub_sprite.animation.begins_with("idle_"))
	state.active_combat_style = "heavy_suppression"
	assert(corridor._walker_body_texture().resource_path.ends_with("heavy_suppression_spritesheet.png"))
	await process_frame
	assert(corridor.walker_avatar.get_node_or_null("ProfessionSkeletonRig") == null)
	state.active_combat_style = ""
	state.selected_pathway = original_pathway
	state.active_combat_style = original_style
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
	assert(corridor.curator_contract_content.get_child_count() > 0)
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.hub_navigation.visible)
	state.player_profile.active_trial = ""
	state.player_profile.completed_trials = GameProgress.CURATOR_TRIALS.keys()
	state.player_profile.dismissed_trials = []
	state.player_profile.trial_reward_claims = []
	corridor._refresh_curator_contract_panel()
	await process_frame
	assert(_tree_text(corridor.curator_contract_content).contains("本轮暂无可选契约"))
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


func _tree_text(node: Node) -> String:
	var lines: Array[String] = []
	if node is Label or node is Button:
		lines.append(str(node.text))
	for child in node.get_children():
		lines.append(_tree_text(child))
	return "\n".join(lines)
