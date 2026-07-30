extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene := load("res://scenes/test/map_style_demo.tscn") as PackedScene
	assert(scene != null)
	var instance := scene.instantiate() as MapStyleDemo
	root.add_child(instance)
	await process_frame
	await process_frame

	var player := instance.get_node("Player") as Player
	var camera := player.get_node("Camera2D") as Camera2D
	var room := instance.get_node("Rooms/SampleRoom") as MapRoomModule
	var architecture := instance.get_node("Architecture") as Sprite2D
	var foreground := instance.get_node("Foreground/WallsForeground") as Sprite2D
	var zones := instance.get_node("Rooms/SampleRoom/EncounterZones")

	assert(player != null and not player.use_runtime_progress)
	assert(architecture.texture != null)
	assert(
		architecture.texture.resource_path
		== "res://assets/art/worlds/map_demo/sample_room_v2/hospital_standard_shell_v2.jpg"
	)
	assert(architecture.texture.get_size() == Vector2(1536, 1024))
	assert(architecture.scale == Vector2.ONE)
	assert(foreground.texture != null)
	assert(
		foreground.texture.resource_path
		== "res://assets/art/worlds/map_demo/sample_room_v2/hospital_standard_foreground_v2.webp"
	)
	assert(MapStyleDemo.MAP_SIZE == Vector2(1536, 1024))
	assert(camera.zoom == Vector2(1.52, 1.52))
	assert(camera.limit_right == 1536 and camera.limit_bottom == 1024)
	assert(camera.position_smoothing_enabled)

	# The default vertical slice is the polished, empty standard room.
	assert(room.room_id == &"hospital_standard_combat")
	assert(room.room_kind == "combat")
	assert(room.size_class == MapRoomModule.RoomSizeClass.STANDARD)
	assert(not room.is_multi_screen())
	assert(room.walkable_outline.size() == 8)
	assert(room.camera_guide_outline.size() == 8)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.get_obstacles().is_empty())
	assert(zones.get_child_count() == 1)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)
	assert(instance.exit_doors.size() == 2)

	for door in instance.exit_doors:
		assert(door is MapRoomDoor)
		assert(door.state == MapRoomDoor.DoorState.SEALED)
		assert(door.get_node("DoorFrame") is Sprite2D)
		assert(door.get_node("LeftLeaf") is Sprite2D)
		assert(door.get_node("RightLeaf") is Sprite2D)
		assert(door.get_node("ForegroundLintel") is Sprite2D)
		assert(door.get_node("LockedIndicator") is Sprite2D)
		assert(door.get_node("OpenIndicator") is Sprite2D)
		assert(door.get_node("DoorBlocker") is StaticBody2D)

	var boundary_segments := _boundary_segment_count(instance)
	assert(boundary_segments == room.walkable_outline.size())

	var outside_corner := Vector2(60, 180)
	assert(not room.contains_world_point(outside_corner))
	player.global_position = outside_corner
	instance._physics_process(0.0)
	assert(room.contains_world_point(player.global_position))

	var requested_camera := Vector2(20, 20)
	var guided_camera := room.guided_camera_world_point(requested_camera)
	assert(guided_camera != requested_camera)
	assert(Geometry2D.is_point_in_polygon(
		room.to_local(guided_camera),
		room.camera_guide_outline,
	))

	# Clearing the single standard-room encounter unlocks both real door prefabs.
	for enemy in get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER):
		enemy.free()
	await process_frame
	await process_frame
	assert(instance.room_cleared)
	for door in instance.exit_doors:
		assert(door.state != MapRoomDoor.DoorState.SEALED)

	# Preserve the previous multi-screen elite-room regression coverage.
	instance._show_room_variant(1)
	await process_frame
	assert(room.room_id == &"hospital_elite_large")
	assert(room.room_kind == "elite")
	assert(room.size_class == MapRoomModule.RoomSizeClass.LARGE)
	assert(room.is_multi_screen())
	assert(room.walkable_outline.size() == 16)
	assert(room.camera_guide_outline.size() == 8)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(zones.get_child_count() == 3)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)
	assert(_boundary_segment_count(instance) == room.walkable_outline.size())

	player.global_position = Vector2(760, 520)
	instance._physics_process(0.0)
	await process_frame
	assert(instance.activated_zone_count == 2)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 4)

	player.global_position = Vector2(1200, 520)
	instance._physics_process(0.0)
	await process_frame
	assert(instance.activated_zone_count == 3)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 6)

	assert(instance.get_node("Foreground/FadeZone") is Area2D)
	instance.queue_free()
	print(
		"Map style demo v5 passed: polished empty room, modular doors, guided camera, "
		+ "and multi-screen elite-room regression",
	)
	quit()


func _boundary_segment_count(instance: MapStyleDemo) -> int:
	var result := 0
	for body in instance.get_node("WorldCollision").get_children():
		if body is StaticBody2D and body.has_meta(&"room_boundary"):
			result += 1
	return result
