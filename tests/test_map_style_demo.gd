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
	var zones := instance.get_node("Rooms/SampleRoom/EncounterZones")

	assert(player != null and not player.use_runtime_progress)
	assert(architecture.texture != null and architecture.texture.get_size() == Vector2(1536, 1024))
	assert(architecture.scale == Vector2.ONE)
	assert(MapStyleDemo.MAP_SIZE == Vector2(1536, 1024))
	assert(camera.zoom == Vector2(1.65, 1.65))
	assert(camera.limit_right == 1536 and camera.limit_bottom == 1024)
	assert(camera.position_smoothing_enabled)

	assert(room.room_id == &"hospital_elite_large")
	assert(room.room_kind == "elite")
	assert(room.size_class == MapRoomModule.RoomSizeClass.LARGE)
	assert(room.is_multi_screen())
	assert(room.walkable_outline.size() == 16)
	assert(room.camera_guide_outline.size() == 8)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.get_obstacles().size() == 8)
	assert(zones.get_child_count() == 3)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)

	var boundary_segments := 0
	for body in instance.get_node("WorldCollision").get_children():
		if body is StaticBody2D and body.has_meta(&"room_boundary"):
			boundary_segments += 1
	assert(boundary_segments == room.walkable_outline.size())

	var unique_prop_paths := {}
	var wall_roles := 0
	for obstacle in room.get_obstacles():
		var sprite := obstacle.get_node("PropSprite") as Sprite2D
		assert(sprite != null and sprite.texture != null)
		assert(obstacle.visual_scale <= 0.68)
		assert(obstacle.footprint_size.x <= 210.0)
		unique_prop_paths[sprite.texture.resource_path] = true
		if obstacle.placement_role == "wall":
			wall_roles += 1
			assert(not obstacle.wall_side.is_empty())
	assert(unique_prop_paths.size() == 6)
	assert(wall_roles == 7)

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
		"Map style demo v4 passed: true multi-screen scale, arbitrary room polygons, "
		+ "guided camera, coherent props and encounter zones",
	)
	quit()
