class_name Orderly
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")

@export var movement_speed := 58.0
@export var max_health := 150
@export var detection_range := 360.0
@export var attack_range := 82.0
@export var attack_damage := 28
@export var windup_duration := 0.85
@export var attack_cooldown := 1.8

var health := 150
var target: Player
var _cooldown := 0.0
var _windup := 0.0
var _hurt_flash := 0.0
var _last_seen_position := Vector2.ZERO
var _memory_timer := 0.0
var enemy_label := "护理员"


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("orderlies")
	health = max_health
	queue_redraw()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_memory_timer = maxf(_memory_timer - delta, 0.0)
	if not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(target.global_position)
	var effective_detection := detection_range * target.get_detection_multiplier()
	if distance <= effective_detection:
		_last_seen_position = target.global_position
		_memory_timer = 5.0
	if _windup > 0.0:
		velocity = Vector2.ZERO
		_windup -= delta
		queue_redraw()
		if _windup <= 0.0:
			_cooldown = attack_cooldown
			if global_position.distance_to(target.global_position) <= attack_range + 18.0:
				target.take_damage(attack_damage, global_position)
	elif distance <= attack_range and _cooldown <= 0.0:
		_windup = windup_duration
		queue_redraw()
	elif distance <= effective_detection:
		velocity = global_position.direction_to(target.global_position) * movement_speed
	elif _memory_timer > 0.0 and global_position.distance_to(_last_seen_position) > 22.0:
		velocity = global_position.direction_to(_last_seen_position) * movement_speed * 0.65
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func take_damage(amount: int, source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.18
	global_position += source_position.direction_to(global_position) * 8.0
	if health == 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var body := Color("a85a55") if _hurt_flash > 0.0 else Color("4e5955")
	if _windup > 0.0:
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 48, Color(0.82, 0.2, 0.16, 0.7), 7.0)
	draw_rect(Rect2(-20, -28, 40, 58), body)
	draw_circle(Vector2(0, -38), 14.0, Color("77736b"))
	for y in [-44, -38, -32]:
		draw_line(Vector2(-14, y), Vector2(14, y + 3), Color("b5ad98"), 4.0)
	draw_line(Vector2(-18, -4), Vector2(-34, 28), body, 10.0)
	draw_line(Vector2(18, -4), Vector2(34, 28), body, 10.0)
	draw_rect(Rect2(-28, -59, 56, 5), Color("261b1a"))
	draw_rect(Rect2(-28, -59, 56.0 * float(health) / max_health, 5), Color("9f3e38"))
	draw_string(UI_FONT, Vector2(-50, 52), enemy_label, HORIZONTAL_ALIGNMENT_CENTER, 100, 13, Color("d89b76") if enemy_label == "检票员" else Color("9aa49e"))
