class_name LayeredSkeletonCharacter
extends Skeleton2D

enum IKDemoMode {
	FREE,
	PISTOL,
	RIFLE,
	CAST,
}

const ASSET_ROOT := "res://assets/art/characters/professions/sacrifice_medic_rig"
const DIRECTIONS := ["front", "left", "right", "back"]
const PARTS := [
	"head",
	"torso",
	"mech_upper",
	"mech_forearm",
	"organic_upper",
	"organic_forearm",
	"thigh_near",
	"thigh_far",
	"shin_near",
	"shin_far",
	"coat_near",
	"coat_far",
	"lantern",
]

# The generated rig pieces deliberately include covered joint tabs.  These
# values keep those tabs inside the neighbouring piece instead of treating
# their full bitmap height as visible anatomy.
const HEAD_COLLAR_INSET := 152.0
const HIP_TOP_INSET := 20.0
const LEG_KNEE_OVERLAP := 84.0
const LOWER_LEG_TOP_INSET := 44.0
const FOOT_BASELINE_OFFSET := 10.0
const ARM_ELBOW_OVERLAP := 86.0
const FOREARM_TOP_INSET := 50.0
const HAND_ATTACHMENT_INSET := 74.0
const RIFLE_CENTER_FORWARD := 175.0
const RIFLE_CENTER_FORWARD_AXIAL := 150.0
const RIFLE_REAR_GRIP_BACK := 46.0
const RIFLE_FRONT_GRIP_FORWARD := 76.0
const RIFLE_FRONT_GRIP_FORWARD_AXIAL := 64.0
const RIFLE_GRIP_DROP := 18.0
const RIFLE_STOCK_BACK := 102.0

@export var visual_scale := 0.055
@export var ik_demo_enabled := true
@export var default_ik_demo_mode := IKDemoMode.PISTOL

@onready var _player := get_parent() as Player
@onready var _hips := $Hips as Bone2D
@onready var _torso := $Hips/Torso as Bone2D
@onready var _head := $Hips/Torso/Head as Bone2D
@onready var _left_leg := $Hips/LeftLeg as Bone2D
@onready var _left_lower_leg := $Hips/LeftLeg/LowerLeg as Bone2D
@onready var _right_leg := $Hips/RightLeg as Bone2D
@onready var _right_lower_leg := $Hips/RightLeg/LowerLeg as Bone2D
@onready var _left_upper_arm := $Hips/Torso/LeftUpperArm as Bone2D
@onready var _left_forearm := $Hips/Torso/LeftUpperArm/LeftForearm as Bone2D
@onready var _lantern := $Hips/Torso/LeftUpperArm/LeftForearm/Lantern as Bone2D
@onready var _right_upper_arm := $Hips/Torso/RightUpperArm as Bone2D
@onready var _right_forearm := $Hips/Torso/RightUpperArm/RightForearm as Bone2D
@onready var _far_coat := $Hips/FarCoat as Bone2D
@onready var _near_coat := $Hips/NearCoat as Bone2D
@onready var _ik_weapon := $IKWeapon as Node2D
@onready var _ik_weapon_body := $IKWeapon/Body as Polygon2D
@onready var _ik_weapon_grip := $IKWeapon/Grip as Polygon2D
@onready var _ik_weapon_foregrip := $IKWeapon/Foregrip as Polygon2D
@onready var _cast_orb := $CastOrb as Polygon2D

