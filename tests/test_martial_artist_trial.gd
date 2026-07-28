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
	var rendered := player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	var rendered_sprite := (
		player.get_node("RenderedAtlasCharacter/AnimatedSprite2D") as AnimatedSprite2D
	)
	assert(rendered != null)
	assert(rendered_sprite != null and rendered_sprite.visible)
	assert(player.get_node_or_null("MartialArtistTrialCharacter") == null)
	assert(player.get_node_or_null("UniversalHumanoidActionCharacter") == null)
	assert(instance.get_node_or_null("HUD/TouchTestButtons/Trial") == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/EquipmentButtons") == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/OffhandButtons") == null)
	assert(rendered_sprite.position == Vector2(0.0, -12.0))
	assert(rendered_sprite.sprite_frames.get_animation_names().size() == 64)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await process_frame
	assert(rendered_sprite.animation == &"idle_front")
	assert(not rendered_sprite.flip_h)

	player.facing = Vector2.LEFT
	player.velocity = Vector2.LEFT * player.movement_speed
	await process_frame
	assert(rendered_sprite.animation == &"walk_left")
	assert(not rendered_sprite.flip_h)

	player.facing = Vector2.RIGHT
	await process_frame
	assert(rendered_sprite.animation == &"walk_right")
	assert(not rendered_sprite.flip_h)

	player.facing = Vector2.UP
	player.velocity = Vector2.UP * player.movement_speed
	await process_frame
	assert(rendered_sprite.animation == &"walk_back")
	assert(not rendered_sprite.flip_h)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.14
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_front")

	player._attack_flash = 0.0
	await create_timer(0.3).timeout
	player.facing = Vector2.RIGHT
	player._attack_flash = 0.14
	await process_frame
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_right")

	player._attack_flash = 0.0
	player._hurt_flash = 0.18
	await process_frame
	assert(rendered_sprite.animation == &"hit_right")

	player._hurt_flash = 0.0
	player._dead = true
	await process_frame
	assert(rendered_sprite.animation == &"death_right")
	print("Martial artist trial isolation passed: 26e9f58 rendered-atlas baseline")
	quit()
