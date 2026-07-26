class_name RewardChest
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

var candidates: Array[String] = []
var opened := false


func _ready() -> void:
	z_index = 12
	queue_redraw()


func get_prompt() -> String:
	return "[E] 打开异常回收箱" if not opened else "奖励已回收"


func mark_opened() -> void:
	opened = true
	queue_redraw()


func _draw() -> void:
	var color := Color("3e7369") if not opened else Color("394641")
	draw_circle(Vector2.ZERO, 34.0, Color(0.2, 0.88, 0.76, 0.1 if opened else 0.2))
	draw_rect(Rect2(-30, -18, 60, 38), color)
	draw_rect(Rect2(-30, -18, 60, 38), Color("79dcca"), false, 3.0)
	draw_line(Vector2(-30, -6), Vector2(30, -6), Color("172a27"), 4.0)
	draw_circle(Vector2(0, 3), 5.0, Color("69e4cd"))
	draw_string(UI_FONT, Vector2(-58, 45), "异常回收箱", HORIZONTAL_ALIGNMENT_CENTER, 116, 15, Color("83dacb"))
