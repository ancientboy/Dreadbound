class_name MartialArtistTrialCharacter
extends Node2D

const FRAME_SIZE := Vector2i(128, 128)
const FRAME_COUNT := 6
const GROUND_OFFSET := Vector2(0.0, -12.0)
const BASIC_WEAPONS: Texture2D = preload("res://assets/art/weapons/basic_weapons.png")
const EQUIPMENT_RUNTIME: Texture2D = preload("res://assets/art/weapons/equipment_runtime.png")
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
	&"idle_back": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/idle_back.png"
	),
	&"walk_back": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/walk_back.png"
	),
	&"attack_front": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/attack_front.png"
	),
	&"attack_left": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/attack_left.png"
	),
	&"attack_back": preload(
		"res://assets/art/characters/rendered3d/martial_artist_trial/attack_back.png"
	),
}

@export var trial_enabled := true

var _player: Player
var _base_character: RenderedAtlasCharacter
var _base_sprite: AnimatedSprite2D
var _sprite: AnimatedSprite2D
var _main_hand_sprite: Sprite2D
var _offhand_sprite: Sprite2D
var _active_one_shot := &""
var _attack_was_active := false
var _death_pose_active := false


func _ready() -> void:
	assert(get_parent() is Player, "MartialArtistTrialCharacter must be a child of Player")
	_player = get_parent() as Player
	_base_character = _player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.position = GROUND_OFFSET
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)
	add_child(_sprite)
	_main_hand_sprite = Sprite2D.new()
	_main_hand_sprite.name = "MainHandEquipment"
	_main_hand_sprite.z_index = 2
	_main_hand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_main_hand_sprite)
	_offhand_sprite = Sprite2D.new()
	_offhand_sprite.name = "OffHandEquipment"
	_offhand_sprite.z_index = 1
	_offhand_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_offhand_sprite)
	call_deferred("_activate_trial")


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_sprite):
		return
	if not trial_enabled:
		_show_base_character()
		return
	_show_trial_character()
	var attack_is_active := _player._attack_flash > 0.0
	if _player._dead:
		_show_death_pose()
	elif attack_is_active and not _attack_was_active:
		_play_attack()
	elif _active_one_shot == &"weapon_attack" and not attack_is_active:
		_active_one_shot = &""
		_play_locomotion()
	elif _active_one_shot.is_empty():
		_play_locomotion()
	_attack_was_active = attack_is_active
	_sync_equipment_visuals()
	_sprite.modulate = (
		Color("7b7f86")
		if _player._dead
		else (
			Color("ffb5ad")
			if _player._hurt_flash > 0.0
			else (Color("c8ffdc") if _player._heal_flash > 0.0 else Color.WHITE)
		)
	)


func set_trial_enabled(enabled: bool) -> void:
	trial_enabled = enabled
	if not enabled:
		_show_base_character()
	else:
		_active_one_shot = &""
		_attack_was_active = false
		_death_pose_active = false
		_sprite.rotation = 0.0
		_show_trial_character()
		_play_locomotion()
		_sync_equipment_visuals()
	_player.queue_redraw()


func is_trial_enabled() -> bool:
	return trial_enabled


func equipment_anchor(slot: StringName) -> Vector2:
	if not trial_enabled:
		var side := -1.0 if slot == &"off_hand" else 1.0
		return Vector2(0, -27) + _player.facing * 13.0 + _player.facing.orthogonal() * 5.0 * side
	var direction := RenderedAtlasCharacter.direction_from_vector(_player.facing)
	var anchors := {
		&"front": {&"main_hand": Vector2(-15, -28), &"off_hand": Vector2(15, -28)},
		&"back": {&"main_hand": Vector2(14, -30), &"off_hand": Vector2(-14, -30)},
		&"left": {&"main_hand": Vector2(-17, -29), &"off_hand": Vector2(-7, -31)},
		&"right": {&"main_hand": Vector2(17, -29), &"off_hand": Vector2(7, -31)},
	}
	var anchor: Vector2 = anchors[direction][slot]
	if _active_one_shot == &"attack" and slot == &"main_hand":
		var extension: float = [0.0, 3.0, 13.0, 5.0, 2.0, 0.0][_sprite.frame]
		anchor += _player.facing * extension
	return anchor


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
			(
				8.0
				if String(animation_name).begins_with("idle")
				else (24.0 if String(animation_name).begins_with("attack") else 10.0)
			),
		)
		frames.set_animation_loop(
			animation_name,
			not String(animation_name).begins_with("attack"),
		)
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
	var source_direction := &"left" if direction in [&"left", &"right"] else direction
	var animation_name := StringName("%s_%s" % [logical_name, source_direction])
	_sprite.flip_h = direction == &"right"
	if _sprite.animation != animation_name or not _sprite.is_playing():
		_sprite.play(animation_name)


