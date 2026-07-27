class_name ProfessionSkeletonCharacter
extends LayeredSkeletonCharacter

const RIG_ROOT := "res://assets/art/characters/professions/rigs"
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
	return FileAccess.file_exists(
		_atlas_path_for(rig_id)
	) and FileAccess.file_exists(
		"%s/%s/front/rig.json" % [RIG_ROOT, rig_id]
	)


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
	return "%s/%s" % [RIG_ROOT, _rig_id]


func _apply_direction_assets(direction: String) -> void:
	var legacy_medic := _rig_id == "sacrifice_medic"
	var manifest: Dictionary = {}
	var atlas: Texture2D
	if not legacy_medic:
		manifest = _load_manifest(direction)
		atlas = load(_atlas_path_for(_rig_id)) as Texture2D
		assert(atlas != null, "Missing profession rig atlas: %s" % _asset_root())
	for sprite_key in PARTS:
		var sprite := _sprites[sprite_key] as Sprite2D
		if sprite_key == "lantern" and not legacy_medic:
			sprite.texture = null
			sprite.visible = false
			continue
		var file_name: String = sprite_key if legacy_medic else str(
			GENERIC_PART_FILES.get(sprite_key, "")
		)
		var texture: Texture2D
		if legacy_medic:
			var path := "%s/%s/%s.png" % [_asset_root(), direction, file_name]
			texture = load(path) as Texture2D
			assert(texture != null, "Missing profession rig part: %s" % path)
		else:
			var part := (manifest["parts"] as Dictionary)[file_name] as Dictionary
			var region := _json_rect(part["region"])
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = atlas
			atlas_texture.region = region
			texture = atlas_texture
		sprite.texture = texture
		sprite.visible = true
	_layout_rig(direction)
	_apply_depth_order(direction)
	for bone in _animated_bones():
		bone.rotation = 0.0
		bone.rest = bone.transform
	_rest_positions.clear()
	for bone in _animated_bones():
		_rest_positions[bone] = bone.position


func _layout_rig(direction: String) -> void:
	if _rig_id == "sacrifice_medic":
		super._layout_rig(direction)
		return
	_layout_manifest_rig(direction)
	_lantern.position = Vector2.ZERO


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
	super._apply_walk_pose(speed_ratio, delta)
	var stride := sin(_player._step_phase * TAU) * speed_ratio
	var profile_stride := float(_profile["stride"])
	var coat_sway := float(_profile["coat_sway"])
	_left_leg.rotation *= profile_stride
	_right_leg.rotation *= profile_stride
	_left_lower_leg.rotation *= profile_stride
	_right_lower_leg.rotation *= profile_stride
	_left_upper_arm.rotation *= profile_stride
	_right_upper_arm.rotation *= profile_stride
	_hips.position.y += absf(stride) * (2.5 + float(_profile["weight"]) * 3.0)
	_near_coat.rotation += stride * 0.045 * coat_sway
	_far_coat.rotation -= stride * 0.032 * coat_sway


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
