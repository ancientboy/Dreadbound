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
 corridor._open_terminal()
 assert(corridor.get_node("Margin").visible)
 assert(not corridor.get_node("HubActions").visible)
 corridor._open_warehouse()
 assert(corridor.warehouse_panel.visible)
 corridor.warehouse_panel.visible = false
 corridor._close_terminal()
 assert(not corridor.get_node("Margin").visible)
 assert(not corridor.get_node("HubActions").visible)
 print("Corridor hub test passed: independent space, terminal toggle, warehouse overlay")
 quit()
