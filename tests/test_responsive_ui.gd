extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var main = load("res://scenes/metro.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var minimap = main.get_node("Interface/Minimap")
	assert(minimap.map_button != null)
	minimap.map_button.pressed.emit()
	assert(minimap.expanded)
	minimap.map_button.pressed.emit()
	assert(not minimap.expanded)
	for viewport_width in [1280, 1024, 960]:
		main._apply_responsive_ui(Vector2(viewport_width, 720))
		var top_bar: Control = main.get_node("Interface/TopBar")
		assert(top_bar.position.x >= 14.0)
		assert(top_bar.position.x + top_bar.size.x <= viewport_width + 0.1)
		for panel_path in ["Interface/CompletePanel", "Interface/EventPanel"]:
			var panel: Control = main.get_node(panel_path)
			assert(panel.position.x >= 31.0)
			assert(panel.position.x + panel.size.x <= viewport_width - 31.0)
			for child in panel.get_children():
				if child is Control:
					assert(child.position.x >= 0.0)
					assert(child.position.x + child.size.x <= panel.size.x + 0.1)
		var reward_panel: Control = main.reward_panel
		assert(reward_panel.position.x >= 23.0)
		assert(reward_panel.position.x + reward_panel.size.x <= viewport_width - 23.0)
		var previous_bottom := 0.0
		for button in main.reward_buttons:
			assert(button.position.x >= 0.0)
			assert(button.position.x + button.size.x <= reward_panel.size.x + 0.1)
			assert(button.position.y >= previous_bottom)
			previous_bottom = button.position.y + button.size.y
		assert(previous_bottom <= reward_panel.size.y - 52.0 + 0.1)
	main._apply_responsive_ui(Vector2(720, 420))
	var short_reward_panel: Control = main.reward_panel
	var short_note: Control = short_reward_panel.get_child(short_reward_panel.get_child_count() - 1)
	for button in main.reward_buttons:
		assert(button.position.y + button.size.y <= short_note.position.y + 0.1)
	main.queue_free()
	var corridor = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	for viewport_width in [1280, 1024, 960]:
		corridor._apply_responsive_ui(Vector2(viewport_width, 720))
		var actions: HBoxContainer = corridor.get_node("Margin/Layout/Actions")
		var required_width := 0.0
		for action in actions.get_children():
			required_width += action.custom_minimum_size.x
		required_width += actions.get_theme_constant("separation") * (actions.get_child_count() - 1)
		assert(required_width <= viewport_width - 40.0)
		var warehouse: Control = corridor.warehouse_panel
		assert(warehouse.position.x >= 23.0)
		assert(warehouse.position.x + warehouse.size.x <= viewport_width - 23.0)
		var archive: Control = corridor.run_archive_panel
		assert(archive.position.x >= 15.0)
		assert(archive.position.x + archive.size.x <= viewport_width - 15.0)
	corridor.size = Vector2(1280, 1200)
	assert(corridor._is_portrait())
	corridor._open_terminal()
	assert(not corridor.get_node("Margin").visible)
	assert(corridor.mobile_terminal_panel.visible)
	assert(not corridor.hub_navigation.visible)
	var terminal_actions := corridor.mobile_terminal_panel.get_node("FixedActions") as HBoxContainer
	var terminal_scroll := corridor.mobile_terminal_panel.get_child(2) as ScrollContainer
	assert(terminal_actions.position.y >= terminal_scroll.position.y + terminal_scroll.size.y)
	assert(terminal_actions.position.y + terminal_actions.size.y <= corridor.mobile_terminal_panel.size.y)
	corridor._close_terminal()
	assert(corridor.hub_navigation.visible)
	corridor._apply_responsive_ui(Vector2(680, 720))
	corridor.size = Vector2(680, 720)
	var nav_top: float = corridor.hub_navigation.position.y
	assert(corridor._hub_stick_center().y + 104.0 < nav_top)
	assert(corridor._hub_action_center().y + 84.0 < nav_top)
	corridor._open_warehouse()
	var detail_scroll: ScrollContainer = corridor.warehouse_detail_scroll
	assert(detail_scroll != null and detail_scroll.clip_contents)
	assert(detail_scroll.position.y + detail_scroll.size.y <= corridor.equip_button.position.y)
	corridor.queue_free()
	print("Responsive UI tests passed")
	quit()
