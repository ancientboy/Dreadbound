extends SceneTree


const FACINGS := [
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	assert(ProfessionSkeletonCharacter.STYLE_IDS.size() == 12)
	assert(ProfessionSkeletonCharacter.PROFESSION_PROFILES.size() == 3)
	var state := root.get_node("GameState") as GameProgress
	var scene := load("res://scenes/entities/player.tscn") as PackedScene
	assert(scene != null)
	var tested_directions := 0
	for style_id in ProfessionSkeletonCharacter.STYLE_IDS:
		var definition: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
		state.selected_pathway = str(definition.path)
		state.active_combat_style = str(style_id)
		assert(ProfessionSkeletonCharacter.has_style_rig(style_id))
		if style_id != "sacrifice_medic":
			_assert_generic_asset_contract(style_id)

		var player := scene.instantiate() as Player
		root.add_child(player)
		# Formal IK deliberately blends in instead of snapping on spawn.
		for frame in range(10):
			await process_frame
		var rig := (
			player.get_node("ProfessionSkeletonRig")
			as ProfessionSkeletonCharacter
		)
		assert(rig != null and rig.visible, "missing formal rig: %s" % style_id)
		assert(not player._body_sprite.visible)
		assert(rig.current_profession_id() == str(definition.path))
		assert(rig.has_split_body_parts())
		assert(rig.uses_runtime_equipment_only())
		assert(rig.has_weapon_ik())
		rig.set_ik_demo_mode(rig.current_ik_demo_mode(), true)
		_assert_walk_cycle(player, rig, style_id)

		for facing in FACINGS:
			player.facing = facing
			await process_frame
			tested_directions += 1
			assert(
				rig.current_direction()
				== LayeredSkeletonCharacter.direction_from_facing(facing)
			)
			for equipment_case in [
				["service_crowbar", "melee"],
				["balanced_pistol", "ranged"],
				["breach_shotgun", "shotgun"],
			]:
				player.equipped_weapon_item = str(equipment_case[0])
				await process_frame
				assert(player._weapon_attack_type() == str(equipment_case[1]))
				_assert_weapon_hands(
					player,
					rig,
					str(equipment_case[1]),
					style_id,
				)
			player._skill_pose_timer = 0.24
			await process_frame
			assert(
				rig.current_ik_demo_mode()
				== LayeredSkeletonCharacter.IKDemoMode.CAST
			)
			assert(rig.ik_hand_error("organic") < 2.0)
			assert(rig.ik_hand_error("mech") < 2.0)
			player._skill_pose_timer = 0.0
			await process_frame
		player.free()

	assert(tested_directions == 48)
	print(
		"Profession skeleton rigs passed: 12 split bodies, 48 directions, "
		+ "three weapon IK modes and cast IK"
	)
	quit()


func _assert_generic_asset_contract(style_id: String) -> void:
	var style_root := "%s/%s" % [
		ProfessionSkeletonCharacter.RIG_ROOT,
		style_id,
	]
	assert(FileAccess.file_exists("%s/atlas.png" % style_root))
	for direction in LayeredSkeletonCharacter.DIRECTIONS:
		var root_path := "%s/%s" % [style_root, direction]
		assert(FileAccess.file_exists("%s/rig.json" % root_path))
		var manifest = JSON.parse_string(
			FileAccess.get_file_as_string("%s/rig.json" % root_path)
		)
		assert(manifest is Dictionary)
		assert(
			(manifest.parts as Dictionary).size()
			== ProfessionSkeletonCharacter.GENERIC_PART_FILES.size()
		)
		for part_file in ProfessionSkeletonCharacter.GENERIC_PART_FILES.values():
			assert((manifest.parts as Dictionary).has(part_file))
			assert(
				((manifest.parts as Dictionary)[part_file] as Dictionary).has(
					"region"
				)
			)
		for forbidden in [
			"weapon",
			"gun",
			"rifle",
			"shield",
			"lantern",
			"grenade",
			"backpack",
		]:
			assert(
				not FileAccess.file_exists("%s/%s.png" % [root_path, forbidden])
			)


func _assert_weapon_hands(
	player: Player,
	rig: ProfessionSkeletonCharacter,
	weapon_type: String,
	style_id: String,
) -> void:
	match weapon_type:
		"shotgun":
			assert(
				rig.current_ik_demo_mode()
				== LayeredSkeletonCharacter.IKDemoMode.RIFLE
			)
			assert(
				rig.ik_hand_error("organic") < 2.0,
				"%s organic=%s" % [style_id, rig.ik_hand_error("organic")],
			)
			assert(
				rig.ik_hand_error("mech") < 2.0,
				"%s mech=%s" % [style_id, rig.ik_hand_error("mech")],
			)
			assert(rig.has_forward_rifle_stance(), style_id)
		"ranged":
			assert(
				rig.current_ik_demo_mode()
				== LayeredSkeletonCharacter.IKDemoMode.PISTOL
			)
			assert(rig.ik_hand_error("organic") < 2.0, style_id)
		_:
			assert(player._weapon_attack_type() == "melee")
			assert(
				rig.current_ik_demo_mode()
				== LayeredSkeletonCharacter.IKDemoMode.MELEE
			)
			assert(rig.ik_hand_error("organic") < 2.0, style_id)


func _assert_walk_cycle(
	player: Player,
	rig: ProfessionSkeletonCharacter,
	style_id: String,
) -> void:
	player.set_physics_process(false)
	rig.set_process(false)
	player.facing = Vector2.RIGHT
	player.velocity = Vector2.RIGHT * player.movement_speed
	var signatures: Array[PackedFloat32Array] = []
	for phase in [0.0, 0.25, 0.5, 0.75]:
		player._step_phase = phase
		for frame in range(5):
			rig._process(1.0 / 30.0)
		signatures.append(rig.walk_pose_signature())
	assert(rig.is_using_true_opposition(), "walk opposition: %s" % style_id)
	var left_leg_range := _signature_range(signatures, 0)
	var right_leg_range := _signature_range(signatures, 1)
	var left_knee_range := _signature_range(signatures, 2)
	var right_knee_range := _signature_range(signatures, 3)
	var left_foot_x_range := _signature_range(signatures, 4)
	var right_foot_x_range := _signature_range(signatures, 6)
	assert(left_leg_range > 0.18, "left leg cycle too small: %s" % style_id)
	assert(right_leg_range > 0.18, "right leg cycle too small: %s" % style_id)
	assert(left_knee_range > 0.06, "left knee cycle missing: %s" % style_id)
	assert(right_knee_range > 0.06, "right knee cycle missing: %s" % style_id)
	assert(
		left_foot_x_range > 2.0,
		"left foot cycle too small: %s (%0.2f px)" % [
			style_id,
			left_foot_x_range,
		],
	)
	assert(
		right_foot_x_range > 2.0,
		"right foot cycle too small: %s (%0.2f px)" % [
			style_id,
			right_foot_x_range,
		],
	)
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	rig.set_process(true)


func _signature_range(
	signatures: Array[PackedFloat32Array],
	index: int,
) -> float:
	var minimum := INF
	var maximum := -INF
	for signature in signatures:
		minimum = minf(minimum, signature[index])
		maximum = maxf(maximum, signature[index])
	return maximum - minimum
