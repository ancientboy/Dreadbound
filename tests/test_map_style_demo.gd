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
	var floor_macro := modular.get_node("StandardFloorMacro") as Sprite2D
	assert(floor_macro != null)
	assert(floor_macro.texture.get_size() == Vector2(1586, 992))
	assert(floor_macro.position == Vector2(0, 32))
	assert(floor_macro.scale.is_equal_approx(Vector2(
		1536.0 / 1586.0,
		960.0 / 992.0,
	)))
	assert(floor_macro.z_index > floor_tiles.z_index)
	assert(floor_macro.z_index < wall_tiles.z_index)
	var wall_shell := modular.get_node("StandardWallShell") as Node2D
	assert(wall_shell != null and wall_shell.get_child_count() == 4)
	for wall_region in wall_shell.get_children():
		assert((wall_region as Sprite2D).z_index > floor_macro.z_index)
	assert((wall_shell.get_node("Architecture") as Sprite2D).z_index == -7)
	assert((wall_shell.get_node("Architecture") as Sprite2D).position == Vector2(0, 32))
	assert((wall_shell.get_node("BackProps") as Sprite2D).z_index == -2)
	assert((wall_shell.get_node("FrontProps") as Sprite2D).z_index == 37)
	assert((wall_shell.get_node("ForegroundWall") as Sprite2D).z_index == 38)
	assert(not wall_tiles.visible)
	assert(not side_wall_tiles.visible)
	assert(not foreground_tiles.visible)
	assert(not modular.has_node("FloorDetails/MedicalGuideLine"))
	assert(not modular.has_node("FloorDetails/MedicalGuideGlow"))
	assert(not modular.has_node("FloorDetails/ObjectiveBay"))
	assert(modular.get_node("ThemeProps").get_child_count() == 0)
	assert(modular.get_node("LightAccents").get_child_count() == 2)
	assert(modular.theme.theme_id == MapThemeCatalog.HOSPITAL_THEME)
	assert(modular.theme.display_name == "异常侵蚀医疗研究设施")
	assert(modular is RoomBuilder)
	assert(_sprite_count(modular) == 5)
	assert(MapStyleDemo.MAP_SIZE == Vector2(1536, 1024))
	var viewport_size := instance.get_viewport_rect().size
	var expected_cover_zoom := maxf(
		0.96,
		maxf(viewport_size.x / 1408.0, viewport_size.y / 896.0)
		* MapStyleDemo.CAMERA_COVER_OVERSCAN
		* room.camera_overscan,
	)
	assert(camera.zoom.is_equal_approx(Vector2.ONE * expected_cover_zoom))
	assert(camera.zoom.x >= 0.96)
	assert(camera.limit_left == 64 and camera.limit_top == 64)
	assert(camera.limit_right == 1472 and camera.limit_bottom == 960)
	assert(camera.position_smoothing_enabled)

	assert(room.room_id == &"hospital_standard_combat")
	assert(room.room_kind == "combat")
	assert(room.size_class == MapRoomModule.RoomSizeClass.STANDARD)
	assert(not room.is_multi_screen())
	assert(room.walkable_outline.size() == 4)
	assert(room.camera_guide_outline == PackedVector2Array([
		Vector2(640, 480), Vector2(896, 480),
		Vector2(896, 672), Vector2(640, 672),
	]))
	assert(room.blocked_outlines.size() == 10)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.door_anchor_overrides.size() == 2)
	assert(room.door_anchor_world(&"west") == Vector2(256, 494))
	assert(room.door_anchor_world(&"east") == Vector2(1280, 494))
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
		assert(door.get_node("LeftLeaf") is Sprite2D)
		assert(door.get_node("RightLeaf") is Sprite2D)
		assert((door.get_node("LeftLeaf") as Sprite2D).texture is AtlasTexture)
		assert((door.get_node("RightLeaf") as Sprite2D).texture is AtlasTexture)
		assert(door.get_node("LockedIndicator") is Polygon2D)
		assert(door.get_node("OpenIndicator") is Polygon2D)
		assert(door.get_node("DoorBlocker") is StaticBody2D)
		assert(door._theme == modular.theme)
		var expected_recess := door.outward_vector() * 69.5
		assert((door.get_node("DoorFrame") as Node2D).position == expected_recess)
		assert((door.get_node("DoorOpening") as Polygon2D).position == expected_recess)

	# Door openings remain free; fixture collision uses each polygon's real
	# edge count and leaves transparent corners/component gaps walkable.
	var boundary_segments := _boundary_segment_count(instance)
	var fixture_edge_count := 0
	for blocked_outline in room.blocked_outlines:
		fixture_edge_count += blocked_outline.size()
	assert(boundary_segments == room.walkable_outline.size() + 2 + fixture_edge_count)
	assert(room.contains_world_point(Vector2(300, 494)))
	assert(room.contains_world_point(Vector2(1236, 494)))
	assert(room.contains_world_point(Vector2(324, 286)))
	assert(room.contains_world_point(Vector2(496, 350)))
	var fixture_center := Vector2(400, 350)
	assert(not room.contains_world_point(fixture_center))
	player.global_position = fixture_center
	instance._physics_process(0.0)
	assert(room.contains_world_point(player.global_position))

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

	# The second room is the approved authored long ward: two encounter stages,
	# a nurse-station checkpoint, layered art, authored doors and precise fixture
	# footprints over a 2048x1024 horizontal camera track.
	instance._show_room_variant(1)
	await process_frame
	assert(room.room_id == &"hospital_long_ward")
	assert(room.room_kind == "elite")
	assert(room.size_class == MapRoomModule.RoomSizeClass.LARGE)
	assert(room.is_multi_screen())
	assert(room.walkable_outline.size() == 4)
	assert(room.camera_guide_outline == PackedVector2Array([
		Vector2(448, 448), Vector2(1600, 448),
		Vector2(1600, 672), Vector2(448, 672),
	]))
	assert(room.blocked_outlines.size() == 18)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.door_anchor_world(&"west") == Vector2(190, 484))
	assert(room.door_anchor_world(&"east") == Vector2(1858, 484))
	assert(zones.get_child_count() == 2)
	assert(instance.activated_zone_count == 1)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 2)
	assert(modular.visible)
	assert(modular.floor_tiles.get_used_cells().size() == 60)
	assert(modular.get_node("ContentSlots").get_child_count() == 5)
	assert(modular.get_node("ThemeProps").get_child_count() == 0)
	var long_floor := modular.get_node("LongWardFloorMacro") as Sprite2D
	assert(long_floor != null)
	assert(long_floor.texture.get_size() == Vector2(2048, 1024))
	assert(long_floor.position == Vector2.ZERO)
	assert(long_floor.scale == Vector2.ONE)
	var long_shell := modular.get_node("LongWardWallShell") as Node2D
	assert(long_shell != null and long_shell.get_child_count() == 4)
	assert((long_shell.get_node("Architecture") as Sprite2D).z_index == -7)
	assert((long_shell.get_node("BackProps") as Sprite2D).z_index == -2)
	assert((long_shell.get_node("FrontProps") as Sprite2D).z_index == 37)
	assert((long_shell.get_node("ForegroundWall") as Sprite2D).z_index == 38)
	assert(not modular.wall_base_tiles.visible)
	assert(not modular.side_wall_tiles.visible)
	assert(not modular.foreground_walls.visible)
	assert(not modular.has_node("FloorDetails/MedicalGuideLine"))
	assert(not modular.has_node("FloorDetails/MedicalGuideGlow"))
	assert(room.camera_bounds == Rect2(0, 0, 2048, 1024))
	assert(camera.limit_left == 64 and camera.limit_top == 64)
	assert(camera.limit_right == 1984 and camera.limit_bottom == 960)
	var west_camera := room.guided_camera_world_point(Vector2(320, 520))
	var east_camera := room.guided_camera_world_point(Vector2(1728, 520))
	assert(east_camera.x > west_camera.x)
	assert(is_equal_approx(east_camera.y, west_camera.y))
	assert(room.contains_world_point(Vector2(760, 500)))
	assert(room.contains_world_point(Vector2(1260, 500)))
	assert(not room.contains_world_point(Vector2(390, 260)))
	assert(not room.contains_world_point(Vector2(1010, 500)))
	for door in instance.exit_doors:
		assert(door.get_node("LeftLeaf") is Sprite2D)
		assert(door.get_node("RightLeaf") is Sprite2D)
		assert((door.get_node("LeftLeaf") as Sprite2D).texture is AtlasTexture)
		assert((door.get_node("RightLeaf") as Sprite2D).texture is AtlasTexture)

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

	# The fourth room is a fully themed 16x10 Boss arena with a unique authored
	# floor, split wall shell, obstacle navigation, sealed doors, and reward hook.
	instance._show_room_variant(3)
	await process_frame
	await process_frame
	assert(room.room_id == &"hospital_boss_containment_arena")
	assert(room.room_kind == "boss")
	assert(room.size_class == MapRoomModule.RoomSizeClass.BOSS)
	assert(room.is_multi_screen())
	assert(is_equal_approx(room.camera_overscan, 1.28))
	assert(room.camera_bounds == Rect2(0, 0, 2560, 1792))
	assert(room.walkable_outline.size() == 4)
	assert(room.blocked_outlines.size() == 4)
	assert(room.door_directions == PackedStringArray(["north", "south"]))
	assert(room.door_anchor_world(&"north") == Vector2(1280, 256))
	assert(room.door_anchor_world(&"south") == Vector2(1280, 1536))
	assert(modular.floor_tiles.get_used_cells().size() == 160)
	assert(modular.get_node("ContentSlots").get_child_count() == 10)
	assert(modular.get_node("ThemeProps").get_child_count() == 4)
	var boss_floor := modular.get_node("BossFloorMacro") as Sprite2D
	assert(boss_floor != null)
	assert(boss_floor.texture.get_size() == Vector2(2256, 1408))
	assert(boss_floor.position == Vector2(152, 192))
	assert(boss_floor.z_index == -24)
	var boss_shell := modular.get_node("BossWallShell") as Node2D
	assert(boss_shell != null and boss_shell.get_child_count() == 4)
	assert((boss_shell.get_node("BackWall") as Sprite2D).position == Vector2.ZERO)
	assert((boss_shell.get_node("WestWall") as Sprite2D).position == Vector2(0, 384))
	assert((boss_shell.get_node("EastWall") as Sprite2D).position == Vector2(2176, 384))
	assert((boss_shell.get_node("ForegroundWall") as Sprite2D).position == Vector2(0, 1408))
	assert((boss_shell.get_node("ForegroundWall") as Sprite2D).z_index == 38)
	assert(not modular.wall_base_tiles.visible)
	assert(not modular.side_wall_tiles.visible)
	assert(not modular.foreground_walls.visible)
	assert(not modular.has_node("FloorDetails/MedicalGuideLine"))
	assert(not modular.has_node("FloorDetails/MedicalGuideGlow"))
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
		assert(door._uses_containment_visuals())
		assert(door.rotation == 0.0)
		assert(not door.has_node("DoorRecessShadow"))
		assert(not door.has_node("DoorFrame"))
		assert(door.get_node("LeftLeaf") is Polygon2D)
		assert(door.get_node("RightLeaf") is Polygon2D)
		assert(door.get_node("LeftLeaf/ThemeStencil/WarningTriangle") is Line2D)
		assert(door.get_node("RightLeaf/ThemeStencil/WarningTriangle") is Line2D)
		assert((door.get_node("DoorOpening") as Polygon2D).position == Vector2.ZERO)
		assert((door.get_node("LeftLeaf") as Polygon2D).position == Vector2(-49, 0))
		assert((door.get_node("RightLeaf") as Polygon2D).position == Vector2(49, 0))
		if door.direction == &"south":
			assert(door.z_index > (boss_shell.get_node("ForegroundWall") as Sprite2D).z_index)
	assert(camera.zoom.x >= 0.84)
	assert(instance.boss_warning_play_count == 1)
	assert(instance.boss_warning_overlay.visible)
	assert(instance.boss_warning_icon is Control)
	assert(instance.boss_warning_icon.get_node("WarningTriangle") is Line2D)
	assert(instance.boss_warning_icon.get_node("WarningBar") is ColorRect)
	var warning_title := instance.boss_warning_overlay.get_node(
		"WarningBanner/WarningCopy/WarningTitle",
	) as Label
	assert(warning_title.text == MapStyleDemo.BOSS_WARNING_TITLE)
	instance._stop_boss_warning()
	assert(not instance.boss_warning_overlay.visible)
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
		"Map style demo passed: modular samples plus the themed Boss arena retain "
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
