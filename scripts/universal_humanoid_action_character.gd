class_name UniversalHumanoidActionCharacter
extends Node2D

const ACTION_LIBRARY_PATH := "res://content/humanoid_action_tracks.json"
const SKIN_ROOT := "res://assets/art/characters/professions/skins"
const BASIC_WEAPONS: Texture2D = preload("res://assets/art/weapons/basic_weapons.png")
const EQUIPMENT_RUNTIME: Texture2D = preload("res://assets/art/weapons/equipment_runtime.png")
const PART_NAMES := [
	"coat_far",
	"left_thigh",
	"left_shin",
	"right_thigh",
	"right_shin",
	"torso",
	"left_upper_arm",
	"left_forearm",
	"right_upper_arm",
	"right_forearm",
	"head",
	"coat_near",
]
const PART_JOINTS := {
	"head": ["head", "head"],
	"torso": ["hips", "head"],
	"left_upper_arm": ["left_shoulder", "left_elbow"],
	"left_forearm": ["left_elbow", "left_hand"],
	"right_upper_arm": ["right_shoulder", "right_elbow"],
	"right_forearm": ["right_elbow", "right_hand"],
	"left_thigh": ["left_hip", "left_knee"],
	"left_shin": ["left_knee", "left_foot"],
	"right_thigh": ["right_hip", "right_knee"],
	"right_shin": ["right_knee", "right_foot"],
	"coat_far": ["left_hip", "left_knee"],
	"coat_near": ["right_hip", "right_knee"],
}
const PREVIEW_ACTION_MAP := {
	&"idle": "idle",
	&"walk": "walk",
	&"attack_melee": "one_hand_melee_attack",
	&"hit": "hit_chest",
	&"death": "death",
	&"one_hand_melee_idle": "one_hand_melee_idle",
	&"pistol_idle": "pistol_idle",
	&"pistol_aim_down": "pistol_aim_down",
	&"pistol_aim": "pistol_aim",
	&"pistol_aim_up": "pistol_aim_up",
	&"pistol_shoot": "pistol_shoot",
	&"pistol_reload": "pistol_reload",
	&"spell_enter": "spell_enter",
	&"spell_idle": "spell_idle",
	&"spell_shoot": "spell_shoot",
	&"spell_exit": "spell_exit",
	&"bow_idle": "bow_idle",
	&"bow_draw": "bow_draw",
	&"bow_aim": "bow_draw",
	&"bow_release": "bow_release",
	&"shield_raise": "shield_idle",
	&"shield_block": "shield_block",
	&"shield_hit": "shield_impact",
	&"shield_bash": "shield_impact",
}

@export var action_library_enabled := false
@export var skin_id := "base_armorer"
@export var playback_fps := 10.0

var _player: Player
var _base_character: RenderedAtlasCharacter
var _martial_trial: MartialArtistTrialCharacter
var _library := {}
var _rig := {}
var _part_sprites := {}
var _main_hand_sprite: Sprite2D
var _offhand_sprite: Sprite2D
var _elapsed := 0.0
var _attack_elapsed := 0.0
var _attack_was_active := false
var _current_action := "idle"
var _current_direction := "front"
var _current_joints := {}
var _preview_action := ""
var _preview_elapsed := 0.0


func _ready() -> void:
	assert(get_parent() is Player, "UniversalHumanoidActionCharacter must be a child of Player")
	_player = get_parent() as Player
	_base_character = _player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	_martial_trial = _player.get_node_or_null("MartialArtistTrialCharacter")
	_load_action_library()
	_create_part_sprites()
	_create_equipment_sprites()
	set_skin(skin_id)
	set_action_library_enabled(action_library_enabled)


func _process(delta: float) -> void:
	if not action_library_enabled or _library.is_empty() or _rig.is_empty():
		return
	_elapsed += delta
	_preview_elapsed += delta
	var attacking := _player._attack_flash > 0.0
	if attacking and not _attack_was_active:
		_attack_elapsed = 0.0
	elif attacking:
		_attack_elapsed += delta
	_attack_was_active = attacking
	_current_direction = String(RenderedAtlasCharacter.direction_from_vector(_player.facing))
	if _player.velocity.length() > 2.0 and _preview_action not in ["", "walk"]:
		_preview_action = ""
	_current_action = (
		_preview_action
		if not _preview_action.is_empty()
		else _select_action(attacking)
	)
	var frame := _sample_action(_current_action, _current_direction)
	if not frame.is_empty():
		_current_joints = _retarget_frame(frame)
		_apply_pose(_current_joints)
	_sync_equipment_visuals()
	_apply_feedback_color()


