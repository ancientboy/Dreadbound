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
	var martial_artist := (
		player.get_node("MartialArtistTrialCharacter")
		as MartialArtistTrialCharacter
	)
	assert(player != null)
	assert(camera != null)
	assert(rendered != null)
	assert(martial_artist != null)
	assert(camera.position_smoothing_enabled)
	assert(player.movement_speed == 210.0)
	assert(player.has_signal("footstep_requested"))
	assert(player._body_frame_ground_y.size() == 24)
	assert(not player._body_sprite.visible)

	# The character lab is locked to the screenshot-approved v11 martial artist.
	# The inherited production atlas must remain hidden.
	var rendered_sprite := rendered.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(rendered_sprite != null and not rendered_sprite.visible)
	assert(martial_artist.visible)
	assert(martial_artist.is_trial_enabled())
	assert(player.demo_weapon_slots.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	assert(player.get_node_or_null("ProfessionSkeletonRig") == null)
	assert(player.get_node_or_null("UniversalHumanoidActionCharacter") == null)
	assert(martial_artist.get_node_or_null("MainHandEquipment") == null)
	assert(martial_artist.get_node_or_null("OffHandEquipment") == null)
	var trial_sprite := martial_artist.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(trial_sprite != null and trial_sprite.visible)
	assert(trial_sprite.position == Vector2(0.0, -12.0))
	assert(trial_sprite.sprite_frames.get_animation_names().size() == 9)

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
	assert(trial_sprite.animation == &"walk_left")
	assert(trial_sprite.flip_h)

	player.velocity = Vector2.ZERO
	player._attack_flash = 0.2
	await process_frame
	assert(trial_sprite.animation == &"attack_left")
	assert(trial_sprite.flip_h)

	camera.add_attack_shake(2.0)
	assert(camera._shake_time_left > 0.0)
	print("Character feel passed: isolated v11 martial-artist visual baseline")
	quit()
