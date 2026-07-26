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
	corridor.size = Vector2(1280, 1200)
	assert(corridor._is_portrait())
	corridor._open_terminal()
	assert(not corridor.get_node("Margin").visible)
	assert(corridor.mobile_terminal_panel.visible)
	corridor.queue_free()
	print("Responsive UI tests passed")
	quit()
