class_name Conductor
extends Orderly

const INSPECTOR_SPRITESHEET: Texture2D = preload("res://assets/art/characters/metro/inspector_spritesheet.png")

var noise_provider: Callable
var route_provider: Callable
var _charge_windup := 0.0
var _charge_direction := Vector2.ZERO
var _charge_time := 0.0
var _heard_noise := 0
var _intercept_target := Vector2.ZERO
var _intercept_timer := 0.0
var _intercept_cooldown := 0.0


func _ready() -> void:
	enemy_label = "检票员"
	max_health = 130
	attack_damage = 24
	movement_speed = 54.0
	super._ready()
	add_to_group("metro_enemies")


func _setup_body_sprite() -> void:
	if INSPECTOR_SPRITESHEET == null or INSPECTOR_SPRITESHEET.get_size() != Vector2(288, 256):
		push_warning("Inspector sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = INSPECTOR_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -28)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite(0.0)


func _physics_process(delta: float) -> void:
	_intercept_timer = maxf(_intercept_timer - delta, 0.0)
	_intercept_cooldown = maxf(_intercept_cooldown - delta, 0.0)
	var noise := int(noise_provider.call()) if noise_provider.is_valid() else 0
	if noise > _heard_noise:
		_heard_noise = noise
		_memory_timer = 7.0
		_choose_intercept_target()
		if is_instance_valid(target):
			_last_seen_position = target.global_position
	if _charge_windup > 0.0:
		_charge_windup -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if _charge_windup <= 0.0:
			_charge_time = 0.34
		return
	if _intercept_timer > 0.0 and _intercept_target != Vector2.ZERO:
		if global_position.distance_to(_intercept_target) > 28.0:
			velocity = global_position.direction_to(_intercept_target) * movement_speed * 1.15
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		queue_redraw()
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


func _choose_intercept_target() -> void:
	if not route_provider.is_valid() or _intercept_cooldown > 0.0:
		return
	var candidates: Array = route_provider.call()
	if candidates.is_empty():
		return
	var best_distance := INF
	for candidate in candidates:
		var position := Vector2(candidate)
		var distance := global_position.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			_intercept_target = position
	_intercept_timer = 7.0
	_intercept_cooldown = 12.0


func is_intercepting() -> bool:
	return _intercept_timer > 0.0


func intercept_target() -> Vector2:
	return _intercept_target


func _draw() -> void:
	super._draw()
	if _charge_windup > 0.0:
		draw_line(Vector2.ZERO, _charge_direction * 330.0, Color(1.0, 0.55, 0.2, 0.78), 9.0)
		draw_circle(Vector2(0, -38), 8.0, Color("f3a13b"))
	if _intercept_timer > 0.0:
		draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 32, Color(0.95, 0.45, 0.12, 0.7), 4.0)
