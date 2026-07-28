class_name ActionReferenceWeapon
extends Node2D

const OUTLINE := Color("172126")
const METAL := Color("b8c6c8")
const ACCENT := Color("58d7c5")
const GRIP := Color("755a43")

var family := ""


func set_family(next_family: String) -> void:
	visible = not next_family.is_empty() and next_family != "unarmed"
	if family == next_family:
		return
	family = next_family
	queue_redraw()


func _draw() -> void:
	match family:
		"sword":
			_draw_sword()
		"pistol":
			_draw_pistol()
		"bow":
			_draw_bow()
		"spell":
			_draw_staff()
		"shield":
			_draw_shield()


func _draw_sword() -> void:
	draw_polygon(
		PackedVector2Array([
			Vector2(8, -8),
			Vector2(112, -5),
			Vector2(142, 0),
			Vector2(112, 5),
			Vector2(8, 8),
		]),
		PackedColorArray([METAL]),
	)
	draw_polyline(PackedVector2Array([Vector2(8, -8), Vector2(142, 0), Vector2(8, 8)]), OUTLINE, 5.0)
	draw_line(Vector2(2, -20), Vector2(2, 20), OUTLINE, 10.0)
	draw_line(Vector2(-34, 0), Vector2(8, 0), GRIP, 15.0)


func _draw_pistol() -> void:
	draw_polygon(
		PackedVector2Array([
			Vector2(-10, -14),
			Vector2(88, -14),
			Vector2(104, -4),
			Vector2(88, 6),
			Vector2(14, 6),
			Vector2(4, 16),
			Vector2(-16, 16),
		]),
		PackedColorArray([METAL]),
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-10, -14),
			Vector2(88, -14),
			Vector2(104, -4),
			Vector2(88, 6),
			Vector2(14, 6),
		]),
		OUTLINE,
		6.0,
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(2, 5),
			Vector2(28, 7),
			Vector2(12, 54),
			Vector2(-12, 50),
		]),
		PackedColorArray([GRIP]),
	)


func _draw_bow() -> void:
	var curve := PackedVector2Array([
		Vector2(0, -116),
		Vector2(34, -78),
		Vector2(46, -34),
		Vector2(48, 0),
		Vector2(46, 34),
		Vector2(34, 78),
		Vector2(0, 116),
	])
	draw_polyline(curve, OUTLINE, 15.0)
	draw_polyline(curve, ACCENT, 8.0)
	draw_line(Vector2(0, -116), Vector2(48, 0), METAL, 3.0)
	draw_line(Vector2(48, 0), Vector2(0, 116), METAL, 3.0)
	draw_line(Vector2(34, -12), Vector2(62, 12), GRIP, 14.0)


func _draw_staff() -> void:
	draw_line(Vector2(-92, 0), Vector2(120, 0), OUTLINE, 16.0)
	draw_line(Vector2(-92, 0), Vector2(120, 0), GRIP, 9.0)
	draw_circle(Vector2(126, 0), 28.0, OUTLINE)
	draw_circle(Vector2(126, 0), 19.0, ACCENT)
	draw_circle(Vector2(126, 0), 8.0, Color("d7fff8"))


func _draw_shield() -> void:
	draw_polygon(
		PackedVector2Array([
			Vector2(-58, -70),
			Vector2(58, -70),
			Vector2(70, -18),
			Vector2(54, 54),
			Vector2(0, 88),
			Vector2(-54, 54),
			Vector2(-70, -18),
		]),
		PackedColorArray([Color("49646b")]),
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-58, -70),
			Vector2(58, -70),
			Vector2(70, -18),
			Vector2(54, 54),
			Vector2(0, 88),
			Vector2(-54, 54),
			Vector2(-70, -18),
			Vector2(-58, -70),
		]),
		OUTLINE,
		9.0,
	)
	draw_line(Vector2(0, -54), Vector2(0, 62), ACCENT, 6.0)
	draw_line(Vector2(-45, -5), Vector2(45, -5), ACCENT, 6.0)
