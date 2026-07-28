class_name ProfessionSkeletonCharacter
extends LayeredSkeletonCharacter

const RIG_ROOT := "res://assets/art/characters/professions/rigs"
const SKIN_ROOT := "res://assets/art/characters/professions/skins"
const HUMANOID_BASE_SKIN_ID := "base_humanoid"
const HUMANOID_SKELETON_ID := "humanoid_v1"
const STYLE_IDS := [
	"barrier_counter",
	"last_stand",
	"sacrifice_medic",
	"choke_control",
	"weakpoint_sniper",
	"heavy_suppression",
	"demolition_traps",
	"relic_engineer",
	"psychic_sense",
	"anomaly_ingestion",
	"echo_summoner",
	"aberrant_form",
]
const BASE_RIG_IDS := [
	"base_drifter",
	"base_steadfast",
	"base_armorer",
	"base_resonant",
]
const BASE_RIG_BY_PATHWAY := {
	"": "base_drifter",
	"steadfast": "base_steadfast",
	"armorer": "base_armorer",
	"resonant": "base_resonant",
}
const GENERIC_PART_FILES := {
	"head": "head",
	"torso": "torso",
	"mech_upper": "left_upper",
	"mech_forearm": "left_forearm",
	"organic_upper": "right_upper",
	"organic_forearm": "right_forearm",
	"thigh_near": "thigh_near",
	"shin_near": "shin_near",
	"thigh_far": "thigh_far",
	"shin_far": "shin_far",
	"coat_near": "coat_near",
	"coat_far": "coat_far",
}
const HUMANOID_SKIN_PART_FILES := {
	"head": "head",
	"torso": "torso",
	"mech_upper": "left_upper_arm",
	"mech_forearm": "left_forearm",
	"organic_upper": "right_upper_arm",
	"organic_forearm": "right_forearm",
	"thigh_near": "left_thigh",
	"shin_near": "left_shin",
	"thigh_far": "right_thigh",
	"shin_far": "right_shin",
	"coat_near": "coat_near",
	"coat_far": "coat_far",
}
const PROFESSION_PROFILES := {
	"drifter": {
		"visual_scale": 0.128,
		"stride": 0.94,
		"weight": 0.78,
		"coat_sway": 1.0,
		"recoil": 0.9,
		"weapon": Color("879b8e"),
		"grip": Color("252c29"),
	},
	"steadfast": {
		"visual_scale": 0.125,
		"stride": 0.78,
		"weight": 0.62,
		"coat_sway": 0.62,
		"recoil": 0.78,
		"weapon": Color("91ad93"),
		"grip": Color("27302b"),
	},
	"armorer": {
		"visual_scale": 0.128,
		"stride": 0.72,
		"weight": 0.52,
		"coat_sway": 0.76,
		"recoil": 1.18,
		"weapon": Color("b37a42"),
		"grip": Color("30251d"),
	},
	"resonant": {
		"visual_scale": 0.130,
		"stride": 1.08,
		"weight": 0.92,
		"coat_sway": 1.28,
		"recoil": 0.92,
		"weapon": Color("8061aa"),
		"grip": Color("241d31"),
	},
}

var _rig_id := ""
var _rig_available := false
var _profession_id := "steadfast"
var _profile: Dictionary = PROFESSION_PROFILES["steadfast"]
var _standard_rest_feet := {}
var _humanoid_skin_override := ""


func _ready() -> void:
	ik_demo_enabled = false
	_rig_id = _active_rig_id()
	_rig_available = has_rig(_rig_id)
	visible = _rig_available
	if not _rig_available:
		for child in find_children("*", "Bone2D"):
			var bone := child as Bone2D
			bone.rest = bone.transform
		set_process(false)
		queue_free()
		return
	_apply_profession_profile()
	super._ready()


func _process(delta: float) -> void:
	var next_rig := _active_rig_id()
	if next_rig != _rig_id:
		_rig_id = next_rig
		_rig_available = has_rig(_rig_id)
		visible = _rig_available
		set_process(_rig_available)
		if not _rig_available:
			if is_instance_valid(_player._body_sprite):
				_player._body_sprite.visible = true
			return
		_apply_profession_profile()
		_apply_direction_assets(_direction)
	_sync_formal_ik_mode()
	super._process(delta)
	# Equipment is always mounted by the runtime IK layer. The medic's lantern
	# remains in the legacy demo source only and is never baked into formal play.
	(_sprites["lantern"] as Sprite2D).visible = false


