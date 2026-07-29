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
	var background := instance.get_node("MapBackground") as Sprite2D
	var left_room := instance.get_node("Rooms/LeftRoom") as MapRoomModule
	var right_room := instance.get_node("Rooms/RightRoom") as MapRoomModule
	var gate_shape := instance.get_node(
		"WorldCollision/CentralGate/CollisionShape2D",
	) as CollisionShape2D

	assert(player != null)
	assert(not player.use_runtime_progress)
	assert(player.demo_weapon_slots == ["service_crowbar", "balanced_pistol", "echo_staff"])
	assert(player.weapon_vfx is DemoWeaponVFX)
	assert(rendered != null and not rendered.runtime_sync_enabled)
	assert(background.texture != null)
	assert(background.texture.get_size() == Vector2(1672, 941))
	assert(background.scale == Vector2(2, 2))
	assert(MapStyleDemo.MAP_SIZE == Vector2(3344, 1882))
	assert(camera.zoom == Vector2(1.24, 1.24))
	assert(camera.limit_right == 1652)
	assert(camera.limit_bottom == 1882)
	assert(camera.position_smoothing_enabled)
	assert(left_room != null and left_room.room_id == &"left")
	assert(right_room != null and right_room.room_id == &"right")
	assert(left_room.room_kind == "combat")
	assert(right_room.room_kind == "elite")
	assert(left_room.walkable_outline.size() >= 24)
	assert(right_room.walkable_outline.size() >= 32)
	assert(left_room.door_directions == PackedStringArray(["east"]))
	assert(right_room.door_directions == PackedStringArray(["west", "north", "south"]))
	assert(left_room.get_spawn_points(&"EnemySpawns").size() == 3)
	assert(right_room.get_spawn_points(&"EnemySpawns").size() == 2)
	assert(left_room.get_obstacles().size() == 4)
	assert(right_room.get_obstacles().size() == 5)
	assert(not gate_shape.disabled)
	assert(get_nodes_in_group(MapStyleDemo.LEFT_ENCOUNTER).size() == 3)
	assert(instance.get_node("Triggers/EliteRoom") is Area2D)
	assert(instance.get_node("Triggers/LeftRoom") is Area2D)
	assert(instance.get_node("Triggers/UpperBranch") is Area2D)
	assert(instance.get_node("Triggers/LowerBranch") is Area2D)
	assert(instance.get_node("Foreground/FadeZones/LowerLeftWallFade") is Area2D)
	assert(instance.get_node("Foreground/FadeZones/LowerRightWallFade") is Area2D)

	var polygon_collision_found := false
	var room_boundary_segments := 0
	for body in instance.get_node("WorldCollision").get_children():
		if not body is StaticBody2D:
			continue
		if body.has_meta(&"room_boundary"):
			room_boundary_segments += 1
		for collision_child in body.get_children():
			if collision_child is CollisionPolygon2D:
				polygon_collision_found = true
				break
		if polygon_collision_found and room_boundary_segments >= 50:
			break
	assert(polygon_collision_found)
	assert(room_boundary_segments >= 50)

	for obstacle in get_nodes_in_group(&"map_room_obstacles"):
		assert(obstacle is MapRoomObstacle)
		assert(obstacle.get_node("FootprintCollision") is CollisionPolygon2D)
		assert(obstacle.placement_role in ["wall", "combat"])

	# The floor constraint is the final guarantee against painted black void.
	player.global_position = Vector2(300, 100)
	instance._physics_process(0.0)
	assert(left_room.contains_world_point(player.global_position))
	assert(player.global_position.y > 200.0)

	for enemy in get_nodes_in_group(MapStyleDemo.LEFT_ENCOUNTER):
		enemy.queue_free()
	await process_frame
	await process_frame
	assert(gate_shape.disabled)
	assert(not instance.get_node("Foreground/CentralGateVisual").visible)
	assert("中央连廊已开启" in instance.objective_label.text)

	instance._on_elite_room_entered(player)
	assert(instance._current_room == &"right")
	assert(camera.limit_left == 1652)
	assert(camera.limit_right == 3344)
	assert(get_nodes_in_group(MapStyleDemo.ELITE_ENCOUNTER).size() == 2)

	instance._on_left_room_entered(player)
	assert(instance._current_room == &"left")
	assert(camera.limit_left == 0)
	assert(camera.limit_right == 1652)

	instance.queue_free()
	print(
		"Map style demo v3 passed: room modules, exact floor constraints, "
		+ "independent obstacles, room camera and branch exits",
	)
	quit()
