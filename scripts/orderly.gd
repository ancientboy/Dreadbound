class_name Orderly
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const ORDERLY_SPRITESHEET: Texture2D = preload("res://assets/art/characters/sanatorium/orderly_spritesheet.png")

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
var _stagger_timer := 0.0
var _last_seen_position := Vector2.ZERO
var _memory_timer := 0.0
var enemy_label := "护理员"
var _walk_animation_time := 0.0
var _facing := Vector2.DOWN
var _body_sprite: Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("orderlies")
	_setup_body_sprite()
	health = max_health
	queue_redraw()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_stagger_timer = maxf(_stagger_timer - delta, 0.0)
	_memory_timer = maxf(_memory_timer - delta, 0.0)
	if not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		_sync_body_sprite(delta)
		return
	if _stagger_timer > 0.0:
		velocity = Vector2.ZERO
		_sync_body_sprite(delta)
		queue_redraw()
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
				(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_at("orderly_attack", global_position, 0.025)
				_get_combat_fx().sanatorium_enemy_skill("orderly_heavy", global_position, _facing, 108.0, 0.34)
				target.take_damage(attack_damage, global_position)
	elif distance <= attack_range and _cooldown <= 0.0:
		_windup = windup_duration
		(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_at("director_windup", global_position, 0.02)
		_get_combat_fx().attack_telegraph(global_position, attack_range, windup_duration, Color("ed875c"))
		queue_redraw()
	elif distance <= effective_detection:
		velocity = global_position.direction_to(target.global_position) * movement_speed
	elif _memory_timer > 0.0 and global_position.distance_to(_last_seen_position) > 22.0:
		velocity = global_position.direction_to(_last_seen_position) * movement_speed * 0.65
	else:
		velocity = Vector2.ZERO
	_sync_body_sprite(delta)
	move_and_slide()


func take_damage(amount: int, source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.18
	_stagger_timer = 0.2 if amount >= 24 else 0.1
	global_position += source_position.direction_to(global_position) * 8.0
	_get_combat_fx().enemy_hit(global_position, source_position.direction_to(global_position), amount >= 24, Color("e29b72"))
	if health == 0:
		_get_combat_fx().enemy_defeat(global_position, Color("d38468"))
		queue_free()
	else:
		queue_redraw()


func _setup_body_sprite() -> void:
	if ORDERLY_SPRITESHEET == null or ORDERLY_SPRITESHEET.get_size() != Vector2(288, 256):
		push_warning("Orderly sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = ORDERLY_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -28)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite(0.0)


func _sync_body_sprite(delta: float) -> void:
	if velocity.length() > 2.0:
		_facing = velocity.normalized()
		_walk_animation_time += delta
	else:
		_walk_animation_time = 0.0
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		return
	var row := 0
	if absf(_facing.x) > absf(_facing.y):
		row = 2 if _facing.x > 0.0 else 1
	elif _facing.y < 0.0:
		row = 3
	var frame := int(_walk_animation_time * 7.0) % 6 if velocity.length() > 2.0 else 0
	_body_sprite.frame_coords = Vector2i(frame, row)
	_body_sprite.modulate = Color("ffb5ad") if _hurt_flash > 0.0 else Color.WHITE


func _draw() -> void:
	var body := Color("a85a55") if _hurt_flash > 0.0 else Color("4e5955")
	if _windup > 0.0:
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 48, Color(0.82, 0.2, 0.16, 0.7), 7.0)
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		draw_rect(Rect2(-20, -28, 40, 58), body)
		draw_circle(Vector2(0, -38), 14.0, Color("77736b"))
		for y in [-44, -38, -32]:
			draw_line(Vector2(-14, y), Vector2(14, y + 3), Color("b5ad98"), 4.0)
		draw_line(Vector2(-18, -4), Vector2(-34, 28), body, 10.0)
		draw_line(Vector2(18, -4), Vector2(34, 28), body, 10.0)
	draw_rect(Rect2(-28, -59, 56, 5), Color("261b1a"))
	draw_rect(Rect2(-28, -59, 56.0 * float(health) / max_health, 5), Color("9f3e38"))
	draw_string(UI_FONT, Vector2(-50, 52), enemy_label, HORIZONTAL_ALIGNMENT_CENTER, 100, 13, Color("d89b76") if enemy_label == "检票员" else Color("9aa49e"))


func _get_combat_fx() -> CombatFX:
	if is_instance_valid(target) and target.combat_fx != null:
		return target.combat_fx
	return CombatFX.new()