func _active_rig_id() -> String:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return "base_drifter"
	var selected_style := str(state.active_combat_style)
	if selected_style in STYLE_IDS:
		return selected_style
	# Initial progression has four deliberate designs: an unbound drifter and
	# one base skeleton for each pathway. Never borrow a combat-style body here.
	return str(BASE_RIG_BY_PATHWAY.get(
		str(state.selected_pathway),
		"base_drifter",
	))


static func has_style_rig(style_id: String) -> bool:
	if style_id.is_empty() or style_id not in STYLE_IDS:
		return false
	return has_rig(style_id)


static func has_rig(rig_id: String) -> bool:
	if rig_id not in STYLE_IDS and rig_id not in BASE_RIG_IDS:
		return false
	if rig_id == "sacrifice_medic":
		return true
	if rig_id == "base_armorer":
		return FileAccess.file_exists(
			"%s/%s/front/rig.json" % [SKIN_ROOT, rig_id]
		)
	return FileAccess.file_exists(
		_atlas_path_for(rig_id)
	) and FileAccess.file_exists(
		"%s/%s/front/rig.json" % [RIG_ROOT, rig_id]
	)


static func has_humanoid_skin(skin_id: String) -> bool:
	if skin_id not in [HUMANOID_BASE_SKIN_ID, "base_armorer"]:
		return false
	for direction in DIRECTIONS:
		if not FileAccess.file_exists(
			"%s/%s/%s/rig.json" % [SKIN_ROOT, skin_id, direction]
		):
			return false
	return true


static func _atlas_path_for(rig_id: String) -> String:
	var extension := "webp" if rig_id in BASE_RIG_IDS else "png"
	return "%s/%s/atlas.%s" % [RIG_ROOT, rig_id, extension]


func _apply_profession_profile() -> void:
	if _rig_id.begins_with("base_"):
		_profession_id = _rig_id.trim_prefix("base_")
	else:
		var definition: Dictionary = ExchangeEvolution.COMBAT_STYLES.get(
			_rig_id, {}
		)
		_profession_id = str(definition.get("path", "drifter"))
	_profile = PROFESSION_PROFILES.get(
		_profession_id, PROFESSION_PROFILES["drifter"]
	)
	visual_scale = (
		0.055
		if _rig_id == "sacrifice_medic"
		else float(_profile["visual_scale"])
	)
	scale = Vector2.ONE * visual_scale
	_ik_weapon_body.color = _profile["weapon"] as Color
	_ik_weapon_grip.color = _profile["grip"] as Color
	_ik_weapon_foregrip.color = _profile["grip"] as Color


func _asset_root() -> String:
	if _rig_id == "sacrifice_medic":
		return ASSET_ROOT
	if _rig_id == "base_armorer" or not _humanoid_skin_override.is_empty():
		return "%s/%s" % [SKIN_ROOT, current_humanoid_skin_id()]
	return "%s/%s" % [RIG_ROOT, _rig_id]


