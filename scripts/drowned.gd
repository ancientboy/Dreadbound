class_name Drowned
extends Patient

const DROWNED_SPRITESHEET: Texture2D = preload("res://assets/art/characters/metro/drowned_spritesheet.png")

var water_depth_provider: Callable
var water_depth := 0
var _water_fx_timer := 0.0


func _ready() -> void:
	enemy_label = "溺行者"
	movement_speed = 88.0
	max_health = 62
	super._ready()
	add_to_group("metro_enemies")


func _setup_body_sprite() -> void:
	if DROWNED_SPRITESHEET == null or DROWNED_SPRITESHEET.get_size() != Vector2(288, 256):
		push_warning("Drowned sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = DROWNED_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -26)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite()


func _physics_process(delta: float) -> void:
	water_depth = int(water_depth_provider.call(global_position)) if water_depth_provider.is_valid() else 0
	var dry_speed := 88.0
	movement_speed = dry_speed * (1.42 if water_depth > 0 else 1.0)
	_water_fx_timer = maxf(_water_fx_timer - delta, 0.0)
	if water_depth > 0 and velocity.length() > 8.0 and _water_fx_timer <= 0.0:
		_get_combat_fx().metro_enemy_skill("drowned_splash", global_position + Vector2(0, 12), facing, 76.0, 0.38)
		_water_fx_timer = 0.42
	super._physics_process(delta)


func _draw() -> void:
	super._draw()