@onready var _sprites := {
	"head": $Hips/Torso/Head/Sprite as Sprite2D,
	"torso": $Hips/Torso/Sprite as Sprite2D,
	"mech_upper": $Hips/Torso/LeftUpperArm/Sprite as Sprite2D,
	"mech_forearm": $Hips/Torso/LeftUpperArm/LeftForearm/Sprite as Sprite2D,
	"organic_upper": $Hips/Torso/RightUpperArm/Sprite as Sprite2D,
	"organic_forearm": $Hips/Torso/RightUpperArm/RightForearm/Sprite as Sprite2D,
	"thigh_near": $Hips/LeftLeg/Sprite as Sprite2D,
	"shin_near": $Hips/LeftLeg/LowerLeg/Sprite as Sprite2D,
	"thigh_far": $Hips/RightLeg/Sprite as Sprite2D,
	"shin_far": $Hips/RightLeg/LowerLeg/Sprite as Sprite2D,
	"coat_near": $Hips/NearCoat/Sprite as Sprite2D,
	"coat_far": $Hips/FarCoat/Sprite as Sprite2D,
	"lantern": $Hips/Torso/LeftUpperArm/LeftForearm/Lantern/Sprite as Sprite2D,
}

var _rest_positions: Dictionary = {}
var _idle_time := 0.0
var _attack_weight := 0.0
var _attack_was_active := false
var _direction := "front"
var _ik_mode := IKDemoMode.FREE
var _ik_blend := 0.0
var _ik_targets := {}
var _cast_orb_preview_enabled := true


func _ready() -> void:
	scale = Vector2.ONE * visual_scale
	_apply_direction_assets(_direction)
	if ik_demo_enabled:
		set_ik_demo_mode(default_ik_demo_mode)
	call_deferred("_hide_frame_sprite")


func _unhandled_input(event: InputEvent) -> void:
	if not ik_demo_enabled or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_0:
			set_ik_demo_mode(IKDemoMode.FREE)
		KEY_1:
			set_ik_demo_mode(IKDemoMode.PISTOL)
		KEY_2:
			set_ik_demo_mode(IKDemoMode.RIFLE)
		KEY_3:
			set_ik_demo_mode(IKDemoMode.CAST)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_hide_frame_sprite()
	_idle_time += delta
	var next_direction := direction_from_facing(_player.facing)
	if next_direction != _direction:
		_direction = next_direction
		_apply_direction_assets(_direction)
	var speed_ratio := clampf(
		_player.velocity.length() / maxf(_player.movement_speed, 1.0),
		0.0,
		1.0,
	)
	var attack_active := _player._attack_flash > 0.0
	if attack_active and not _attack_was_active:
		_attack_weight = 1.0
	_attack_was_active = attack_active
	_attack_weight = move_toward(_attack_weight, 0.0, delta * 4.8)
	if speed_ratio > 0.04:
		_apply_walk_pose(speed_ratio, delta)
	else:
		_apply_idle_pose(delta)
	_ik_blend = move_toward(_ik_blend, 0.0 if _ik_mode == IKDemoMode.FREE else 1.0, delta * 7.5)
	if _ik_blend > 0.001:
		_apply_ik_pose(delta)
	else:
		_apply_attack_pose()
	_apply_damage_tint()


func _apply_direction_assets(direction: String) -> void:
	for part in PARTS:
		var texture := load("%s/%s/%s.png" % [ASSET_ROOT, direction, part]) as Texture2D
		assert(texture != null, "Missing Sacrifice Medic rig part: %s/%s" % [direction, part])
		(_sprites[part] as Sprite2D).texture = texture
	_layout_rig(direction)
	_apply_depth_order(direction)
	for bone in _animated_bones():
		bone.rotation = 0.0
		bone.rest = bone.transform
	_rest_positions.clear()
	for bone in _animated_bones():
		_rest_positions[bone] = bone.position