func _apply_direction_assets(direction: String) -> void:
	var legacy_medic := _rig_id == "sacrifice_medic"
	var manifest: Dictionary = {}
	var atlas: Texture2D
	var individual_skin := false
	if not legacy_medic:
		manifest = _load_manifest(direction)
		individual_skin = int(manifest.get("schema_version", 1)) >= 2
		if not individual_skin:
			atlas = load(_atlas_path_for(_rig_id)) as Texture2D
			assert(atlas != null, "Missing profession rig atlas: %s" % _asset_root())
	for sprite_key in PARTS:
		var sprite := _sprites[sprite_key] as Sprite2D
		if sprite_key == "lantern" and not legacy_medic:
			sprite.texture = null
			sprite.visible = false
			continue
		var file_name: String = sprite_key
		if individual_skin:
			file_name = str(HUMANOID_SKIN_PART_FILES.get(sprite_key, ""))
		elif not legacy_medic:
			file_name = str(GENERIC_PART_FILES.get(sprite_key, ""))
		var texture: Texture2D
		if legacy_medic:
			var path := "%s/%s/%s.png" % [_asset_root(), direction, file_name]
			texture = load(path) as Texture2D
			assert(texture != null, "Missing profession rig part: %s" % path)
		elif individual_skin:
			var part := (manifest["parts"] as Dictionary)[file_name] as Dictionary
			var path := "%s/%s/%s" % [
				_asset_root(),
				direction,
				str(part["file"]),
			]
			texture = load(path) as Texture2D
			assert(texture != null, "Missing humanoid skin part: %s" % path)
		else:
			var part := (manifest["parts"] as Dictionary)[file_name] as Dictionary
			var region := _json_rect(part["region"])
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = atlas
			atlas_texture.region = region
			texture = atlas_texture
		sprite.texture = texture
		sprite.visible = true
	for bone in _animated_bones():
		bone.rotation = 0.0
	for sprite in _sprites.values():
		(sprite as Sprite2D).rotation = 0.0
	_layout_rig(direction)
	_apply_depth_order(direction)
	if individual_skin and direction == "right":
		(_sprites["thigh_near"] as Sprite2D).z_index = -7
		(_sprites["shin_near"] as Sprite2D).z_index = -7
		(_sprites["thigh_far"] as Sprite2D).z_index = 2
		(_sprites["shin_far"] as Sprite2D).z_index = 2
	_rest_positions.clear()
	_rest_rotations.clear()
	for bone in _animated_bones():
		bone.rest = bone.transform
		_rest_positions[bone] = bone.position
		_rest_rotations[bone] = bone.rotation


func _layout_rig(direction: String) -> void:
	if _rig_id == "sacrifice_medic":
		super._layout_rig(direction)
		return
	var manifest := _load_manifest(direction)
	if int(manifest.get("schema_version", 1)) >= 2:
		_layout_individual_skin_rig(direction, manifest)
		return
	_layout_manifest_rig(direction)
	_lantern.position = Vector2.ZERO


func _layout_individual_skin_rig(
	direction: String,
	manifest: Dictionary,
) -> void:
	assert(
		int(manifest.get("schema_version", 0)) >= 3,
		"Individual humanoid skins must use the aligned v3 schema"
	)
	assert(
		str(manifest.get("skeleton_id", "")) == HUMANOID_SKELETON_ID,
		"Humanoid skin uses the wrong skeleton contract"
	)
	var joints := manifest["joints"] as Dictionary
	var parts := manifest["parts"] as Dictionary
	var frame_size := _json_vector(manifest["frame_size"])
	var root := Vector2(frame_size.x * 0.5, frame_size.y)
	var hips := _json_vector(joints["hips"])
	var torso_pivot := _json_vector(joints["torso"])
	_hips.position = hips - root
	_torso.position = torso_pivot - hips
	_set_individual_part_offset("torso", parts["torso"])

	var head_pivot := _json_vector(joints["head"])
	_head.position = head_pivot - torso_pivot
	_set_individual_part_offset("head", parts["head"])

	_layout_individual_arm(
		_left_upper_arm,
		_left_forearm,
		"mech_upper",
		"mech_forearm",
		parts["left_upper_arm"],
		parts["left_forearm"],
		_json_vector(joints["left_shoulder"]),
		_json_vector(joints["left_elbow"]),
		_json_vector(joints["left_hand"]),
		torso_pivot,
	)
	_layout_individual_arm(
		_right_upper_arm,
		_right_forearm,
		"organic_upper",
		"organic_forearm",
		parts["right_upper_arm"],
		parts["right_forearm"],
		_json_vector(joints["right_shoulder"]),
		_json_vector(joints["right_elbow"]),
		_json_vector(joints["right_hand"]),
		torso_pivot,
	)
	_layout_individual_leg(
		_left_leg,
		_left_lower_leg,
		"thigh_near",
		"shin_near",
		parts["left_thigh"],
		parts["left_shin"],
		_json_vector(joints["left_hip"]),
		_json_vector(joints["left_knee"]),
		_json_vector(joints["left_foot"]),
		hips,
	)
	_layout_individual_leg(
		_right_leg,
		_right_lower_leg,
		"thigh_far",
		"shin_far",
		parts["right_thigh"],
		parts["right_shin"],
		_json_vector(joints["right_hip"]),
		_json_vector(joints["right_knee"]),
		_json_vector(joints["right_foot"]),
		hips,
	)
	var far_coat_pivot := _json_vector(joints["coat_left"])
	var near_coat_pivot := _json_vector(joints["coat_right"])
	_far_coat.position = far_coat_pivot - hips
	_near_coat.position = near_coat_pivot - hips
	_set_individual_part_offset("coat_far", parts["coat_far"])
	_set_individual_part_offset("coat_near", parts["coat_near"])
	_lantern.position = Vector2.ZERO
	_standard_rest_feet = {
		"left": _json_vector(joints["left_foot"]) - hips,
		"right": _json_vector(joints["right_foot"]) - hips,
	}

