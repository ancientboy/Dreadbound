extends SceneTree

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var corridor = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.get_node("HubActions").visible)
	corridor.walker_position = corridor.TERMINAL_POSITION
	await process_frame
	assert(corridor.get_node("HubActions").visible)
	assert(corridor.get_node("HubActions/OpenTerminal").visible)
	corridor._open_terminal()
	assert(corridor.get_node("Margin").visible or corridor.mobile_terminal_panel.visible)
	assert(not corridor.get_node("HubActions").visible)
	corridor._open_warehouse()
	assert(corridor.warehouse_panel.visible)
	corridor.warehouse_panel.visible = false
	corridor._close_terminal()
	assert(not corridor.get_node("Margin").visible)
	assert(not corridor.get_node("HubActions").visible)
	corridor.walker_position = corridor.SANATORIUM_GATE_POSITION
	await process_frame
	assert(corridor._nearby_target().id == "sanatorium_gate")
	assert(corridor.get_node("HubActions/Deploy").visible)
	assert(not corridor.get_node("HubActions/OpenTerminal").visible)
	corridor.walker_position = corridor.METRO_GATE_POSITION
	await process_frame
	assert(corridor._nearby_target().id == "metro_gate")
	assert(corridor.active_gate_world == "metro")
	print("Corridor hub test passed: terminal, warehouse, and two direct legendary gates")
	quit()
