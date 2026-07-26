class_name Conductor
extends Orderly

var noise_provider: Callable
var route_provider: Callable
var _charge_windup := 0.0
var _charge_direction := Vector2.ZERO
var _charge_time := 0.0
var _heard_noise := 0


func _ready() -> void:
	enemy_label = "检票员"
	max_health = 130
	attack_damage = 24
	movement_speed = 54.0
	super._ready()
	add_to_group("metro_enemies")


func _physics_process(delta: float) -> void:
	var noise := int(noise_provider.call()) if noise_provider.is_valid() else 0
	if noise > _heard_noise:
		_heard_noise = noise
		_memory_timer = 7.0
		if is_instance_valid(target):
			_last_seen_position = target.global_position
	if _charge_windup > 0.0:
		_charge_windup -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if _charge_windup <= 0.0:
			_charge_time = 0.34
		return
	if _charge_time > 0.0:
		_charge_time -= delta
		velocity = _charge_direction * 430.0
		move_and_slide()
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < 52.0:
			target.take_damage(attack_damage, global_position)
			_charge_time = 0.0
		return
	if is_instance_valid(target) and _cooldown <= 0.0:
		var distance := global_position.distance_to(target.global_position)
		if noise >= 3 and distance >= 120.0 and distance <= 330.0:
			_charge_direction = global_position.direction_to(target.global_position)
			_charge_windup = 0.9
			_cooldown = 2.8
			queue_redraw()
			return
	super._physics_process(delta)


func _draw() -> void:
	super._draw()
	if _charge_windup > 0.0:
		draw_line(Vector2.ZERO, _charge_direction * 330.0, Color(1.0, 0.55, 0.2, 0.78), 9.0)
		draw_circle(Vector2(0, -38), 8.0, Color("f3a13b"))