func _layout_individual_arm(
	upper: Bone2D,
	forearm: Bone2D,
	upper_key: String,
	forearm_key: String,
	upper_part: Dictionary,
	forearm_part: Dictionary,
	shoulder: Vector2,
	elbow: Vector2,
	hand: Vector2,
	torso_pivot: Vector2,
) -> void:
	upper.position = shoulder - torso_pivot
	var upper_vector := elbow - shoulder
	var forearm_vector := hand - elbow
	var upper_angle := upper_vector.angle() - PI * 0.5
	var forearm_world_angle := forearm_vector.angle() - PI * 0.5
	upper.rotation = upper_angle
	upper.length = maxf(1.0, upper_vector.length())
	forearm.position = Vector2(0.0, upper.length)
	forearm.rotation = forearm_world_angle - upper_angle
	forearm.length = maxf(1.0, forearm_vector.length())
	_set_oriented_individual_part(
		upper_key,
		upper_part,
		upper_angle,
	)
	_set_oriented_individual_part(
		forearm_key,
		forearm_part,
		forearm_world_angle,
	)


func _layout_individual_leg(
	upper: Bone2D,
	lower: Bone2D,
	upper_key: String,
	lower_key: String,
	upper_part: Dictionary,
	lower_part: Dictionary,
	hip: Vector2,
	knee: Vector2,
	foot: Vector2,
	hips: Vector2,
) -> void:
	upper.position = hip - hips
	var upper_vector := knee - hip
	var lower_vector := foot - knee
	var upper_angle := upper_vector.angle() - PI * 0.5
	var lower_world_angle := lower_vector.angle() - PI * 0.5
	upper.rotation = upper_angle
	upper.length = maxf(1.0, upper_vector.length())
	lower.position = Vector2(0.0, upper.length)
	lower.rotation = lower_world_angle - upper_angle
	lower.length = maxf(1.0, lower_vector.length())
	_set_oriented_individual_part(
		upper_key,
		upper_part,
		upper_angle,
	)
	_set_oriented_individual_part(
		lower_key,
		lower_part,
		lower_world_angle,
	)


func _set_individual_part_offset(
	sprite_key: String,
	part: Dictionary,
	correction := Vector2.ZERO,
) -> void:
	var size := _json_vector(part["size"])
	var pivot := _json_vector(part["pivot"])
	(_sprites[sprite_key] as Sprite2D).position = size * 0.5 - pivot + correction


func _set_oriented_individual_part(
	sprite_key: String,
	part: Dictionary,
	world_rest_angle: float,
) -> void:
	var size := _json_vector(part["size"])
	var pivot := _json_vector(part["pivot"])
	var sprite := _sprites[sprite_key] as Sprite2D
	sprite.position = (size * 0.5 - pivot).rotated(-world_rest_angle)
	# The source art is authored upright in frame coordinates. Cancel the
	# complete rest angle so it reconstructs exactly, while later pose rotation
	# still moves the pixels around the true two-dimensional bone vector.
	sprite.rotation = -world_rest_angle


