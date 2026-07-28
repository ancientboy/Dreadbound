extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	assert(demo != null)
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	var player := instance.get_node("Player") as Player
	var humanoid := player.get_node("UniversalHumanoidActionCharacter") as UniversalHumanoidActionCharacter
	assert(humanoid != null and humanoid.is_action_library_enabled())
	assert(humanoid.isolated_demo_mode)
	assert(player.equipped_weapon_item.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	assert(player.get_node_or_null("MartialArtistTrialCharacter") == null)
	assert((humanoid.get_node("MainHandEquipment") as Sprite2D).texture == null)
	assert((humanoid.get_node("OffHandEquipment") as Sprite2D).texture == null)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await process_frame
	assert(humanoid.current_action_name() == "idle")
	player.velocity = Vector2.RIGHT * player.movement_speed
	await process_frame
	assert(humanoid.current_action_name() == "walk")
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.14
	await process_frame
	assert(humanoid.current_action_name() == "punch_jab")

	print("Character demo passed: isolated empty-hand skeleton baseline")
	quit()
