class_name MartialArtistTrialCharacter
extends Node2D

const FRAME_SIZE := Vector2i(128, 128)
const FRAME_COUNT := 6
const GROUND_OFFSET := Vector2(0.0, -12.0)
const ATLAS_TEXTURES := {
	&"idle_front": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/idle_front.png"
	),
	&"walk_front": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/walk_front.png"
	),
	&"idle_left": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/idle_left.png"
	),
	&"walk_left": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/walk_left.png"
	),
}

@export var trial_enabled := true

var _player: Player
var _base_character: RenderedAtlasCharacter
var _base_sprite: AnimatedSprite2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	assert(get_parent() is Player, "MartialArtistTrialCharacter must be a child of Player")
	_player = get_parent() as Player
	_base_character = _player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.position = GROUND_OFFSET
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.sprite_frames = _build_sprite_frames()
	add_child(_sprite)
	call_deferred("_activate_trial")


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_sprite):
		return
	if not trial_enabled or _uses_base_one_shot():
		_show_base_character()
		return
	_show_trial_character()
	_play_locomotion()
	_sprite.modulate = Color("c8ffdc") if _player._heal_flash > 0.0 else Color.WHITE


func set_trial_enabled(enabled: bool) -> void:
	trial_enabled = enabled
	if not enabled:
		_show_base_character()


func is_trial_enabled() -> bool:
	return trial_enabled


func _activate_trial() -> void:
	if not is_instance_valid(_base_character):
		return
	_base_sprite = _base_character.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_play_locomotion()
	_show_trial_character()


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation_name in ATLAS_TEXTURES:
		var texture := ATLAS_TEXTURES[animation_name] as Texture2D
		assert(
			texture.get_size() == Vector2(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y),
			"Martial artist trial atlas dimensions do not match: %s" % animation_name,
		)
		frames.add_animation(animation_name)
		frames.set_animation_speed(
			animation_name,
			8.0 if String(animation_name).begins_with("idle") else 10.0,
		)
		frames.set_animation_loop(animation_name, true)
		for frame_index in FRAME_COUNT:
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = texture
			frame_texture.region = Rect2(
				frame_index * FRAME_SIZE.x,
				0,
				FRAME_SIZE.x,
				FRAME_SIZE.y,
			)
			frames.add_frame(animation_name, frame_texture)
	return frames


func _play_locomotion() -> void:
	var direction := RenderedAtlasCharacter.direction_from_vector(_player.facing)
	var logical_name := &"walk" if _player.velocity.length() > 2.0 else &"idle"
	var source_direction := &"left" if direction in [&"left", &"right"] else &"front"
	var animation_name := StringName("%s_%s" % [logical_name, source_direction])
	_sprite.flip_h = direction == &"right"
	if _sprite.animation != animation_name or not _sprite.is_playing():
		_sprite.play(animation_name)


func _uses_base_one_shot() -> bool:
	return _player._dead or _player._attack_flash > 0.0 or _player._hurt_flash > 0.0


func _show_trial_character() -> void:
	_sprite.show()
	if is_instance_valid(_base_sprite):
		_base_sprite.hide()


func _show_base_character() -> void:
	_sprite.hide()
	if is_instance_valid(_base_sprite):
		_base_sprite.show()
