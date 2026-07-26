class_name SanatoriumBoss
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.woff")

@export var max_health := 420
var health := 420
var target: Player
var active := false
var phase_two := false
var _timer := 1.2
var _windup := 0.0
var _attack_index := 0
var boss_label := "缝合主任"


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	health = max_health
	visible = false
	set_physics_process(false)


func activate(player: Player) -> void:
	target = player
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		return
	phase_two = health <= max_health / 2
	_timer = maxf(_timer - delta, 0.0)
	if _windup > 0.0:
		_windup -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if _windup <= 0.0:
			_execute_attack()
		return
	var distance := global_position.distance_to(target.global_position)
	var speed := 92.0 if phase_two else 68.0
	if _timer <= 0.0 and distance < 250.0:
		_windup = 0.65
		queue_redraw()
	else:
		velocity = global_position.direction_to(target.global_position) * speed
		move_and_slide()


func _execute_attack() -> void:
	var distance := global_position.distance_to(target.global_position)
	if _attack_index % 2 == 0:
		if distance <= 105.0:
			target.take_damage(32 if phase_two else 25, global_position)
	else:
		if distance <= 230.0:
			target.take_damage(20, global_position)
	_attack_index += 1
	_timer = 1.15 if phase_two else 1.65


func take_damage(amount: int, _source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	if health == 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var warning_radius := 230.0 if _attack_index % 2 == 1 else 105.0
	if _windup > 0.0:
		draw_arc(Vector2.ZERO, warning_radius, 0.0, TAU, 64, Color(0.88, 0.16, 0.12, 0.55), 9.0)
	var color := Color("77383d") if phase_two else Color("475751")
	draw_circle(Vector2.ZERO, 42.0, color)
	draw_rect(Rect2(-32, -50, 64, 90), color)
	draw_circle(Vector2(0, -62), 23.0, Color("878077"))
	draw_circle(Vector2(-9, -65), 4.0, Color("39d7c2"))
	draw_circle(Vector2(9, -65), 4.0, Color("39d7c2"))
	draw_rect(Rect2(-80, -98, 160, 10), Color("1e1718"))
	draw_rect(Rect2(-80, -98, 160.0 * float(health) / max_health, 10), Color("a73f3a"))
	draw_string(UI_FONT, Vector2(-115, 72), boss_label, HORIZONTAL_ALIGNMENT_CENTER, 230, 18, Color("8ed9ef") if boss_label.begins_with("末班") else Color("c3b7a8"))
