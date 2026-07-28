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
	var trial := player.get_node("MartialArtistTrialCharacter") as MartialArtistTrialCharacter
	assert(trial != null and trial.is_trial_enabled())
	assert(player.equipped_weapon_item.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	assert(player.get_node_or_null("UniversalHumanoidActionCharacter") == null)
	assert(trial.get_node_or_null("MainHandEquipment") == null)
	assert(trial.get_node_or_null("OffHandEquipment") == null)
	var trial_sprite := trial.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(trial_sprite.sprite_frames.get_animation_names().size() == 9)

	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await process_frame
	assert(trial_sprite.animation == &"idle_front")
	player.velocity = Vector2.RIGHT * player.movement_speed
	await process_frame
	assert(trial_sprite.animation == &"walk_front")
	player.velocity = Vector2.ZERO
	player._attack_flash = 0.14
	await process_frame
	assert(trial_sprite.animation == &"attack_front")

	print("Character demo passed: isolated v11 martial-artist visual baseline")
	quit()
