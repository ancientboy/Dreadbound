class_name LayeredSkeletonCharacter
extends Skeleton2D

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

@export var visual_scale := 0.055

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


func _ready() -> void:
	scale = Vector2.ONE * visual_scale
	_apply_direction_assets(_direction)
	call_deferred("_hide_frame_sprite")


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
	) - 48.0
	_hips.position = Vector2(0.0, -leg_length)
	_torso.position = Vector2.ZERO
	(_sprites["torso"] as Sprite2D).position = Vector2(0.0, -torso_size.y * 0.5 + 14.0)
	# Both generated pieces contain a long hidden neck tab. Sink the head deeply
	# into the collar so the overlap remains invisible during head rotation.
	_head.position = Vector2(0.0, -torso_size.y + 92.0)
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
	_lantern.position = Vector2(12.0 if direction != "right" else -12.0, mech_forearm_size.y - 34.0)
	(_sprites["lantern"] as Sprite2D).position = Vector2(0.0, lantern_size.y * 0.5 - 24.0)
	var coat_spread := 25.0 if side_view else 54.0
	_far_coat.position = Vector2(coat_spread, -12.0)
	_near_coat.position = Vector2(-coat_spread, -12.0)
	(_sprites["coat_far"] as Sprite2D).position = Vector2(0.0, coat_far_size.y * 0.5 - 18.0)
	(_sprites["coat_near"] as Sprite2D).position = Vector2(0.0, coat_near_size.y * 0.5 - 18.0)
	_left_upper_arm.length = mech_upper_size.y - 28.0
	_left_forearm.length = mech_forearm_size.y - 28.0
	_right_upper_arm.length = organic_upper_size.y - 28.0
	_right_forearm.length = organic_forearm_size.y - 28.0


func _layout_leg(
	upper: Bone2D,
	lower: Bone2D,
	upper_sprite: Sprite2D,
	lower_sprite: Sprite2D,
	x: float,
) -> void:
	var upper_size := Vector2(upper_sprite.texture.get_size())
	var lower_size := Vector2(lower_sprite.texture.get_size())
	upper.position = Vector2(x, -16.0)
	upper_sprite.position = Vector2(0.0, upper_size.y * 0.5 - 14.0)
	lower.position = Vector2(0.0, upper_size.y - 28.0)
	lower_sprite.position = Vector2(0.0, lower_size.y * 0.5 - 14.0)
	upper.length = upper_size.y - 28.0
	lower.length = lower_size.y - 28.0


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
	forearm.position = Vector2(0.0, upper_size.y - 28.0)
	forearm_sprite.position = Vector2(0.0, forearm_size.y * 0.5 - 14.0)


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