func _layout_rig(direction: String) -> void:
	var side_view := direction == "left" or direction == "right"
	var torso_size := _texture_size("torso")
	var head_size := _texture_size("head")
	var mech_upper_size := _texture_size("mech_upper")
	var mech_forearm_size := _texture_size("mech_forearm")
	var organic_upper_size := _texture_size("organic_upper")
	var organic_forearm_size := _texture_size("organic_forearm")
	var thigh_near_size := _texture_size("thigh_near")
	var thigh_far_size := _texture_size("thigh_far")
	var shin_near_size := _texture_size("shin_near")
	var shin_far_size := _texture_size("shin_far")
	var coat_near_size := _texture_size("coat_near")
	var coat_far_size := _texture_size("coat_far")
	var lantern_size := _texture_size("lantern")
	var leg_length := maxf(
		thigh_near_size.y + shin_near_size.y,
		thigh_far_size.y + shin_far_size.y,
	) - (
		HIP_TOP_INSET
		+ LEG_KNEE_OVERLAP
		+ LOWER_LEG_TOP_INSET
		- FOOT_BASELINE_OFFSET
	)
	_hips.position = Vector2(0.0, -leg_length)
	_torso.position = Vector2.ZERO
	(_sprites["torso"] as Sprite2D).position = Vector2(0.0, -torso_size.y * 0.5 + 14.0)
	# Sink the long neck tab into the collar. Only the short painted neck between
	# the jaw and collar remains visible; the rest is still available as overlap
	# when the head turns.
	_head.position = Vector2(0.0, -torso_size.y + HEAD_COLLAR_INSET)
	(_sprites["head"] as Sprite2D).position = Vector2(0.0, -head_size.y * 0.5 + 14.0)
	var hip_spread := 13.0 if side_view else 34.0
	_layout_leg(
		_left_leg,
		_left_lower_leg,
		_sprites["thigh_near"],
		_sprites["shin_near"],
		-hip_spread,
	)
	_layout_leg(
		_right_leg,
		_right_lower_leg,
		_sprites["thigh_far"],
		_sprites["shin_far"],
		hip_spread,
	)
	# Shoulder pivots live inside the painted torso silhouette; the sprite overlap
	# hides the joint even at the largest walk/attack rotations.
	var shoulder_spread := 8.0 if side_view else torso_size.x * 0.22
	var shoulder_y := -torso_size.y + 122.0
	_layout_arm(
		_left_upper_arm,
		_left_forearm,
		_sprites["mech_upper"],
		_sprites["mech_forearm"],
		Vector2(-shoulder_spread, shoulder_y),
	)
	_layout_arm(
		_right_upper_arm,
		_right_forearm,
		_sprites["organic_upper"],
		_sprites["organic_forearm"],
		Vector2(shoulder_spread, shoulder_y),
	)
	_lantern.position = Vector2(
		12.0 if direction != "right" else -12.0,
		mech_forearm_size.y - HAND_ATTACHMENT_INSET,
	)
	(_sprites["lantern"] as Sprite2D).position = Vector2(0.0, lantern_size.y * 0.5 - 24.0)
	var coat_spread := 25.0 if side_view else 54.0
	_far_coat.position = Vector2(coat_spread, -12.0)
	_near_coat.position = Vector2(-coat_spread, -12.0)
	(_sprites["coat_far"] as Sprite2D).position = Vector2(0.0, coat_far_size.y * 0.5 - 18.0)
	(_sprites["coat_near"] as Sprite2D).position = Vector2(0.0, coat_near_size.y * 0.5 - 18.0)
	_left_upper_arm.length = mech_upper_size.y - ARM_ELBOW_OVERLAP
	_left_forearm.length = mech_forearm_size.y - HAND_ATTACHMENT_INSET
	_right_upper_arm.length = organic_upper_size.y - ARM_ELBOW_OVERLAP
	_right_forearm.length = organic_forearm_size.y - HAND_ATTACHMENT_INSET