func _layout_manifest_rig(direction: String) -> void:
	var manifest := _load_manifest(direction)
	var joints := manifest["joints"] as Dictionary
	var parts := manifest["parts"] as Dictionary
	var frame_size := _json_vector(manifest["frame_size"])
	var root := Vector2(frame_size.x * 0.5, frame_size.y)
	var hips := _json_vector(joints["hips"])
	var torso_pivot := _json_vector(joints["torso"])
	var right_is_near := direction == "right"
	var near_prefix := "right" if right_is_near else "left"
	var far_prefix := "left" if right_is_near else "right"

	_hips.position = hips - root
	_torso.position = torso_pivot - hips
	_set_part_offset("torso", parts["torso"], torso_pivot)

	var head_pivot := _json_vector(joints["head"])
	_head.position = head_pivot - torso_pivot
	_set_part_offset("head", parts["head"], head_pivot)

	_layout_manifest_arm(
		_left_upper_arm,
		_left_forearm,
		"mech_upper",
		"mech_forearm",
		parts["left_upper"],
		parts["left_forearm"],
		_json_vector(joints["left_shoulder"]),
		_json_vector(joints["left_elbow"]),
		_json_vector(joints["left_hand"]),
		torso_pivot,
	)
	_layout_manifest_arm(
		_right_upper_arm,
		_right_forearm,
		"organic_upper",
		"organic_forearm",
		parts["right_upper"],
		parts["right_forearm"],
		_json_vector(joints["right_shoulder"]),
		_json_vector(joints["right_elbow"]),
		_json_vector(joints["right_hand"]),
		torso_pivot,
	)
	_layout_manifest_leg(
		_left_leg,
		_left_lower_leg,
		"thigh_near",
		"shin_near",
		parts["thigh_near"],
		parts["shin_near"],
		_json_vector(joints["%s_hip" % near_prefix]),
		_json_vector(joints["%s_knee" % near_prefix]),
		_json_vector(joints["%s_foot" % near_prefix]),
		hips,
	)
	_layout_manifest_leg(
		_right_leg,
		_right_lower_leg,
		"thigh_far",
		"shin_far",
		parts["thigh_far"],
		parts["shin_far"],
		_json_vector(joints["%s_hip" % far_prefix]),
		_json_vector(joints["%s_knee" % far_prefix]),
		_json_vector(joints["%s_foot" % far_prefix]),
		hips,
	)
	var near_coat_name := "coat_right" if right_is_near else "coat_left"
	var far_coat_name := "coat_left" if right_is_near else "coat_right"
	var near_coat_pivot := _json_vector(joints[near_coat_name])
	var far_coat_pivot := _json_vector(joints[far_coat_name])
	_near_coat.position = near_coat_pivot - hips
	_far_coat.position = far_coat_pivot - hips
	_set_part_offset("coat_near", parts["coat_near"], near_coat_pivot)
	_set_part_offset("coat_far", parts["coat_far"], far_coat_pivot)


func _layout_manifest_arm(
	upper: Bone2D,
	forearm: Bone2D,
	upper_key: String,
	forearm_key: String,
	upper_part,
	forearm_part,
	shoulder: Vector2,
	elbow: Vector2,
	hand: Vector2,
	torso_pivot: Vector2,
) -> void:
	upper.position = shoulder - torso_pivot
	forearm.position = Vector2(0.0, elbow.y - shoulder.y)
	upper.length = maxf(1.0, elbow.y - shoulder.y)
	forearm.length = maxf(1.0, hand.y - elbow.y)
	_set_part_offset(upper_key, upper_part, shoulder)
	# Keep the IK chain vertical while preserving the exact neutral crop offset.
	_set_part_offset(
		forearm_key,
		forearm_part,
		Vector2(shoulder.x, elbow.y),
	)


func _layout_manifest_leg(
	upper: Bone2D,
	lower: Bone2D,
	upper_key: String,
	lower_key: String,
	upper_part,
	lower_part,
	hip: Vector2,
	knee: Vector2,
	foot: Vector2,
	hips: Vector2,
) -> void:
	upper.position = hip - hips
	lower.position = Vector2(0.0, knee.y - hip.y)
	upper.length = maxf(1.0, knee.y - hip.y)
	lower.length = maxf(1.0, foot.y - knee.y)
	_set_part_offset(upper_key, upper_part, hip)
	_set_part_offset(lower_key, lower_part, Vector2(hip.x, knee.y))


func _set_part_offset(sprite_key: String, part, pivot: Vector2) -> void:
	var center := _json_vector((part as Dictionary)["center"])
	(_sprites[sprite_key] as Sprite2D).position = center - pivot


static func _json_vector(value) -> Vector2:
	var items := value as Array
	return Vector2(float(items[0]), float(items[1]))


