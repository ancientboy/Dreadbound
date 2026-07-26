class_name SignalAnchor
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const SIGNAL_ANCHOR_SPRITESHEET: Texture2D = preload("res://assets/art/characters/metro/signal_anchor_spritesheet.png")

var max_health := 75
var health := 75
var _fallback_combat_fx: CombatFX
var _body_sprite: Sprite2D
var _animation_time := 0.0
var _hurt_flash := 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("signal_anchors")
	_setup_body_sprite()
	queue_redraw()


func _process(delta: float) -> void:
	_animation_time += delta
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if is_instance_valid(_body_sprite):
		_body_sprite.frame_coords = Vector2i(int(_animation_time * 7.0) % 6, 0)
		_body_sprite.modulate = Color("ffb2a6") if _hurt_flash > 0.0 else Color.WHITE


func take_damage(amount: int, source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.18
	_get_combat_fx().enemy_hit(global_position, source_position.direction_to(global_position), amount >= 24, Color("79d6e9"))
	if health == 0:
		_get_combat_fx().enemy_defeat(global_position, Color("60cbe0"))
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		draw_circle(Vector2.ZERO, 34.0, Color(0.08, 0.18, 0.24, 0.95))
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color("5cc9e8"), 5.0)
		draw_line(Vector2(-22, 0), Vector2(22, 0), Color("e8b45f"), 5.0)
	draw_rect(Rect2(-36, -49, 72, 6), Color("20191a"))
	draw_rect(Rect2(-36, -49, 72.0 * float(health) / max_health, 6), Color("5cc9e8"))
	draw_string(UI_FONT, Vector2(-58, 57), "信号锚", HORIZONTAL_ALIGNMENT_CENTER, 116, 14, Color("91dcef"))


func _setup_body_sprite() -> void:
	if SIGNAL_ANCHOR_SPRITESHEET == null or SIGNAL_ANCHOR_SPRITESHEET.get_size() != Vector2(384, 256):
		push_warning("Signal Anchor sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = SIGNAL_ANCHOR_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -18)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)


func _get_combat_fx() -> CombatFX:
	# Unit tests can damage an anchor without a player-owned effect pool. Keep
	# the fallback attached so it is released with the anchor instead of leaking.
	if is_inside_tree():
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null and player.combat_fx != null:
			return player.combat_fx
	if _fallback_combat_fx == null:
		_fallback_combat_fx = CombatFX.new()
		add_child(_fallback_combat_fx)
	return _fallback_combat_fx
