class_name ResourcePickup
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

enum Kind { BANDAGE, ECHO_SHARD }

@export var kind := Kind.BANDAGE
@export var amount := 1

var _pulse := 0.0


func _ready() -> void:
	add_to_group("pickups")
	z_index = 10
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func collect(player: Player) -> bool:
	var accepted := false
	match kind:
		Kind.BANDAGE:
			accepted = player.add_bandages(amount)
		Kind.ECHO_SHARD:
			player.add_echo_shards(amount)
			accepted = true
	if accepted:
		queue_free()
	return accepted


func _draw() -> void:
	var bob := sin(_pulse * 2.4) * 3.0
	var color := Color("8fc6a1") if kind == Kind.BANDAGE else Color("45d8c3")
	draw_circle(Vector2(0, bob), 18.0 + sin(_pulse * 3.0) * 2.0, Color(color, 0.1))
	if kind == Kind.BANDAGE:
		draw_rect(Rect2(-13, -9 + bob, 26, 18), Color("d1cbb5"))
		draw_rect(Rect2(-3, -9 + bob, 6, 18), Color("758f78"))
	else:
		var points := PackedVector2Array([Vector2(0, -17 + bob), Vector2(12, bob), Vector2(0, 17 + bob), Vector2(-12, bob)])
		draw_colored_polygon(points, color)
	var label := "绷带" if kind == Kind.BANDAGE else "回响碎片"
	draw_string(UI_FONT, Vector2(-42, 38), label, HORIZONTAL_ALIGNMENT_CENTER, 84, 12, color)