func _layout_leg(
	upper: Bone2D,
	lower: Bone2D,
	upper_sprite: Sprite2D,
	lower_sprite: Sprite2D,
	x: float,
) -> void:
	var upper_size := Vector2(upper_sprite.texture.get_size())
	var lower_size := Vector2(lower_sprite.texture.get_size())
	upper.position = Vector2(x, -HIP_TOP_INSET)
	upper_sprite.position = Vector2(0.0, upper_size.y * 0.5 - 14.0)
	lower.position = Vector2(0.0, upper_size.y - LEG_KNEE_OVERLAP)
	lower_sprite.position = Vector2(0.0, lower_size.y * 0.5 - LOWER_LEG_TOP_INSET)
	upper.length = upper_size.y - LEG_KNEE_OVERLAP
	lower.length = lower_size.y - LOWER_LEG_TOP_INSET


func _layout_arm(
	upper: Bone2D,
	forearm: Bone2D,
	upper_sprite: Sprite2D,
	forearm_sprite: Sprite2D,
	shoulder: Vector2,
) -> void:
	var upper_size := Vector2(upper_sprite.texture.get_size())
	var forearm_size := Vector2(forearm_sprite.texture.get_size())
	upper.position = shoulder
	upper_sprite.position = Vector2(0.0, upper_size.y * 0.5 - 14.0)
	forearm.position = Vector2(0.0, upper_size.y - ARM_ELBOW_OVERLAP)
	forearm_sprite.position = Vector2(0.0, forearm_size.y * 0.5 - FOREARM_TOP_INSET)


func _apply_depth_order(direction: String) -> void:
	var front_view := direction == "front"
	var back_view := direction == "back"
	(_sprites["coat_far"] as Sprite2D).z_index = -8
	(_sprites["thigh_far"] as Sprite2D).z_index = -7
	(_sprites["shin_far"] as Sprite2D).z_index = -7
	if direction == "left":
		(_sprites["organic_upper"] as Sprite2D).z_index = -6
		(_sprites["organic_forearm"] as Sprite2D).z_index = -6
		(_sprites["mech_upper"] as Sprite2D).z_index = 3
		(_sprites["mech_forearm"] as Sprite2D).z_index = 3
	elif direction == "right":
		(_sprites["mech_upper"] as Sprite2D).z_index = -6
		(_sprites["mech_forearm"] as Sprite2D).z_index = -6
		(_sprites["organic_upper"] as Sprite2D).z_index = 3
		(_sprites["organic_forearm"] as Sprite2D).z_index = 3
	elif front_view:
		(_sprites["mech_upper"] as Sprite2D).z_index = -5
		(_sprites["organic_upper"] as Sprite2D).z_index = -5
		(_sprites["mech_forearm"] as Sprite2D).z_index = 2
		(_sprites["organic_forearm"] as Sprite2D).z_index = 2
	else:
		(_sprites["mech_upper"] as Sprite2D).z_index = 1
		(_sprites["organic_upper"] as Sprite2D).z_index = 1
		(_sprites["mech_forearm"] as Sprite2D).z_index = 2
		(_sprites["organic_forearm"] as Sprite2D).z_index = 2
	(_sprites["torso"] as Sprite2D).z_index = 0
	(_sprites["coat_near"] as Sprite2D).z_index = 1 if front_view else -1
	(_sprites["thigh_near"] as Sprite2D).z_index = 2
	(_sprites["shin_near"] as Sprite2D).z_index = 2
	(_sprites["lantern"] as Sprite2D).z_index = 4
	(_sprites["head"] as Sprite2D).z_index = -2 if back_view else 5


func _texture_size(part: String) -> Vector2:
	return Vector2((_sprites[part] as Sprite2D).texture.get_size())


func _animated_bones() -> Array[Bone2D]:
	return [
		_hips,
		_torso,
		_head,
		_left_leg,
		_left_lower_leg,
		_right_leg,
		_right_lower_leg,
		_left_upper_arm,
		_left_forearm,
		_right_upper_arm,
		_right_forearm,
		_lantern,
		_far_coat,
		_near_coat,
	]


func _hide_frame_sprite() -> void:
	if is_instance_valid(_player._body_sprite):
		_player._body_sprite.visible = false


