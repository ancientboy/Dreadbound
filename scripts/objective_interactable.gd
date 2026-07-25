class_name ObjectiveInteractable
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

enum Kind { RECORD, POWER, EXIT }

@export var kind := Kind.RECORD
@export var objective_id := ""
@export var display_name := "INTERACTABLE"

var completed := false


func _ready() -> void:
	queue_redraw()


func get_prompt(records_found: int, power_online: bool, records_required := 3) -> String:
	match kind:
		Kind.RECORD:
			return "[E] 读取%s" % display_name
		Kind.POWER:
			if records_found < records_required:
				return "尚未解锁 // 需要全部目标（%d/%d）" % [records_found, records_required]
			return "[E] 恢复疗养院电力"
		Kind.EXIT:
			if not power_online:
				return "尚未解锁 // 疗养院电力中断"
			return "[E] 撤离并返回终末回廊"
	return "[E] 交互"


func mark_complete() -> void:
	completed = true
	queue_redraw()


func _draw() -> void:
	var color := _display_color()
	draw_circle(Vector2.ZERO, 44.0, Color(color, 0.1))
	draw_rect(Rect2(-19, -27, 38, 54), Color("15211f"))
	draw_rect(Rect2(-14, -21, 28, 20), color)
	draw_string(UI_FONT, Vector2(-110, 56), display_name, HORIZONTAL_ALIGNMENT_CENTER, 220, 12, color)


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
	return Color.WHITE
