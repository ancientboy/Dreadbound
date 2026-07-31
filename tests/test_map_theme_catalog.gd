extends SceneTree


func _texture_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	assert(texture != null)
	return texture.get_image()


func _init() -> void:
	var rooms := MapThemeCatalog.hospital_rooms()
	assert(rooms.size() == 4)
	assert(MapThemeCatalog.is_theme_locked(rooms))
	assert(MapThemeCatalog.rooms_for_theme(MapThemeCatalog.HOSPITAL_THEME).size() == 4)

	var kinds := {}
	for index in rooms.size():
		var room: Dictionary = rooms[index]
		assert(room["theme_id"] == MapThemeCatalog.HOSPITAL_THEME)
		assert(room["camera_guide_outline"].size() >= 4)
		assert(not room["zones"].is_empty())
		assert(room.has("grid_cells"))
		var room_module := MapRoomModule.new()
		var directions := PackedStringArray()
		assert(not room["grid_cells"].is_empty())
		assert(not room["door_sockets"].is_empty())
		assert(not room["content_slots"].is_empty())
		assert(room["theme_resource"] == MapThemeCatalog.HOSPITAL_THEME_RESOURCE)
		assert(room.has("door_profile"))
		assert(room["door_profile"].has("theme_mark"))
		assert(room["door_profile"].has("mark_color"))
		assert(ResourceLoader.exists(room["theme_resource"]))
		var builder := ModularHospitalRoom.new()
		builder.build_from_spec(room)
		assert(builder.walkable_outline.size() >= 4)
		assert(builder.map_bounds == room["map_bounds"])
		room_module.apply_built_spec(room, builder)
		directions = builder.door_directions()
		assert(room_module.get_node("NavigationRegion2D") is NavigationRegion2D)
		builder.free()
		for direction_value in directions:
			assert(MapRoomDoor.VALID_DIRECTIONS.has(direction_value))
			assert(MapRoomDoor.opposite_direction(StringName(direction_value)) != &"")
			assert(room_module.door_anchor_world(StringName(direction_value)).is_finite())
		room_module.free()
		kinds[room["room_kind"]] = true

	assert(kinds.has("combat"))
	assert(kinds.has("elite"))
	assert(kinds.has("boss"))
	for asset_path in [
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/frame.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_left.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_right.png",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/floor_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/wall_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/prop_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/standard_floor_macro_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/standard_wall_shell_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/boss_floor_macro_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/boss_wall_shell_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/standard_combat_floor_v1.png",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/standard_combat_wall_shell_v1.png",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/standard_combat_foreground_v1.png",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/standard_combat_props_v1.png",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/standard_combat_doors_v1.png",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/long_ward_floor_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/long_ward_wall_shell_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/long_ward_foreground_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/long_ward_props_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/long_ward_doors_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/l_elite_floor_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/l_elite_wall_shell_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/l_elite_foreground_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/l_elite_props_v1.webp",
		"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/l_elite_doors_v1.webp",
		"res://resources/map_themes/dungeon1_hospital.tres",
	]:
		assert(ResourceLoader.exists(asset_path))
	assert(rooms[0]["grid_cells"].size() == 40)
	assert(rooms[0]["hide_theme_props"])
	assert(rooms[0]["camera_zoom"] == Vector2(0.96, 0.96))
	assert(is_equal_approx(float(rooms[0]["camera_overscan"]), 1.08))
	assert(rooms[0]["camera_view_bounds"] == Rect2(64, 64, 1408, 896))
	assert(rooms[0]["camera_guide_outline"] == PackedVector2Array([
		Vector2(640, 480), Vector2(896, 480),
		Vector2(896, 672), Vector2(640, 672),
	]))
	assert(rooms[0]["blocked_outlines"].size() == 10)
	assert(rooms[0]["blocked_outlines"][0] == PackedVector2Array([
		Vector2(340, 326), Vector2(354, 312),
		Vector2(474, 312), Vector2(490, 328),
		Vector2(482, 382), Vector2(350, 382),
	]))
	assert(rooms[0]["blocked_outlines"][1] == PackedVector2Array([
		Vector2(511, 338), Vector2(531, 338),
		Vector2(538, 345), Vector2(538, 377),
		Vector2(531, 384), Vector2(511, 384),
		Vector2(504, 377), Vector2(504, 345),
	]))
	# The transparent corners and gaps inside the old coarse rectangles stay walkable.
	var standard_builder := ModularHospitalRoom.new()
	standard_builder.build_from_spec(rooms[0])
	var standard_module := MapRoomModule.new()
	standard_module.apply_built_spec(rooms[0], standard_builder)
	assert(standard_module.contains_world_point(Vector2(324, 286)))
	assert(standard_module.contains_world_point(Vector2(496, 350)))
	assert(not standard_module.contains_world_point(Vector2(400, 350)))
	standard_module.free()
	standard_builder.free()
	assert(rooms[0]["floor_macro"]["world_rect"] == Rect2(0, 32, 1536, 960))
	assert(rooms[0]["wall_shell"]["regions"].size() == 4)
	assert(rooms[0]["wall_shell"]["regions"][1]["world_rect"] == Rect2(256, 192, 1024, 400))
	assert(rooms[0]["wall_shell"]["regions"][2]["world_rect"] == Rect2(256, 752, 1024, 240))
	assert(rooms[0]["door_sockets"][0]["anchor"] == Vector2(256, 494))
	assert(rooms[0]["door_sockets"][1]["anchor"] == Vector2(1280, 494))
	assert(rooms[0]["door_profile"].has("art_texture_path"))
	assert(rooms[1]["grid_cells"].size() == 60)
	assert(rooms[1]["title"] == "长条病区")
	assert(rooms[1]["hide_theme_props"])
	assert(rooms[1]["camera_zoom"] == Vector2(0.92, 0.92))
	assert(is_equal_approx(float(rooms[1]["camera_overscan"]), 1.04))
	assert(rooms[1]["camera_view_bounds"] == Rect2(64, 64, 1920, 896))
	assert(rooms[1]["blocked_outlines"].size() == 11)
	assert(rooms[1]["door_sockets"][0]["anchor"] == Vector2(256, 512))
	assert(rooms[1]["door_sockets"][1]["anchor"] == Vector2(1792, 512))
	assert(rooms[1]["door_profile"].has("art_texture_path"))
	assert(rooms[1]["floor_macro"]["world_rect"] == Rect2(0, 0, 2048, 1024))
	assert(rooms[1]["wall_shell"]["regions"].size() == 4)
	assert(rooms[1]["content_slots"].size() == 5)
	assert(rooms[1]["zones"].size() == 2)
	var long_wall_image := _texture_image(
		MapThemeCatalog.SANATORIUM_LONG_WARD_WALL_SHELL
	)
	var long_props_image := _texture_image(
		MapThemeCatalog.SANATORIUM_LONG_WARD_PROPS
	)
	assert(long_wall_image.get_pixel(256, 512).a < 0.05)
	assert(long_wall_image.get_pixel(1792, 512).a < 0.05)
	for corridor_x in range(288, 1793, 128):
		assert(long_props_image.get_pixel(corridor_x, 512).a < 0.05)
	var long_builder := ModularHospitalRoom.new()
	long_builder.build_from_spec(rooms[1])
	var long_module := MapRoomModule.new()
	long_module.apply_built_spec(rooms[1], long_builder)
	assert(long_builder.get_node("LongWardFloorMacro") is Sprite2D)
	assert(long_builder.get_node("LongWardWallShell").get_child_count() == 4)
	assert(long_builder.blocked_outlines.size() == 11)
	assert(long_module.contains_world_point(Vector2(760, 500)))
	assert(not long_module.contains_world_point(Vector2(410, 310)))
	for corridor_x in range(288, 1793, 128):
		assert(long_module.contains_world_point(Vector2(corridor_x, 512)))
	long_module.free()
	long_builder.free()
	assert(rooms[2]["grid_cells"].size() == 66)
	assert(rooms[2]["title"] == "L 形精英收容区")
	assert(rooms[2]["map_bounds"] == Rect2(0, 0, 2048, 1536))
	assert(rooms[2]["camera_view_bounds"] == Rect2(64, 64, 1920, 1408))
	assert(rooms[2]["blocked_outlines"].size() == 7)
	assert(rooms[2]["door_sockets"][0]["anchor"] == Vector2(128, 405))
	assert(rooms[2]["door_sockets"][1]["direction"] == &"south")
	assert(rooms[2]["door_sockets"][1]["anchor"] == Vector2(1320, 1305))
	assert(rooms[2]["door_profile"].has("south_source_region"))
	assert(rooms[2]["floor_macro"]["world_rect"] == Rect2(0, 0, 2048, 1536))
	assert(rooms[2]["wall_shell"]["regions"].size() == 4)
	assert(rooms[2]["content_slots"].size() == 6)
	assert(rooms[2]["zones"].size() == 2)
	var elite_wall_image := _texture_image(
		MapThemeCatalog.SANATORIUM_L_ELITE_WALL_SHELL
	)
	var elite_props_image := _texture_image(
		MapThemeCatalog.SANATORIUM_L_ELITE_PROPS
	)
	assert(elite_wall_image.get_pixel(128, 405).a < 0.15)
	assert(elite_wall_image.get_pixel(1320, 1305).a < 0.05)
	assert(elite_props_image.get_pixel(128, 405).a < 0.05)
	assert(elite_props_image.get_pixel(1320, 1305).a < 0.05)
	var elite_builder := ModularHospitalRoom.new()
	elite_builder.build_from_spec(rooms[2])
	var elite_module := MapRoomModule.new()
	elite_module.apply_built_spec(rooms[2], elite_builder)
	assert(elite_builder.get_node("LEliteFloorMacro") is Sprite2D)
	assert(elite_builder.get_node("LEliteWallShell").get_child_count() == 4)
	assert(elite_builder.blocked_outlines.size() == 7)
	assert(elite_module.contains_world_point(Vector2(720, 380)))
	assert(elite_module.contains_world_point(Vector2(1380, 1180)))
	assert(not elite_module.contains_world_point(Vector2(500, 900)))
	for route_point in [
		Vector2(180, 405),
		Vector2(600, 405),
		Vector2(950, 405),
		Vector2(1120, 600),
		Vector2(1320, 1120),
		Vector2(1320, 1280),
	]:
		assert(elite_module.contains_world_point(route_point))
	elite_module.free()
	elite_builder.free()
	var boss_room: Dictionary = rooms[3]
	assert(boss_room["grid_cells"].size() == 160)
	assert(boss_room["obstacle_cells"].size() == 4)
	assert(boss_room["size_class"] == MapRoomModule.RoomSizeClass.BOSS)
	assert(boss_room["camera_zoom"] == Vector2(0.84, 0.84))
	assert(is_equal_approx(float(boss_room["camera_overscan"]), 1.28))
	assert(boss_room["door_profile"]["style"] == &"containment")
	assert(boss_room["door_profile"]["theme_mark"] == &"containment_warning")
	assert(boss_room["door_sockets"][0]["anchor"] == Vector2(1280, 256))
	assert(boss_room["door_sockets"][1]["anchor"] == Vector2(1280, 1536))
	assert(boss_room["map_bounds"] == Rect2(0, 0, 2560, 1792))
	assert(boss_room["art_contract"]["canvas_size"] == Vector2i(2560, 1792))
	assert(boss_room["art_contract"]["combat_rect"] == Rect2i(256, 256, 2048, 1280))
	assert(boss_room["floor_macro"]["world_rect"] == Rect2(152, 192, 2256, 1408))
	assert(boss_room["wall_shell"]["regions"].size() == 4)
	assert(ResourceLoader.exists(boss_room["boss"]["scene"]))
	assert(boss_room["boss"]["summon_slots"].size() == 4)
	var boss_builder := ModularHospitalRoom.new()
	boss_builder.build_from_spec(boss_room)
	assert(boss_builder.blocked_outlines.size() == 4)
	assert(boss_builder.content_slots.get_child_count() == 10)
	assert(boss_builder.get_node("BossFloorMacro") is Sprite2D)
	assert(boss_builder.get_node("BossWallShell").get_child_count() == 4)
	assert(not boss_builder.wall_base_tiles.visible)
	assert(not boss_builder.side_wall_tiles.visible)
	assert(not boss_builder.foreground_walls.visible)
	assert(
		boss_builder.content_slots.get_node("PillarNorthWest").get_meta(&"visual_id")
		== &"cover_a"
	)
	boss_builder.free()
	print("Map theme catalog passed: three authored sanatorium rooms plus the Boss layout")
	quit()
