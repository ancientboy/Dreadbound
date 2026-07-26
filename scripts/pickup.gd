class_name ResourcePickup
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const WORLD_FEEDBACK: Texture2D = preload("res://assets/art/vfx/world_feedback.png")
const MATERIAL_AFFIX_ATLAS: Texture2D = preload("res://assets/art/vfx/materials_enemy_affixes.png")

signal material_collected(material_id: String, amount: int)

enum Kind { BANDAGE, ECHO_SHARD, AMMO, SHELLS, SEDATIVE, STIMULANT, MATERIAL }

@export var kind := Kind.BANDAGE
@export var amount := 1
@export var material_id := ""

var _pulse := 0.0
var _redraw_accumulator := 0.0


func _ready() -> void:
	add_to_group("pickups")
	z_index = 10
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= 0.066:
		_redraw_accumulator = 0.0
		queue_redraw()


func collect(player: Player) -> bool:
	var accepted := false
	match kind:
		Kind.BANDAGE:
			accepted = player.add_bandages(amount)
		Kind.ECHO_SHARD:
			player.add_echo_shards(amount)
			accepted = true
		Kind.AMMO:
			accepted = player.add_ammo(amount)
		Kind.SHELLS:
			accepted = player.add_shells(amount)
		Kind.SEDATIVE:
			accepted = player.add_sedatives(amount)
		Kind.STIMULANT:
			accepted = player.add_stimulants(amount)
		Kind.MATERIAL:
			accepted = ExchangeEvolution.MATERIALS.has(material_id)
			if accepted:
				material_collected.emit(material_id, amount)
	if accepted:
		AudioDirector.play_at("pickup", global_position, 0.04)
		queue_free()
	return accepted


func _draw() -> void:
	var bob := sin(_pulse * 2.4) * 3.0
	var colors := [Color("8fc6a1"), Color("45d8c3"), Color("d0a75a"), Color("c77b52"), Color("8ca7c7"), Color("d18b9f"), Color("c892ff")]
	var color: Color = colors[int(kind)]
	draw_circle(Vector2(0, bob), 18.0 + sin(_pulse * 3.0) * 2.0, Color(color, 0.1))
	var atlas_index := _atlas_index()
	var material_index := _material_atlas_index()
	if material_index >= 0 and MATERIAL_AFFIX_ATLAS != null and MATERIAL_AFFIX_ATLAS.get_size() == Vector2(320, 128):
		draw_texture_rect_region(
			MATERIAL_AFFIX_ATLAS,
			Rect2(-24, -24 + bob, 48, 48),
			Rect2(material_index * 64, 0, 64, 64),
			Color(1.12, 1.12, 1.12, 1.0),
		)
	elif atlas_index >= 0 and WORLD_FEEDBACK != null and WORLD_FEEDBACK.get_size() == Vector2(256, 128):
		draw_texture_rect_region(
			WORLD_FEEDBACK,
			Rect2(-24, -24 + bob, 48, 48),
			Rect2((atlas_index % 4) * 64, (atlas_index / 4) * 64, 64, 64),
			Color(1.12, 1.12, 1.12, 1.0),
		)
	elif kind == Kind.BANDAGE:
		draw_rect(Rect2(-13, -9 + bob, 26, 18), Color("d1cbb5"))
		draw_rect(Rect2(-3, -9 + bob, 6, 18), Color("758f78"))
	elif kind == Kind.ECHO_SHARD or kind == Kind.MATERIAL:
		var points := PackedVector2Array([Vector2(0, -17 + bob), Vector2(12, bob), Vector2(0, 17 + bob), Vector2(-12, bob)])
		draw_colored_polygon(points, color)
	elif kind == Kind.AMMO or kind == Kind.SHELLS:
		draw_rect(Rect2(-15, -10 + bob, 30, 20), Color("4c4639"))
		for x in [-9, 0, 9]:
			draw_circle(Vector2(x, bob), 4.0, color)
	else:
		draw_rect(Rect2(-8, -16 + bob, 16, 32), Color("aeb7b0"))
		draw_rect(Rect2(-6, -12 + bob, 12, 20), color)
	var labels := ["绷带", "回响碎片", "手枪弹药", "霰弹", "镇静剂", "兴奋剂", "材料"]
	var label: String = str(ExchangeEvolution.MATERIALS.get(material_id, {}).get("name", "未知材料")) if kind == Kind.MATERIAL else labels[int(kind)]
	draw_string(UI_FONT, Vector2(-42, 38), label, HORIZONTAL_ALIGNMENT_CENTER, 84, 12, color)


func _atlas_index() -> int:
	match kind:
		Kind.BANDAGE: return 0
		Kind.ECHO_SHARD: return 1
		Kind.AMMO: return 2
		Kind.SHELLS: return 3
		Kind.SEDATIVE: return 4
		Kind.STIMULANT: return 5
		Kind.MATERIAL:
			if material_id == "tissue_sample":
				return 6
			if material_id == "medical_record":
				return 7
	return -1


func _material_atlas_index() -> int:
	if kind != Kind.MATERIAL:
		return -1
	match material_id:
		"stitch_core": return 0
		"flooded_circuit": return 1
		"ticket_stub": return 2
		"conductor_coil": return 3
	return -1
