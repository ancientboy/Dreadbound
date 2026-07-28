extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var accelerated := Player.smooth_movement_velocity(
		Vector2.ZERO,
		Vector2(210.0, 0.0),
		1850.0,
		2450.0,
		1.35,
		0.05,
	)
	assert(accelerated.x > 0.0 and accelerated.x < 210.0)
	var stopped := Player.smooth_movement_velocity(
		Vector2(80.0, 0.0),
		Vector2.ZERO,
		1850.0,
		2450.0,
		1.35,
		0.05,
	)
	assert(stopped == Vector2.ZERO)
	var normal_turn := Player.smooth_movement_velocity(
		Vector2(100.0, 0.0),
		Vector2(-210.0, 0.0),
		1850.0,
		2450.0,
		1.0,
		0.02,
	)
	var boosted_turn := Player.smooth_movement_velocity(
		Vector2(100.0, 0.0),
		Vector2(-210.0, 0.0),
		1850.0,
		2450.0,
		1.35,
		0.02,
	)
	assert(boosted_turn.x < normal_turn.x)
	assert(is_equal_approx(Player.grounded_sprite_y(61, 64, 1.0, 8.0), -21.0))
	assert(is_equal_approx(Player.grounded_sprite_y(242, 256, 0.55, 8.0), -54.7))

	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	assert(demo != null)
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	var player := instance.get_node("Player") as Player
	var camera := player.get_node("Camera2D") as PlayerFeelCamera
	var rendered := player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	var humanoid := (
		player.get_node("UniversalHumanoidActionCharacter")
		as UniversalHumanoidActionCharacter
	)
	assert(player != null)
	assert(camera != null)
	assert(rendered != null)
	assert(humanoid != null)
	assert(camera.position_smoothing_enabled)
	assert(player.movement_speed == 210.0)
	assert(player.has_signal("footstep_requested"))
	assert(player._body_frame_ground_y.size() == 24)
	assert(not player._body_sprite.visible)

	# The character lab is locked to the verified empty-hand skeleton. The
	# production atlas remains inherited from Player but must never be visible.
	assert(not rendered.visible)
	assert(humanoid.visible)
	assert(humanoid.is_action_library_enabled())
	assert(humanoid.isolated_demo_mode)
	assert(humanoid.current_skin_id() == "base_armorer")
	assert(humanoid.action_count() == 44)
	assert(humanoid.owns_equipment_visuals())
	assert(humanoid.current_action_name() == "idle")
	assert(player.demo_weapon_slots.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	assert(player.get_node_or_null("ProfessionSkeletonRig") == null)

	var main_hand := humanoid.get_node("MainHandEquipment") as Sprite2D
	var offhand := humanoid.get_node("OffHandEquipment") as Sprite2D
	assert(main_hand != null and offhand != null)
	assert(main_hand.texture == null and offhand.texture == null)
	assert(not main_hand.visible and not offhand.visible)
	assert((humanoid.get_node("Head") as Sprite2D).texture != null)
	assert((humanoid.get_node("Torso") as Sprite2D).texture != null)

	# No production inventory, equipment picker, weapon preview, or skill-range
	# controls are allowed back into this isolated model-and-animation test.
	assert(instance.get_node_or_null("SkillRangeDemo") == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/ModeButtons") == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/SkillButtons") == null)
	var mobile_controls := instance.get_node("HUD/MobileControls") as MobileControls
	assert(mobile_controls != null)
	assert(mobile_controls.is_in_group("mobile_controls"))
	assert((instance.get_node("HUD/TouchTestButtons/Trial") as Button).disabled)
	assert(instance.get_node("HUD/TouchTestButtons/Hit") is Button)
	assert(instance.get_node("HUD/TouchTestButtons/Death") is Button)
	assert(instance.get_node("HUD/TouchTestButtons/Reset") is Button)

	player.velocity = Vector2(player.movement_speed, 0.0)
	player.facing = Vector2.RIGHT
	await process_frame
	assert(humanoid.current_action_name() == "walk")

	player.velocity = Vector2.ZERO
	player._attack_flash = 0.2
	await process_frame
	assert(humanoid.current_action_name() == "punch_jab")
	assert(main_hand.texture == null and offhand.texture == null)

	player._attack_flash = 0.0
	player._hurt_flash = 0.2
	await process_frame
	assert(humanoid.current_action_name() == "hit_chest")

	player._hurt_flash = 0.0
	player._dead = true
	await process_frame
	assert(humanoid.current_action_name() == "death")

	camera.add_attack_shake(2.0)
	assert(camera._shake_time_left > 0.0)
	print("Character feel passed: isolated empty-hand skeleton and animation baseline")
	quit()