func _play_attack() -> void:
	var direction := RenderedAtlasCharacter.direction_from_vector(_player.facing)
	var source_direction := &"left" if direction in [&"left", &"right"] else direction
	_sprite.flip_h = direction == &"right"
	# Every equipped weapon uses the clothed holding pose and moves the item from
	# its hand anchor. The old attack atlas is an unarmed punch and must never be
	# replayed for a crowbar, bow, staff, gun, or any other equipped item.
	_active_one_shot = &"weapon_attack"
	_sprite.play(StringName("idle_%s" % source_direction))
	_sprite.pause()
	_sprite.frame = 0


func _show_death_pose() -> void:
	if _death_pose_active:
		return
	_death_pose_active = true
	_active_one_shot = &"death_pose"
	var direction := RenderedAtlasCharacter.direction_from_vector(_player.facing)
	var source_direction := &"left" if direction in [&"left", &"right"] else direction
	_sprite.flip_h = direction == &"right"
	_sprite.play(StringName("idle_%s" % source_direction))
	_sprite.pause()
	_sprite.frame = 0


func _on_animation_finished() -> void:
	if _active_one_shot != &"attack":
		return
	_active_one_shot = &""
	_play_locomotion()


func _show_trial_character() -> void:
	_sprite.show()
	_main_hand_sprite.show()
	_offhand_sprite.show()
	if is_instance_valid(_base_sprite):
		_base_sprite.hide()


func _show_base_character() -> void:
	_sprite.hide()
	_main_hand_sprite.hide()
	_offhand_sprite.hide()
	if is_instance_valid(_base_sprite):
		_base_sprite.show()


func _sync_equipment_visuals() -> void:
	_sync_main_hand_visual()
	_sync_offhand_visual()
	var attack_active := _player._attack_flash > 0.0
	var profile := _player._weapon_attack_profile()
	var cast_id := str(profile.get("cast", ""))
	var main_position := equipment_anchor(&"main_hand")
	var main_rotation := _player.facing.angle() + PI * 0.25
	if _player.equipped_weapon_item == "mourning_bow":
		main_rotation = _player.facing.angle() - PI * 0.5
		if attack_active:
			main_position -= _player.facing * 5.0
			main_rotation -= 0.12
	elif _player.equipped_weapon_item == "echo_staff":
		main_rotation = _player.facing.angle() + PI * 0.5
		if attack_active:
			main_position += _player.facing * 10.0
			main_rotation += 0.1
	elif attack_active and cast_id in ["sweep", "heavy_sweep", "anomaly_sweep", "reaping_arc"]:
		main_position += _player.facing * 7.0
		main_rotation += 0.28
	_main_hand_sprite.position = main_position
	_main_hand_sprite.rotation = main_rotation
	_offhand_sprite.position = equipment_anchor(&"off_hand")
	_offhand_sprite.rotation = _player.facing.angle() - PI * 0.5


func _sync_main_hand_visual() -> void:
	match _player.equipped_weapon_item:
		"service_crowbar":
			_set_atlas_cell(_main_hand_sprite, BASIC_WEAPONS, 32, 0)
		"mourning_bow":
			_set_atlas_cell(_main_hand_sprite, EQUIPMENT_RUNTIME, 64, 0)
		"echo_staff":
			_set_atlas_cell(_main_hand_sprite, EQUIPMENT_RUNTIME, 64, 1)
		_:
			_main_hand_sprite.texture = null


func _sync_offhand_visual() -> void:
	match _player.demo_offhand_item:
		"riot_shield":
			_set_atlas_cell(_offhand_sprite, EQUIPMENT_RUNTIME, 64, 2)
			_offhand_sprite.scale = Vector2.ONE * 0.75
		"field_codex":
			_set_atlas_cell(_offhand_sprite, EQUIPMENT_RUNTIME, 64, 3)
			_offhand_sprite.scale = Vector2.ONE * 0.54
		_:
			_offhand_sprite.texture = null


func _set_atlas_cell(sprite: Sprite2D, atlas: Texture2D, cell_size: int, index: int) -> void:
	var current := sprite.texture as AtlasTexture
	var region := Rect2(index * cell_size, 0, cell_size, cell_size)
	if current != null and current.atlas == atlas and current.region == region:
		return
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	sprite.texture = texture
	sprite.scale = Vector2.ONE
