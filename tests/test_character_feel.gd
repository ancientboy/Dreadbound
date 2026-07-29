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
	assert(player != null)
	assert(camera != null)
	assert(rendered != null)
	assert(player.get_node_or_null("ProfessionSkeletonRig") == null)
	assert(camera.position_smoothing_enabled)
	assert(player.movement_speed == 210.0)
	assert(player.attack_damage == 35)
	assert(player.demo_weapon_slots.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	assert(player.equipped_weapon_item.is_empty())
	assert(player.has_signal("footstep_requested"))
	assert(player._body_frame_ground_y.size() == 24)
	assert(not player._body_sprite.visible)

	var rendered_sprite := rendered.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var weapon_sprite := rendered.get_node("WeaponLayer") as AnimatedSprite2D
	assert(rendered_sprite != null)
	assert(weapon_sprite != null)
	assert(not weapon_sprite.visible)
	assert(rendered.ground_offset == Vector2(0.0, -12.0))
	assert(rendered_sprite.position == Vector2(0.0, -12.0))
	assert(rendered_sprite.sprite_frames.get_animation_names().size() == 64)
	var idle_frame_0 := (
		rendered_sprite.sprite_frames.get_frame_texture(&"idle_front", 0) as AtlasTexture
	)
	var idle_frame_18 := (
		rendered_sprite.sprite_frames.get_frame_texture(&"idle_front", 18) as AtlasTexture
	)
	assert(idle_frame_0 != null and idle_frame_18 != null)
	assert(idle_frame_0.atlas.get_size() == Vector2(2304, 256))
	assert(idle_frame_0.region == Rect2(0, 0, 128, 128))
	assert(idle_frame_18.region == Rect2(0, 128, 128, 128))
	for animation_name in rendered_sprite.sprite_frames.get_animation_names():
		for frame_index in rendered_sprite.sprite_frames.get_frame_count(animation_name):
			var frame_texture := (
				rendered_sprite.sprite_frames.get_frame_texture(
					animation_name,
					frame_index,
				) as AtlasTexture
			)
			assert(frame_texture != null)
			assert(frame_texture.atlas.get_width() <= 4096)
			assert(frame_texture.atlas.get_height() <= 4096)
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.DOWN) == &"front")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.UP) == &"back")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.LEFT) == &"left")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.RIGHT) == &"right")
	assert(RenderedAtlasCharacter.source_direction_for_logical(&"left") == &"right")
	assert(RenderedAtlasCharacter.source_direction_for_logical(&"right") == &"left")
	var walk_left_frame := (
		rendered_sprite.sprite_frames.get_frame_texture(&"walk_left", 0) as AtlasTexture
	)
	var walk_right_frame := (
		rendered_sprite.sprite_frames.get_frame_texture(&"walk_right", 0) as AtlasTexture
	)
	assert(
		walk_left_frame.atlas
		== load("res://assets/art/characters/rendered3d/base_drifter/walk_right.png")
	)
	assert(
		walk_right_frame.atlas
		== load("res://assets/art/characters/rendered3d/base_drifter/walk_left.png")
	)
	assert(instance.get_node_or_null("SkillRangeDemo") == null)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/Idle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/Attack") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/Idle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/AimDown") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/Aim") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/AimUp") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/Shoot") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/PistolButtons/Reload") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/StaffButtons/Enter") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/StaffButtons/Idle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/StaffButtons/Shoot") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/StaffButtons/Exit") is Button)
	var mobile_controls := instance.get_node("HUD/MobileControls") as MobileControls
	assert(mobile_controls != null)
	assert(mobile_controls.is_in_group("mobile_controls"))
	assert(mobile_controls.movement_only)
	var demo_attack_button := instance.get_node("HUD/DemoAttackButton") as Button
	assert(demo_attack_button != null)
	assert(demo_attack_button.text == "测试攻击")
	var panel := instance.get_node("HUD/Panel") as PanelContainer
	assert(
		panel.get_theme_font("font")
		== load("res://assets/fonts/DreadboundChineseFull.otf")
	)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Hit") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Death") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Reset") is Button)

	player.velocity = Vector2(player.movement_speed, 0.0)
	player.facing = Vector2.RIGHT
	await process_frame
	assert(rendered_sprite.animation == &"walk_right")
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.2
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_right")
	player._attack_flash = 0.0
	rendered.select_preview_family(&"pistol")
	await process_frame
	assert(rendered_sprite.animation == &"pistol_idle_right")
	demo_attack_button.pressed.emit()
	await process_frame
	assert(rendered_sprite.animation == &"pistol_shoot_right")
	assert(rendered.play_preview_action(&"one_hand_melee_idle"))
	await process_frame
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == rendered_sprite.animation)
	assert(weapon_sprite.frame == rendered_sprite.frame)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"one_hand_melee_idle_front") == 21)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"attack_melee_front") == 19)
	var sword_idle_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"one_hand_melee_idle_front",
			0,
		) as AtlasTexture
	)
	assert(sword_idle_frame != null)
	assert(
		sword_idle_frame.atlas.get_size()
		== Vector2(21 * 128, 128)
	)
	demo_attack_button.pressed.emit()
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_right")
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"attack_melee_right")
	assert(weapon_sprite.frame == rendered_sprite.frame)
	assert(rendered.play_preview_action(&"spell_idle"))
	await process_frame
	assert(not weapon_sprite.visible)
	demo_attack_button.pressed.emit()
	await process_frame
	assert(rendered_sprite.animation == &"spell_shoot_right")
	assert(rendered.play_preview_action(&"pistol_reload"))
	assert(rendered_sprite.animation == &"pistol_reload_right")
	assert(rendered.play_preview_action(&"spell_enter"))
	assert(rendered_sprite.animation == &"spell_enter_right")
	assert(rendered.play_preview_action(&"spell_idle"))
	assert(rendered_sprite.animation == &"spell_idle_right")
	assert(rendered_sprite.sprite_frames.get_frame_count(&"one_hand_melee_idle_front") == 21)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"pistol_idle_front") == 21)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"pistol_aim_front") == 3)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"pistol_shoot_front") == 8)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"pistol_reload_front") == 21)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"spell_enter_front") == 7)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"spell_idle_front") == 26)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"spell_shoot_front") == 7)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"spell_exit_front") == 6)
	camera.add_attack_shake(2.0)
	assert(camera._shake_time_left > 0.0)
	print("Character feel passed: isolated original sword, pistol, and staff actions")
	quit()