func set_action_library_enabled(enabled: bool) -> void:
	action_library_enabled = enabled
	visible = enabled
	if is_instance_valid(_base_character):
		_base_character.set_body_layer_visible(not enabled)
	if not enabled:
		_preview_action = ""
	if is_instance_valid(_martial_trial):
		_martial_trial.set_trial_enabled(not enabled)
	if is_instance_valid(_player):
		_player.queue_redraw()


func is_action_library_enabled() -> bool:
	return action_library_enabled


func owns_equipment_visuals() -> bool:
	return action_library_enabled


func current_skin_id() -> String:
	return skin_id


func current_action_name() -> String:
	return _current_action


func play_preview_action(logical_name: StringName) -> bool:
	var mapped_action := str(PREVIEW_ACTION_MAP.get(logical_name, ""))
	if mapped_action.is_empty():
		return false
	_preview_action = mapped_action
	_preview_elapsed = 0.0
	return true


func set_skin(next_skin_id: String) -> bool:
	var direction_path := "%s/%s/front/rig.json" % [SKIN_ROOT, next_skin_id]
	if not FileAccess.file_exists(direction_path):
		return false
	skin_id = next_skin_id
	_load_direction_skin(_current_direction)
	return true


func equipment_anchor(slot: StringName) -> Vector2:
	var joint_name := "left_hand" if slot == &"off_hand" else "right_hand"
	var local_anchor: Vector2 = _current_joints.get(
		joint_name,
		Vector2(-55, -165) if slot == &"off_hand" else Vector2(55, -165),
	)
	return position + local_anchor * scale


func action_count() -> int:
	return int(_library.get("action_count", 0))


func _load_action_library() -> void:
	assert(FileAccess.file_exists(ACTION_LIBRARY_PATH), "Missing humanoid action library")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ACTION_LIBRARY_PATH))
	assert(parsed is Dictionary, "Invalid humanoid action library JSON")
	_library = parsed
	assert(int(_library.get("action_count", 0)) == 44, "Expected 44 humanoid actions")


func _create_part_sprites() -> void:
	for part_name in PART_NAMES:
		var sprite := Sprite2D.new()
		sprite.name = String(part_name).to_pascal_case()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.z_index = PART_NAMES.find(part_name)
		add_child(sprite)
		_part_sprites[part_name] = sprite


func _create_equipment_sprites() -> void:
	_offhand_sprite = Sprite2D.new()
	_offhand_sprite.name = "OffHandEquipment"
	_offhand_sprite.z_index = 7
	_offhand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_offhand_sprite)
	_main_hand_sprite = Sprite2D.new()
	_main_hand_sprite.name = "MainHandEquipment"
	_main_hand_sprite.z_index = 11
	_main_hand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_main_hand_sprite)


func _select_action(attacking: bool) -> String:
	if _player._dead:
		return "death"
	if _player._hurt_flash > 0.0:
		return "hit_chest"
	var family := _weapon_family()
	if attacking:
		match family:
			"bow": return "bow_release"
			"spell": return "spell_shoot"
			"pistol": return "pistol_shoot"
			"two_hand_firearm": return "two_hand_firearm_shoot"
			"heavy_two_hand": return "heavy_two_hand_attack"
			"unarmed": return "punch_jab"
			_: return "one_hand_melee_attack"
	if _player.velocity.length() > 2.0:
		return "walk"
	match family:
		"bow": return "bow_idle"
		"spell": return "spell_idle"
		"pistol": return "pistol_idle"
		"two_hand_firearm": return "two_hand_firearm_idle"
		"heavy_two_hand": return "heavy_two_hand_idle"
		"unarmed": return "idle"
		_: return "one_hand_melee_idle"


func _weapon_family() -> String:
	match _player.equipped_weapon_item:
		"mourning_bow":
			return "bow"
		"echo_staff":
			return "spell"
		"service_pistol", "nullpoint_sidearm":
			return "pistol"
		"breach_shotgun", "siege_cannon", "conductor_railgun":
			return "two_hand_firearm"
		"director_reaper":
			return "heavy_two_hand"
		"":
			return "unarmed"
		_:
			return "one_hand_melee"


