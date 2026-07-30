extends SceneTree


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
		"res://resources/map_themes/dungeon1_hospital.tres",
	]:
		assert(ResourceLoader.exists(asset_path))
	assert(rooms[0]["grid_cells"].size() == 40)
	assert(rooms[1]["grid_cells"].size() == 60)
	assert(rooms[2]["grid_cells"].size() == 45)
	var boss_room: Dictionary = rooms[3]
	assert(boss_room["grid_cells"].size() == 160)
	assert(boss_room["obstacle_cells"].size() == 4)
	assert(boss_room["size_class"] == MapRoomModule.RoomSizeClass.BOSS)
	assert(boss_room["map_bounds"] == Rect2(0, 0, 2560, 1792))
	assert(boss_room["art_contract"]["canvas_size"] == Vector2i(2560, 1792))
	assert(boss_room["art_contract"]["combat_rect"] == Rect2i(256, 256, 2048, 1280))
	assert(ResourceLoader.exists(boss_room["boss"]["scene"]))
	assert(boss_room["boss"]["summon_slots"].size() == 4)
	var boss_builder := ModularHospitalRoom.new()
	boss_builder.build_from_spec(boss_room)
	assert(boss_builder.blocked_outlines.size() == 4)
	assert(boss_builder.content_slots.get_child_count() == 10)
	assert(
		boss_builder.content_slots.get_node("PillarNorthWest").get_meta(&"visual_id")
		== &"cover_a"
	)
	boss_builder.free()
	print("Map theme catalog passed: three modular rooms and one Boss graybox")
	quit()
