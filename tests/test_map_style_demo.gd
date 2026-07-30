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
	var rendered := player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	var camera := player.get_node("Camera2D") as Camera2D
	var floor := instance.get_node("Floor") as Sprite2D
	var walls_back := instance.get_node("WallsBack") as Sprite2D
	var walls_front := instance.get_node("Foreground/WallsForeground") as Sprite2D
	var room := instance.get_node("Rooms/SampleRoom") as MapRoomModule

	assert(player != null and not player.use_runtime_progress)
	assert(player.demo_weapon_slots == ["service_crowbar", "balanced_pistol", "echo_staff"])
	assert(player.weapon_vfx is DemoWeaponVFX)
	assert(rendered != null and not rendered.runtime_sync_enabled)
	assert(floor.texture != null and floor.texture.get_size() == Vector2(1672, 941))
	assert(floor.scale == Vector2(2, 2))
	assert(walls_back.texture != null)
	assert(walls_front.texture != null)
	assert(walls_back.texture.resource_path != floor.texture.resource_path)
	assert(walls_front.texture.resource_path != floor.texture.resource_path)
	assert(MapStyleDemo.MAP_SIZE == Vector2(3344, 1882))
	assert(camera.zoom == Vector2(1.28, 1.28))
	assert(camera.limit_right == 3344 and camera.limit_bottom == 1882)
	assert(camera.position_smoothing_enabled)
	assert(room.room_id == &"sample" and room.room_kind == "combat")
	assert(room.walkable_outline.size() == 8)
	assert(room.door_directions == PackedStringArray(["west", "east"]))
	assert(room.get_spawn_points(&"EnemySpawns").size() == 4)
	assert(room.get_obstacles().size() == 8)
	assert(get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER).size() == 4)
	assert(instance.get_node("Foreground/FadeZone") is Area2D)

	var boundary_segments := 0
	for body in instance.get_node("WorldCollision").get_children():
		if body is StaticBody2D and body.has_meta(&"room_boundary"):
			boundary_segments += 1
	assert(boundary_segments == room.walkable_outline.size())

	var wall_roles := 0
	var combat_roles := 0
	var prop_paths := {}
	for obstacle in get_nodes_in_group(&"map_room_obstacles"):
		assert(obstacle is MapRoomObstacle)
		assert(obstacle.get_node("FootprintCollision") is CollisionPolygon2D)
		var sprite := obstacle.get_node("PropSprite") as Sprite2D
		assert(sprite != null and sprite.texture != null)
		assert(sprite.texture.resource_path.begins_with(
			"res://assets/art/worlds/map_demo/sample_room/props/",
		))
		prop_paths[sprite.texture.resource_path] = true
		if obstacle.placement_role == "wall":
			wall_roles += 1
			assert(not obstacle.wall_side.is_empty())
		elif obstacle.placement_role == "combat":
			combat_roles += 1
		else:
			assert(false)
	assert(prop_paths.size() == 8)
	assert(wall_roles == 6)
	assert(combat_roles == 2)

	player.global_position = Vector2(40, 40)
	instance._physics_process(0.0)
	assert(room.contains_world_point(player.global_position))
	assert(player.global_position.x > 150.0)
	assert(player.global_position.y > 300.0)

	for enemy in get_nodes_in_group(MapStyleDemo.SAMPLE_ENCOUNTER):
		enemy.queue_free()
	await process_frame
	await process_frame
	assert("样板房验证完成" in instance.objective_label.text)

	instance.queue_free()
	print(
		"Map style demo v3.5 passed: separate floor and wall layers, "
		+ "eight detailed props, logical placement, exact collisions and occlusion",
	)
	quit()