static func _json_rect(value) -> Rect2:
	var items := value as Array
	return Rect2(
		float(items[0]),
		float(items[1]),
		float(items[2]),
		float(items[3]),
	)


func _load_manifest(direction: String) -> Dictionary:
	var path := "%s/%s/rig.json" % [_asset_root(), direction]
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Missing profession rig manifest: %s" % path)
	var manifest = JSON.parse_string(file.get_as_text())
	assert(manifest is Dictionary, "Invalid profession rig manifest: %s" % path)
	return manifest as Dictionary


func _sync_formal_ik_mode() -> void:
	if _player._skill_pose_timer > 0.0:
		set_ik_demo_mode(IKDemoMode.CAST)
		set_cast_orb_preview_enabled(false)
		return
	# current_weapon is a free equipment-slot index.  The character body never
	# owns a weapon; its pose follows the actual item mounted in that slot.
	match _player._weapon_attack_type():
		"ranged":
			set_ik_demo_mode(IKDemoMode.PISTOL)
		"shotgun":
			set_ik_demo_mode(IKDemoMode.RIFLE)
		_:
			set_ik_demo_mode(IKDemoMode.MELEE)


func _apply_idle_pose(delta: float) -> void:
	super._apply_idle_pose(delta)
	var weight := float(_profile["weight"])
	var breath := sin(_idle_time * (1.82 if _profession_id == "steadfast" else 2.15))
	_torso.rotation += breath * 0.004 * weight
	_near_coat.rotation += breath * 0.006 * float(_profile["coat_sway"])
	_far_coat.rotation -= breath * 0.004 * float(_profile["coat_sway"])


func _apply_walk_pose(speed_ratio: float, delta: float) -> void:
	if _uses_standard_humanoid_skin():
		_apply_standard_humanoid_walk_pose(speed_ratio, delta)
	else:
		super._apply_walk_pose(speed_ratio, delta)
	var stride := sin(_player._step_phase * TAU) * speed_ratio
	var profile_stride := float(_profile["stride"])
	var coat_sway := float(_profile["coat_sway"])
	if not _uses_standard_humanoid_skin():
		_left_leg.rotation *= profile_stride
		_right_leg.rotation *= profile_stride
		_left_lower_leg.rotation *= profile_stride
		_right_lower_leg.rotation *= profile_stride
		_left_upper_arm.rotation *= profile_stride
		_right_upper_arm.rotation *= profile_stride
	_hips.position.y += absf(stride) * (2.5 + float(_profile["weight"]) * 3.0)
	_near_coat.rotation += stride * 0.045 * coat_sway
	_far_coat.rotation -= stride * 0.032 * coat_sway


func _uses_standard_humanoid_skin() -> bool:
	return _rig_id == "base_armorer" and not _standard_rest_feet.is_empty()


func _apply_standard_humanoid_walk_pose(
	speed_ratio: float,
	delta: float,
) -> void:
	var phase := _player._step_phase * TAU
	var stride := sin(phase)
	var opposite_stride := -stride
	var side_view := _direction == "left" or _direction == "right"
	var settle := 1.0 - exp(-delta * 18.0)
	var left_lift := maxf(stride, 0.0)
	var right_lift := maxf(opposite_stride, 0.0)
	var contact := pow(absf(cos(phase)), 4.0)
	var hips_offset := Vector2(
		0.0 if side_view else stride * 2.2,
		contact * 3.4,
	) * speed_ratio
	_pose_position(_hips, hips_offset, settle)
	_pose_position(_left_leg, Vector2.ZERO, settle)
	_pose_position(_right_leg, Vector2.ZERO, settle)

	var travel := (23.0 if side_view else 7.0) * speed_ratio
	var lift := (11.0 if side_view else 7.0) * speed_ratio
	var left_target := _standard_rest_feet["left"] as Vector2
	var right_target := _standard_rest_feet["right"] as Vector2
	if side_view:
		left_target.x += stride * travel
		right_target.x += opposite_stride * travel
	else:
		# Axial views show depth through shortening and overlap, not the broad
		# sideways pendulum used by a profile walk.
		left_target.x += stride * 2.5 * speed_ratio
		right_target.x += opposite_stride * 2.5 * speed_ratio
		left_target.y += stride * travel
		right_target.y += opposite_stride * travel
	left_target.y -= left_lift * lift + hips_offset.y
	right_target.y -= right_lift * lift + hips_offset.y
	_apply_leg_target(
		_left_leg,
		_left_lower_leg,
		left_target,
		_standard_leg_bend_sign("left"),
		settle,
	)
	_apply_leg_target(
		_right_leg,
		_right_lower_leg,
		right_target,
		_standard_leg_bend_sign("right"),
		settle,
	)

	var arm_amount := (0.23 if side_view else 0.075) * speed_ratio
	_pose_rotation(_left_upper_arm, opposite_stride * arm_amount, settle)
	_pose_rotation(_right_upper_arm, stride * arm_amount, settle)
	_pose_rotation(_left_forearm, left_lift * 0.10, settle)
	_pose_rotation(_right_forearm, -right_lift * 0.10, settle)
	_pose_rotation(
		_torso,
		opposite_stride * (0.018 if side_view else 0.010) * speed_ratio,
		settle,
	)
	_pose_rotation(_head, stride * 0.008 * speed_ratio, settle)
	_pose_rotation(_far_coat, opposite_stride * 0.035 * speed_ratio, settle)
	_pose_rotation(_near_coat, opposite_stride * 0.048 * speed_ratio, settle)


