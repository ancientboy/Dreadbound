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
const DIRECT_SIDE_ACTIONS := {
	&"attack_melee": true,
	&"one_hand_melee_idle": true,
	&"pistol_idle": true,
	&"pistol_aim_down": true,
	&"pistol_aim": true,
	&"pistol_aim_up": true,
	&"pistol_shoot": true,
	&"pistol_reload": true,
	&"spell_enter": true,
	&"spell_idle": true,
	&"spell_shoot": true,
	&"spell_exit": true,
}
const ANIMATION_FRAMES := {
	&"idle": 36,
	&"walk": 17,
	&"attack_melee": 19,
	&"hit": 5,
	&"death": 30,
	&"one_hand_melee_idle": 21,
	&"pistol_idle": 21,
	&"pistol_aim_down": 3,
	&"pistol_aim": 3,
	&"pistol_aim_up": 3,
	&"pistol_shoot": 8,
	&"pistol_reload": 21,
	&"spell_enter": 7,
	&"spell_idle": 26,
	&"spell_shoot": 7,
	&"spell_exit": 6,
}
const ANIMATION_COLUMNS := {
	&"idle": 18,
	&"walk": 17,
	&"attack_melee": 19,
	&"hit": 5,
	&"death": 30,
	&"one_hand_melee_idle": 21,
	&"pistol_idle": 21,
	&"pistol_aim_down": 3,
	&"pistol_aim": 3,
	&"pistol_aim_up": 3,
	&"pistol_shoot": 8,
	&"pistol_reload": 21,
	&"spell_enter": 7,
	&"spell_idle": 26,
	&"spell_shoot": 7,
	&"spell_exit": 6,
}
const ANIMATION_SPEEDS := {
	&"idle": 12.0,
	&"walk": 18.0,
	&"attack_melee": 36.0,
	&"hit": 18.0,
	&"death": 18.0,
	&"one_hand_melee_idle": 12.0,
	&"pistol_idle": 12.0,
	&"pistol_aim_down": 12.0,
	&"pistol_aim": 12.0,
	&"pistol_aim_up": 12.0,
	&"pistol_shoot": 12.0,
	&"pistol_reload": 12.0,
	&"spell_enter": 12.0,
	&"spell_idle": 12.0,
	&"spell_shoot": 12.0,
	&"spell_exit": 12.0,
}
const LOOPING_ANIMATIONS := {
	&"idle": true,
	&"walk": true,
	&"attack_melee": false,
	&"hit": false,
	&"death": false,
	&"one_hand_melee_idle": true,
	&"pistol_idle": true,
	&"pistol_aim_down": false,
	&"pistol_aim": false,
	&"pistol_aim_up": false,
	&"pistol_shoot": false,
	&"pistol_reload": false,
	&"spell_enter": false,
	&"spell_idle": true,
	&"spell_shoot": false,
	&"spell_exit": false,
}
const HOLD_LAST_FRAME := {
	&"pistol_aim_down": true,
	&"pistol_aim": true,
	&"pistol_aim_up": true,
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
	&"one_hand_melee_idle_front": preload("res://assets/art/characters/rendered3d/base_drifter/one_hand_melee_idle_front.png"),
	&"one_hand_melee_idle_left": preload("res://assets/art/characters/rendered3d/base_drifter/one_hand_melee_idle_left.png"),
	&"one_hand_melee_idle_back": preload("res://assets/art/characters/rendered3d/base_drifter/one_hand_melee_idle_back.png"),
	&"one_hand_melee_idle_right": preload("res://assets/art/characters/rendered3d/base_drifter/one_hand_melee_idle_right.png"),
	&"pistol_idle_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_idle_front.png"),
	&"pistol_idle_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_idle_left.png"),
	&"pistol_idle_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_idle_back.png"),
	&"pistol_idle_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_idle_right.png"),
	&"pistol_aim_down_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_down_front.png"),
	&"pistol_aim_down_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_down_left.png"),
	&"pistol_aim_down_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_down_back.png"),
	&"pistol_aim_down_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_down_right.png"),
	&"pistol_aim_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_front.png"),
	&"pistol_aim_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_left.png"),
	&"pistol_aim_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_back.png"),
	&"pistol_aim_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_right.png"),
	&"pistol_aim_up_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_up_front.png"),
	&"pistol_aim_up_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_up_left.png"),
	&"pistol_aim_up_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_up_back.png"),
	&"pistol_aim_up_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_aim_up_right.png"),
	&"pistol_shoot_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_shoot_front.png"),
	&"pistol_shoot_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_shoot_left.png"),
	&"pistol_shoot_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_shoot_back.png"),
	&"pistol_shoot_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_shoot_right.png"),
	&"pistol_reload_front": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_reload_front.png"),
	&"pistol_reload_left": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_reload_left.png"),
	&"pistol_reload_back": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_reload_back.png"),
	&"pistol_reload_right": preload("res://assets/art/characters/rendered3d/base_drifter/pistol_reload_right.png"),
	&"spell_enter_front": preload("res://assets/art/characters/rendered3d/base_drifter/spell_enter_front.png"),
	&"spell_enter_left": preload("res://assets/art/characters/rendered3d/base_drifter/spell_enter_left.png"),
	&"spell_enter_back": preload("res://assets/art/characters/rendered3d/base_drifter/spell_enter_back.png"),
	&"spell_enter_right": preload("res://assets/art/characters/rendered3d/base_drifter/spell_enter_right.png"),
	&"spell_idle_front": preload("res://assets/art/characters/rendered3d/base_drifter/spell_idle_front.png"),
	&"spell_idle_left": preload("res://assets/art/characters/rendered3d/base_drifter/spell_idle_left.png"),
	&"spell_idle_back": preload("res://assets/art/characters/rendered3d/base_drifter/spell_idle_back.png"),
	&"spell_idle_right": preload("res://assets/art/characters/rendered3d/base_drifter/spell_idle_right.png"),
	&"spell_shoot_front": preload("res://assets/art/characters/rendered3d/base_drifter/spell_shoot_front.png"),
	&"spell_shoot_left": preload("res://assets/art/characters/rendered3d/base_drifter/spell_shoot_left.png"),
	&"spell_shoot_back": preload("res://assets/art/characters/rendered3d/base_drifter/spell_shoot_back.png"),
	&"spell_shoot_right": preload("res://assets/art/characters/rendered3d/base_drifter/spell_shoot_right.png"),
	&"spell_exit_front": preload("res://assets/art/characters/rendered3d/base_drifter/spell_exit_front.png"),
	&"spell_exit_left": preload("res://assets/art/characters/rendered3d/base_drifter/spell_exit_left.png"),
	&"spell_exit_back": preload("res://assets/art/characters/rendered3d/base_drifter/spell_exit_back.png"),
	&"spell_exit_right": preload("res://assets/art/characters/rendered3d/base_drifter/spell_exit_right.png"),
}
const WEAPON_LAYER_SPECS := {
	&"sword": {
		"directory": "res://assets/art/weapons/character_layers/standard_melee_sword",
		"prefix": "standard_sword",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"pistol": {
		"directory": "res://assets/art/weapons/character_layers/standard_service_pistol",
		"prefix": "standard_pistol",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"staff": {
		"directory": "res://assets/art/weapons/character_layers/standard_echo_staff",
		"prefix": "standard_staff",
		"animations": [
			&"spell_enter",
			&"spell_idle",
			&"spell_shoot",
			&"spell_exit",
		],
	},
}

@export var ground_offset := Vector2(0.0, -12.0)
@export var display_scale := Vector2.ONE

var _player: Player
var _sprite: AnimatedSprite2D
var _weapon_sprite: AnimatedSprite2D
var _active_one_shot := &""
var _attack_was_active := false
var _hurt_was_active := false
var _preview_idle := &"idle"
var _preview_attack := &"attack_melee"
var _preview_weapon_family := &""


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
	_weapon_sprite = AnimatedSprite2D.new()
	_weapon_sprite.name = "WeaponLayer"
	_weapon_sprite.position = ground_offset
	_weapon_sprite.scale = display_scale
	_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_weapon_sprite.sprite_frames = _build_weapon_layer_frames()
	_weapon_sprite.z_index = 1
	_weapon_sprite.hide()
	add_child(_weapon_sprite)
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
		_play_one_shot(_preview_attack)
	elif _active_one_shot.is_empty():
		_play_locomotion()
	_attack_was_active = attack_is_active
	_hurt_was_active = hurt_is_active
	_sprite.modulate = (
		Color("ffb5ad")
		if hurt_is_active
		else (Color("c8ffdc") if _player._heal_flash > 0.0 else Color.WHITE)
	)
	_sync_weapon_layer()


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
				source_direction_for_animation(logical_name, direction),
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


func _build_weapon_layer_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for family in WEAPON_LAYER_SPECS:
		var spec := WEAPON_LAYER_SPECS[family] as Dictionary
		for logical_name in spec["animations"] as Array:
			for direction in DIRECTIONS:
				var animation_name := _animation_name(logical_name, direction)
				# Weapon layers are exported with logical left/right names. They
				# must not inherit the legacy character atlas side correction.
				var texture_path := (
					"%s/%s_%s.png"
					% [spec["directory"], spec["prefix"], animation_name]
				)
				var texture := load(texture_path) as Texture2D
				assert(texture != null, "Missing weapon layer: %s" % texture_path)
				var frame_count := int(ANIMATION_FRAMES[logical_name])
				assert(
					texture.get_size() == Vector2(FRAME_SIZE.x * frame_count, FRAME_SIZE.y),
					"Weapon layer dimensions do not match: %s" % animation_name,
				)
				frames.add_animation(animation_name)
				frames.set_animation_speed(
					animation_name,
					float(ANIMATION_SPEEDS[logical_name]),
				)
				frames.set_animation_loop(
					animation_name,
					bool(LOOPING_ANIMATIONS[logical_name]),
				)
				for frame_index in frame_count:
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


func _sync_weapon_layer() -> void:
	if not is_instance_valid(_weapon_sprite) or not is_instance_valid(_sprite):
		return
	var has_weapon_animation := _weapon_sprite.sprite_frames.has_animation(_sprite.animation)
	_weapon_sprite.visible = (
		WEAPON_LAYER_SPECS.has(_preview_weapon_family)
		and has_weapon_animation
	)
	if not _weapon_sprite.visible:
		return
	_weapon_sprite.animation = _sprite.animation
	_weapon_sprite.frame = _sprite.frame
	_weapon_sprite.frame_progress = _sprite.frame_progress


func _play_locomotion() -> void:
	var direction := direction_from_vector(_player.facing)
	var logical_name := &"walk" if _player.velocity.length() > 2.0 else _preview_idle
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
	if bool(HOLD_LAST_FRAME.get(_active_one_shot, false)):
		_sprite.pause()
		_sprite.frame = maxi(0, _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1)
		return
	_active_one_shot = &""
	_play_locomotion()


func select_preview_family(family: StringName) -> void:
	match family:
		&"sword":
			_preview_idle = &"one_hand_melee_idle"
			_preview_attack = &"attack_melee"
			_preview_weapon_family = &"sword"
		&"pistol":
			_preview_idle = &"pistol_idle"
			_preview_attack = &"pistol_shoot"
			_preview_weapon_family = &"pistol"
		&"staff":
			_preview_idle = &"spell_idle"
			_preview_attack = &"spell_shoot"
			_preview_weapon_family = &"staff"
		_:
			_preview_idle = &"idle"
			_preview_attack = &"attack_melee"
			_preview_weapon_family = &""
	_active_one_shot = &""
	_play_locomotion()


func play_preview_action(logical_name: StringName) -> bool:
	if not ANIMATION_FRAMES.has(logical_name):
		return false
	if logical_name == &"attack_melee" or String(logical_name).begins_with("one_hand_melee"):
		select_preview_family(&"sword")
	elif String(logical_name).begins_with("pistol"):
		select_preview_family(&"pistol")
	elif String(logical_name).begins_with("spell"):
		select_preview_family(&"staff")
	if bool(LOOPING_ANIMATIONS[logical_name]):
		_preview_idle = logical_name
		_active_one_shot = &""
		_play_locomotion()
	else:
		_play_one_shot(logical_name)
	return true


func selected_preview_attack() -> StringName:
	return _preview_attack


static func direction_from_vector(value: Vector2) -> StringName:
	if absf(value.x) > absf(value.y):
		return &"right" if value.x > 0.0 else &"left"
	if value.y < 0.0:
		return &"back"
	return &"front"


static func source_direction_for_logical(direction: StringName) -> StringName:
	return SOURCE_DIRECTIONS.get(direction, direction) as StringName


static func source_direction_for_animation(
	logical_name: StringName,
	direction: StringName,
) -> StringName:
	if DIRECT_SIDE_ACTIONS.has(logical_name):
		return direction
	return source_direction_for_logical(direction)


static func _animation_name(logical_name: StringName, direction: StringName) -> StringName:
	return StringName("%s_%s" % [logical_name, direction])
