class_name SanatoriumBoss
extends CharacterBody2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const STITCH_DIRECTOR_SPRITESHEET: Texture2D = preload("res://assets/art/characters/sanatorium/stitch_director_spritesheet.png")

@export var max_health := 420
var health := 420
var target: Player
var active := false
var phase_two := false
var _timer := 1.2
var _windup := 0.0
var _attack_index := 0
var _hurt_flash := 0.0
var boss_label := "缝合主任"
var history_damage_multiplier := 1.0
var history_effect := ""
var _walk_animation_time := 0.0
var _facing := Vector2.DOWN
var _body_sprite: Sprite2D
var _phase_visual_played := false


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	_setup_body_sprite()
	health = max_health
	visible = false
	set_physics_process(false)


func activate(player: Player) -> void:
	target = player
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()


func configure_history_variant(variant: Dictionary) -> void:
	boss_label = str(variant.get("name", boss_label))
	history_damage_multiplier = maxf(float(variant.get("damage", 1.0)), 1.0)
	history_effect = str(variant.get("effect", ""))
	set_meta("dreadbound_boss_phase", str(variant.get("phase", "")))
	set_meta("dreadbound_boss_effect", history_effect)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target) or target.health <= 0:
		velocity = Vector2.ZERO
		_sync_body_sprite(delta)
		return
	var entering_phase_two := not phase_two and health <= max_health / 2
	phase_two = health <= max_health / 2
	if entering_phase_two and not _phase_visual_played:
		_phase_visual_played = true
		_get_combat_fx().sanatorium_enemy_skill("director_mutation", global_position, Vector2.DOWN, 188.0, 0.72)
	_timer = maxf(_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if _windup > 0.0:
		_windup -= delta
		velocity = Vector2.ZERO
		_sync_body_sprite(delta)
		queue_redraw()
		if _windup <= 0.0:
			_execute_attack()
		return
	var distance := global_position.distance_to(target.global_position)
	var speed := 92.0 if phase_two else 68.0
	if _timer <= 0.0 and distance < 250.0:
		_windup = 0.65
		_get_combat_fx().attack_telegraph(global_position, 230.0 if _attack_index % 2 == 1 else 105.0, _windup, Color("f06b4e"))
		queue_redraw()
	else:
		velocity = global_position.direction_to(target.global_position) * speed
		move_and_slide()
	_sync_body_sprite(delta)


func _execute_attack() -> void:
	var distance := global_position.distance_to(target.global_position)
	if _attack_index % 2 == 0:
		_get_combat_fx().sanatorium_enemy_skill("director_sweep", global_position, global_position.direction_to(target.global_position), 176.0, 0.4)
		if distance <= 105.0:
			target.take_damage(int(round((32 if phase_two else 25) * history_damage_multiplier)), global_position)
	else:
		_get_combat_fx().sanatorium_enemy_skill("director_slam", global_position, Vector2.DOWN, 244.0, 0.5)
		if distance <= 230.0:
			target.take_damage(int(round(20 * history_damage_multiplier)), global_position)
	_attack_index += 1
	_timer = 1.15 if phase_two else 1.65


func take_damage(amount: int, _source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.18
	_get_combat_fx().enemy_hit(global_position, _source_position.direction_to(global_position), amount >= 28, Color("f0a475"))
	if health == 0:
		_get_combat_fx().enemy_defeat(global_position, Color("e98568"), true)
		queue_free()
	else:
		queue_redraw()


func _setup_body_sprite() -> void:
	if STITCH_DIRECTOR_SPRITESHEET == null or STITCH_DIRECTOR_SPRITESHEET.get_size() != Vector2(576, 384):
		push_warning("Stitch Director sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = STITCH_DIRECTOR_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -44)
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
	var frame := int(_walk_animation_time * (8.0 if phase_two else 5.0)) % 6 if velocity.length() > 2.0 else 0
	_body_sprite.frame_coords = Vector2i(frame, row)
	if _hurt_flash > 0.0:
		_body_sprite.modulate = Color("ffafa5")
	elif phase_two:
		_body_sprite.modulate = Color("ffc9bd")
	else:
		_body_sprite.modulate = Color.WHITE


func _draw() -> void:
	var warning_radius := 230.0 if _attack_index % 2 == 1 else 105.0
	if _windup > 0.0:
		draw_arc(Vector2.ZERO, warning_radius, 0.0, TAU, 64, Color(0.88, 0.16, 0.12, 0.55), 9.0)
	var color := Color("9b4d4e") if _hurt_flash > 0.0 else (Color("77383d") if phase_two else Color("475751"))
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		draw_circle(Vector2.ZERO, 42.0, color)
		draw_rect(Rect2(-32, -50, 64, 90), color)
		draw_circle(Vector2(0, -62), 23.0, Color("878077"))
		draw_circle(Vector2(-9, -65), 4.0, Color("39d7c2"))
		draw_circle(Vector2(9, -65), 4.0, Color("39d7c2"))
	draw_rect(Rect2(-80, -98, 160, 10), Color("1e1718"))
	draw_rect(Rect2(-80, -98, 160.0 * float(health) / max_health, 10), Color("a73f3a"))
	draw_string(UI_FONT, Vector2(-115, 72), boss_label, HORIZONTAL_ALIGNMENT_CENTER, 230, 18, Color("8ed9ef") if boss_label.begins_with("末班") else Color("c3b7a8"))
	if not history_effect.is_empty():
		draw_string(UI_FONT, Vector2(-90, 94), "历史能力：%s" % history_effect, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color("efb36f"))


func _get_combat_fx() -> CombatFX:
	if is_instance_valid(target) and target.combat_fx != null:
		return target.combat_fx
	return CombatFX.new()
