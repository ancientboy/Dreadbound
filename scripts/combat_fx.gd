class_name CombatFX
extends Node2D

## Lightweight, asset-free combat presentation. Effects use a fixed event pool so
## repeated fights on mobile do not continually allocate nodes or particles.
const MAX_EVENTS := 48

var _events: Array[Dictionary] = []
var _camera: Camera2D


func _ready() -> void:
	set_as_top_level(true)
	for index in MAX_EVENTS:
		_events.append({"active": false})
	_camera = get_viewport().get_camera_2d()


func _process(delta: float) -> void:
	var needs_redraw := false
	for event in _events:
		if not event.active:
			continue
		event.age += delta
		if event.age >= event.duration:
			event.active = false
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


func melee_swing(origin: Vector2, direction: Vector2, radius: float) -> void:
	_spawn("arc", origin, direction, radius, 0.16, Color("e5c977"))
	_kick_camera(2.0)


func pistol_shot(origin: Vector2, end: Vector2) -> void:
	_spawn("tracer", origin, end, 0.0, 0.085, Color("6fe8c8"))
	_spawn("muzzle", origin, Vector2.ZERO, 0.0, 0.065, Color("f5e6b2"))
	_kick_camera(1.5)


func shotgun_blast(origin: Vector2, direction: Vector2, max_range: float) -> void:
	_spawn("muzzle", origin, Vector2.ZERO, 0.0, 0.11, Color("f2b86f"))
	for spread in [-0.30, -0.20, -0.10, 0.0, 0.10, 0.20, 0.30]:
		var endpoint := origin + direction.rotated(spread) * max_range
		_spawn("pellet", origin, endpoint, 0.0, 0.12, Color("e7b969"))
	_kick_camera(4.0)


func impact(position: Vector2, direction: Vector2, heavy := false) -> void:
	_spawn("impact", position, direction, 0.0, 0.14 if heavy else 0.10, Color("f2dca1") if heavy else Color("9fe2d0"))


func _spawn(kind: String, origin: Vector2, payload: Vector2, radius: float, duration: float, color: Color) -> void:
	for event in _events:
		if event.active:
			continue
		event.active = true
		event.kind = kind
		event.origin = origin
		event.payload = payload
		event.radius = radius
		event.duration = duration
		event.age = 0.0
		event.color = color
		queue_redraw()
		return


func _kick_camera(amount: float) -> void:
	if _camera != null:
		_camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		var reset := create_tween()
		reset.tween_property(_camera, "offset", Vector2.ZERO, 0.08)


func _draw() -> void:
	for event in _events:
		if not event.active:
			continue
		var progress: float = clampf(event.age / event.duration, 0.0, 1.0)
		var fade := 1.0 - progress
		var color: Color = event.color
		color.a *= fade
		match String(event.kind):
			"arc":
				var direction: Vector2 = event.payload
				var start := direction.angle() - 0.9 + progress * 0.55
				var finish := direction.angle() - 0.35 + progress * 0.55
				draw_arc(event.origin, event.radius * (0.82 + progress * 0.2), start, finish, 18, color, 5.0 * fade)
			"tracer", "pellet":
				var start_pos: Vector2 = event.origin.lerp(event.payload, progress * 0.24)
				var end_pos: Vector2 = event.origin.lerp(event.payload, minf(1.0, progress * 1.45 + 0.18))
				draw_line(start_pos, end_pos, color, 2.8 if event.kind == "tracer" else 1.5)
			"muzzle":
				draw_circle(event.origin, 15.0 * fade + 3.0, color)
				draw_circle(event.origin, 27.0 * fade + 5.0, Color(color, 0.16 * fade))
			"impact":
				var direction: Vector2 = event.payload.normalized()
				for spread in [-0.7, -0.35, 0.0, 0.35, 0.7]:
					draw_line(event.origin, event.origin + direction.rotated(spread) * (10.0 + progress * 15.0), color, 2.0 * fade)
				draw_circle(event.origin, 6.0 * fade + 2.0, color)
