class_name FemaleDrifterRig
extends Node2D

# A deliberately small, runtime-built 2D rig.  Each visible limb is its own
# node and the weapon is parented to the hand mount, so this prototype proves
# the production rule: weapons follow the hand rather than being drawn beside
# the player as an unrelated decal.
const HEAD: Texture2D = preload("res://assets/art/characters/drifter/female_rig/head.webp")
const TORSO: Texture2D = preload("res://assets/art/characters/drifter/female_rig/torso.webp")
const LEFT_UPPER_ARM: Texture2D = preload("res://assets/art/characters/drifter/female_rig/left_upper_arm.webp")
const LEFT_FOREARM: Texture2D = preload("res://assets/art/characters/drifter/female_rig/left_forearm.webp")
const RIGHT_UPPER_ARM: Texture2D = preload("res://assets/art/characters/drifter/female_rig/right_upper_arm.webp")
const RIGHT_FOREARM: Texture2D = preload("res://assets/art/characters/drifter/female_rig/right_forearm.webp")
const LEFT_LEG: Texture2D = preload("res://assets/art/characters/drifter/female_rig/left_leg.webp")
const RIGHT_LEG: Texture2D = preload("res://assets/art/characters/drifter/female_rig/right_leg.webp")
const COAT_LEFT: Texture2D = preload("res://assets/art/characters/drifter/female_rig/coat_left.webp")
const COAT_RIGHT: Texture2D = preload("res://assets/art/characters/drifter/female_rig/coat_right.webp")
const BASIC_WEAPONS: Texture2D = preload("res://assets/art/weapons/basic_weapons.webp")

const ART_SCALE := 0.18

var _left_upper: Node2D
var _left_forearm: Node2D
var _right_upper: Node2D
var _right_forearm: Node2D
var _left_leg: Node2D
var _right_leg: Node2D
var _coat_left: Node2D
var _coat_right: Node2D
var _weapon_mount: Node2D
var _weapon: Sprite2D
var _time := 0.0


func _ready() -> void:
	name = "FemaleDrifterRig"
	scale = Vector2.ONE * ART_SCALE
	z_index = 1
	_add_piece("CoatLeft", COAT_LEFT, Vector2(-138, 46), -0.10, -1)
	_add_piece("CoatRight", COAT_RIGHT, Vector2(138, 46), 0.10, -1)
	_coat_left = get_node("CoatLeft")
	_coat_right = get_node("CoatRight")
	_add_piece("LeftLeg", LEFT_LEG, Vector2(-78, 95), -0.03, 0)
	_add_piece("RightLeg", RIGHT_LEG, Vector2(78, 95), 0.03, 0)
	_left_leg = get_node("LeftLeg")
	_right_leg = get_node("RightLeg")
	_add_piece("Torso", TORSO, Vector2(0, -33), 0.0, 1)
	_add_piece("Head", HEAD, Vector2(0, -178), 0.0, 2)
	_add_piece("LeftUpperArm", LEFT_UPPER_ARM, Vector2(-154, -94), -0.12, 2)
	_add_piece("RightUpperArm", RIGHT_UPPER_ARM, Vector2(154, -94), 0.12, 2)
	_left_upper = get_node("LeftUpperArm")
	_right_upper = get_node("RightUpperArm")
	_add_piece("LeftForearm", LEFT_FOREARM, Vector2(-207, 17), -0.13, 3)
	_add_piece("RightForearm", RIGHT_FOREARM, Vector2(207, 17), 0.13, 3)
	_left_forearm = get_node("LeftForearm")
	_right_forearm = get_node("RightForearm")
	_weapon_mount = Node2D.new()
	_weapon_mount.name = "WeaponMount"
	_weapon_mount.position = Vector2(16, 97)
	_right_forearm.add_child(_weapon_mount)
	_weapon = Sprite2D.new()
	_weapon.name = "Weapon"
	_weapon.texture = BASIC_WEAPONS
	_weapon.hframes = 3
	_weapon.scale = Vector2.ONE * 2.25
	_weapon.position = Vector2(12, 18)
	_weapon.rotation = 0.65
	_weapon.z_index = 1
	_weapon_mount.add_child(_weapon)


func _add_piece(piece_name: String, texture: Texture2D, position_in_rig: Vector2, rotation_in_rig: float, piece_z: int) -> void:
	var pivot := Node2D.new()
	pivot.name = piece_name
	pivot.position = position_in_rig
	pivot.rotation = rotation_in_rig
	pivot.z_index = piece_z
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pivot.add_child(sprite)
	add_child(pivot)


func sync_visual(facing: Vector2, moving: bool, attack_flash: float, weapon_index: int, hurt: bool, healed: bool, delta: float) -> void:
	_time += delta
	# The prototype uses a full, readable front rig.  It rotates as a unit for
	# top-down navigation; the finalized production template will supply four
	# authored angle sets while retaining this identical bone/weapon hierarchy.
	rotation = facing.angle() - PI * 0.5
	var walk := sin(_time * 10.0) if moving else 0.0
	_left_upper.rotation = -0.14 + walk * 0.20
	_right_upper.rotation = 0.14 - walk * 0.20 - (0.30 if attack_flash > 0.0 else 0.0)
	_left_forearm.rotation = -0.12 + walk * 0.28
	_right_forearm.rotation = 0.12 - walk * 0.28 - (0.48 if attack_flash > 0.0 else 0.0)
	_left_leg.rotation = walk * 0.12
	_right_leg.rotation = -walk * 0.12
	_coat_left.rotation = -0.10 - walk * 0.07
	_coat_right.rotation = 0.10 + walk * 0.07
	_weapon.frame = clampi(weapon_index, 0, 2)
	_weapon.modulate = Color("ffb5ad") if hurt else (Color("c8ffdc") if healed else Color.WHITE)
	modulate = Color("ffb5ad") if hurt else (Color("c8ffdc") if healed else Color.WHITE)
