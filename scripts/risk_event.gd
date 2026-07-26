class_name RiskEvent
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

@export var event_id := ""
@export var title := "异常事件"
@export_multiline var description := ""
@export var choice_a := "承担风险"
@export var choice_b := "安全离开"

var resolved := false


func _ready() -> void:
	z_index = 12
	queue_redraw()


func get_prompt() -> String:
	return "[E] 调查异常：%s" % title


func mark_resolved() -> void:
	resolved = true
	queue_redraw()


func _draw() -> void:
	var color := Color("59635f") if resolved else Color("41c7b5")
	draw_circle(Vector2.ZERO, 38.0, Color(color, 0.12))
	draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 24, color, 4.0)
	draw_line(Vector2(-16, -16), Vector2(16, 16), color, 3.0)
	draw_line(Vector2(16, -16), Vector2(-16, 16), color, 3.0)
	draw_string(UI_FONT, Vector2(-95, 54), title, HORIZONTAL_ALIGNMENT_CENTER, 190, 13, color)
