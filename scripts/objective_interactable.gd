class_name ObjectiveInteractable
extends Node2D

enum Kind { RECORD, POWER, EXIT }

@export var kind := Kind.RECORD
@export var objective_id := ""
@export var display_name := "INTERACTABLE"

var completed := false


func _ready() -> void:
	queue_redraw()


func get_prompt(records_found: int, power_online: bool) -> String:
	match kind:
		Kind.RECORD:
			return "[E] RETRIEVE %s" % display_name
		Kind.POWER:
			if records_found < 3:
				return "LOCKED // FIND ALL RECORDS (%d/3)" % records_found
			return "[E] RESTORE FACILITY POWER"
		Kind.EXIT:
			if not power_online:
				return "LOCKED // FACILITY POWER OFFLINE"
			return "[E] EXTRACT TO THE TERMINAL CORRIDOR"
	return "[E] INTERACT"


func mark_complete() -> void:
	completed = true
	queue_redraw()


func _draw() -> void:
	var color := _display_color()
	draw_circle(Vector2.ZERO, 44.0, Color(color, 0.1))
	draw_rect(Rect2(-19, -27, 38, 54), Color("15211f"))
	draw_rect(Rect2(-14, -21, 28, 20), color)
	draw_string(ThemeDB.fallback_font, Vector2(-110, 56), display_name, HORIZONTAL_ALIGNMENT_CENTER, 220, 12, color)


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
