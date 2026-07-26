extends SceneTree

func _init() -> void:
 call_deferred("_run_test")

func _run_test() -> void:
 var metro = DynamicRunConfig.new(2048, "metro")
 assert(metro.validate())
 assert(metro.world_id == "metro")
 assert(metro.action_code.begins_with("MET-"))
 assert(metro.room_order[0] == "检票大厅")
 assert(metro.room_order.size() == 10)
 assert(metro.room_order[-1] == "零号换乘层")
 assert(metro.mission_id in ["lost_service", "switch_zero"])
 assert(metro.objective_count == 3)
 assert(metro.objective_positions == DynamicRunConfig.METRO_BEACON_POSITIONS)
 assert(metro.metro_route_positions.north.exit == DynamicRunConfig.METRO_NORTH_EXIT)
 assert(metro.metro_route_positions.south.exit == DynamicRunConfig.METRO_SOUTH_EXIT)
 print("Metro config test passed: seeded pressure route, dual stations, contracts and action code")
 quit()
