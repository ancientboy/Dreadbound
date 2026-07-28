class_name RenderedAtlasCharacter
extends Node2D

const FRAME_SIZE := Vector2i(128, 128)
const DIRECTIONS := [&"front", &"left", &"back", &"right"]
const SOURCE_DIRECTIONS := {
	&"front": &"front",
	&"left": &"right",
	&"back": &"back",
	&"right": &"left",
}
const ANIMATION_FRAMES := {
	&"idle": 36,
	&"walk": 17,
	&"attack_melee": 19,
	&"hit": 5,
	&"death": 30,
}
const ANIMATION_COLUMNS := {
	&"idle": 18,
	&"walk": 17,
	&"attack_melee": 19,
	&"hit": 5,
	&"death": 30,
}
const ANIMATION_SPEEDS := {
	&"idle": 12.0,
	&"walk": 18.0,
	&"attack_melee": 36.0,
	&"hit": 18.0,
	&"death": 18.0,
}
const LOOPING_ANIMATIONS := {
	&"idle": true,
	&"walk": true,
	&"attack_melee": false,
	&"hit": false,
	&"death": false,
}
const ATLAS_TEXTURES := {
	&"idle_front": preload("res://assets/art/characters/rendered3d/base_drifter/idle_front.png"),
	&"idle_left": preload("res://assets/art/characters/rendered3d/base_drifter/idle_left.png"),
	&"idle_back": preload("res://assets/art/characters/rendered3d/base_drifter/idle_back.png"),
	&"idle_right": preload("res://assets/art/characters/rendered3d/base_drifter/idle_right.png"),
	&"walk_front": preload("res://assets/art/characters/rendered3d/base_drifter/walk_front.png"),
	&"walk_left": preload("res://assets/art/characters/rendered3d/base_drifter/walk_left.png"),
	&"walk_back": preload("res://assets/art/characters/rendered3d/base_drifter/walk_back.png"),
	&"walk_right": preload("res://assets/art/characters/rendered3d/base_drifter/walk_right.png"),
	&"attack_melee_front": preload("res://assets/art/characters/rendered3d/base_drifter/attack_melee_front.png"),
	&"attack_melee_left": preload("res://assets/art/characters/rendered3d/base_drifter/attack_melee_left.png"),
	&"attack_melee_back": preload("res://assets/art/characters/rendered3d/base_drifter/attack_melee_back.png"),
	&"attack_melee_right": preload("res://assets/art/characters/rendered3d/base_drifter/attack_melee_right.png"),
	&"hit_front": preload("res://assets/art/characters/rendered3d/base_drifter/hit_front.png"),
	&"hit_left": preload("res://assets/art/characters/rendered3d/base_drifter/hit_left.png"),
	&"hit_back": preload("res://assets/art/characters/rendered3d/base_drifter/hit_back.png"),
	&"hit_right": preload("res://assets/art/characters/rendered3d/base_drifter/hit_right.png"),
	&"death_front": preload("res://assets/art/characters/rendered3d/base_drifter/death_front.png"),
	&"death_left": preload("res://assets/art/characters/rendered3d/base_drifter/death_left.png"),
	&"death_back": preload("res://assets/art/characters/rendered3d/base_drifter/death_back.png"),
	&"death_right": preload("res://assets/art/characters/rendered3d/base_drifter/death_right.png"),
}

@export var ground_offset := Vector2(0.0, -12.0)
@export var display_scale := Vector2.ONE

var _player: Player
var _sprite: AnimatedSprite2D
var _active_one_shot := &""
var _attack_was_active := false
var _hurt_was_active := false


func _ready() -> void:
	assert(get_parent() is Player, "RenderedAtlasCharacter must be a child of Player")
	_player = get_parent() as Player
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.position = ground_offset
	_sprite.scale = display_scale
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)
	add_child(_sprite)
	call_deferred("_activate_presentation")


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_sprite):
		return
	var attack_is_active := _player._attack_flash > 0.0
	var hurt_is_active := _player._hurt_flash > 0.0
	if _player._dead:
		if _active_one_shot != &"death":
			_play_one_shot(&"death")
	elif hurt_is_active and not _hurt_was_active:
		_play_one_shot(&"hit")
	elif attack_is_active and not _attack_was_active:
		_play_one_shot(&"attack_melee")
	elif _active_one_shot.is_empty():
		_play_locomotion()
	_attack_was_active = attack_is_active
	_hurt_was_active = hurt_is_active
	_sprite.modulate = (
		Color("ffb5ad")
		if hurt_is_active
		else (Color("c8ffdc") if _player._heal_flash > 0.0 else Color.WHITE)
	)


func _activate_presentation() -> void:
	if is_instance_valid(_player._body_sprite):
		_player._body_sprite.hide()
	_play_locomotion()


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for logical_name in ANIMATION_FRAMES:
		for direction in DIRECTIONS:
			var animation_name := _animation_name(logical_name, direction)
			var source_name := _animation_name(
				logical_name,
				source_direction_for_logical(direction),
			)
			var texture := ATLAS_TEXTURES[source_name] as Texture2D
			var frame_count := int(ANIMATION_FRAMES[logical_name])
			var columns := int(ANIMATION_COLUMNS[logical_name])
			var rows := ceili(float(frame_count) / float(columns))
			assert(
				texture.get_size() == Vector2(FRAME_SIZE.x * columns, FRAME_SIZE.y * rows),
				"Rendered atlas dimensions do not match manifest: %s" % animation_name,
			)
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, float(ANIMATION_SPEEDS[logical_name]))
			frames.set_animation_loop(animation_name, bool(LOOPING_ANIMATIONS[logical_name]))
			for frame_index in frame_count:
				var frame_texture := AtlasTexture.new()
				frame_texture.atlas = texture
				frame_texture.region = Rect2(
					(frame_index % columns) * FRAME_SIZE.x,
					(frame_index / columns) * FRAME_SIZE.y,
					FRAME_SIZE.x,
					FRAME_SIZE.y,
				)
				frames.add_frame(animation_name, frame_texture)
	return frames


func _play_locomotion() -> void:
	var direction := direction_from_vector(_player.facing)
	var logical_name := &"walk" if _player.velocity.length() > 2.0 else &"idle"
	var animation_name := _animation_name(logical_name, direction)
	if _sprite.animation != animation_name or not _sprite.is_playing():
		_sprite.play(animation_name)


func _play_one_shot(logical_name: StringName) -> void:
	_active_one_shot = logical_name
	var direction := direction_from_vector(_player.facing)
	_sprite.play(_animation_name(logical_name, direction))


func _on_animation_finished() -> void:
	if _active_one_shot == &"death":
		_sprite.pause()
		_sprite.frame = maxi(0, _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1)
		return
	_active_one_shot = &""
	_play_locomotion()


static func direction_from_vector(value: Vector2) -> StringName:
	if absf(value.x) > absf(value.y):
		return &"right" if value.x > 0.0 else &"left"
	if value.y < 0.0:
		return &"back"
	return &"front"


static func source_direction_for_logical(direction: StringName) -> StringName:
	return SOURCE_DIRECTIONS.get(direction, direction) as StringName


static func _animation_name(logical_name: StringName, direction: StringName) -> StringName:
	return StringName("%s_%s" % [logical_name, direction])
