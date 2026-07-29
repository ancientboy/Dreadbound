extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var expected_families := {
		"service_crowbar": &"sword",
		"balanced_pistol": &"pistol",
		"breach_shotgun": &"pistol",
		"echo_edge": &"sword",
		"insulated_crowbar": &"sword",
		"nullpoint_sidearm": &"pistol",
		"siege_core": &"pistol",
		"volatile_edge": &"sword",
		"director_reaper": &"sword",
		"conductor_railgun": &"pistol",
		"mourning_bow": &"bow",
		"echo_staff": &"staff",
	}
	for item_id in expected_families:
		assert(
			EquipmentDatabase.weapon_animation_family(item_id) == expected_families[item_id],
			"Wrong animation family for %s" % item_id,
		)
	assert(
		str(EquipmentDatabase.offhand_presentation("riot_shield").animation_family) == "shield",
		"Riot shield must keep the shield action family",
	)
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
	var weapon_vfx := instance.get_node("DemoWeaponVFX") as DemoWeaponVFX
	var humanoid := player.get_node_or_null(
		"UniversalHumanoidActionCharacter"
	) as UniversalHumanoidActionCharacter
	assert(player != null)
	assert(camera != null)
	assert(rendered != null)
	assert(weapon_vfx != null)
	assert(humanoid == null)
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
	assert(weapon_vfx.active_effect_count() == 0)
	weapon_vfx.play_melee(player.global_position, Vector2.RIGHT, &"volatile_edge")
	assert(weapon_vfx.active_effect_count() == 1)
	assert(weapon_vfx.last_effect() == &"melee")
	assert(weapon_vfx.last_family() == &"volatile_edge")
	assert(weapon_vfx.last_direction() == Vector2.RIGHT)
	assert(weapon_vfx.melee_texture_id(&"volatile_edge") == &"anomaly_rift")
	assert(weapon_vfx.melee_texture_id(&"heavy_blade") == &"heavy_cleave")
	assert(weapon_vfx.melee_texture_id(&"director_reaper_final") == &"reaper_arc")
	assert(weapon_vfx.melee_layer_for_direction(Vector2.UP) < 0)
	assert(weapon_vfx.melee_layer_for_direction(Vector2.DOWN) > 0)
	weapon_vfx.play_melee(player.global_position, Vector2(-0.8, 0.1), &"echo_edge")
	assert(weapon_vfx.last_direction() == Vector2.LEFT)
	weapon_vfx.play_melee(player.global_position, Vector2(0.1, -0.9), &"crowbar")
	assert(weapon_vfx.last_direction() == Vector2.UP)
	weapon_vfx.play_melee(player.global_position, Vector2(0.1, 0.9), &"sword")
	assert(weapon_vfx.last_direction() == Vector2.DOWN)
	weapon_vfx._process(0.18)
	var visible_melee_layers := 0
	var has_back_layer := false
	var has_front_layer := false
	for child in weapon_vfx.get_children():
		var effect_sprite := child as Sprite2D
		if effect_sprite == null or not effect_sprite.visible:
			continue
		visible_melee_layers += 1
		has_back_layer = has_back_layer or effect_sprite.z_index < 0
		has_front_layer = has_front_layer or effect_sprite.z_index > 0
		assert(maxi(
			effect_sprite.texture.get_width(),
			effect_sprite.texture.get_height(),
		) <= 768)
	assert(visible_melee_layers >= 4)
	assert(has_back_layer)
	assert(has_front_layer)
	weapon_vfx.play_ballistic(
		player.global_position,
		Vector2.RIGHT,
		&"conductor_railgun_final",
	)
	assert(weapon_vfx.active_effect_count() == 5)
	assert(weapon_vfx.last_effect() == &"rail")
	weapon_vfx.play_arcane(player.global_position, Vector2.RIGHT, &"echo_staff")
	assert(weapon_vfx.active_effect_count() == 6)
	assert(weapon_vfx.last_effect() == &"arcane")
	weapon_vfx.play_bow(player.global_position, Vector2.RIGHT, &"mourning_bow")
	assert(weapon_vfx.active_effect_count() == 7)
	assert(weapon_vfx.last_effect() == &"bow")
	instance.get_node(
		"HUD/Panel/Margin/Text/SwordButtons/CrowbarAttack",
	).pressed.emit()
	assert(weapon_vfx.last_effect() == &"melee")
	var vfx_firearm_selector := instance.get_node(
		"HUD/Panel/Margin/Text/FirearmEquipment",
	) as OptionButton
	vfx_firearm_selector.select(2)
	vfx_firearm_selector.item_selected.emit(2)
	instance.get_node(
		"HUD/Panel/Margin/Text/PistolButtons/Shoot",
	).pressed.emit()
	assert(weapon_vfx.last_effect() == &"shotgun")
	instance.get_node(
		"HUD/Panel/Margin/Text/StaffButtons/Shoot",
	).pressed.emit()
	assert(weapon_vfx.last_effect() == &"arcane")
	instance.get_node(
		"HUD/Panel/Margin/Text/BowButtons/Release",
	).pressed.emit()
	assert(weapon_vfx.last_effect() == &"bow")
	rendered.select_preview_family(&"sword")

	var rendered_sprite := rendered.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var weapon_sprite := rendered.get_node("WeaponLayer") as AnimatedSprite2D
	var skin_selector := instance.get_node(
		"HUD/Panel/Margin/Text/SkinRow/SkinSelector"
	) as OptionButton
	assert(rendered_sprite != null)
	assert(weapon_sprite != null)
	assert(not weapon_sprite.visible)
	assert(skin_selector != null)
	assert(skin_selector.item_count == 4)
	assert(rendered.selected_skin() == &"base_drifter")
	assert(rendered_sprite.self_modulate == Color.WHITE)
	assert(rendered.ground_offset == Vector2(0.0, -12.0))
	assert(rendered_sprite.position == Vector2(0.0, -12.0))
	assert(rendered_sprite.sprite_frames.get_animation_names().size() == 96)
	var body_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/characters/rendered3d/base_drifter/manifest.json"
		)
	)
	var sword_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/standard_melee_sword/manifest.json"
		)
	)
	var crowbar_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/service_crowbar/manifest.json"
		)
	)
	var pistol_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/standard_service_pistol/manifest.json"
		)
	)
	var staff_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/standard_echo_staff/manifest.json"
		)
	)
	var bow_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/standard_hunter_bow/manifest.json"
		)
	)
	var shield_manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(
			"res://assets/art/weapons/character_layers/standard_guard_shield/manifest.json"
		)
	)
	assert(body_manifest["animations"]["attack_melee"]["frames"] == 19)
	assert(body_manifest["animations"]["attack_melee"]["facing_stabilized"])
	assert(sword_manifest["animations"]["attack_melee"]["frames"] == 19)
	assert(sword_manifest["animations"]["attack_melee"]["facing_stabilized"])
	assert(crowbar_manifest["weapon_id"] == "service_crowbar")
	assert(crowbar_manifest["motion_family"] == "sword")
	assert(crowbar_manifest["appearance_reference"].ends_with("#cell-0"))
	assert(crowbar_manifest["animations"]["one_hand_melee_idle"]["frames"] == 21)
	assert(crowbar_manifest["animations"]["attack_melee"]["frames"] == 19)
	assert(pistol_manifest["bone"] == "hand_r")
	assert(pistol_manifest["animations"]["pistol_idle"]["frames"] == 21)
	assert(pistol_manifest["animations"]["pistol_aim"]["frames"] == 3)
	assert(pistol_manifest["animations"]["pistol_shoot"]["frames"] == 8)
	assert(pistol_manifest["animations"]["pistol_reload"]["frames"] == 21)
	assert(staff_manifest["bone"] == "hand_r")
	assert(staff_manifest["animations"]["spell_enter"]["frames"] == 7)
	assert(staff_manifest["animations"]["spell_idle"]["frames"] == 26)
	assert(staff_manifest["animations"]["spell_shoot"]["frames"] == 7)
	assert(staff_manifest["animations"]["spell_exit"]["frames"] == 6)
	assert(bow_manifest["bone"] == "hand_l")
	assert(bow_manifest["animations"]["bow_idle"]["frames"] == 48)
	assert(bow_manifest["animations"]["bow_draw"]["frames"] == 41)
	assert(bow_manifest["animations"]["bow_aim"]["frames"] == 56)
	assert(bow_manifest["animations"]["bow_release"]["frames"] == 41)
	assert(shield_manifest["bone"] == "hand_l")
	assert(shield_manifest["animations"]["shield_raise"]["frames"] == 33)
	assert(shield_manifest["animations"]["shield_block"]["frames"] == 33)
	assert(shield_manifest["animations"]["shield_hit"]["frames"] == 33)
	assert(shield_manifest["animations"]["shield_bash"]["frames"] == 33)
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
	assert(
		RenderedAtlasCharacter.source_direction_for_animation(&"walk", &"left")
		== &"right"
	)
	for weapon_action in [
		&"attack_melee",
		&"one_hand_melee_idle",
		&"pistol_idle",
		&"pistol_aim_down",
		&"pistol_aim",
		&"pistol_aim_up",
		&"pistol_shoot",
		&"pistol_reload",
		&"spell_enter",
		&"spell_idle",
		&"spell_shoot",
		&"spell_exit",
		&"bow_idle",
		&"bow_draw",
		&"bow_aim",
		&"bow_release",
		&"shield_raise",
		&"shield_block",
		&"shield_hit",
		&"shield_bash",
	]:
		assert(
			RenderedAtlasCharacter.source_direction_for_animation(weapon_action, &"left")
			== &"left"
		)
		assert(
			RenderedAtlasCharacter.source_direction_for_animation(weapon_action, &"right")
			== &"right"
		)
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
	for weapon_action in [
		&"attack_melee",
		&"one_hand_melee_idle",
		&"pistol_idle",
		&"pistol_shoot",
		&"pistol_reload",
		&"spell_enter",
		&"spell_idle",
		&"spell_shoot",
		&"spell_exit",
		&"bow_idle",
		&"bow_draw",
		&"bow_aim",
		&"bow_release",
		&"shield_raise",
		&"shield_block",
		&"shield_hit",
		&"shield_bash",
	]:
		for side in [&"left", &"right"]:
			var animation_name := StringName("%s_%s" % [weapon_action, side])
			var action_frame := (
				rendered_sprite.sprite_frames.get_frame_texture(animation_name, 0)
				as AtlasTexture
			)
			assert(
				action_frame.atlas
				== load(
					"res://assets/art/characters/rendered3d/base_drifter/%s.png"
					% animation_name
				)
			)
	var sword_left_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"one_hand_melee_idle_left",
			0,
		) as AtlasTexture
	)
	var sword_right_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"one_hand_melee_idle_right",
			0,
		) as AtlasTexture
	)
	assert(
		sword_left_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_melee_sword/"
			+ "standard_sword_one_hand_melee_idle_left.png"
		)
	)
	assert(
		sword_right_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_melee_sword/"
			+ "standard_sword_one_hand_melee_idle_right.png"
		)
	)
	var pistol_left_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(&"pistol_idle_left", 0)
		as AtlasTexture
	)
	var pistol_right_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(&"pistol_idle_right", 0)
		as AtlasTexture
	)
	assert(
		pistol_left_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_service_pistol/"
			+ "standard_pistol_pistol_idle_left.png"
		)
	)
	assert(
		pistol_right_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_service_pistol/"
			+ "standard_pistol_pistol_idle_right.png"
		)
	)
	var staff_left_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(&"spell_idle_left", 0)
		as AtlasTexture
	)
	var staff_right_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(&"spell_idle_right", 0)
		as AtlasTexture
	)
	assert(
		staff_left_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_echo_staff/"
			+ "standard_staff_spell_idle_left.png"
		)
	)
	assert(
		staff_right_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/standard_echo_staff/"
			+ "standard_staff_spell_idle_right.png"
		)
	)
	assert(instance.get_node_or_null("SkillRangeDemo") == null)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/Idle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/Attack") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/CrowbarIdle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/SwordButtons/CrowbarAttack") is Button)
	var firearm_selector := (
		instance.get_node("HUD/Panel/Margin/Text/FirearmEquipment")
		as OptionButton
	)
	assert(firearm_selector.item_count == 8)
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
	assert(instance.get_node("HUD/Panel/Margin/Text/BowButtons/Idle") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BowButtons/Draw") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BowButtons/Aim") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BowButtons/Release") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/ShieldButtons/Raise") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/ShieldButtons/Block") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/ShieldButtons/Hit") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/ShieldButtons/Bash") is Button)
	var mobile_controls := instance.get_node("HUD/MobileControls") as MobileControls
	assert(mobile_controls != null)
	assert(mobile_controls.is_in_group("mobile_controls"))
	assert(mobile_controls.movement_only)
	var demo_attack_button := instance.get_node("HUD/DemoAttackButton") as Button
	assert(demo_attack_button != null)
	assert(demo_attack_button.text == "测试攻击")
	var panel := instance.get_node("HUD/Panel") as PanelContainer
	assert(panel.size.x <= 540.0)
	assert(panel.size.y <= 560.0)
	assert(
		panel.get_theme_font("font")
		== load("res://assets/fonts/DreadboundChineseFull.otf")
	)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Hit") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Death") is Button)
	assert(instance.get_node("HUD/Panel/Margin/Text/BaselineButtons/Reset") is Button)
	skin_selector.select(1)
	skin_selector.item_selected.emit(1)
	await process_frame
	assert(rendered.selected_skin() == &"armorer_demo_v1")
	assert(rendered_sprite.self_modulate == Color.WHITE)
	assert(rendered_sprite.visible)
	var armorer_frame := (
		rendered_sprite.sprite_frames.get_frame_texture(&"idle_front", 0)
		as AtlasTexture
	)
	assert(armorer_frame != null)
	assert(armorer_frame.atlas.resource_path.contains("/armorer_demo_v1/"))
	assert(weapon_sprite.self_modulate == Color.WHITE)
	for skin_test in [
		{
			"index": 2,
			"id": &"steadfast_demo_v1",
			"directory": "/steadfast_demo_v1/",
		},
		{
			"index": 3,
			"id": &"resonant_demo_v1",
			"directory": "/resonant_demo_v1/",
		},
	]:
		skin_selector.select(int(skin_test["index"]))
		skin_selector.item_selected.emit(int(skin_test["index"]))
		await process_frame
		assert(rendered.selected_skin() == skin_test["id"])
		var profession_frame := (
			rendered_sprite.sprite_frames.get_frame_texture(&"idle_front", 0)
			as AtlasTexture
		)
		assert(profession_frame != null)
		assert(
			profession_frame.atlas.resource_path.contains(
				str(skin_test["directory"])
			)
		)
	skin_selector.select(1)
	skin_selector.item_selected.emit(1)
	await process_frame
	assert(rendered.selected_skin() == &"armorer_demo_v1")

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
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"pistol_idle_right")
	assert(weapon_sprite.frame == rendered_sprite.frame)
	demo_attack_button.pressed.emit()
	await process_frame
	assert(rendered_sprite.animation == &"pistol_shoot_right")
	assert(rendered.selected_skin() == &"armorer_demo_v1")
	assert(rendered_sprite.self_modulate == Color.WHITE)
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"pistol_shoot_right")
	assert(weapon_sprite.frame == rendered_sprite.frame)
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
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"spell_idle_right")
	assert(weapon_sprite.frame == rendered_sprite.frame)
	demo_attack_button.pressed.emit()
	await process_frame
	assert(rendered_sprite.animation == &"spell_shoot_right")
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"spell_shoot_right")
	assert(weapon_sprite.frame == rendered_sprite.frame)
	assert(rendered.play_preview_action(&"pistol_reload"))
	await process_frame
	assert(rendered_sprite.animation == &"pistol_reload_right")
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"pistol_reload_right")
	assert(rendered.play_preview_action(&"spell_enter"))
	await process_frame
	assert(rendered_sprite.animation == &"spell_enter_right")
	assert(rendered.play_preview_action(&"spell_idle"))
	await process_frame
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
	assert(rendered_sprite.sprite_frames.get_frame_count(&"bow_idle_front") == 48)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"bow_draw_front") == 41)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"bow_aim_front") == 56)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"bow_release_front") == 41)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"shield_raise_front") == 33)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"shield_block_front") == 33)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"shield_hit_front") == 33)
	assert(rendered_sprite.sprite_frames.get_frame_count(&"shield_bash_front") == 33)
	assert(weapon_sprite.sprite_frames.get_animation_names().size() == 352)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"pistol_idle_front") == 21)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"pistol_aim_front") == 3)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"pistol_shoot_front") == 8)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"pistol_reload_front") == 21)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"spell_enter_front") == 7)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"spell_idle_front") == 26)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"spell_shoot_front") == 7)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"spell_exit_front") == 6)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"bow_idle_front") == 48)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"bow_draw_front") == 41)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"bow_aim_front") == 56)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"bow_release_front") == 41)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"shield_raise_front") == 33)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"shield_block_front") == 33)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"shield_hit_front") == 33)
	assert(weapon_sprite.sprite_frames.get_frame_count(&"shield_bash_front") == 33)
	for logical_name in [
		&"bow_idle",
		&"bow_draw",
		&"bow_aim",
		&"bow_release",
		&"shield_raise",
		&"shield_block",
		&"shield_hit",
		&"shield_bash",
	]:
		for direction in [&"front", &"left", &"back", &"right"]:
			var animation_name := StringName("%s_%s" % [logical_name, direction])
			for frame_index in rendered_sprite.sprite_frames.get_frame_count(animation_name):
				var body_frame := (
					rendered_sprite.sprite_frames.get_frame_texture(
						animation_name,
						frame_index,
					) as AtlasTexture
				)
				assert(
					not body_frame.get_image().is_invisible(),
					"Transparent character frame: %s[%d]" % [animation_name, frame_index],
				)
	rendered.select_preview_family(&"crowbar")
	assert(rendered.play_preview_action(&"one_hand_melee_idle"))
	await process_frame
	assert(rendered_sprite.animation == &"one_hand_melee_idle_right")
	assert(weapon_sprite.visible)
	assert(weapon_sprite.animation == &"crowbar__one_hand_melee_idle_right")
	var crowbar_idle_frame := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"crowbar__one_hand_melee_idle_right",
			0,
		) as AtlasTexture
	)
	assert(crowbar_idle_frame != null)
	assert(
		crowbar_idle_frame.atlas
		== load(
			"res://assets/art/weapons/character_layers/service_crowbar/"
			+ "service_crowbar_one_hand_melee_idle_right.png"
		)
	)
	assert(not crowbar_idle_frame.get_image().is_invisible())
	for crowbar_action in [&"one_hand_melee_idle", &"attack_melee"]:
		for direction in [&"front", &"left", &"back", &"right"]:
			var crowbar_animation := StringName(
				"crowbar__%s_%s" % [crowbar_action, direction]
			)
			assert(
				weapon_sprite.sprite_frames.get_frame_count(crowbar_animation)
				== int(RenderedAtlasCharacter.ANIMATION_FRAMES[crowbar_action])
			)
			for frame_index in weapon_sprite.sprite_frames.get_frame_count(
				crowbar_animation,
			):
				var crowbar_frame := (
					weapon_sprite.sprite_frames.get_frame_texture(
						crowbar_animation,
						frame_index,
					) as AtlasTexture
				)
				assert(crowbar_frame != null)
				assert(
					not crowbar_frame.get_image().is_invisible(),
					"Transparent crowbar frame: %s[%d]"
					% [crowbar_animation, frame_index],
				)
	assert(rendered.play_preview_action(&"attack_melee"))
	await process_frame
	assert(rendered_sprite.animation == &"attack_melee_right")
	assert(weapon_sprite.animation == &"crowbar__attack_melee_right")
	for melee_family in [
		&"echo_edge",
		&"insulated_crowbar",
		&"volatile_edge",
		&"director_reaper",
		&"director_reaper_awakened",
		&"director_reaper_final",
	]:
		rendered.select_preview_family(melee_family)
		assert(rendered.play_preview_action(&"one_hand_melee_idle"))
		await process_frame
		assert(
			weapon_sprite.animation
			== StringName("%s__one_hand_melee_idle_right" % melee_family)
		)
		for melee_action in [&"one_hand_melee_idle", &"attack_melee"]:
			for direction in [&"front", &"left", &"back", &"right"]:
				var melee_animation := StringName(
					"%s__%s_%s" % [melee_family, melee_action, direction]
				)
				assert(
					weapon_sprite.sprite_frames.get_frame_count(melee_animation)
					== int(RenderedAtlasCharacter.ANIMATION_FRAMES[melee_action])
				)
				for frame_index in weapon_sprite.sprite_frames.get_frame_count(
					melee_animation,
				):
					var melee_frame := (
						weapon_sprite.sprite_frames.get_frame_texture(
							melee_animation,
							frame_index,
						) as AtlasTexture
					)
					assert(melee_frame != null)
					assert(
						not melee_frame.get_image().is_invisible(),
						"Transparent melee frame: %s[%d]"
						% [melee_animation, frame_index],
					)
	var growth_base := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"director_reaper__one_hand_melee_idle_right",
			0,
		) as AtlasTexture
	)
	var growth_awakened := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"director_reaper_awakened__one_hand_melee_idle_right",
			0,
		) as AtlasTexture
	)
	var growth_final := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"director_reaper_final__one_hand_melee_idle_right",
			0,
		) as AtlasTexture
	)
	assert(growth_base.get_image().get_data() != growth_awakened.get_image().get_data())
	assert(growth_awakened.get_image().get_data() != growth_final.get_image().get_data())
	var firearm_actions := [
		&"pistol_idle",
		&"pistol_aim_down",
		&"pistol_aim",
		&"pistol_aim_up",
		&"pistol_shoot",
		&"pistol_reload",
	]
	for firearm_family in [
		&"balanced_pistol",
		&"breach_shotgun",
		&"nullpoint_sidearm",
		&"siege_core",
		&"conductor_railgun",
		&"conductor_railgun_awakened",
		&"conductor_railgun_final",
	]:
		rendered.select_preview_family(firearm_family)
		assert(rendered.play_preview_action(&"pistol_idle"))
		await process_frame
		assert(
			weapon_sprite.animation
			== StringName("%s__pistol_idle_right" % firearm_family)
		)
		for firearm_action in firearm_actions:
			for direction in [&"front", &"left", &"back", &"right"]:
				var firearm_animation := StringName(
					"%s__%s_%s"
					% [firearm_family, firearm_action, direction]
				)
				assert(
					weapon_sprite.sprite_frames.get_frame_count(
						firearm_animation,
					)
					== int(RenderedAtlasCharacter.ANIMATION_FRAMES[firearm_action])
				)
				for frame_index in weapon_sprite.sprite_frames.get_frame_count(
					firearm_animation,
				):
					var firearm_frame := (
						weapon_sprite.sprite_frames.get_frame_texture(
							firearm_animation,
							frame_index,
						) as AtlasTexture
					)
					assert(firearm_frame != null)
					assert(
						not firearm_frame.get_image().is_invisible(),
						"Transparent firearm frame: %s[%d]"
						% [firearm_animation, frame_index],
					)
	var railgun_base := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"conductor_railgun__pistol_idle_right",
			0,
		) as AtlasTexture
	)
	var railgun_awakened := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"conductor_railgun_awakened__pistol_idle_right",
			0,
		) as AtlasTexture
	)
	var railgun_final := (
		weapon_sprite.sprite_frames.get_frame_texture(
			&"conductor_railgun_final__pistol_idle_right",
			0,
		) as AtlasTexture
	)
	assert(
		railgun_base.get_image().get_data()
		!= railgun_awakened.get_image().get_data()
	)
	assert(
		railgun_awakened.get_image().get_data()
		!= railgun_final.get_image().get_data()
	)
	var remaining_equipment_actions := {
		&"mourning_bow": [&"bow_idle", &"bow_draw", &"bow_aim", &"bow_release"],
		&"echo_staff": [
			&"spell_enter",
			&"spell_idle",
			&"spell_shoot",
			&"spell_exit",
		],
		&"riot_shield": [
			&"shield_raise",
			&"shield_block",
			&"shield_hit",
			&"shield_bash",
		],
	}
	for equipment_family in remaining_equipment_actions:
		var equipment_actions: Array = remaining_equipment_actions[equipment_family]
		rendered.select_preview_family(equipment_family)
		for equipment_action in equipment_actions:
			assert(rendered.play_preview_action(equipment_action))
			await process_frame
			assert(
				weapon_sprite.animation
				== StringName(
					"%s__%s_right" % [equipment_family, equipment_action]
				)
			)
			for direction in [&"front", &"left", &"back", &"right"]:
				var equipment_animation := StringName(
					"%s__%s_%s"
					% [equipment_family, equipment_action, direction]
				)
				assert(
					weapon_sprite.sprite_frames.get_frame_count(
						equipment_animation,
					)
					== int(
						RenderedAtlasCharacter.ANIMATION_FRAMES[equipment_action]
					)
				)
				for frame_index in weapon_sprite.sprite_frames.get_frame_count(
					equipment_animation,
				):
					var equipment_frame := (
						weapon_sprite.sprite_frames.get_frame_texture(
							equipment_animation,
							frame_index,
						) as AtlasTexture
					)
					assert(equipment_frame != null)
					assert(
						not equipment_frame.get_image().is_invisible(),
						"Transparent remaining equipment frame: %s[%d]"
						% [equipment_animation, frame_index],
					)
	assert(
		not RenderedAtlasCharacter.WEAPON_LAYER_SPECS.has(&"field_codex"),
		"Off-hand codex presentation must stay disabled",
	)
	camera.add_attack_shake(2.0)
	assert(camera._shake_time_left > 0.0)
	assert(rendered.play_preview_action(&"bow_aim"))
	await process_frame
	assert(rendered_sprite.animation == &"bow_aim_right")
	assert(weapon_sprite.animation == &"bow_aim_right")
	assert(rendered.play_preview_action(&"bow_release"))
	await process_frame
	assert(rendered_sprite.animation == &"bow_release_right")
	assert(weapon_sprite.animation == &"bow_release_right")
	assert(rendered.play_preview_action(&"shield_block"))
	await process_frame
	assert(rendered_sprite.animation == &"shield_block_right")
	assert(weapon_sprite.animation == &"shield_block_right")
	assert(rendered.play_preview_action(&"shield_bash"))
	await process_frame
	assert(rendered_sprite.animation == &"shield_bash_right")
	assert(weapon_sprite.animation == &"shield_bash_right")
	print("Character feel passed: synchronized per-item melee, firearm, staff, bow, and shield layers")
	quit()
