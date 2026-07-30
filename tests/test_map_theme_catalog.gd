extends SceneTree


func _init() -> void:
	var rooms := MapThemeCatalog.hospital_rooms()
	assert(rooms.size() == 6)
	assert(MapThemeCatalog.is_theme_locked(rooms))
	assert(MapThemeCatalog.rooms_for_theme(MapThemeCatalog.HOSPITAL_THEME).size() == 6)

	var kinds := {}
	var textures := {}
	for room in rooms:
		assert(room["theme_id"] == MapThemeCatalog.HOSPITAL_THEME)
		assert(room["walkable_outline"].size() >= 8)
		assert(room["camera_guide_outline"].size() >= 8)
		assert(not room["zones"].is_empty())
		assert(ResourceLoader.exists(room["texture_path"]))
		assert(not room["door_directions"].is_empty())
		var room_module := MapRoomModule.new()
		room_module.walkable_outline = room["walkable_outline"]
		for direction_value in room["door_directions"]:
			assert(MapRoomDoor.VALID_DIRECTIONS.has(direction_value))
			assert(MapRoomDoor.opposite_direction(StringName(direction_value)) != &"")
			assert(room_module.door_anchor_world(StringName(direction_value)).is_finite())
		room_module.free()
		kinds[room["room_kind"]] = true
		textures[room["texture_path"]] = true

	assert(kinds.has("combat"))
	assert(kinds.has("elite"))
	assert(kinds.has("ambush"))
	assert(kinds.has("boss"))
	assert(textures.size() == rooms.size())
	var ring := rooms[4]
	assert(ring["blocked_outlines"].size() == 1)
	print("Map theme catalog passed: six hospital rooms have live compatible door anchors")
	quit()
