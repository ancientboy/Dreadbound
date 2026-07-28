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
	assert(config.authored_actions.size() == 12)
	assert(tracks.action_count == 44)
	assert(tracks.skeleton_id == "humanoid_v1")
	for required_action in [
		"one_hand_melee_attack",
		"pistol_shoot",
		"spell_shoot",
		"bow_draw",
		"bow_release",
		"shield_block",
		"two_hand_firearm_shoot",
		"heavy_two_hand_attack",
	]:
		assert(tracks.actions.has(required_action))
	for action in tracks.actions.values():
		assert(action.frames.size() == 4)
		for direction in tracks.directions:
			assert(action.frames[direction].size() == 8)

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
	assert(humanoid != null and humanoid.is_action_library_enabled())
	assert(humanoid.action_count() == 44)
	assert(humanoid.current_skin_id() == "base_humanoid")
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
	assert(humanoid.set_skin("base_armorer"))
	await process_frame
	assert(humanoid.current_skin_id() == "base_armorer")
	assert(humanoid.current_action_name() == action_before_skin_swap)
	assert((humanoid.get_node("Torso") as Sprite2D).texture.resource_path.contains("base_armorer"))

	var main_anchor := humanoid.equipment_anchor(&"main_hand")
	var off_anchor := humanoid.equipment_anchor(&"off_hand")
	assert(main_anchor.distance_to(off_anchor) > 1.0)
	humanoid.set_action_library_enabled(false)
	await process_frame
	assert(not humanoid.visible)
	assert(martial.is_trial_enabled())
	print("Humanoid action library passed: 32 reused + 12 authored actions, skins and equipment")
	quit()
