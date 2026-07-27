class_name PlayerFeelCamera
extends Camera2D

## Camera presentation for player locomotion. Position is reserved for movement
## look-ahead while offset is reserved for short, decaying combat shake.
@export var movement_offset_distance := 28.0
@export var movement_offset_smoothing := 6.5
@export var attack_shake_decay := 18.0

var _rest_position := Vector2.ZERO
var _shake_strength := 0.0
var _shake_duration := 0.0
var _shake_time_left := 0.0


func _ready() -> void:
	_rest_position = position


func _process(delta: float) -> void:
	var target_offset := Vector2.ZERO
	var followed_body := get_parent() as CharacterBody2D
	if followed_body != null and followed_body.velocity.length() > 8.0:
		var speed_ratio := clampf(
			followed_body.velocity.length() / maxf(float(followed_body.get("movement_speed")), 1.0),
			0.0,
			1.0,
		)
		target_offset = followed_body.velocity.normalized() * movement_offset_distance * speed_ratio
	var follow_weight := 1.0 - exp(-movement_offset_smoothing * delta)
	position = position.lerp(_rest_position + target_offset, follow_weight)
	_update_attack_shake(delta)


func add_attack_shake(strength: float, duration := 0.11) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(duration, 0.01)
	_shake_time_left = maxf(_shake_time_left, _shake_duration)


func _update_attack_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = offset.lerp(Vector2.ZERO, 1.0 - exp(-attack_shake_decay * delta))
		if offset.length_squared() < 0.01:
			offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var envelope := _shake_time_left / _shake_duration
	offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength),
	) * envelope
