class_name SignalAnchor
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")

var max_health := 75
var health := 75


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("signal_anchors")
	queue_redraw()


func take_damage(amount: int, _source_position: Vector2) -> void:
	health = maxi(health - amount, 0)
	if health == 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 34.0, Color(0.08, 0.18, 0.24, 0.95))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color("5cc9e8"), 5.0)
	draw_line(Vector2(-22, 0), Vector2(22, 0), Color("e8b45f"), 5.0)
	draw_rect(Rect2(-36, -49, 72, 6), Color("20191a"))
	draw_rect(Rect2(-36, -49, 72.0 * float(health) / max_health, 6), Color("5cc9e8"))
	draw_string(UI_FONT, Vector2(-58, 57), "信号锚", HORIZONTAL_ALIGNMENT_CENTER, 116, 14, Color("91dcef"))

