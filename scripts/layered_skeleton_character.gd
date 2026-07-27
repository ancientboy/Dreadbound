class_name LayeredSkeletonCharacter
extends Skeleton2D

@export var visual_scale := 0.075
@export var walk_cycles_per_second := 2.35

@onready var _player := get_parent() as Player
@onready var _hips := $Hips as Bone2D
@onready var _torso := $Hips/Torso as Bone2D
@onready var _head := $Hips/Torso/Head as Bone2D
@onready var _left_leg := $Hips/LeftLeg as Bone2D
@onready var _right_leg := $Hips/RightLeg as Bone2D
@onready var _left_upper_arm := $Hips/Torso/LeftUpperArm as Bone2D
@onready var _left_forearm := $Hips/Torso/LeftUpperArm/LeftForearm as Bone2D
@onready var _right_upper_arm := $Hips/Torso/RightUpperArm as Bone2D
@onready var _right_forearm := $Hips/Torso/RightUpperArm/RightForearm as Bone2D
@onready var _left_coat := $Hips/LeftCoat as Bone2D
@onready var _right_coat := $Hips/RightCoat as Bone2D

var _rest_positions: Dictionary = {}
var _idle_time := 0.0
var _attack_weight := 0.0
var _attack_was_active := false
var _look_sign := 1.0


func _ready() -> void:
	scale = Vector2.ONE * visual_scale
	for bone in _animated_bones():
		_rest_positions[bone] = bone.position
	call_deferred("_hide_frame_sprite")


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_hide_frame_sprite()
	_idle_time += delta
	var speed_ratio := clampf(
		_player.velocity.length() / maxf(_player.movement_speed, 1.0),
		0.0,
		1.0,
	)
	var moving := speed_ratio > 0.04
	var attack_active := _player._attack_flash > 0.0
	if attack_active and not _attack_was_active:
		_attack_weight = 1.0
	_attack_was_active = attack_active
	_attack_weight = move_toward(_attack_weight, 0.0, delta * 4.8)
	_update_facing()
	if moving:
		_apply_walk_pose(speed_ratio, delta)
	else:
		_apply_idle_pose(delta)
	_apply_attack_pose()
	_apply_damage_tint()


func _animated_bones() -> Array[Bone2D]:
	return [
		_hips,
		_torso,
		_head,
		_left_leg,
		_right_leg,
		_left_upper_arm,
		_left_forearm,
		_right_upper_arm,
		_right_forearm,
		_left_coat,
		_right_coat,
	]


func _hide_frame_sprite() -> void:
	if is_instance_valid(_player._body_sprite):
		_player._body_sprite.visible = false


func _update_facing() -> void:
	if absf(_player.facing.x) > 0.25:
		_look_sign = signf(_player.facing.x)
	scale.x = absf(visual_scale) * _look_sign
	scale.y = absf(visual_scale)


func _apply_idle_pose(delta: float) -> void:
	var breath := sin(_idle_time * 2.15)
	var settle := 1.0 - exp(-delta * 10.0)
	_pose_position(_hips, Vector2(0.0, maxf(breath, 0.0) * 2.2), settle)
	_pose_rotation(_torso, breath * 0.012, settle)
	_pose_rotation(_head, -breath * 0.009, settle)
	_pose_rotation(_left_leg, -0.025, settle)
	_pose_rotation(_right_leg, 0.025, settle)
	_pose_rotation(_left_upper_arm, 0.035 + breath * 0.012, settle)
	_pose_rotation(_right_upper_arm, -0.035 - breath * 0.012, settle)
	_pose_rotation(_left_forearm, -0.025, settle)
	_pose_rotation(_right_forearm, 0.025, settle)
	_pose_rotation(_left_coat, -0.025 + breath * 0.008, settle)
	_pose_rotation(_right_coat, 0.025 - breath * 0.008, settle)


func _apply_walk_pose(speed_ratio: float, delta: float) -> void:
	# One phase drives the whole skeleton: legs alternate, arms counter-swing,
	# and the planted foot remains lower while the passing foot retracts.
	var phase := _player._step_phase * TAU
	var stride := sin(phase)
	var contact := pow(absf(cos(phase)), 4.0)
	var stride_amount := lerpf(0.11, 0.19, speed_ratio)
	var arm_amount := lerpf(0.09, 0.17, speed_ratio)
	var settle := 1.0 - exp(-delta * 18.0)
	_pose_position(
		_hips,
		Vector2(stride * 5.0 * speed_ratio, contact * 5.0 * speed_ratio),
		settle,
	)
	_pose_rotation(_left_leg, stride * stride_amount, settle)
	_pose_rotation(_right_leg, -stride * stride_amount, settle)
	_pose_position(_left_leg, Vector2(0.0, stride * 13.0 * speed_ratio), settle)
	_pose_position(_right_leg, Vector2(0.0, -stride * 13.0 * speed_ratio), settle)
	_pose_rotation(_left_upper_arm, -stride * arm_amount, settle)
	_pose_rotation(_right_upper_arm, stride * arm_amount, settle)
	_pose_rotation(_left_forearm, maxf(stride, 0.0) * 0.055, settle)
	_pose_rotation(_right_forearm, -maxf(-stride, 0.0) * 0.055, settle)
	_pose_rotation(_torso, -stride * 0.025 * speed_ratio, settle)
	_pose_rotation(_head, stride * 0.014 * speed_ratio, settle)
	_pose_rotation(_left_coat, -stride * 0.065 * speed_ratio - 0.025, settle)
	_pose_rotation(_right_coat, -stride * 0.065 * speed_ratio + 0.025, settle)


func _apply_attack_pose() -> void:
	if _attack_weight <= 0.001:
		return
	var snap := sin((1.0 - _attack_weight) * PI)
	_torso.rotation += -0.12 * snap
	_head.rotation += 0.05 * snap
	_right_upper_arm.rotation += -0.72 * snap
	_right_forearm.rotation += -0.38 * snap
	_left_upper_arm.rotation += 0.16 * snap
	_left_coat.rotation += 0.07 * snap
	_right_coat.rotation += 0.11 * snap


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


func is_using_true_opposition() -> bool:
	var leg_sign := signf(_left_leg.rotation - _right_leg.rotation)
	var arm_sign := signf(_left_upper_arm.rotation - _right_upper_arm.rotation)
	return leg_sign != 0.0 and arm_sign != 0.0 and leg_sign != arm_sign