func _sample_action(action_name: String, direction: String) -> Dictionary:
	var action: Dictionary = _library.get("actions", {}).get(action_name, {})
	var direction_frames: Array = action.get("frames", {}).get(direction, [])
	if direction_frames.is_empty():
		return {}
	var looped := bool(action.get("loop", false))
	var time := (
		_preview_elapsed
		if action_name == _preview_action
		else (_elapsed if looped else (_attack_elapsed if _attack_was_active else 0.0))
	)
	var frame_index := int(floor(time * playback_fps))
	frame_index = frame_index % direction_frames.size() if looped else mini(
		frame_index,
		direction_frames.size() - 1,
	)
	return direction_frames[frame_index]


func _retarget_frame(frame: Dictionary) -> Dictionary:
	var joints: Dictionary = _rig.get("joints", {})
	var baseline_y := float(_rig.get("baseline_y", 410.0))
	var center_x := float(_rig.get("center_x", 128.0))
	var rest_head := _vec(joints.get("head", [128, 82]))
	var rest_hips := _vec(joints.get("hips", [128, 230]))
	var body_height := baseline_y - rest_head.y
	var raw := {}
	for joint_name in frame:
		var normalized := _vec(frame[joint_name])
		raw[joint_name] = Vector2(
			center_x + normalized.x * body_height,
			baseline_y + normalized.y * body_height,
		)
	var target := {}
	var hips: Vector2 = raw.get("hips", rest_hips)
	var raw_torso: Vector2 = raw.get("head", rest_head) - raw.get("hips", rest_hips)
	var rest_torso := rest_head - rest_hips
	var torso_delta := clampf(
		wrapf(raw_torso.angle() - rest_torso.angle(), -PI, PI),
		-deg_to_rad(38.0),
		deg_to_rad(38.0),
	)
	target["hips"] = hips
	target["torso"] = hips
	target["head"] = hips + rest_torso.rotated(torso_delta)
	for side in ["left", "right"]:
		var shoulder_name := "%s_shoulder" % side
		var hip_name := "%s_hip" % side
		var elbow_name := "%s_elbow" % side
		var hand_name := "%s_hand" % side
		var knee_name := "%s_knee" % side
		var foot_name := "%s_foot" % side
		var shoulder := hips + (_vec(joints[shoulder_name]) - rest_hips).rotated(torso_delta)
		var hip := hips + (_vec(joints[hip_name]) - rest_hips).rotated(torso_delta)
		target[shoulder_name] = shoulder
		target[hip_name] = hip
		var arm := _solve_two_bone(
			shoulder,
			raw.get(hand_name, _vec(joints[hand_name])),
			_vec(joints[elbow_name]).distance_to(_vec(joints[shoulder_name])),
			_vec(joints[hand_name]).distance_to(_vec(joints[elbow_name])),
			raw.get(elbow_name, _vec(joints[elbow_name])),
		)
		target[elbow_name] = arm[0]
		target[hand_name] = arm[1]
		var leg := _solve_two_bone(
			hip,
			raw.get(foot_name, _vec(joints[foot_name])),
			_vec(joints[knee_name]).distance_to(_vec(joints[hip_name])),
			_vec(joints[foot_name]).distance_to(_vec(joints[knee_name])),
			raw.get(knee_name, _vec(joints[knee_name])),
		)
		target[knee_name] = leg[0]
		target[foot_name] = leg[1]
	for joint_name in target:
		target[joint_name] = (target[joint_name] as Vector2) - Vector2(center_x, baseline_y)
	return target


func _solve_two_bone(
	root: Vector2,
	requested_end: Vector2,
	first_length: float,
	second_length: float,
	bend_hint: Vector2,
) -> Array:
	var delta := requested_end - root
	var distance := clampf(delta.length(), absf(first_length - second_length) + 0.01, first_length + second_length - 0.01)
	var direction := delta.normalized() if delta.length() > 0.001 else Vector2.DOWN
	var end := root + direction * distance
	var along := (first_length * first_length - second_length * second_length + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(first_length * first_length - along * along, 0.0))
	var perpendicular := direction.orthogonal()
	var bend_sign := signf((bend_hint - root).dot(perpendicular))
	if is_zero_approx(bend_sign):
		bend_sign = 1.0
	var middle := root + direction * along + perpendicular * height * bend_sign
	return [middle, end]


