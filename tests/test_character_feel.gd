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
	assert(rendered.ground_offset == Vector2(0.0, -12.0))
	assert(rendered_sprite.position == Vector2(0.0, -12.0))
	assert(rendered_sprite.sprite_frames.get_animation_names().size() == 20)
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
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/ModeButtons") == null)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Close") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Mid") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Long") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SkillButtons/Release") is Button)
	var mobile_controls := instance.get_node("HUD/MobileControls") as MobileControls
	assert(mobile_controls != null)
	assert(mobile_controls.is_in_group("mobile_controls"))
	assert(instance.get_node("HUD/TouchTestButtons/Hit") is Button)
	assert(instance.get_node("HUD/TouchTestButtons/Death") is Button)
	assert(instance.get_node("HUD/TouchTestButtons/Reset") is Button)

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
	assert(not skill_demo.trigger_target_at_world_position(player.global_position + Vector2.UP * 90.0))
	var long_target := (
		player.global_position
		+ Vector2.RIGHT * float(
			SkillRangeDemo.SKILLS[SkillRangeDemo.SkillMode.LONG_RIFT].range
		)
	)
	assert(skill_demo.trigger_target_at_world_position(long_target))
	assert(skill_demo.current_skill_mode() == SkillRangeDemo.SkillMode.LONG_RIFT)
	assert(skill_demo.current_phase() == "windup")
	assert(skill_demo.cast_endpoint().distance_to(long_target) < 0.1)
	assert(player.facing.is_equal_approx(Vector2.RIGHT))
	skill_demo._phase = "idle"
	skill_demo._cooldown_left = 0.0
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
