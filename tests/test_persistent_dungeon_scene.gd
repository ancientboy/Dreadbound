extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var game_state := root.get_node("GameState") as GameProgress
	game_state.save_path = "user://test_dreadbound_persistent_scene.json"
	game_state.reset_progress()
	game_state.selected_world = "metro"
	game_state.begin_run(501)
	var first_scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(first_scene)
	await process_frame
	var first_npc := _find_interactable(first_scene, "linye_story")
	assert(first_npc != null)
	assert(is_instance_valid(first_scene.hidden_gate))
	first_scene._open_persistent_narrative(first_npc)
	assert(first_scene.event_panel.visible)
	first_scene._resolve_persistent_narrative(true)
	assert(str(game_state.world_state.npcs.linye.promise) == "return_for_linye")
	assert(not game_state.dungeon_hidden_open("metro", "lost_passenger_level"))
	assert(is_instance_valid(first_scene.hidden_gate))
	var first_code := game_state.last_action_code
	first_scene.queue_free()
	await process_frame
	game_state.settle_run(true, 3, 0, 0, 1, [], {"world": "metro", "action_code": first_code})

	game_state.begin_run(502)
	var second_scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(second_scene)
	await process_frame
	assert(str(second_scene.narrative_chapter.chapter) == "promise_due")
	var returning_npc := _find_interactable(second_scene, "linye_story")
	second_scene._open_persistent_narrative(returning_npc)
	second_scene._resolve_persistent_narrative(true)
	await process_frame
	assert(game_state.dungeon_hidden_open("metro", "lost_passenger_level"))
	assert(not is_instance_valid(second_scene.hidden_gate))
	assert(_find_interactable(second_scene, "metro_hidden_archive") != null)
	assert(second_scene.run_config.map_regions().any(func(region): return str(region.id) == "lost_passenger_level"))
	game_state.reset_progress()
	second_scene.queue_free()
	await process_frame
	print("Persistent dungeon scene passed: NPC panel, sealed first visit, second-visit gate and hidden-map reveal")
	quit()


func _find_interactable(scene: Node, id: String) -> ObjectiveInteractable:
	for item in scene.interactables:
		if item.objective_id == id:
			return item
	return null
