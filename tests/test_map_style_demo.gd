extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene := load("res://scenes/test/map_style_demo.tscn") as PackedScene
	if scene == null:
		push_error("Map style demo scene failed to load")
		quit(1)
		return
	var instance := scene.instantiate() as MapStyleDemo
	if instance == null:
		push_error("Map style demo scene failed to instantiate")
		quit(1)
		return
	root.add_child(instance)
	await process_frame
	await process_frame

	var player := instance.get_node("Player") as Player
	var rendered_player := (
		player.get_node("RenderedAtlasCharacter")
		as RenderedAtlasCharacter
	)
	var camera := player.get_node("Camera2D") as Camera2D
	var room := instance.get_node("Rooms/SampleRoom") as MapRoomModule
	var modular := instance.get_node("ModularArchitecture") as ModularHospitalRoom
	var zones := instance.get_node("Rooms/SampleRoom/EncounterZones")

	assert(player != null and not player.use_runtime_progress)
	assert(rendered_player != null)
	assert(not rendered_player.runtime_sync_enabled)
	assert(rendered_player.selected_skin() == &"resonant_demo_v1")
	assert(modular.visible)
	var floor_tiles := modular.get_node("FloorTiles") as TileMapLayer
	var wall_tiles := modular.get_node("WallBaseTiles") as TileMapLayer
	var side_wall_tiles := modular.get_node("SideWallTiles") as TileMapLayer
	var foreground_tiles := modular.get_node("ForegroundWalls") as TileMapLayer
	assert(floor_tiles != null and floor_tiles.get_used_cells().size() == 40)
	assert(wall_tiles != null and wall_tiles.get_used_cells().size() == 8)
	assert(side_wall_tiles != null and side_wall_tiles.get_used_cells().size() == 8)
	assert(foreground_tiles != null and foreground_tiles.get_used_cells().size() == 8)
	assert(modular.wall_tile_count() == 28)
	assert(floor_tiles.tile_set.tile_size == Vector2i(128, 128))
	assert(modular.get_node("DoorSockets").get_child_count() == 2)
	assert(modular.get_node("ContentSlots").get_child_count() == 3)
	var floor_macro := modular.get_node("StandardFloorMacro") as Polygon2D
	assert(floor_macro != null)
	assert(floor_macro.texture.get_size() == Vector2(2048, 1280))
	assert(floor_macro.position == Vector2(152, 192))
	assert(floor_macro.scale == Vector2.ONE)
	assert(floor_macro.polygon == PackedVector2Array([
		Vector2(44, 0),
		Vector2(1188, 0),
		Vector2(1232, 44),
		Vector2(1232, 724),
		Vector2(1188, 768),
		Vector2(44, 768),
		Vector2(0, 724),
		Vector2(0, 44),
	]))
	assert(floor_macro.uv.size() == floor_macro.polygon.size())
	for point_index in floor_macro.polygon.size():
		var expected_uv := (
			floor_macro.polygon[point_index]
			/ Vector2(1232, 768)
			* Vector2(2048, 1280)
		)
		assert(floor_macro.uv[point_index].is_equal_approx(expected_uv))
	assert(floor_macro.z_index > floor_tiles.z_index)
	assert(floor_macro.z_index < wall_tiles.z_index)
	var wall_shell := modular.get_node("StandardWallShell") as Node2D
	assert(wall_shell != null and wall_shell.get_child_count() == 4)
	for wall_region in wall_shell.get_children():
		assert((wall_region as Sprite2D).z_index > floor_macro.z_index)
	assert((wall_shell.get_node("BackWall") as Sprite2D).z_index == -7)
	assert((wall_shell.get_node("WestWall") as Sprite2D).position == Vector2(0, 256))
	assert((wall_shell.get_node("EastWall") as Sprite2D).position == Vector2(1280, 256))
	assert((wall_shell.get_node("ForegroundWall") as Sprite2D).z_index == 38)
	assert(not wall_tiles.visible)
	assert(not side_wall_tiles.visible)
	assert(not foreground_tiles.visible)
	assert(not modular.has_node("FloorDetails/MedicalGuideLine"))
	assert(not modular.has_node("FloorDetails/MedicalGuideGlow"))
	assert(not modular.has_node("FloorDetails/ObjectiveBay"))
	assert(modular.get_node("ThemeProps").get_child_count() == 3)
	assert(modular.get_node("LightAccents").get_child_count() == 2)
	assert(modular.theme.theme_id == MapThemeCatalog.HOSPITAL_THEME)
	assert(modular.theme.display_name == "异常侵蚀医疗研究设施")
	assert(modular is RoomBuilder)
	assert(_sprite_count(modular) == 7)
	assert(MapStyleDemo.MAP_SIZE == Vector2(1536, 1024))
	var viewport_size := instance.get_viewport_rect().size
	var expected_cover_zoom := (
		maxf(viewport_size.x / 1536.0, viewport_size.y / 1024.0)
		* MapStyleDemo.CAMERA_COVER_OVERSCAN
	)
	assert(camera.zoom.is_equal_approx(Vector2.ONE * expected_cover_zoom))
	assert(camera.zoom.x > 0.72)
	assert(camera.limit_right == 1536 and camera.limit_bottom == 1024)
	assert(camera.position_smoothing_enabled)

	assert(room.room_id == &"hospital_standard_combat")
	assert(room.room_kind == "combat")
	assert(room.size_class == MapRoomModule.RoomSizeClass.STANDARD)
	assert(not room.is_multi_screen())
	assert(room.walkable_outline.size() == 4)
	assert(room.camera_guide_outline.size() == 4)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.door_anchor_overrides.size() == 2)
	assert(room.get_obstacles().is_empty())
	assert(room.get_node("NavigationRegion2D") is NavigationRegion2D)
	assert((room.get_node("NavigationRegion2D") as NavigationRegion2D).enabled)
	assert(
		(room.get_node("NavigationRegion2D") as NavigationRegion2D)
		.navigation_polygon.get_polygon_count() >= 1
	)
	assert(zones.get_child_count() == 1)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)
	assert(instance.exit_doors.size() == 2)

	for door in instance.exit_doors:
		assert(door is MapRoomDoor)
		assert(door.state == MapRoomDoor.DoorState.SEALED)
		assert(door.rotation == 0.0)
		assert(door.get_node("DoorOpening") is Polygon2D)
		assert(door.get_node("DoorFrame") is Node2D)
		assert(door.get_node("LeftLeaf") is Polygon2D)
		assert(door.get_node("RightLeaf") is Polygon2D)
		assert(door.get_node("LockedIndicator") is Polygon2D)
		assert(door.get_node("OpenIndicator") is Polygon2D)
		assert(door.get_node("DoorBlocker") is StaticBody2D)
		assert(door._theme == modular.theme)
		var expected_recess := door.outward_vector() * MapRoomDoor.SIDE_DOOR_VISUAL_RECESS
		assert((door.get_node("DoorFrame") as Node2D).position == expected_recess)
		assert((door.get_node("DoorOpening") as Polygon2D).position == expected_recess)

	# Each of the two wall edges is split around a real door opening.
	var boundary_segments := _boundary_segment_count(instance)
	assert(boundary_segments == room.walkable_outline.size() + 2)

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

	for enemy in get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER):
		enemy.free()
	await process_frame
	await process_frame
	assert(instance.room_cleared)
	for door in instance.exit_doors:
		assert(door.state != MapRoomDoor.DoorState.SEALED)
		var blocker := door.get_node("DoorBlocker/CollisionShape2D") as CollisionShape2D
		assert(blocker.disabled)

	# The second room uses the same builder but extends the long axis to 12 cells.
	instance._show_room_variant(1)
	await process_frame
	assert(room.room_id == &"hospital_long_ward")
	assert(room.room_kind == "elite")
	assert(room.size_class == MapRoomModule.RoomSizeClass.LARGE)
	assert(room.is_multi_screen())
	assert(room.walkable_outline.size() == 4)
	assert(room.camera_guide_outline.size() == 4)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(zones.get_child_count() == 2)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)
	assert(modular.visible)
	assert(modular.floor_tiles.get_used_cells().size() == 60)
	assert(modular.floor_tiles.get_cell_atlas_coords(Vector2i(10, 2)) == Vector2i(7, 0))
	assert(
		modular.floor_tiles.get_cell_alternative_tile(Vector2i(10, 2))
		== RoomBuilder.TILE_FLIP_H
	)
	assert(modular.get_node("ContentSlots").get_child_count() == 4)
	assert(modular.get_node("ThemeProps").get_child_count() == 4)
	assert(not modular.has_node("StandardFloorMacro"))
	assert(not modular.has_node("StandardWallShell"))
	assert(modular.get_node("FloorDetails/MedicalGuideLine") is Line2D)
	assert(modular.get_node("FloorDetails/MedicalGuideGlow") is Line2D)
	assert(room.camera_bounds == Rect2(0, 0, 2048, 1024))
	assert(camera.limit_right == 2048 and camera.limit_bottom == 1024)
	var west_camera := room.guided_camera_world_point(Vector2(384, 576))
	var east_camera := room.guided_camera_world_point(Vector2(1664, 576))
	assert(east_camera.x > west_camera.x)
	assert(is_equal_approx(east_camera.y, west_camera.y))

	player.global_position = Vector2(1280, 520)
	instance._physics_process(0.0)
	await process_frame
	assert(instance.activated_zone_count == 2)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 4)

	# The third room validates a concave L outline, automatic inner wall overlap,
	# explicit door anchors, navigation triangulation, and two-axis camera travel.
	instance._show_room_variant(2)
	await process_frame
	assert(room.room_id == &"hospital_l_elite")
	assert(room.walkable_outline.size() == 8)
	assert(room.camera_guide_outline.size() == 8)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(modular.floor_tiles.get_used_cells().size() == 45)
	assert(modular.get_node("ContentSlots").get_child_count() == 4)
	assert(modular.get_node("ThemeProps").get_child_count() == 4)
	assert(not modular.has_node("StandardFloorMacro"))
	assert(not modular.has_node("StandardWallShell"))
	assert(room.camera_bounds == Rect2(0, 0, 2048, 1280))
	assert(_boundary_segment_count(instance) == 10)
	assert(room.contains_world_point(Vector2(512, 448)))
	assert(room.contains_world_point(Vector2(1408, 832)))
	assert(not room.contains_world_point(Vector2(1408, 448)))
	var upper_camera := room.guided_camera_world_point(Vector2(512, 448))
	var lower_camera := room.guided_camera_world_point(Vector2(1536, 896))
	assert(lower_camera.x > upper_camera.x)
	assert(lower_camera.y > upper_camera.y)
	assert(room.get_node("NavigationRegion2D") is NavigationRegion2D)

	# The fourth room is a 16x10 Boss graybox with data-driven encounter slots,
	# solid obstacle footprints, navigation holes, sealed doors, and a reward hook.
	instance._show_room_variant(3)
	await process_frame
	await process_frame
	assert(room.room_id == &"hospital_boss_arena_graybox")
	assert(room.room_kind == "boss")
	assert(room.size_class == MapRoomModule.RoomSizeClass.BOSS)
	assert(room.is_multi_screen())
	assert(room.camera_bounds == Rect2(0, 0, 2560, 1792))
	assert(room.walkable_outline.size() == 4)
	assert(room.blocked_outlines.size() == 4)
	assert(room.door_directions == PackedStringArray(["north", "south"]))
	assert(modular.floor_tiles.get_used_cells().size() == 160)
	assert(modular.get_node("ContentSlots").get_child_count() == 10)
	assert(modular.get_node("ThemeProps").get_child_count() == 4)
	assert(not modular.has_node("RoomFloorMacro"))
	assert(not modular.has_node("RoomWallShell"))
	assert(not room.contains_world_point(Vector2(704, 704)))
	assert(room.contains_world_point(Vector2(1280, 896)))
	assert(room.get_node("NavigationRegion2D") is NavigationRegion2D)
	assert(
		(room.get_node("NavigationRegion2D") as NavigationRegion2D)
		.navigation_polygon.get_polygon_count() >= 1
	)
	assert(instance.active_boss != null)
	assert(instance.active_boss.visible)
	assert(instance.active_boss.get_meta(&"summon_points").size() == 4)
	assert(instance.active_boss.get_meta(&"phase_thresholds") == PackedFloat32Array([0.5]))
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 1)
	for door in instance.exit_doors:
		assert(door.state == MapRoomDoor.DoorState.SEALED)
	instance.active_boss.free()
	await process_frame
	await process_frame
	assert(instance.room_cleared)
	assert(instance.boss_reward_preview != null)
	assert(instance.boss_reward_preview.get_node("RewardGlow") is Polygon2D)
	for door in instance.exit_doors:
		assert(door.state != MapRoomDoor.DoorState.SEALED)

	instance.queue_free()
	print(
		"Map style demo passed: modular samples plus the Boss graybox retain "
		+ "continuous walls, encounters, obstacle navigation, doors, and cameras",
	)
	quit()


func _boundary_segment_count(instance: MapStyleDemo) -> int:
	var result := 0
	for body in instance.get_node("WorldCollision").get_children():
		if body is StaticBody2D and body.has_meta(&"room_boundary"):
			result += 1
	return result


func _sprite_count(root_node: Node) -> int:
	var result := 0
	for child in root_node.get_children():
		if child is Sprite2D:
			result += 1
		result += _sprite_count(child)
	return result