func _apply_idle_pose(delta: float) -> void:
	var breath := sin(_idle_time * 2.15)
	var settle := 1.0 - exp(-delta * 10.0)
	_pose_position(_hips, Vector2(0.0, maxf(breath, 0.0) * 2.0), settle)
	_pose_rotation(_torso, breath * 0.009, settle)
	_pose_rotation(_head, -breath * 0.006, settle)
	_pose_rotation(_left_leg, -0.018, settle)
	_pose_rotation(_right_leg, 0.018, settle)
	_pose_rotation(_left_lower_leg, 0.0, settle)
	_pose_rotation(_right_lower_leg, 0.0, settle)
	_pose_rotation(_left_upper_arm, 0.028 + breath * 0.008, settle)
	_pose_rotation(_right_upper_arm, -0.028 - breath * 0.008, settle)
	_pose_rotation(_left_forearm, -0.018, settle)
	_pose_rotation(_right_forearm, 0.018, settle)
	_pose_rotation(_lantern, breath * 0.018, settle)
	_pose_rotation(_far_coat, -0.018 + breath * 0.006, settle)
	_pose_rotation(_near_coat, 0.018 - breath * 0.006, settle)


func _apply_walk_pose(speed_ratio: float, delta: float) -> void:
	var phase := _player._step_phase * TAU
	var stride := sin(phase)
	var opposite_stride := -stride
	var contact := pow(absf(cos(phase)), 4.0)
	var settle := 1.0 - exp(-delta * 18.0)
	var side_view := _direction == "left" or _direction == "right"
	var stride_amount := lerpf(0.085, 0.17 if side_view else 0.105, speed_ratio)
	var knee_amount := lerpf(0.04, 0.13 if side_view else 0.075, speed_ratio)
	var arm_amount := lerpf(0.07, 0.15 if side_view else 0.095, speed_ratio)
	_pose_position(_hips, Vector2(0.0, contact * 4.0 * speed_ratio), settle)
	_pose_rotation(_left_leg, stride * stride_amount, settle)
	_pose_rotation(_right_leg, opposite_stride * stride_amount, settle)
	_pose_rotation(_left_lower_leg, maxf(-stride, 0.0) * knee_amount, settle)
	_pose_rotation(_right_lower_leg, maxf(stride, 0.0) * knee_amount, settle)
	_pose_position(_left_leg, Vector2(0.0, maxf(stride, 0.0) * -8.0), settle)
	_pose_position(_right_leg, Vector2(0.0, maxf(-stride, 0.0) * -8.0), settle)
	_pose_rotation(_left_upper_arm, opposite_stride * arm_amount, settle)
	_pose_rotation(_right_upper_arm, stride * arm_amount, settle)
	_pose_rotation(_left_forearm, maxf(stride, 0.0) * 0.06, settle)
	_pose_rotation(_right_forearm, maxf(-stride, 0.0) * -0.06, settle)
	_pose_rotation(_torso, opposite_stride * 0.018 * speed_ratio, settle)
	_pose_rotation(_head, stride * 0.01 * speed_ratio, settle)
	_pose_rotation(_lantern, -stride * 0.12 * speed_ratio, settle)
	_pose_rotation(_far_coat, opposite_stride * 0.045 * speed_ratio - 0.02, settle)
	_pose_rotation(_near_coat, opposite_stride * 0.055 * speed_ratio + 0.02, settle)


func _apply_attack_pose() -> void:
	if _attack_weight <= 0.001:
		return
	var snap := sin((1.0 - _attack_weight) * PI)
	_torso.rotation += -0.09 * snap
	_left_upper_arm.rotation += -0.58 * snap
	_left_forearm.rotation += -0.34 * snap
	_right_upper_arm.rotation += 0.12 * snap
	_lantern.rotation += 0.18 * snap


