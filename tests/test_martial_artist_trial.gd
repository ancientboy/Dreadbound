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
	var trial := (
		player.get_node("MartialArtistTrialCharacter") as MartialArtistTrialCharacter
	)
	var humanoid_actions := (
		player.get_node("UniversalHumanoidActionCharacter")
		as UniversalHumanoidActionCharacter
	)
	assert(humanoid_actions != null and humanoid_actions.is_action_library_enabled())
	humanoid_actions.set_action_library_enabled(false)
	await process_frame
	var trial_sprite := trial.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var main_hand := trial.get_node("MainHandEquipment") as Sprite2D
	var off_hand := trial.get_node("OffHandEquipment") as Sprite2D
	var base_sprite := (
		player.get_node("RenderedAtlasCharacter/AnimatedSprite2D") as AnimatedSprite2D
	)
	assert(trial != null and trial.is_trial_enabled())
	assert(trial_sprite != null and trial_sprite.visible)
	assert(main_hand != null and main_hand.visible)
	assert(off_hand != null and off_hand.visible)
	assert((main_hand.texture as AtlasTexture).atlas.resource_path.ends_with("basic_weapons.png"))
	assert((off_hand.texture as AtlasTexture).region.position.x == 128.0)
	assert(base_sprite != null and not base_sprite.visible)
	assert(trial_sprite.position == Vector2(0.0, -12.0))
	assert(trial_sprite.sprite_frames.get_animation_names().size() == 9)
	for animation_name in trial_sprite.sprite_frames.get_animation_names():
		assert(trial_sprite.sprite_frames.get_frame_count(animation_name) == 6)
		for frame_index in 6:
			var frame_texture := (
				trial_sprite.sprite_frames.get_frame_texture(
					animation_name,
					frame_index,
				) as AtlasTexture
			)
			assert(frame_texture != null)
			assert(frame_texture.atlas.get_size() == Vector2(768, 128))
			assert(frame_texture.atlas.get_width() <= 4096)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await process_frame
	assert(trial_sprite.animation == &"idle_front")
	assert(not trial_sprite.flip_h)

	player.facing = Vector2.LEFT
	player.velocity = Vector2.LEFT * player.movement_speed
	await process_frame
	assert(trial_sprite.animation == &"walk_left")
	assert(not trial_sprite.flip_h)

	player.facing = Vector2.RIGHT
	await process_frame
	assert(trial_sprite.animation == &"walk_left")
	assert(trial_sprite.flip_h)

	player.facing = Vector2.UP
	player.velocity = Vector2.UP * player.movement_speed
	await process_frame
	assert(trial_sprite.animation == &"walk_back")
	assert(not trial_sprite.flip_h)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.14
	await process_frame
	assert(trial_sprite.animation == &"idle_front")
	assert(trial._active_one_shot == &"weapon_attack")
	assert(trial_sprite.visible)
	assert(not base_sprite.visible)

	player._attack_flash = 0.0
	await create_timer(0.3).timeout
	player.facing = Vector2.RIGHT
	player._attack_flash = 0.14
	await process_frame
	await process_frame
	assert(trial_sprite.animation == &"idle_left")
	assert(trial._active_one_shot == &"weapon_attack")
	assert(trial_sprite.flip_h)
	assert(trial_sprite.visible)
	assert(not base_sprite.visible)

	player._attack_flash = 0.0
	await process_frame
	player.select_demo_weapon_slot(1)
	await process_frame
	assert(player.equipped_weapon_item == "mourning_bow")
	assert((main_hand.texture as AtlasTexture).atlas.resource_path.ends_with("equipment_runtime.png"))
	assert((main_hand.texture as AtlasTexture).region.position.x == 0.0)
	player.facing = Vector2.DOWN
	player._attack_flash = 0.11
	await process_frame
	assert(trial_sprite.animation == &"idle_front")
	assert(trial._active_one_shot == &"weapon_attack")

	player._attack_flash = 0.0
	await process_frame
	player.select_demo_weapon_slot(2)
	await process_frame
	assert(player.equipped_weapon_item == "echo_staff")
	assert((main_hand.texture as AtlasTexture).region.position.x == 64.0)
	var staff_rest_position := main_hand.position
	player._attack_flash = 0.11
	await process_frame
	assert(trial_sprite.animation == &"idle_front")
	assert(main_hand.position.y > staff_rest_position.y)

	player.select_demo_offhand("field_codex")
	await process_frame
	assert((off_hand.texture as AtlasTexture).region.position.x == 192.0)

	player._hurt_flash = 0.18
	await process_frame
	assert(trial_sprite.visible)
	assert(not base_sprite.visible)

	player._dead = true
	await process_frame
	assert(trial_sprite.visible)
	assert(not base_sprite.visible)

	trial.set_trial_enabled(false)
	await process_frame
	assert(not trial_sprite.visible)
	assert(base_sprite.visible)
	print("Martial artist trial passed: four-direction locomotion and clothed attacks")
	quit()
