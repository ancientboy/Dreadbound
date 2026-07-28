extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var config = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://character_pipeline/humanoid_action_library.json",
		),
	)
	var tracks = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/humanoid_action_tracks.json"),
	)
	assert(config is Dictionary and tracks is Dictionary)
	assert(config.reuse_actions.size() == 32)
	assert(config.authored_actions.size() == 5)
	assert(config.blender_calibrated_actions.size() == 4)
	assert(config.timing_policy == "preserve_source_keyframes")
	assert(tracks.action_count == 37)
	assert(tracks.skeleton_id == "humanoid_v1")
	var expected_frame_counts := {
		"idle": 76,
		"walk": 41,
		"walk_formal": 41,
		"jog": 29,
		"sprint": 21,
		"crouch_idle": 89,
		"crouch_walk": 61,
		"jump_start": 41,
		"jump_air": 76,
		"jump_land": 39,
		"roll": 45,
		"hit_chest": 11,
		"hit_head": 14,
		"death": 73,
		"interact": 61,
		"pickup": 26,
		"push": 81,
		"fix_kneeling": 157,
		"punch_jab": 27,
		"punch_cross": 31,
		"one_hand_melee_idle": 51,
		"one_hand_melee_attack": 47,
		"pistol_idle": 51,
		"pistol_aim_down": 6,
		"pistol_aim": 6,
		"pistol_aim_up": 6,
		"pistol_shoot": 20,
		"pistol_reload": 51,
		"spell_enter": 17,
		"spell_idle": 64,
		"spell_shoot": 16,
		"spell_exit": 14,
		"bow_idle": 51,
		"bow_draw": 17,
		"bow_release": 20,
		"shield_idle": 51,
		"shield_block": 39,
	}
	assert(expected_frame_counts.size() == tracks.action_count)
	for required_action in [
		"one_hand_melee_attack",
		"pistol_shoot",
		"spell_shoot",
		"bow_draw",
		"bow_release",
		"shield_block",
	]:
		assert(tracks.actions.has(required_action))
	for action_name in tracks.actions:
		var action: Dictionary = tracks.actions[action_name]
		assert(action.frame_count == expected_frame_counts[action_name])
		assert(is_equal_approx(float(action.fps), 30.0))
		assert(
			is_equal_approx(
				float(action.duration_seconds),
				float(action.frame_count - 1) / float(action.fps),
			)
		)
		assert(action.frames.size() == 4)
		for direction in tracks.directions:
			assert(action.frames[direction].size() == action.frame_count)
	for action_name in config.authored_actions:
		var timing_action: String = config.authored_actions[action_name].timing_action
		assert(tracks.actions[action_name].source == "Dreadbound_Blender")
		assert(tracks.actions[action_name].authoring_rig == "blender_weapon_rig_v1")
		assert(
			tracks.actions[action_name].reference_weapon
			== config.authored_actions[action_name].reference_weapon
		)
		assert(tracks.actions[action_name].timing_action == timing_action)
		assert(
			tracks.actions[action_name].frame_count
			== tracks.actions[timing_action].frame_count
		)
	for action_name in config.blender_calibrated_actions:
		var spec: Dictionary = config.blender_calibrated_actions[action_name]
		assert(tracks.actions[action_name].source == "Dreadbound_Blender")
		assert(tracks.actions[action_name].authoring_rig == "blender_weapon_rig_v1")
		assert(tracks.actions[action_name].reference_weapon == "standard_staff")
		assert(tracks.actions[action_name].frame_count == expected_frame_counts[action_name])

	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	assert(demo != null)
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var player := instance.get_node("Player") as Player
	var humanoid := (
		player.get_node("UniversalHumanoidActionCharacter")
		as UniversalHumanoidActionCharacter
	)
	var martial := (
		player.get_node("MartialArtistTrialCharacter") as MartialArtistTrialCharacter
	)
	assert(humanoid != null and not humanoid.is_action_library_enabled())
	assert(humanoid.action_count() == 37)
	humanoid.playback_fps = 1.0
	humanoid._attack_elapsed = 1.0 / 30.0 + 0.0001
	assert(
		humanoid._sample_action("pistol_shoot", "front")
		== tracks.actions.pistol_shoot.frames.front[1]
	)
	humanoid.playback_fps = 30.0
	assert(humanoid.current_skin_id() == "base_armorer")
	assert(martial.is_trial_enabled())
	var formal_sprite := martial.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(formal_sprite != null and formal_sprite.visible)
	player.facing = Vector2.DOWN
	player.velocity = Vector2.ZERO
	await process_frame
	assert(formal_sprite.animation == &"idle_front")
	assert(not formal_sprite.flip_h)
	player.facing = Vector2.LEFT
	await process_frame
	assert(formal_sprite.animation == &"idle_left")
	assert(not formal_sprite.flip_h)
	player.facing = Vector2.RIGHT
	await process_frame
	assert(formal_sprite.animation == &"idle_left")
	assert(formal_sprite.flip_h)
	player.facing = Vector2.UP
	await process_frame
	assert(formal_sprite.animation == &"idle_back")
	assert(not formal_sprite.flip_h)
	humanoid.set_action_library_enabled(true)
	await process_frame
	assert(humanoid.is_action_library_enabled())
	assert(not martial.is_trial_enabled())
	for part_name in [
		"Head",
		"Torso",
		"LeftUpperArm",
		"LeftForearm",
		"RightUpperArm",
		"RightForearm",
		"LeftThigh",
		"LeftShin",
		"RightThigh",
		"RightShin",
	]:
		var sprite := humanoid.get_node(part_name) as Sprite2D
		assert(sprite != null and sprite.visible and sprite.texture != null)

	var main_hand := humanoid.get_node("MainHandEquipment") as Sprite2D
	var off_hand := humanoid.get_node("OffHandEquipment") as Sprite2D
	assert(main_hand.texture != null and off_hand.texture != null)
	assert(humanoid.current_action_name() == "one_hand_melee_idle")
	assert(humanoid.set_preview_weapon_family("unarmed"))
	await process_frame
	assert(humanoid.current_action_name() == "idle")
	assert(main_hand.texture == null and off_hand.texture == null)
	humanoid.trigger_preview_attack()
	await process_frame
	assert(humanoid.current_action_name() == "punch_jab")

	assert(humanoid.set_preview_weapon_family("sword"))
	await process_frame
	assert(humanoid.current_action_name() == "one_hand_melee_idle")
	assert(main_hand.texture.resource_path.ends_with("action_reference_sword.png"))
	humanoid.trigger_preview_attack()
	await process_frame
	assert(humanoid.current_action_name() == "one_hand_melee_attack")

	assert(humanoid.set_preview_weapon_family("pistol"))
	await process_frame
	assert(humanoid.current_action_name() == "pistol_idle")
	assert((main_hand.texture as AtlasTexture).region.position.x == 32.0)
	humanoid.trigger_preview_attack()
	await process_frame
	assert(humanoid.current_action_name() == "pistol_shoot")

	assert(humanoid.set_preview_weapon_family("shield"))
	await process_frame
	assert(humanoid.current_action_name() == "shield_idle")
	assert(main_hand.texture == null)
	assert((off_hand.texture as AtlasTexture).region.position.x == 128.0)
	humanoid.trigger_preview_attack()
	await process_frame
	assert(humanoid.current_action_name() == "shield_block")
	humanoid.clear_preview_weapon_family()
	await process_frame
	player._attack_flash = 0.14
	await process_frame
	assert(humanoid.current_action_name() == "one_hand_melee_attack")

	player._attack_flash = 0.0
	player.select_demo_weapon_slot(1)
	await process_frame
	assert(player.equipped_weapon_item == "mourning_bow")
	assert(humanoid.current_action_name() == "bow_idle")
	player._attack_flash = 0.14
	await process_frame
	assert(humanoid.current_action_name() == "bow_release")
	assert((main_hand.texture as AtlasTexture).region.position.x == 0.0)

	player._attack_flash = 0.0
	await process_frame
	assert(humanoid.current_action_name() == "bow_release")
	player.select_demo_weapon_slot(2)
	await process_frame
	assert(humanoid.current_action_name() == "spell_idle")
	player._attack_flash = 0.14
	await process_frame
	assert(humanoid.current_action_name() == "spell_shoot")
	assert((main_hand.texture as AtlasTexture).region.position.x == 64.0)

	player.select_demo_offhand("field_codex")
	await process_frame
	assert((off_hand.texture as AtlasTexture).region.position.x == 192.0)
	var action_before_skin_swap := humanoid.current_action_name()
	assert(humanoid.set_skin("base_humanoid"))
	await process_frame
	assert(humanoid.current_skin_id() == "base_humanoid")
	assert(humanoid.current_action_name() == action_before_skin_swap)
	assert((humanoid.get_node("Torso") as Sprite2D).texture.resource_path.contains("base_humanoid"))
	assert(humanoid.set_skin("base_armorer"))
	await process_frame
	assert(humanoid.current_skin_id() == "base_armorer")
	assert((humanoid.get_node("Torso") as Sprite2D).texture.resource_path.contains("base_armorer"))

	var main_anchor := humanoid.equipment_anchor(&"main_hand")
	var off_anchor := humanoid.equipment_anchor(&"off_hand")
	assert(main_anchor.distance_to(off_anchor) > 1.0)
	humanoid.set_action_library_enabled(false)
	await process_frame
	assert(not humanoid.visible)
	assert(martial.is_trial_enabled())
	assert(formal_sprite.visible)
	print("Humanoid action library passed: formal model default plus 37 verified actions")
	quit()