func _apply_ik_pose(_delta: float) -> void:
	var aim := _aim_vector()
	var side := Vector2(-aim.y, aim.x)
	var recoil := sin((1.0 - _attack_weight) * PI) if _attack_weight > 0.0 else 0.0
	var chest := Vector2(0.0, -235.0)
	_ik_targets.clear()
	_cast_orb.visible = _ik_mode == IKDemoMode.CAST and _cast_orb_preview_enabled
	_ik_weapon.visible = _ik_mode == IKDemoMode.PISTOL or _ik_mode == IKDemoMode.RIFLE
	(_sprites["lantern"] as Sprite2D).visible = (
		_ik_mode == IKDemoMode.FREE or _ik_mode == IKDemoMode.PISTOL
	)

	match _ik_mode:
		IKDemoMode.PISTOL:
			var pistol_target := _right_upper_arm.position + aim * (190.0 - recoil * 22.0) + side * 24.0
			_apply_arm_ik(
				_right_upper_arm,
				_right_forearm,
				pistol_target,
				_bend_sign(false),
				_ik_blend,
			)
			_ik_targets["organic"] = pistol_target
			_pose_rotation(_left_upper_arm, 0.08, _ik_blend)
			_pose_rotation(_left_forearm, -0.16, _ik_blend)
			_pose_rotation(_lantern, -0.04, _ik_blend)
			_configure_weapon(false, pistol_target, aim)
		IKDemoMode.RIFLE:
			# Keep the butt at the shoulder while carrying both hands farther
			# forward. Both grips sit on the support side of the rifle so the
			# character presents the weapon instead of pinching it to the chest.
			var side_view := absf(aim.x) > 0.5
			var center_forward := (
				RIFLE_CENTER_FORWARD if side_view else RIFLE_CENTER_FORWARD_AXIAL
			)
			var front_forward := (
				RIFLE_FRONT_GRIP_FORWARD
				if side_view
				else RIFLE_FRONT_GRIP_FORWARD_AXIAL
			)
			var rifle_center := chest + aim * (center_forward - recoil * 18.0)
			var rear_grip := (
				rifle_center
				- aim * RIFLE_REAR_GRIP_BACK
				+ side * RIFLE_GRIP_DROP
			)
			var front_grip := (
				rifle_center
				+ aim * front_forward
				+ side * RIFLE_GRIP_DROP
			)
			_apply_arm_ik(
				_right_upper_arm,
				_right_forearm,
				rear_grip,
				_bend_sign(false),
				_ik_blend,
			)
			_apply_arm_ik(
				_left_upper_arm,
				_left_forearm,
				front_grip,
				_bend_sign(true),
				_ik_blend,
			)
			_ik_targets["organic"] = rear_grip
			_ik_targets["mech"] = front_grip
			_configure_weapon(true, rifle_center, aim)
		IKDemoMode.CAST:
			var pulse := sin(_idle_time * 4.2) * 10.0
			var orb_center := chest + aim * (150.0 + pulse)
			var mech_target := orb_center - side * 62.0 - aim * 18.0
			var organic_target := orb_center + side * 62.0 - aim * 18.0
			_apply_arm_ik(
				_left_upper_arm,
				_left_forearm,
				mech_target,
				_bend_sign(true),
				_ik_blend,
			)
			_apply_arm_ik(
				_right_upper_arm,
				_right_forearm,
				organic_target,
				_bend_sign(false),
				_ik_blend,
			)
			_ik_targets["mech"] = mech_target
			_ik_targets["organic"] = organic_target
			_cast_orb.position = _torso_target_to_rig(orb_center)
			_cast_orb.scale = Vector2.ONE * (1.0 + sin(_idle_time * 5.0) * 0.08)
		_:
			pass


func _apply_arm_ik(
	upper: Bone2D,
	forearm: Bone2D,
	target: Vector2,
	bend_sign: float,
	weight: float,
) -> void:
	var solution := solve_two_bone(
		upper.position,
		target,
		upper.length,
		forearm.length,
		bend_sign,
	)
	upper.rotation = lerp_angle(upper.rotation, solution.x, weight)
	forearm.rotation = lerp_angle(forearm.rotation, solution.y, weight)


