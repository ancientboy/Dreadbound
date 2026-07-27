class_name Patient
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const PATIENT_SPRITESHEET: Texture2D = preload("res://assets/art/characters/sanatorium/patient_spritesheet.png")

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
var _stagger_timer := 0.0
var _attack_windup := 0.0
var _last_seen_position := Vector2.ZERO
var _memory_timer := 0.0
var enemy_label := "病患"
var facing := Vector2.DOWN
var _walk_animation_time := 0.0
var _body_sprite: Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_setup_body_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var had_hurt_flash := _hurt_flash > 0.0
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_stagger_timer = maxf(_stagger_timer - delta, 0.0)
	_memory_timer = maxf(_memory_timer - delta, 0.0)
	if not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		return

	if _stagger_timer > 0.0:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= detection_range * target.get_detection_multiplier():
		_last_seen_position = target.global_position
		_memory_timer = 3.5
	if distance > detection_range * target.get_detection_multiplier():
		if _memory_timer > 0.0 and global_position.distance_to(_last_seen_position) > 18.0:
			velocity = global_position.direction_to(_last_seen_position) * movement_speed * 0.72
		else:
			velocity = Vector2.ZERO
	elif distance > attack_range:
		velocity = global_position.direction_to(target.global_position) * movement_speed
	else:
		velocity = Vector2.ZERO
		if _attack_windup > 0.0:
			_attack_windup = maxf(_attack_windup - delta, 0.0)
			if _attack_windup <= 0.0 and global_position.distance_to(target.global_position) <= attack_range + 12.0:
				_attack_timer = attack_cooldown
				(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_at("patient_attack", global_position, 0.03)
				_get_combat_fx().sanatorium_enemy_skill("patient_claw", global_position, facing, 82.0, 0.26)
				target.take_damage(attack_damage, global_position)
		elif _attack_timer <= 0.0:
			_attack_windup = 0.32
			(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_at("patient_windup", global_position, 0.025)
			_get_combat_fx().attack_telegraph(global_position, attack_range + 18.0, _attack_windup, Color("d66c59"))
			_get_combat_fx().sanatorium_enemy_skill("patient_grasp", global_position, facing, 72.0, _attack_windup)
		if _attack_timer <= 0.0 and _attack_windup <= 0.0:
			_attack_timer = attack_cooldown
	if velocity.length() > 2.0:
		facing = velocity.normalized()
		_walk_animation_time += delta
	elif is_instance_valid(target):
		facing = global_position.direction_to(target.global_position)
		_walk_animation_time = 0.0
	_sync_body_sprite()
	move_and_slide()
	if had_hurt_flash or velocity.length() > 2.0:
		queue_redraw()


func take_damage(amount: int, source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.2
	_stagger_timer = 0.16 if amount >= 24 else 0.08
	global_position += source_position.direction_to(global_position) * 18.0
	_get_combat_fx().enemy_hit(global_position, source_position.direction_to(global_position), amount >= 24)
	if health == 0:
		_get_combat_fx().enemy_defeat(global_position, Color("bb726a"))
		queue_free()
	else:
		queue_redraw()


func _setup_body_sprite() -> void:
	if PATIENT_SPRITESHEET == null or PATIENT_SPRITESHEET.get_size() != Vector2(288, 256):
		push_warning("Patient sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = PATIENT_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -26)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite()


func _sync_body_sprite() -> void:
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		return
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2 if facing.x > 0.0 else 1
	elif facing.y < 0.0:
		row = 3
	var frame := int(_walk_animation_time * 9.0) % 6 if velocity.length() > 2.0 else 0
	_body_sprite.frame_coords = Vector2i(frame, row)
	_body_sprite.modulate = Color("ffafa6") if _hurt_flash > 0.0 else Color.WHITE


func _draw() -> void:
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		var body_color := Color("9f3e38") if _hurt_flash > 0.0 else Color("7d9b76")
		draw_circle(Vector2(0, -42), 9.0, Color("c9c2ae"))
		draw_rect(Rect2(-13, -34, 26, 34), body_color)
		draw_line(Vector2(-8, -2), Vector2(-11, 8), Color("2b343b"), 7.0)
		draw_line(Vector2(8, -2), Vector2(11, 8), Color("2b343b"), 7.0)
		draw_circle(Vector2(12, -25), 3.0, Color("d0845a"))
	if health < max_health:
		draw_rect(Rect2(-24, -68, 48, 5), Color("261b1a"))
		draw_rect(Rect2(-24, -68, 48.0 * float(health) / max_health, 5), Color("9f3e38"))
	draw_string(UI_FONT, Vector2(-42, 42), enemy_label, HORIZONTAL_ALIGNMENT_CENTER, 84, 12, Color("76bdd0") if enemy_label == "溺行者" else Color("8d9990"))


func _get_combat_fx() -> CombatFX:
	if is_instance_valid(target) and target.combat_fx != null:
		return target.combat_fx
	return CombatFX.new()
