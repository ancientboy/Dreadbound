extends SceneTree


func _init() -> void:
	var rooms := MapThemeCatalog.hospital_rooms()
	assert(rooms.size() == 6)
	assert(MapThemeCatalog.is_theme_locked(rooms))
	assert(MapThemeCatalog.rooms_for_theme(MapThemeCatalog.HOSPITAL_THEME).size() == 6)

	var kinds := {}
	for index in rooms.size():
		var room: Dictionary = rooms[index]
		assert(room["theme_id"] == MapThemeCatalog.HOSPITAL_THEME)
		assert(room["camera_guide_outline"].size() >= 4)
		assert(not room["zones"].is_empty())
		assert(ResourceLoader.exists(room["texture_path"]))
		var room_module := MapRoomModule.new()
		var directions := PackedStringArray()
		if room.has("grid_cells"):
			assert(index < 3)
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
		else:
			assert(room["walkable_outline"].size() >= 4)
			assert(not room["door_directions"].is_empty())
			room_module.apply_legacy_spec(room)
			directions = room["door_directions"]
		for direction_value in directions:
			assert(MapRoomDoor.VALID_DIRECTIONS.has(direction_value))
			assert(MapRoomDoor.opposite_direction(StringName(direction_value)) != &"")
			assert(room_module.door_anchor_world(StringName(direction_value)).is_finite())
		room_module.free()
		kinds[room["room_kind"]] = true

	assert(kinds.has("combat"))
	assert(kinds.has("elite"))
	assert(kinds.has("ambush"))
	assert(kinds.has("boss"))
	for asset_path in [
		"res://assets/art/worlds/map_demo/sample_room_v2/hospital_standard_shell_v2.jpg",
		"res://assets/art/worlds/map_demo/sample_room_v2/hospital_standard_foreground_v2.webp",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/frame.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_left.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_right.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/indicator_locked.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/indicator_open.png",
		"res://assets/art/worlds/map_demo/sample_room_v2/doors/threshold.png",
		"res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png",
		"res://assets/art/worlds/map_demo/hospital_tiles_v8/wall_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/floor_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/wall_atlas.svg",
		"res://assets/art/worlds/map_demo/dungeon1_hospital/prop_atlas.svg",
		"res://resources/map_themes/dungeon1_hospital.tres",
	]:
		assert(ResourceLoader.exists(asset_path))
	var ring := rooms[4]
	assert(ring["blocked_outlines"].size() == 1)
	assert(rooms[0]["grid_cells"].size() == 40)
	assert(rooms[1]["grid_cells"].size() == 60)
	assert(rooms[2]["grid_cells"].size() == 45)
	print("Map theme catalog passed: three grid specs and three legacy rooms share one catalog")
	quit()