static func solve_two_bone(
	root_position: Vector2,
	target_position: Vector2,
	upper_length: float,
	forearm_length: float,
	bend_sign: float,
) -> Vector2:
	var delta := target_position - root_position
	var minimum_reach := absf(upper_length - forearm_length) + 0.001
	var maximum_reach := upper_length + forearm_length - 0.001
	var distance := clampf(delta.length(), minimum_reach, maximum_reach)
	var target_angle := delta.angle()
	var shoulder_cosine := clampf(
		(upper_length * upper_length + distance * distance - forearm_length * forearm_length)
		/ (2.0 * upper_length * distance),
		-1.0,
		1.0,
	)
	var upper_axis_angle := target_angle + signf(bend_sign) * acos(shoulder_cosine)
	var elbow := root_position + Vector2.from_angle(upper_axis_angle) * upper_length
	var forearm_axis_angle := (target_position - elbow).angle()
	return Vector2(
		upper_axis_angle - PI * 0.5,
		forearm_axis_angle - upper_axis_angle,
	)


func _bend_sign(mechanical_arm: bool) -> float:
	if _direction == "right":
		return 1.0
	if _direction == "left":
		return -1.0
	return 1.0 if mechanical_arm else -1.0


func _aim_vector() -> Vector2:
	match _direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"back":
			return Vector2.UP
		_:
			return Vector2.DOWN


func _configure_weapon(rifle: bool, target: Vector2, aim: Vector2) -> void:
	if rifle:
		_ik_weapon_body.polygon = PackedVector2Array([
			Vector2(-RIFLE_STOCK_BACK, -14.0),
			Vector2(116.0, -10.0),
			Vector2(116.0, 10.0),
			Vector2(-RIFLE_STOCK_BACK, 14.0),
		])
		_ik_weapon_grip.polygon = PackedVector2Array([
			Vector2(-58.0, 8.0),
			Vector2(-37.0, 8.0),
			Vector2(-39.0, 48.0),
			Vector2(-60.0, 42.0),
		])
		_ik_weapon_foregrip.visible = true
		_ik_weapon_foregrip.polygon = PackedVector2Array([
			Vector2(64.0, 7.0),
			Vector2(88.0, 7.0),
			Vector2(88.0, 27.0),
			Vector2(64.0, 27.0),
		])
	else:
		_ik_weapon_body.polygon = PackedVector2Array([
			Vector2(-15.0, -17.0),
			Vector2(82.0, -12.0),
			Vector2(82.0, 12.0),
			Vector2(-15.0, 17.0),
		])
		_ik_weapon_grip.polygon = PackedVector2Array([
			Vector2(-9.0, 0.0),
			Vector2(11.0, 0.0),
			Vector2(4.0, 43.0),
			Vector2(-18.0, 36.0),
		])
		_ik_weapon_foregrip.visible = false
	_ik_weapon.position = _torso_target_to_rig(target)
	_ik_weapon.rotation = aim.angle()


func _torso_target_to_rig(target: Vector2) -> Vector2:
	return to_local(_torso.to_global(target))


func _apply_damage_tint() -> void:
	var tint := Color.WHITE
	if _player._hurt_flash > 0.0:
		tint = Color("ffb5ad")
	elif _player._heal_flash > 0.0:
		tint = Color("c8ffdc")
	modulate = tint


func _pose_position(bone: Bone2D, offset: Vector2, weight: float) -> void:
	var target: Vector2 = _rest_positions.get(bone, bone.position) + offset
	bone.position = bone.position.lerp(target, weight)


func _pose_rotation(bone: Bone2D, target: float, weight: float) -> void:
	bone.rotation = lerp_angle(bone.rotation, target, weight)


