class_name MapRoomObstacle
extends StaticBody2D

enum PropKind {
	WALL_CONSOLE,
	MEDICAL_LOCKER,
	SUPPLY_CRATE,
	GURNEY,
	BARRICADE,
}

@export var prop_kind := PropKind.SUPPLY_CRATE
@export var footprint_size := Vector2(120.0, 64.0)
@export var visual_height := 72.0
@export var placement_role := "combat"
@export var blocks_projectiles := true


func _ready() -> void:
	add_to_group(&"map_room_obstacles")
	var collision := CollisionPolygon2D.new()
	collision.name = "FootprintCollision"
	collision.polygon = _footprint_polygon()
	add_child(collision)
	queue_redraw()


func _draw() -> void:
	var footprint := _footprint_polygon()
	var top_offset := Vector2(0.0, -visual_height)
	var top := PackedVector2Array()
	for point in footprint:
		top.append(point + top_offset)
	var palette := _palette()
	draw_set_transform(Vector2(10.0, 12.0))
	draw_colored_polygon(footprint, Color(0.0, 0.0, 0.0, 0.34))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(
		PackedVector2Array([footprint[2], footprint[3], top[3], top[2]]),
		palette[2],
	)
	draw_colored_polygon(
		PackedVector2Array([footprint[1], footprint[2], top[2], top[1]]),
		palette[1],
	)
	draw_colored_polygon(top, palette[0])
	draw_polyline(top, Color(0.03, 0.09, 0.09, 0.95), 4.0, true)
	_draw_details(top, palette[3])


func _footprint_polygon() -> PackedVector2Array:
	var half := footprint_size * 0.5
	var skew := minf(18.0, footprint_size.x * 0.12)
	return PackedVector2Array([
		Vector2(-half.x + skew, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x - skew, half.y),
		Vector2(-half.x, half.y),
	])


func _palette() -> Array[Color]:
	match prop_kind:
		PropKind.WALL_CONSOLE:
			return [
				Color("263f3d"), Color("172b2b"), Color("102020"), Color("55e4c5"),
			]
		PropKind.MEDICAL_LOCKER:
			return [
				Color("465452"), Color("293735"), Color("1c2928"), Color("73d7c2"),
			]
		PropKind.GURNEY:
			return [
				Color("625e55"), Color("393732"), Color("242421"), Color("c3a978"),
			]
		PropKind.BARRICADE:
			return [
				Color("4b4a42"), Color("2d2e2b"), Color("20211f"), Color("e1a34e"),
			]
		_:
			return [
				Color("4d493c"), Color("302d25"), Color("201f1a"), Color("6cd9c3"),
			]


func _draw_details(top: PackedVector2Array, accent: Color) -> void:
	var left := top[0].x
	var right := top[1].x
	var rear := top[0].y
	var front := top[3].y
	match prop_kind:
		PropKind.WALL_CONSOLE:
			draw_rect(
				Rect2(Vector2(left + 20.0, rear + 14.0), Vector2(right - left - 40.0, 18.0)),
				Color(0.02, 0.08, 0.08, 0.92),
			)
			draw_line(
				Vector2(left + 28.0, rear + 23.0),
				Vector2(right - 28.0, rear + 23.0),
				accent,
				4.0,
			)
		PropKind.MEDICAL_LOCKER:
			draw_line(Vector2(0.0, rear + 8.0), Vector2(0.0, front - 8.0), accent, 4.0)
			draw_circle(Vector2(-12.0, (rear + front) * 0.5), 4.0, accent)
		PropKind.GURNEY:
			draw_line(Vector2(left + 14.0, rear + 14.0), Vector2(right - 14.0, front - 14.0), accent, 5.0)
		PropKind.BARRICADE:
			for offset in [-26.0, 0.0, 26.0]:
				draw_line(
					Vector2(offset - 18.0, rear + 8.0),
					Vector2(offset + 18.0, front - 8.0),
					accent,
					6.0,
				)
		_:
			draw_line(Vector2(left + 14.0, rear + 12.0), Vector2(right - 14.0, front - 12.0), accent, 3.0)
			draw_line(Vector2(right - 14.0, rear + 12.0), Vector2(left + 14.0, front - 12.0), accent, 3.0)
