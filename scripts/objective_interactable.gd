class_name ObjectiveInteractable
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const SANATORIUM_PROPS: Texture2D = preload("res://assets/art/worlds/sanatorium/sanatorium_props.png")
const SANATORIUM_OBJECTIVE_LIGHTING: Texture2D = preload("res://assets/art/vfx/sanatorium_objective_lighting.png")
const METRO_PROPS: Texture2D = preload("res://assets/art/worlds/metro/metro_props.png")

enum Kind { RECORD, POWER, EXIT, FLOODGATE, NPC, SECRET }

@export var kind := Kind.RECORD
@export var objective_id := ""
@export var display_name := "INTERACTABLE"
@export var world_id := "sanatorium"

var completed := false
var active := false


func _ready() -> void:
	queue_redraw()


func get_prompt(records_found: int, power_online: bool, records_required := 3) -> String:
	match kind:
		Kind.RECORD:
			return "[E] 读取%s" % display_name
		Kind.POWER:
			if records_found < records_required:
				return "尚未解锁 // 需要全部目标（%d/%d）" % [records_found, records_required]
			return "[E] 启动%s" % display_name
		Kind.EXIT:
			if not power_online:
				return "尚未解锁 // 撤离线路未校准"
			return "[E] 撤离并返回终末回廊"
		Kind.FLOODGATE:
			return "水闸已开启" if completed else "[E] 开启应急水闸 · 清空低层通道"
		Kind.NPC:
			return "[E] 与%s交谈" % display_name
		Kind.SECRET:
			return "[E] 检查%s" % display_name
	return "[E] 交互"


func mark_complete() -> void:
	completed = true
	queue_redraw()


func mark_active() -> void:
	active = true
	queue_redraw()


func _draw() -> void:
	var color := _display_color()
	draw_circle(Vector2.ZERO, 44.0, Color(color, 0.06))
	var metro_prop_index := _metro_prop_index()
	if metro_prop_index >= 0 and METRO_PROPS != null and METRO_PROPS.get_size() == Vector2(512, 384):
		var draw_size := Vector2(112, 112) if kind in [Kind.EXIT, Kind.FLOODGATE] else Vector2(92, 92)
		draw_texture_rect_region(
			METRO_PROPS,
			Rect2(-draw_size.x * 0.5, -draw_size.y * 0.68, draw_size.x, draw_size.y),
			Rect2((metro_prop_index % 4) * 128, floori(float(metro_prop_index) / 4.0) * 128, 128, 128),
			Color(0.58, 0.62, 0.64, 0.76) if completed else (Color(0.82, 1.0, 0.96) if active else Color.WHITE),
		)
		_draw_objective_halo(color)
		draw_string(UI_FONT, Vector2(-110, 56), display_name, HORIZONTAL_ALIGNMENT_CENTER, 220, 12, color)
		return
	var objective_index := _objective_sprite_index()
	if objective_index >= 0 and SANATORIUM_OBJECTIVE_LIGHTING != null and SANATORIUM_OBJECTIVE_LIGHTING.get_size() == Vector2(512, 256):
		draw_texture_rect_region(
			SANATORIUM_OBJECTIVE_LIGHTING,
			Rect2(-56, -80, 112, 112),
			Rect2((objective_index % 4) * 128, (objective_index / 4) * 128, 128, 128),
			Color(0.58, 0.62, 0.6, 0.72) if completed else Color.WHITE,
		)
	else:
		var prop_index := _sanatorium_prop_index()
		if prop_index >= 0 and SANATORIUM_PROPS != null and SANATORIUM_PROPS.get_size() == Vector2(512, 384):
			draw_texture_rect_region(
				SANATORIUM_PROPS,
				Rect2(-48, -64, 96, 96),
				Rect2((prop_index % 4) * 128, (prop_index / 4) * 128, 128, 128),
				Color(0.58, 0.62, 0.6, 0.72) if completed else Color.WHITE,
			)
		else:
			draw_rect(Rect2(-19, -27, 38, 54), Color("15211f"))
			draw_rect(Rect2(-14, -21, 28, 20), color)
	_draw_objective_halo(color)
	draw_string(UI_FONT, Vector2(-110, 56), display_name, HORIZONTAL_ALIGNMENT_CENTER, 220, 12, color)


func _objective_sprite_index() -> int:
	if world_id != "sanatorium":
		return -1
	match kind:
		Kind.RECORD: return 1 if completed else 0
		Kind.EXIT: return 3 if active else 2
	return -1


func _draw_objective_halo(color: Color) -> void:
	if completed or SANATORIUM_OBJECTIVE_LIGHTING == null or SANATORIUM_OBJECTIVE_LIGHTING.get_size() != Vector2(512, 256):
		return
	draw_texture_rect_region(
		SANATORIUM_OBJECTIVE_LIGHTING,
		Rect2(-50, 10, 100, 50),
		Rect2(2 * 128, 128, 128, 128),
		Color(color, 0.62),
	)
	if kind == Kind.EXIT and active:
		draw_texture_rect_region(
			SANATORIUM_OBJECTIVE_LIGHTING,
			Rect2(-40, -108, 80, 150),
			Rect2(3 * 128, 128, 128, 128),
			Color(0.8, 1.0, 0.96, 0.48),
		)


func _sanatorium_prop_index() -> int:
	if world_id != "sanatorium":
		return -1
	match kind:
		Kind.POWER: return 5
	return -1


func _metro_prop_index() -> int:
	if world_id != "metro":
		return -1
	match kind:
		Kind.RECORD: return 4
		Kind.POWER: return 5
		Kind.EXIT: return 10
		Kind.FLOODGATE: return 6
		Kind.NPC: return 2
		Kind.SECRET: return 11
	return -1


func _display_color() -> Color:
	if completed:
		return Color("50625d")
	match kind:
		Kind.RECORD:
			return Color("39d9c0")
		Kind.POWER:
			return Color("b7b75d")
		Kind.EXIT:
			return Color("b55252")
		Kind.FLOODGATE:
			return Color("6eaee8")
		Kind.NPC:
			return Color("d5b66f")
		Kind.SECRET:
			return Color("a477d4")
	return Color.WHITE
