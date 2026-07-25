class_name Patient
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

@export var movement_speed := 82.0
@export var max_health := 70
@export var detection_range := 390.0
@export var attack_range := 44.0
@export var attack_damage := 18
@export var attack_cooldown := 1.25

var health := 70
var target: Player
var _attack_timer := 0.0
var _hurt_flash := 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	queue_redraw()


func _physics_process(delta: float) -> void:
	var had_hurt_flash := _hurt_flash > 0.0
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		return

	var distance := global_position.distance_to(target.global_position)
	if distance > detection_range * target.get_detection_multiplier():
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
	_hurt_flash = 0.2
	global_position += source_position.direction_to(global_position) * 18.0
	if health == 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var body_color := Color("a55d58") if _hurt_flash > 0.0 else Color("707a70")
	draw_rect(Rect2(-14, -18, 28, 40), body_color)
	draw_rect(Rect2(-12, -13, 24, 5), Color("9ba198"))
	draw_circle(Vector2(0, -25), 10.0, Color("8b9088"))
	draw_line(Vector2(-13, -4), Vector2(-23, 13), body_color, 7.0)
	draw_line(Vector2(13, -4), Vector2(23, 13), body_color, 7.0)
	if health < max_health:
		draw_rect(Rect2(-24, -44, 48, 5), Color("261b1a"))
		draw_rect(Rect2(-24, -44, 48.0 * float(health) / max_health, 5), Color("9f3e38"))
	draw_string(UI_FONT, Vector2(-35, 42), "病患", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color("8d9990"))