static func direction_from_facing(facing: Vector2) -> String:
	if absf(facing.x) > absf(facing.y):
		return "right" if facing.x > 0.0 else "left"
	return "front" if facing.y >= 0.0 else "back"


func current_direction() -> String:
	return _direction


func set_ik_demo_mode(mode: IKDemoMode, immediate := false) -> void:
	_ik_mode = mode
	_cast_orb_preview_enabled = _ik_mode == IKDemoMode.CAST
	if immediate:
		_ik_blend = 0.0 if _ik_mode == IKDemoMode.FREE else 1.0
	if _ik_mode == IKDemoMode.FREE:
		(_sprites["lantern"] as Sprite2D).visible = true
		_ik_weapon.visible = false
		_cast_orb.visible = false


func set_cast_orb_preview_enabled(enabled: bool) -> void:
	_cast_orb_preview_enabled = enabled
	if not enabled:
		_cast_orb.visible = false


func is_cast_orb_preview_enabled() -> bool:
	return _cast_orb_preview_enabled


func current_ik_demo_mode() -> IKDemoMode:
	return _ik_mode


func ik_hand_error(arm: String) -> float:
	if not _ik_targets.has(arm):
		return INF
	var upper := _left_upper_arm if arm == "mech" else _right_upper_arm
	var forearm := _left_forearm if arm == "mech" else _right_forearm
	var hand_global := forearm.to_global(Vector2(0.0, forearm.length))
	var hand_in_torso := _torso.to_local(hand_global)
	return hand_in_torso.distance_to(_ik_targets[arm])


func has_weapon_ik() -> bool:
	return (
		_ik_weapon != null
		and _cast_orb != null
		and _left_upper_arm.length > 0.0
		and _left_forearm.length > 0.0
		and _right_upper_arm.length > 0.0
		and _right_forearm.length > 0.0
	)


func has_forward_rifle_stance() -> bool:
	if _ik_mode != IKDemoMode.RIFLE:
		return false
	if not _ik_targets.has("organic") or not _ik_targets.has("mech"):
		return false
	var aim := _aim_vector()
	var shoulder_center := (_left_upper_arm.position + _right_upper_arm.position) * 0.5
	var rear_reach := ((_ik_targets["organic"] as Vector2) - shoulder_center).dot(aim)
	var grip_span := (
		(_ik_targets["mech"] as Vector2) - (_ik_targets["organic"] as Vector2)
	).dot(aim)
	var side_view := absf(aim.x) > 0.5
	return (
		grip_span >= (120.0 if side_view else 105.0)
		and (not side_view or rear_reach >= 120.0)
	)


func is_using_true_opposition() -> bool:
	var leg_sign := signf(_left_leg.rotation - _right_leg.rotation)
	var arm_sign := signf(_left_upper_arm.rotation - _right_upper_arm.rotation)
	return leg_sign != 0.0 and arm_sign != 0.0 and leg_sign != arm_sign


func is_fully_articulated() -> bool:
	return (
		_left_lower_leg != null
		and _right_lower_leg != null
		and _left_forearm != null
		and _right_forearm != null
		and _lantern != null
		and _sprites.size() == PARTS.size()
	)


func has_compact_proportions() -> bool:
	var torso_height := _texture_size("torso").y
	var mech_upper_height := _texture_size("mech_upper").y
	var thigh_height := _texture_size("thigh_near").y
	return (
		is_equal_approx(_head.position.y, -torso_height + HEAD_COLLAR_INSET)
		and is_equal_approx(
			_left_forearm.position.y,
			mech_upper_height - ARM_ELBOW_OVERLAP,
		)
		and is_equal_approx(
			_left_lower_leg.position.y,
			thigh_height - LEG_KNEE_OVERLAP,
		)
		and ARM_ELBOW_OVERLAP * visual_scale >= 3.0
		and LEG_KNEE_OVERLAP * visual_scale >= 3.0
	)
