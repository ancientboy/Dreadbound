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
	var trial_sprite := trial.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var base_sprite := (
		player.get_node("RenderedAtlasCharacter/AnimatedSprite2D") as AnimatedSprite2D
	)
	assert(trial != null and trial.is_trial_enabled())
	assert(trial_sprite != null and trial_sprite.visible)
	assert(base_sprite != null and not base_sprite.visible)
	assert(trial_sprite.position == Vector2(0.0, -12.0))
	assert(trial_sprite.sprite_frames.get_animation_names().size() == 4)
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

	trial.set_trial_enabled(false)
	await process_frame
	assert(not trial_sprite.visible)
	assert(base_sprite.visible)
	print("Martial artist trial passed: down/left idle+walk and mobile-safe atlases")
	quit()
