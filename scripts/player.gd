class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal inventory_changed(bandages: int, echo_shards: int)
signal weapon_changed(weapon_name: String, ammo: int)

enum Weapon { MELEE, RANGED }

@export var movement_speed := 210.0
@export var max_health := 100
@export var attack_damage := 35
@export var attack_range := 76.0
@export var attack_cooldown := 0.48
@export var max_bandages := 3
@export var bandage_heal := 35
@export var ranged_damage := 25
@export var ranged_range := 430.0
@export var ranged_cooldown := 0.34
@export var max_ammo := 24

var health := 100
var facing := Vector2.DOWN
var _attack_timer := 0.0
var _attack_flash := 0.0
var _invulnerability_timer := 0.0
var _hurt_flash := 0.0
var _dead := false
var bandages := 0
var echo_shards := 0
var _heal_flash := 0.0
var current_weapon := Weapon.MELEE
var ammo := 6
var _shot_end := Vector2.ZERO


func _ready() -> void:
	_apply_permanent_upgrades()
	health = max_health
	health_changed.emit(health, max_health)
	inventory_changed.emit(bandages, echo_shards)
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()


func _apply_permanent_upgrades() -> void:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var stats: Dictionary = state.get_player_stats()
	max_health = int(stats.max_health)
	movement_speed = float(stats.movement_speed)
	attack_damage = int(stats.melee_damage)
	ranged_damage = int(stats.ranged_damage)
	bandage_heal = int(stats.bandage_heal)


func _physics_process(delta: float) -> void:
	var had_visual_effect := _attack_flash > 0.0 or _hurt_flash > 0.0 or _heal_flash > 0.0
	var previous_facing := facing
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_attack_flash = maxf(_attack_flash - delta, 0.0)
	_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_heal_flash = maxf(_heal_flash - delta, 0.0)
	if _dead:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wants_to_attack := Input.is_action_just_pressed("attack")
	var wants_to_use_item := Input.is_action_just_pressed("use_item")
	var wants_to_switch := Input.is_action_just_pressed("switch_weapon")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		if mobile_controls.movement_vector != Vector2.ZERO:
			input_direction = mobile_controls.movement_vector
		wants_to_attack = mobile_controls.consume_attack() or wants_to_attack
		wants_to_use_item = mobile_controls.consume_item() or wants_to_use_item
		wants_to_switch = mobile_controls.consume_switch_weapon() or wants_to_switch

	velocity = input_direction * movement_speed
	if input_direction != Vector2.ZERO:
		facing = input_direction.normalized()
	if wants_to_attack:
		try_attack()
	if wants_to_use_item:
		use_bandage()
	if wants_to_switch:
		switch_weapon()
	_collect_nearby_pickups()
	move_and_slide()
	if had_visual_effect or not facing.is_equal_approx(previous_facing):
		queue_redraw()


func try_attack() -> bool:
	if _dead or _attack_timer > 0.0:
		return false
	if current_weapon == Weapon.RANGED:
		return _try_ranged_attack()
	_attack_timer = attack_cooldown
	_attack_flash = 0.14
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() <= attack_range and facing.dot(offset.normalized()) >= 0.25:
			target.take_damage(attack_damage, global_position)
	queue_redraw()
	return true


func _try_ranged_attack() -> bool:
	if ammo <= 0:
		return false
	_attack_timer = ranged_cooldown
	_attack_flash = 0.11
	ammo -= 1
	var best_target: Node2D
	var best_distance := ranged_range
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var offset: Vector2 = target.global_position - global_position
		var distance := offset.length()
		if distance <= best_distance and facing.dot(offset.normalized()) >= 0.94:
			best_target = target
			best_distance = distance
	_shot_end = facing * ranged_range
	if best_target:
		_shot_end = best_target.global_position - global_position
		best_target.take_damage(ranged_damage, global_position)
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()
	return true


func take_damage(amount: int, source_position: Vector2) -> bool:
	if _dead or _invulnerability_timer > 0.0:
		return false
	health = maxi(health - amount, 0)
	_invulnerability_timer = 0.65
	_hurt_flash = 0.18
	var knockback := source_position.direction_to(global_position)
	global_position += knockback * 12.0
	health_changed.emit(health, max_health)
	if health == 0:
		_dead = true
		velocity = Vector2.ZERO
		died.emit()
	queue_redraw()
	return true


func add_bandages(amount: int) -> bool:
	if bandages >= max_bandages:
		return false
	bandages = mini(bandages + amount, max_bandages)
	inventory_changed.emit(bandages, echo_shards)
	return true


func add_echo_shards(amount: int) -> void:
	echo_shards += amount
	inventory_changed.emit(bandages, echo_shards)


func add_ammo(amount: int) -> bool:
	if ammo >= max_ammo:
		return false
	ammo = mini(ammo + amount, max_ammo)
	weapon_changed.emit(get_weapon_name(), ammo)
	return true


func switch_weapon() -> void:
	current_weapon = Weapon.RANGED if current_weapon == Weapon.MELEE else Weapon.MELEE
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()


func get_weapon_name() -> String:
	return "手枪" if current_weapon == Weapon.RANGED else "撬棍"


func use_bandage() -> bool:
	if _dead or bandages <= 0 or health >= max_health:
		return false
	bandages -= 1
	health = mini(health + bandage_heal, max_health)
	_heal_flash = 0.3
	health_changed.emit(health, max_health)
	inventory_changed.emit(bandages, echo_shards)
	queue_redraw()
	return true


func _collect_nearby_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and global_position.distance_to(pickup.global_position) <= 32.0:
			pickup.collect(self)


func _draw() -> void:
	if _attack_flash > 0.0:
		if current_weapon == Weapon.RANGED:
			draw_line(facing * 18.0, _shot_end, Color(0.45, 0.92, 0.82, 0.85), 3.0)
			draw_circle(_shot_end, 5.0, Color(0.75, 1.0, 0.9, 0.7))
		else:
			draw_arc(Vector2.ZERO, attack_range, facing.angle() - 0.55, facing.angle() + 0.55, 20, Color(0.82, 0.8, 0.55, 0.72), 8.0)

	var coat_color := Color("75a783") if _heal_flash > 0.0 else (Color("8a514d") if _hurt_flash > 0.0 else Color("56665b"))
	# Layered graybox silhouette: backpack, coat, head, flashlight and anomaly mark.
	draw_rect(Rect2(-15, -8, 30, 30), Color("35443d"), true)
	draw_rect(Rect2(-18, -5, 7, 25), Color("514a38"), true)
	draw_rect(Rect2(-13, -19, 26, 34), coat_color, true)
	draw_circle(Vector2(0, -24), 9.0, Color("292d2b"))
	draw_line(facing * 8.0, facing * 29.0, Color("d5d0a3"), 5.0)
	if current_weapon == Weapon.RANGED:
		draw_line(facing * 10.0, facing * 34.0, Color("5c7771"), 7.0)
	draw_circle(Vector2(-12, 3), 3.5, Color("36dbc0"))
	draw_circle(Vector2(-12, 3), 7.0, Color(0.21, 0.86, 0.75, 0.13))
