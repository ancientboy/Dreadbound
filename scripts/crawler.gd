class_name Crawler
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.woff")

@export var movement_speed := 148.0
@export var max_health := 35
@export var detection_range := 440.0
@export var attack_range := 36.0
@export var attack_damage := 10
@export var attack_cooldown := 0.78

var health := 35
var target: Player
var _attack_timer := 0.0
var _hurt_flash := 0.0
var _last_seen_position := Vector2.ZERO
var _memory_timer := 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("crawlers")
	health = max_health
	queue_redraw()


func _physics_process(delta: float) -> void:
	var had_hurt_flash := _hurt_flash > 0.0
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_memory_timer = maxf(_memory_timer - delta, 0.0)
	if not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= detection_range * target.get_detection_multiplier():
		_last_seen_position = target.global_position
		_memory_timer = 2.2
	if distance > detection_range * target.get_detection_multiplier():
		if _memory_timer > 0.0 and global_position.distance_to(_last_seen_position) > 14.0:
			velocity = global_position.direction_to(_last_seen_position) * movement_speed * 0.82
		else:
			velocity = Vector2.ZERO
	elif distance > attack_range:
		velocity = global_position.direction_to(target.global_position) * movement_speed
	else:
		velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			target.take_damage(attack_damage, global_position)
	move_and_slide()
	if had_hurt_flash:
		queue_redraw()


func take_damage(amount: int, source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.18
	global_position += source_position.direction_to(global_position) * 24.0
	if health == 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var color := Color("b65a55") if _hurt_flash > 0.0 else Color("59665e")
	_draw_body_ellipse(Vector2.ZERO, Vector2(24, 11), color)
	for side in [-1, 1]:
		draw_line(Vector2(side * 10, -3), Vector2(side * 29, -15), color, 5.0)
		draw_line(Vector2(side * 12, 4), Vector2(side * 31, 17), color, 5.0)
	draw_circle(Vector2(0, -7), 7.0, Color("777f78"))
	if health < max_health:
		draw_rect(Rect2(-22, -31, 44, 4), Color("261b1a"))
		draw_rect(Rect2(-22, -31, 44.0 * float(health) / max_health, 4), Color("9f3e38"))
	draw_string(UI_FONT, Vector2(-36, 35), "爬行者", HORIZONTAL_ALIGNMENT_CENTER, 72, 12, Color("839087"))


func _draw_body_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