func _apply_leg_target(
	upper: Bone2D,
	lower: Bone2D,
	target: Vector2,
	bend_sign: float,
	weight: float,
) -> void:
	var solution := solve_two_bone(
		upper.position,
		target,
		upper.length,
		lower.length,
		bend_sign,
	)
	upper.rotation = lerp_angle(upper.rotation, solution.x, weight)
	lower.rotation = lerp_angle(lower.rotation, solution.y, weight)


func _standard_leg_bend_sign(side: String) -> float:
	var upper := _left_leg if side == "left" else _right_leg
	var rest_root := _rest_positions.get(upper, upper.position) as Vector2
	var rest_foot := _standard_rest_feet[side] as Vector2
	var horizontal := rest_foot.x - rest_root.x
	if absf(horizontal) < 0.5:
		horizontal = -1.0 if _direction == "right" else 1.0
	return -signf(horizontal)


func walk_pose_signature() -> PackedFloat32Array:
	var left_foot := _left_lower_leg.to_global(
		Vector2(0.0, _left_lower_leg.length)
	)
	var right_foot := _right_lower_leg.to_global(
		Vector2(0.0, _right_lower_leg.length)
	)
	return PackedFloat32Array([
		_left_leg.rotation,
		_right_leg.rotation,
		_left_lower_leg.rotation,
		_right_lower_leg.rotation,
		left_foot.x,
		left_foot.y,
		right_foot.x,
		right_foot.y,
		_hips.position.x,
		_hips.position.y,
	])


func _apply_attack_pose() -> void:
	super._apply_attack_pose()
	var recoil := float(_profile["recoil"])
	_torso.rotation += -0.018 * _attack_weight * recoil
	_near_coat.rotation += 0.022 * _attack_weight * recoil


func _hide_frame_sprite() -> void:
	if _rig_available and is_instance_valid(_player._body_sprite):
		_player._body_sprite.visible = false


func current_profession_id() -> String:
	return _profession_id


func current_rig_id() -> String:
	return _rig_id


func current_humanoid_skin_id() -> String:
	return (
		_humanoid_skin_override
		if not _humanoid_skin_override.is_empty()
		else _rig_id
	)


func set_humanoid_skin_for_preview(skin_id: String) -> void:
	assert(
		_rig_id == "base_armorer",
		"Only the standard humanoid rig accepts humanoid skin swaps"
	)
	assert(has_humanoid_skin(skin_id), "Missing humanoid skin: %s" % skin_id)
	_humanoid_skin_override = skin_id
	_apply_direction_assets(_direction)


func has_split_body_parts() -> bool:
	for part_name in GENERIC_PART_FILES:
		if (_sprites[part_name] as Sprite2D).texture == null:
			return false
	return true


func uses_runtime_equipment_only() -> bool:
	return (
		(_sprites["lantern"] as Sprite2D).visible == false
		and _ik_weapon != null
	)
