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
	assert(ProfessionSkeletonCharacter.BASE_RIG_IDS.size() == 4)
	assert(ProfessionSkeletonCharacter.PROFESSION_PROFILES.size() == 4)
	_assert_humanoid_skin_contract(
		ProfessionSkeletonCharacter.HUMANOID_BASE_SKIN_ID
	)
	_assert_standard_humanoid_alignment(
		ProfessionSkeletonCharacter.HUMANOID_BASE_SKIN_ID
	)
	_assert_standard_humanoid_alignment("base_armorer")
	_assert_demo_native_rig_contract()
	var state := root.get_node("GameState") as GameProgress
	var scene := load("res://scenes/entities/player.tscn") as PackedScene
	assert(scene != null)
	var tested_directions := 0
	var base_cases := {
		"base_drifter": ["", "drifter"],
		"base_steadfast": ["steadfast", "steadfast"],
		"base_armorer": ["armorer", "armorer"],
		"base_resonant": ["resonant", "resonant"],
	}
	for rig_id in base_cases:
		var base_case: Array = base_cases[rig_id]
		state.selected_pathway = str(base_case[0])
		state.active_combat_style = ""
		assert(ProfessionSkeletonCharacter.has_rig(rig_id))
		_assert_generic_asset_contract(rig_id)
		var base_player := scene.instantiate() as Player
		root.add_child(base_player)
		for frame in range(10):
			await process_frame
		var base_rig := (
			base_player.get_node("ProfessionSkeletonRig")
			as ProfessionSkeletonCharacter
		)
		assert(base_rig != null and base_rig.visible, "missing base rig: %s" % rig_id)
		assert(base_rig.current_rig_id() == rig_id)
		assert(base_rig.current_profession_id() == str(base_case[1]))
		assert(not base_player._body_sprite.visible)
		assert(base_rig.has_split_body_parts())
		assert(base_rig.uses_runtime_equipment_only())
		_assert_walk_cycle(base_player, base_rig, rig_id)
		if rig_id == "base_armorer":
			assert(ProfessionSkeletonCharacter.has_humanoid_skin("base_humanoid"))
			assert(ProfessionSkeletonCharacter.has_humanoid_skin("base_armorer"))
			base_rig.set_humanoid_skin_for_preview("base_humanoid")
			assert(base_rig.current_humanoid_skin_id() == "base_humanoid")
			assert(base_rig.has_split_body_parts())
			_assert_walk_cycle(base_player, base_rig, "base_humanoid")
			base_rig.set_humanoid_skin_for_preview("base_armorer")
			assert(base_rig.current_humanoid_skin_id() == "base_armorer")
		for facing in FACINGS:
			base_player.facing = facing
			await process_frame
			tested_directions += 1
			assert(
				base_rig.current_direction()
					== LayeredSkeletonCharacter.direction_from_facing(facing)
			)
		base_player.free()

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

	assert(tested_directions == 64)
	print(
		"Profession skeleton rigs passed: 4 base and 12 style split bodies, "
		+ "64 directions, "
		+ "three weapon IK modes and cast IK"
	)
	quit()


func _assert_demo_native_rig_contract() -> void:
	var demo_path := "res://scenes/test/character_feel_demo.tscn"
	var demo_source := FileAccess.get_file_as_string(demo_path)
	assert(not demo_source.is_empty())
	assert(
		demo_source.contains("res://scripts/character_feel_demo.gd")
	)
	assert(
		not demo_source.contains(
			"res://scenes/test/layered_skeleton_character.tscn"
		)
	)
	assert(demo_source.count("LayeredSkeletonRig") == 0)
	var demo_controller := FileAccess.get_file_as_string(
		"res://scripts/character_feel_demo.gd"
	)
	assert(demo_controller.contains("base_armorer"))
	assert(demo_controller.contains("HUMANOID_BASE_SKIN_ID"))


func _assert_generic_asset_contract(style_id: String) -> void:
	if style_id == "base_armorer":
		_assert_humanoid_skin_contract(style_id)
		return
	var style_root := "%s/%s" % [
		ProfessionSkeletonCharacter.RIG_ROOT,
		style_id,
	]
	assert(FileAccess.file_exists(
		ProfessionSkeletonCharacter._atlas_path_for(style_id)
	))
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


