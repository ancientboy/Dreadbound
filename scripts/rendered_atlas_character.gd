class_name RenderedAtlasCharacter
extends Node2D

const FRAME_SIZE := Vector2i(128, 128)
const DIRECTIONS := [&"front", &"left", &"back", &"right"]
const SKIN_PRESETS := [
	{
		"id": &"base_drifter",
		"label": "原始角色",
		"renderer": &"atlas",
	},
	{
		"id": &"armorer_demo_v1",
		"label": "武装师 · Blender样板",
		"renderer": &"atlas",
		"atlas_directory": "res://assets/art/characters/rendered3d/armorer_demo_v1",
		"direct_directions": true,
	},
	{
		"id": &"steadfast_demo_v1",
		"label": "坚守者 · Blender样板",
		"renderer": &"atlas",
		"atlas_directory": "res://assets/art/characters/rendered3d/steadfast_demo_v1",
		"direct_directions": true,
	},
	{
		"id": &"resonant_demo_v1",
		"label": "共鸣者 · Blender样板",
		"renderer": &"atlas",
		"atlas_directory": "res://assets/art/characters/rendered3d/resonant_demo_v1",
		"direct_directions": true,
	},
]
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
	&"bow_idle": true,
	&"bow_draw": true,
	&"bow_aim": true,
	&"bow_release": true,
	&"shield_raise": true,
	&"shield_block": true,
	&"shield_hit": true,
	&"shield_bash": true,
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
	&"bow_idle": 48,
	&"bow_draw": 41,
	&"bow_aim": 56,
	&"bow_release": 41,
	&"shield_raise": 33,
	&"shield_block": 33,
	&"shield_hit": 33,
	&"shield_bash": 33,
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
	&"bow_idle": 28,
	&"bow_draw": 28,
	&"bow_aim": 28,
	&"bow_release": 28,
	&"shield_raise": 28,
	&"shield_block": 28,
	&"shield_hit": 28,
	&"shield_bash": 28,
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
	&"bow_idle": 30.0,
	&"bow_draw": 30.0,
	&"bow_aim": 30.0,
	&"bow_release": 30.0,
	&"shield_raise": 30.0,
	&"shield_block": 30.0,
	&"shield_hit": 30.0,
	&"shield_bash": 30.0,
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
	&"bow_idle": true,
	&"bow_draw": false,
	&"bow_aim": true,
	&"bow_release": false,
	&"shield_raise": false,
	&"shield_block": true,
	&"shield_hit": false,
	&"shield_bash": false,
}
const HOLD_LAST_FRAME := {
	&"pistol_aim_down": true,
	&"pistol_aim": true,
	&"pistol_aim_up": true,
	&"bow_draw": true,
	&"shield_raise": true,
}
# Blender exposes Image.pixels from the lower-left corner. Bow and shield are
# the only current multi-row atlases packed through that API.
const BOTTOM_UP_GRID_ACTIONS := {
	&"bow_idle": true,
	&"bow_draw": true,
	&"bow_aim": true,
	&"bow_release": true,
	&"shield_raise": true,
	&"shield_block": true,
	&"shield_hit": true,
	&"shield_bash": true,
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
	&"bow_idle_front": preload("res://assets/art/characters/rendered3d/base_drifter/bow_idle_front.png"),
	&"bow_idle_left": preload("res://assets/art/characters/rendered3d/base_drifter/bow_idle_left.png"),
	&"bow_idle_back": preload("res://assets/art/characters/rendered3d/base_drifter/bow_idle_back.png"),
	&"bow_idle_right": preload("res://assets/art/characters/rendered3d/base_drifter/bow_idle_right.png"),
	&"bow_draw_front": preload("res://assets/art/characters/rendered3d/base_drifter/bow_draw_front.png"),
	&"bow_draw_left": preload("res://assets/art/characters/rendered3d/base_drifter/bow_draw_left.png"),
	&"bow_draw_back": preload("res://assets/art/characters/rendered3d/base_drifter/bow_draw_back.png"),
	&"bow_draw_right": preload("res://assets/art/characters/rendered3d/base_drifter/bow_draw_right.png"),
	&"bow_aim_front": preload("res://assets/art/characters/rendered3d/base_drifter/bow_aim_front.png"),
	&"bow_aim_left": preload("res://assets/art/characters/rendered3d/base_drifter/bow_aim_left.png"),
	&"bow_aim_back": preload("res://assets/art/characters/rendered3d/base_drifter/bow_aim_back.png"),
	&"bow_aim_right": preload("res://assets/art/characters/rendered3d/base_drifter/bow_aim_right.png"),
	&"bow_release_front": preload("res://assets/art/characters/rendered3d/base_drifter/bow_release_front.png"),
	&"bow_release_left": preload("res://assets/art/characters/rendered3d/base_drifter/bow_release_left.png"),
	&"bow_release_back": preload("res://assets/art/characters/rendered3d/base_drifter/bow_release_back.png"),
	&"bow_release_right": preload("res://assets/art/characters/rendered3d/base_drifter/bow_release_right.png"),
	&"shield_raise_front": preload("res://assets/art/characters/rendered3d/base_drifter/shield_raise_front.png"),
	&"shield_raise_left": preload("res://assets/art/characters/rendered3d/base_drifter/shield_raise_left.png"),
	&"shield_raise_back": preload("res://assets/art/characters/rendered3d/base_drifter/shield_raise_back.png"),
	&"shield_raise_right": preload("res://assets/art/characters/rendered3d/base_drifter/shield_raise_right.png"),
	&"shield_block_front": preload("res://assets/art/characters/rendered3d/base_drifter/shield_block_front.png"),
	&"shield_block_left": preload("res://assets/art/characters/rendered3d/base_drifter/shield_block_left.png"),
	&"shield_block_back": preload("res://assets/art/characters/rendered3d/base_drifter/shield_block_back.png"),
	&"shield_block_right": preload("res://assets/art/characters/rendered3d/base_drifter/shield_block_right.png"),
	&"shield_hit_front": preload("res://assets/art/characters/rendered3d/base_drifter/shield_hit_front.png"),
	&"shield_hit_left": preload("res://assets/art/characters/rendered3d/base_drifter/shield_hit_left.png"),
	&"shield_hit_back": preload("res://assets/art/characters/rendered3d/base_drifter/shield_hit_back.png"),
	&"shield_hit_right": preload("res://assets/art/characters/rendered3d/base_drifter/shield_hit_right.png"),
	&"shield_bash_front": preload("res://assets/art/characters/rendered3d/base_drifter/shield_bash_front.png"),
	&"shield_bash_left": preload("res://assets/art/characters/rendered3d/base_drifter/shield_bash_left.png"),
	&"shield_bash_back": preload("res://assets/art/characters/rendered3d/base_drifter/shield_bash_back.png"),
	&"shield_bash_right": preload("res://assets/art/characters/rendered3d/base_drifter/shield_bash_right.png"),
}
const WEAPON_LAYER_SPECS := {
	&"crowbar": {
		"directory": "res://assets/art/weapons/character_layers/service_crowbar",
		"prefix": "service_crowbar",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"echo_edge": {
		"directory": "res://assets/art/weapons/character_layers/echo_edge",
		"prefix": "echo_edge",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"insulated_crowbar": {
		"directory": "res://assets/art/weapons/character_layers/insulated_crowbar",
		"prefix": "insulated_crowbar",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"volatile_edge": {
		"directory": "res://assets/art/weapons/character_layers/volatile_edge",
		"prefix": "volatile_edge",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"director_reaper": {
		"directory": "res://assets/art/weapons/character_layers/director_reaper",
		"prefix": "director_reaper",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"director_reaper_awakened": {
		"directory": "res://assets/art/weapons/character_layers/director_reaper_awakened",
		"prefix": "director_reaper_awakened",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"director_reaper_final": {
		"directory": "res://assets/art/weapons/character_layers/director_reaper_final",
		"prefix": "director_reaper_final",
		"animations": [&"one_hand_melee_idle", &"attack_melee"],
	},
	&"balanced_pistol": {
		"directory": "res://assets/art/weapons/character_layers/balanced_pistol",
		"prefix": "balanced_pistol",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"breach_shotgun": {
		"directory": "res://assets/art/weapons/character_layers/breach_shotgun",
		"prefix": "breach_shotgun",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"nullpoint_sidearm": {
		"directory": "res://assets/art/weapons/character_layers/nullpoint_sidearm",
		"prefix": "nullpoint_sidearm",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"siege_core": {
		"directory": "res://assets/art/weapons/character_layers/siege_core",
		"prefix": "siege_core",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"conductor_railgun": {
		"directory": "res://assets/art/weapons/character_layers/conductor_railgun",
		"prefix": "conductor_railgun",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"conductor_railgun_awakened": {
		"directory": "res://assets/art/weapons/character_layers/conductor_railgun_awakened",
		"prefix": "conductor_railgun_awakened",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"conductor_railgun_final": {
		"directory": "res://assets/art/weapons/character_layers/conductor_railgun_final",
		"prefix": "conductor_railgun_final",
		"animations": [
			&"pistol_idle",
			&"pistol_aim_down",
			&"pistol_aim",
			&"pistol_aim_up",
			&"pistol_shoot",
			&"pistol_reload",
		],
	},
	&"mourning_bow": {
		"directory": "res://assets/art/weapons/character_layers/mourning_bow",
		"prefix": "mourning_bow",
		"animations": [&"bow_idle", &"bow_draw", &"bow_aim", &"bow_release"],
	},
	&"echo_staff": {
		"directory": "res://assets/art/weapons/character_layers/echo_staff",
		"prefix": "echo_staff",
		"animations": [
			&"spell_enter",
			&"spell_idle",
			&"spell_shoot",
			&"spell_exit",
		],
	},
	&"riot_shield": {
		"directory": "res://assets/art/weapons/character_layers/riot_shield",
		"prefix": "riot_shield",
		"animations": [
			&"shield_raise",
			&"shield_block",
			&"shield_hit",
			&"shield_bash",
		],
	},
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
	&"bow": {
		"directory": "res://assets/art/weapons/character_layers/standard_hunter_bow",
		"prefix": "standard_bow",
		"animations": [&"bow_idle", &"bow_draw", &"bow_aim", &"bow_release"],
	},
	&"shield": {
		"directory": "res://assets/art/weapons/character_layers/standard_guard_shield",
		"prefix": "standard_shield",
		"animations": [
			&"shield_raise",
			&"shield_block",
			&"shield_hit",
			&"shield_bash",
		],
	},
}

@export var ground_offset := Vector2(0.0, -12.0)
@export var display_scale := Vector2.ONE
@export var runtime_sync_enabled := true

var _player: Player
var _sprite: AnimatedSprite2D
var _weapon_sprite: AnimatedSprite2D
var _active_one_shot := &""
var _attack_was_active := false
var _hurt_was_active := false
var _preview_idle := &"idle"
var _preview_attack := &"attack_melee"
var _preview_weapon_family := &""
var _active_skin_id := &"base_drifter"
var _runtime_pathway := ""
var _runtime_weapon_item := ""
var _runtime_weapon_family := &""
var _runtime_show_weapon_layer := true


func _ready() -> void:
	assert(get_parent() is Player, "RenderedAtlasCharacter must be a child of Player")
	_player = get_parent() as Player
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.position = ground_offset
	_sprite.scale = display_scale
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.self_modulate = Color.WHITE
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
	call_deferred("_apply_skin_renderer")


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_sprite):
		return
	if runtime_sync_enabled:
		_sync_runtime_presentation()
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
				_source_direction_for_active_skin(logical_name, direction),
			)
			var texture := _atlas_texture_for_active_skin(source_name)
			assert(texture != null, "Missing character atlas: %s" % source_name)
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
				var atlas_row := frame_index / columns
				if BOTTOM_UP_GRID_ACTIONS.has(logical_name):
					atlas_row = rows - 1 - atlas_row
				frame_texture.region = Rect2(
					(frame_index % columns) * FRAME_SIZE.x,
					atlas_row * FRAME_SIZE.y,
					FRAME_SIZE.x,
					FRAME_SIZE.y,
				)
				frames.add_frame(animation_name, frame_texture)
	return frames


func _active_skin_preset() -> Dictionary:
	for preset in SKIN_PRESETS:
		if preset["id"] == _active_skin_id:
			return preset
	return SKIN_PRESETS[0]


func _source_direction_for_active_skin(
	logical_name: StringName,
	direction: StringName,
) -> StringName:
	var preset := _active_skin_preset()
	if bool(preset.get("direct_directions", false)):
		return direction
	return source_direction_for_animation(logical_name, direction)


func _atlas_texture_for_active_skin(source_name: StringName) -> Texture2D:
	var preset := _active_skin_preset()
	var directory := str(preset.get("atlas_directory", ""))
	if directory.is_empty():
		return ATLAS_TEXTURES[source_name] as Texture2D
	return load("%s/%s.png" % [directory, source_name]) as Texture2D


func _build_weapon_layer_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for family in WEAPON_LAYER_SPECS:
		var spec := WEAPON_LAYER_SPECS[family] as Dictionary
		for logical_name in spec["animations"] as Array:
			for direction in DIRECTIONS:
				var animation_name := _animation_name(logical_name, direction)
				var weapon_animation_name := weapon_layer_animation_name(
					family,
					animation_name,
				)
				# Weapon layers are exported with logical left/right names. They
				# must not inherit the legacy character atlas side correction.
				var texture_path := (
					"%s/%s_%s.png"
					% [spec["directory"], spec["prefix"], animation_name]
				)
				var texture := load(texture_path) as Texture2D
				assert(texture != null, "Missing weapon layer: %s" % texture_path)
				var frame_count := int(ANIMATION_FRAMES[logical_name])
				var columns := int(ANIMATION_COLUMNS[logical_name])
				var rows := ceili(float(frame_count) / float(columns))
				assert(
					texture.get_size() == Vector2(
						FRAME_SIZE.x * columns,
						FRAME_SIZE.y * rows,
					),
					"Weapon layer dimensions do not match: %s" % animation_name,
				)
				frames.add_animation(weapon_animation_name)
				frames.set_animation_speed(
					weapon_animation_name,
					float(ANIMATION_SPEEDS[logical_name]),
				)
				frames.set_animation_loop(
					weapon_animation_name,
					bool(LOOPING_ANIMATIONS[logical_name]),
				)
				for frame_index in frame_count:
					var frame_texture := AtlasTexture.new()
					frame_texture.atlas = texture
					var atlas_row := frame_index / columns
					if BOTTOM_UP_GRID_ACTIONS.has(logical_name):
						atlas_row = rows - 1 - atlas_row
					frame_texture.region = Rect2(
						(frame_index % columns) * FRAME_SIZE.x,
						atlas_row * FRAME_SIZE.y,
						FRAME_SIZE.x,
						FRAME_SIZE.y,
					)
					frames.add_frame(weapon_animation_name, frame_texture)
	return frames


func _sync_weapon_layer() -> void:
	if not is_instance_valid(_weapon_sprite) or not is_instance_valid(_sprite):
		return
	var weapon_animation := weapon_layer_animation_name(
		_preview_weapon_family,
		_sprite.animation,
	)
	var has_weapon_animation := _weapon_sprite.sprite_frames.has_animation(weapon_animation)
	_weapon_sprite.visible = (
		WEAPON_LAYER_SPECS.has(_preview_weapon_family)
		and has_weapon_animation
		and (not runtime_sync_enabled or _runtime_show_weapon_layer)
	)
	if not _weapon_sprite.visible:
		return
	_weapon_sprite.animation = weapon_animation
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
		&"crowbar", &"echo_edge", &"insulated_crowbar", &"volatile_edge", &"director_reaper", &"director_reaper_awakened", &"director_reaper_final":
			_preview_idle = &"one_hand_melee_idle"
			_preview_attack = &"attack_melee"
			_preview_weapon_family = family
		&"sword":
			_preview_idle = &"one_hand_melee_idle"
			_preview_attack = &"attack_melee"
			_preview_weapon_family = &"sword"
		&"pistol":
			_preview_idle = &"pistol_idle"
			_preview_attack = &"pistol_shoot"
			_preview_weapon_family = &"pistol"
		&"balanced_pistol", &"breach_shotgun", &"nullpoint_sidearm", &"siege_core", &"conductor_railgun", &"conductor_railgun_awakened", &"conductor_railgun_final":
			_preview_idle = &"pistol_idle"
			_preview_attack = &"pistol_shoot"
			_preview_weapon_family = family
		&"staff", &"echo_staff":
			_preview_idle = &"spell_idle"
			_preview_attack = &"spell_shoot"
			_preview_weapon_family = family
		&"bow", &"mourning_bow":
			_preview_idle = &"bow_idle"
			_preview_attack = &"bow_release"
			_preview_weapon_family = family
		&"shield", &"riot_shield":
			_preview_idle = &"shield_block"
			_preview_attack = &"shield_bash"
			_preview_weapon_family = family
		_:
			_preview_idle = &"idle"
			_preview_attack = &"attack_melee"
			_preview_weapon_family = &""
	_active_one_shot = &""
	_play_locomotion()


func play_preview_action(logical_name: StringName) -> bool:
	if not ANIMATION_FRAMES.has(logical_name):
		return false
	var skeleton := _skeleton_character()
	if skeleton != null and skeleton.is_action_library_enabled():
		skeleton.play_preview_action(logical_name)
	if logical_name == &"attack_melee" or String(logical_name).begins_with("one_hand_melee"):
		var family_spec: Dictionary = WEAPON_LAYER_SPECS.get(
			_preview_weapon_family,
			{},
		)
		var family_animations: Array = family_spec.get("animations", [])
		if not family_animations.has(logical_name):
			select_preview_family(&"sword")
	elif String(logical_name).begins_with("pistol"):
		var family_spec: Dictionary = WEAPON_LAYER_SPECS.get(
			_preview_weapon_family,
			{},
		)
		var family_animations: Array = family_spec.get("animations", [])
		if not family_animations.has(logical_name):
			select_preview_family(&"pistol")
	elif String(logical_name).begins_with("spell"):
		var family_spec: Dictionary = WEAPON_LAYER_SPECS.get(
			_preview_weapon_family,
			{},
		)
		var family_animations: Array = family_spec.get("animations", [])
		if not family_animations.has(logical_name):
			select_preview_family(&"staff")
	elif String(logical_name).begins_with("bow"):
		var family_spec: Dictionary = WEAPON_LAYER_SPECS.get(
			_preview_weapon_family,
			{},
		)
		var family_animations: Array = family_spec.get("animations", [])
		if not family_animations.has(logical_name):
			select_preview_family(&"bow")
	elif String(logical_name).begins_with("shield"):
		var family_spec: Dictionary = WEAPON_LAYER_SPECS.get(
			_preview_weapon_family,
			{},
		)
		var family_animations: Array = family_spec.get("animations", [])
		if not family_animations.has(logical_name):
			select_preview_family(&"shield")
	if bool(LOOPING_ANIMATIONS[logical_name]):
		_preview_idle = logical_name
		_active_one_shot = &""
		_play_locomotion()
	else:
		_play_one_shot(logical_name)
	return true


func selected_preview_attack() -> StringName:
	return _preview_attack


func owns_equipment_visuals() -> bool:
	return true


func runtime_weapon_family() -> StringName:
	return _runtime_weapon_family


func runtime_weapon_layer_visible() -> bool:
	return (
		runtime_sync_enabled
		and _runtime_show_weapon_layer
		and is_instance_valid(_weapon_sprite)
		and _weapon_sprite.visible
	)


func _sync_runtime_presentation() -> void:
	var state := get_node_or_null("/root/GameState") as GameProgress
	var pathway := str(state.selected_pathway) if state != null else ""
	var weapon_item := _player.equipped_weapon_item
	var family := _runtime_family_for_weapon(weapon_item, state)
	var desired_skin := _runtime_skin_for_pathway(pathway)
	_runtime_show_weapon_layer = pathway.is_empty()
	var presentation_changed := false
	if pathway != _runtime_pathway:
		_runtime_pathway = pathway
		presentation_changed = true
		if desired_skin != _active_skin_id:
			select_skin(desired_skin)
	if weapon_item != _runtime_weapon_item or family != _runtime_weapon_family:
		_runtime_weapon_item = weapon_item
		_runtime_weapon_family = family
		presentation_changed = true
		select_preview_family(family)
	# Profession skins keep a natural unarmed idle because their equipment is
	# intentionally invisible. The equipped weapon still selects the attack
	# action and VFX, so combat rules and weapon identity remain intact.
	if not pathway.is_empty() and _preview_idle != &"idle":
		_preview_idle = &"idle"
		if presentation_changed and _active_one_shot.is_empty():
			_play_locomotion()


func _runtime_skin_for_pathway(pathway: String) -> StringName:
	match pathway:
		"steadfast":
			return &"steadfast_demo_v1"
		"armorer":
			return &"armorer_demo_v1"
		"resonant":
			return &"resonant_demo_v1"
	return &"base_drifter"


func _runtime_family_for_weapon(
	weapon_item: String,
	state: GameProgress,
) -> StringName:
	if weapon_item.is_empty():
		return &"unarmed"
	if weapon_item == "director_reaper":
		var growth := state.get_relic_growth(weapon_item) if state != null else 0
		if growth >= 5:
			return &"director_reaper_final"
		if growth >= 3:
			return &"director_reaper_awakened"
		return &"director_reaper"
	if weapon_item == "conductor_railgun":
		var growth := state.get_relic_growth(weapon_item) if state != null else 0
		if growth >= 5:
			return &"conductor_railgun_final"
		if growth >= 3:
			return &"conductor_railgun_awakened"
		return &"conductor_railgun"
	if weapon_item == "service_crowbar":
		return &"crowbar"
	var direct_family := StringName(weapon_item)
	if WEAPON_LAYER_SPECS.has(direct_family):
		return direct_family
	return EquipmentDatabase.weapon_animation_family(weapon_item)


func select_skin(skin_id: StringName) -> bool:
	for preset in SKIN_PRESETS:
		if preset["id"] == skin_id:
			_active_skin_id = skin_id
			if is_instance_valid(_sprite):
				_sprite.sprite_frames = _build_sprite_frames()
			_apply_skin_renderer()
			_active_one_shot = &""
			_play_locomotion()
			return true
	return false


func set_body_layer_visible(value: bool) -> void:
	if is_instance_valid(_sprite):
		_sprite.visible = value


func _skeleton_character() -> UniversalHumanoidActionCharacter:
	if not is_instance_valid(get_parent()):
		return null
	return get_parent().get_node_or_null(
		"UniversalHumanoidActionCharacter"
	) as UniversalHumanoidActionCharacter


func _apply_skin_renderer() -> void:
	if not is_instance_valid(_sprite):
		return
	_sprite.self_modulate = Color.WHITE
	var preset := {}
	for option in SKIN_PRESETS:
		if option["id"] == _active_skin_id:
			preset = option
			break
	var use_skeleton: bool = preset.get("renderer", &"atlas") == &"skeleton"
	var skeleton := _skeleton_character()
	if skeleton != null:
		if use_skeleton:
			assert(skeleton.set_skin(str(preset.get("skeleton_skin", "base_armorer"))))
		skeleton.set_action_library_enabled(use_skeleton)
	else:
		set_body_layer_visible(not use_skeleton)
	if is_instance_valid(_weapon_sprite):
		# The authored transparent weapon atlases remain independent from skin
		# selection. Raise only that layer while the taller skeleton skin is active.
		_weapon_sprite.z_index = 20 if use_skeleton else 1


func selected_skin() -> StringName:
	return _active_skin_id


static func skin_options() -> Array:
	return SKIN_PRESETS.duplicate(true)



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


static func weapon_layer_animation_name(
	family: StringName,
	body_animation: StringName,
) -> StringName:
	if family in [&"sword", &"pistol", &"staff", &"bow", &"shield"]:
		return body_animation
	return StringName("%s__%s" % [family, body_animation])


static func _animation_name(logical_name: StringName, direction: StringName) -> StringName:
	return StringName("%s_%s" % [logical_name, direction])
