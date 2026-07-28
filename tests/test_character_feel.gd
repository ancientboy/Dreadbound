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
	assert(player.attack_damage == 38)
	assert(player.has_signal("footstep_requested"))
	assert(player._body_frame_ground_y.size() == 24)
	assert(not player._body_sprite.visible)

	var rendered_sprite := rendered.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(rendered_sprite != null)
	assert(rendered_sprite.sprite_frames.get_animation_names().size() == 20)
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.DOWN) == &"front")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.UP) == &"back")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.LEFT) == &"left")
	assert(RenderedAtlasCharacter.direction_from_vector(Vector2.RIGHT) == &"right")
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/ModeButtons") == null)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Close") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Mid") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Long") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Release") is Button)

	player.velocity = Vector2(player.movement_speed, 0.0)
	player.facing = Vector2.RIGHT
	await process_frame
	assert(rendered_sprite.animation == &"walk_right")
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.2
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_right")

	var skill_demo := instance.get_node("SkillRangeDemo") as SkillRangeDemo
	assert(skill_demo != null)
	assert(skill_demo.uses_existing_skill_atlases())
	var previous_range := 0.0
	for mode in [
		SkillRangeDemo.SkillMode.CLOSE_BURST,
		SkillRangeDemo.SkillMode.MID_BOLT,
		SkillRangeDemo.SkillMode.LONG_RIFT,
	]:
		player.facing = Vector2.RIGHT
		skill_demo.set_skill_mode(mode)
		assert(skill_demo.skill_range() > previous_range)
		previous_range = skill_demo.skill_range()
		assert(skill_demo.trigger_skill())
		assert(skill_demo.current_phase() == "windup")
		assert(
			skill_demo.cast_endpoint().distance_to(player.global_position)
			>= skill_demo.skill_range() - 0.1
		)
		assert(skill_demo.uses_distinct_effect_anchors())
		skill_demo._phase = "active"
		skill_demo._phase_time = float(SkillRangeDemo.SKILLS[mode].active) * 0.96
		skill_demo._advance_phase()
		assert(skill_demo.target_hit_count(mode) == 1)
		skill_demo._phase = "idle"
		skill_demo._cooldown_left = 0.0
	camera.add_attack_shake(2.0)
	assert(camera._shake_time_left > 0.0)
	print("Character feel passed: production four-direction atlas and skill ranges")
	quit()