func _assert_humanoid_skin_contract(style_id: String) -> void:
	var required_parts := ProfessionSkeletonCharacter.HUMANOID_SKIN_PART_FILES.values()
	var skin_root := "%s/%s" % [
		ProfessionSkeletonCharacter.SKIN_ROOT,
		style_id,
	]
	assert(required_parts.size() == 12)
	for direction in LayeredSkeletonCharacter.DIRECTIONS:
		var root_path := "%s/%s" % [skin_root, direction]
		var manifest_path := "%s/rig.json" % root_path
		assert(FileAccess.file_exists(manifest_path))
		var manifest = JSON.parse_string(
			FileAccess.get_file_as_string(manifest_path)
		)
		assert(manifest is Dictionary)
		var authored_v2 := (
			style_id
			== ProfessionSkeletonCharacter.HUMANOID_BASE_SKIN_ID
		)
		assert(
			int(manifest.get("schema_version", 0))
			== (4 if authored_v2 else 3)
		)
		assert(
			str(manifest.get("source", ""))
			== (
				"authored_split_parts"
				if authored_v2
				else "standard_humanoid_skin"
			)
		)
		assert(
			str(manifest.get("skeleton_id", ""))
				== ProfessionSkeletonCharacter.HUMANOID_SKELETON_ID
		)
		var frame_size := manifest.frame_size as Array
		assert(frame_size.size() == 2)
		assert(is_equal_approx(float(frame_size[0]), 256.0))
		assert(is_equal_approx(float(frame_size[1]), 420.0))
		assert(is_equal_approx(float(manifest.center_x), 128.0))
		assert(is_equal_approx(float(manifest.baseline_y), 410.0))
		assert((manifest.parts as Dictionary).size() == 12)
		assert((manifest.rest_vectors as Dictionary).size() == 8)
		for part_file in required_parts:
			assert((manifest.parts as Dictionary).has(part_file))
			var part := (
				(manifest.parts as Dictionary)[part_file] as Dictionary
			)
			assert(part.has("pivot"))
			assert(part.has("size"))
			var file_path := "%s/%s" % [root_path, str(part.file)]
			assert(FileAccess.file_exists(file_path), file_path)
			var texture := load(file_path) as Texture2D
			assert(texture != null, file_path)
			if str(part_file) in ["coat_far", "coat_near"]:
				assert(
					texture.get_width() >= 1
					and texture.get_height() >= 1
				)
			else:
				assert(
					texture.get_width() > 8
					and texture.get_height() > 8
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
				not FileAccess.file_exists("%s/%s.webp" % [root_path, forbidden])
			)


func _assert_standard_humanoid_alignment(style_id: String) -> void:
	var skin_root := "%s/%s" % [
		ProfessionSkeletonCharacter.SKIN_ROOT,
		style_id,
	]
	var manifests := {}
	for direction in LayeredSkeletonCharacter.DIRECTIONS:
		var path := "%s/%s/rig.json" % [skin_root, direction]
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert(manifest is Dictionary)
		manifests[direction] = manifest
		var joints := manifest.joints as Dictionary
		for shared_y in [
			["head", 82.0],
			["hips", 230.0],
			["left_knee", 322.0 if direction != "right" else 324.0],
		]:
			assert(
				is_equal_approx(
					float((joints[str(shared_y[0])] as Array)[1]),
					float(shared_y[1]),
				),
				"%s %s %s" % [style_id, direction, shared_y[0]],
			)
		for vector_value in (manifest.rest_vectors as Dictionary).values():
			var vector := vector_value as Array
			assert(
				Vector2(float(vector[0]), float(vector[1])).length() > 60.0
			)
	var left_joints := (manifests.left as Dictionary).joints as Dictionary
	var right_joints := (manifests.right as Dictionary).joints as Dictionary
	for pair in [
		["left_shoulder", "right_shoulder"],
		["left_elbow", "right_elbow"],
		["left_hand", "right_hand"],
		["left_hip", "right_hip"],
		["left_knee", "right_knee"],
		["left_foot", "right_foot"],
		["right_shoulder", "left_shoulder"],
		["right_elbow", "left_elbow"],
		["right_hand", "left_hand"],
		["right_hip", "left_hip"],
		["right_knee", "left_knee"],
		["right_foot", "left_foot"],
	]:
		var left_point := left_joints[str(pair[0])] as Array
		var right_point := right_joints[str(pair[1])] as Array
		assert(
			is_equal_approx(
				float(left_point[0]) + float(right_point[0]),
				256.0,
			),
			"%s mirror x: %s" % [style_id, pair],
		)
		assert(
			is_equal_approx(float(left_point[1]), float(right_point[1])),
			"%s mirror y: %s" % [style_id, pair],
		)
	# Side-view bones must preserve authored x displacement. A vertical-only
	# implementation would make these values zero and recreate the old drift.
	var left_vectors := (
		(manifests.left as Dictionary).rest_vectors as Dictionary
	)
	assert(absf(float((left_vectors.left_upper_arm as Array)[0])) > 5.0)
	assert(absf(float((left_vectors.left_thigh as Array)[0])) > 5.0)


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
	var standard_humanoid := style_id in ["base_armorer", "base_humanoid"]
	var leg_threshold := 0.05 if standard_humanoid else 0.18
	var knee_threshold := 0.04 if standard_humanoid else 0.06
	assert(
		left_leg_range > leg_threshold,
		"left leg cycle too small: %s (%0.3f)" % [style_id, left_leg_range],
	)
	assert(
		right_leg_range > leg_threshold,
		"right leg cycle too small: %s (%0.3f)" % [style_id, right_leg_range],
	)
	assert(
		left_knee_range > knee_threshold,
		"left knee cycle missing: %s (%0.3f)" % [style_id, left_knee_range],
	)
	assert(
		right_knee_range > knee_threshold,
		"right knee cycle missing: %s (%0.3f)" % [style_id, right_knee_range],
	)
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