func _apply_pose(joints: Dictionary) -> void:
	var facing_changed := _loaded_direction() != _current_direction
	if facing_changed:
		_load_direction_skin(_current_direction)
	for part_name in PART_NAMES:
		var sprite := _part_sprites[part_name] as Sprite2D
		var definition: Dictionary = _rig.get("parts", {}).get(part_name, {})
		if definition.is_empty() or sprite.texture == null:
			sprite.hide()
			continue
		sprite.show()
		var joint_pair: Array = PART_JOINTS[part_name]
		var start: Vector2 = joints.get(joint_pair[0], Vector2.ZERO)
		var end: Vector2 = joints.get(joint_pair[1], start)
		var rest_joints: Dictionary = _rig.get("joints", {})
		var rest_start := _vec(rest_joints[joint_pair[0]])
		var rest_end := _vec(rest_joints[joint_pair[1]])
		sprite.position = start
		sprite.rotation = 0.0 if part_name == "head" else (
			(end - start).angle() - (rest_end - rest_start).angle()
		)


func _load_direction_skin(direction: String) -> void:
	var source_direction := direction
	var rig_path := "%s/%s/%s/rig.json" % [SKIN_ROOT, skin_id, source_direction]
	if not FileAccess.file_exists(rig_path):
		source_direction = "left" if direction == "right" else "front"
		rig_path = "%s/%s/%s/rig.json" % [SKIN_ROOT, skin_id, source_direction]
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(rig_path))
	assert(parsed is Dictionary, "Invalid split humanoid rig: %s" % rig_path)
	_rig = parsed
	for part_name in PART_NAMES:
		var sprite := _part_sprites[part_name] as Sprite2D
		var definition: Dictionary = _rig.get("parts", {}).get(part_name, {})
		if definition.is_empty():
			sprite.texture = null
			continue
		var texture_path := "%s/%s/%s/%s" % [
			SKIN_ROOT,
			skin_id,
			source_direction,
			str(definition.get("file", "")),
		]
		sprite.texture = load(texture_path)
		var size := _vec(definition.get("size", [1, 1]))
		var pivot := _vec(definition.get("pivot", [0, 0]))
		sprite.offset = size * 0.5 - pivot
		sprite.flip_h = direction == "right" and source_direction == "left"
	set_meta("loaded_direction", direction)


func _loaded_direction() -> String:
	return str(get_meta("loaded_direction", ""))


func _sync_equipment_visuals() -> void:
	_sync_main_hand_texture()
	_offhand_sprite.texture = null
	_offhand_sprite.hide()
	var main_anchor: Vector2 = _current_joints.get("right_hand", Vector2(45, -170))
	_main_hand_sprite.position = main_anchor
	var facing_angle := _player.facing.angle()
	match _weapon_family():
		"bow":
			_main_hand_sprite.rotation = facing_angle - PI * 0.5
		"spell":
			_main_hand_sprite.rotation = facing_angle + PI * 0.5
		"pistol", "two_hand_firearm":
			_main_hand_sprite.rotation = facing_angle
		_:
			_main_hand_sprite.rotation = facing_angle + PI * 0.25


func _sync_main_hand_texture() -> void:
	match _player.equipped_weapon_item:
		"service_crowbar":
			_set_atlas_cell(_main_hand_sprite, BASIC_WEAPONS, 32, 0, 4.7)
		"mourning_bow":
			_set_atlas_cell(_main_hand_sprite, EQUIPMENT_RUNTIME, 64, 0, 2.8)
		"echo_staff":
			_set_atlas_cell(_main_hand_sprite, EQUIPMENT_RUNTIME, 64, 1, 2.8)
		_:
			_main_hand_sprite.texture = null


func _set_atlas_cell(
	sprite: Sprite2D,
	atlas: Texture2D,
	cell_size: int,
	index: int,
	display_scale: float,
) -> void:
	var region := Rect2(index * cell_size, 0, cell_size, cell_size)
	var current := sprite.texture as AtlasTexture
	if current == null or current.atlas != atlas or current.region != region:
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = region
		sprite.texture = texture
	sprite.scale = Vector2.ONE * display_scale


func _apply_feedback_color() -> void:
	var tint := (
		Color("7b7f86")
		if _player._dead
		else (
			Color("ffb5ad")
			if _player._hurt_flash > 0.0
			else (Color("c8ffdc") if _player._heal_flash > 0.0 else Color.WHITE)
		)
	)
	for sprite in _part_sprites.values():
		(sprite as Sprite2D).modulate = tint


func _vec(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
