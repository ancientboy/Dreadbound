class_name CombatFX
extends Node2D

## Lightweight atlas-backed combat presentation. Effects use a fixed event pool so
## repeated fights on mobile do not continually allocate nodes or particles.
const MAX_EVENTS := 48
const COMBAT_ATLAS: Texture2D = preload("res://assets/art/vfx/combat_core.png")
const METRO_ENEMY_SKILLS: Texture2D = preload("res://assets/art/vfx/metro_enemy_skills.png")

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
	melee_swing_styled(origin, direction, radius, Color("e5c977"))


func melee_swing_styled(origin: Vector2, direction: Vector2, radius: float, color: Color) -> void:
	_spawn("arc", origin, direction, radius, 0.16, color)
	_kick_camera(2.0)


static func melee_arc_rotation(direction: Vector2) -> float:
	# The authored crescent points left in atlas space. Rotate its visual axis
	# half a turn so the open edge and travel direction both face the strike.
	return direction.angle() + PI


func pistol_shot(origin: Vector2, end: Vector2) -> void:
	pistol_shot_styled(origin, end, Color("6fe8c8"), Color("f5e6b2"))


func pistol_shot_styled(origin: Vector2, end: Vector2, tracer_color: Color, muzzle_color: Color) -> void:
	_spawn("tracer", origin, end, 0.0, 0.085, tracer_color)
	_spawn("muzzle_pistol", origin, Vector2.ZERO, 0.0, 0.065, muzzle_color)
	_kick_camera(1.5)


func shotgun_blast(origin: Vector2, direction: Vector2, max_range: float) -> void:
	shotgun_blast_styled(origin, direction, max_range, Color("e7b969"), Color("f2b86f"))


func shotgun_blast_styled(origin: Vector2, direction: Vector2, max_range: float, pellet_color: Color, muzzle_color: Color) -> void:
	_spawn("muzzle_shotgun", origin, direction, 0.0, 0.11, muzzle_color)
	for spread in [-0.30, -0.20, -0.10, 0.0, 0.10, 0.20, 0.30]:
		var endpoint := origin + direction.rotated(spread) * max_range
		_spawn("pellet", origin, endpoint, 0.0, 0.12, pellet_color)
	_kick_camera(4.0)


func movement_echo(position: Vector2, facing_direction: Vector2, color: Color, resonant := false) -> void:
	_spawn("echo", position - facing_direction * 8.0, facing_direction, 0.0, 0.22 if resonant else 0.14, color)


func enemy_hit(position: Vector2, direction: Vector2, heavy := false, color := Color("e69372")) -> void:
	_spawn("enemy_hit", position, direction, 0.0, 0.16 if heavy else 0.11, color)
	_kick_camera(1.7 if heavy else 0.7)


func enemy_defeat(position: Vector2, color := Color("cc6c63"), large := false) -> void:
	_spawn("enemy_defeat", position, Vector2.ZERO, 0.0, 0.52 if large else 0.34, color)
	_kick_camera(5.0 if large else 1.5)


func attack_telegraph(position: Vector2, radius: float, duration: float, color := Color("e36c4d")) -> void:
	_spawn("telegraph", position, Vector2.ZERO, radius, duration, color)


func loot_burst(position: Vector2, color := Color("56d9c6")) -> void:
	_spawn("loot", position, Vector2.ZERO, 0.0, 0.32, color)


func impact(position: Vector2, direction: Vector2, heavy := false) -> void:
	_spawn("impact_heavy" if heavy else "impact", position, direction, 0.0, 0.14 if heavy else 0.10, Color("f2dca1") if heavy else Color("9fe2d0"))


func status_burst(position: Vector2, status: String) -> void:
	var color := Color("a4eaff") if status == "freeze" else Color("c59cff")
	_spawn("status", position, Vector2.ZERO, 26.0, 0.42, color)
	_kick_camera(2.4)


func metro_enemy_skill(kind: String, position: Vector2, direction := Vector2.DOWN, size := 96.0, duration := 0.32) -> void:
	var skill_index: int = int({
		"drowned_splash": 0,
		"drowned_lunge": 1,
		"inspector_charge": 2,
		"inspector_impact": 3,
		"anchor_pulse": 4,
		"anchor_discharge": 5,
		"conductor_stamp": 6,
		"conductor_train": 7,
	}.get(kind, 0))
	_spawn("metro_skill_%d" % int(skill_index), position, direction, size, duration, Color.WHITE)


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
				_draw_fx_cell(0, event.origin + direction * event.radius * 0.52, event.radius * 1.16, melee_arc_rotation(direction), Color(1.0, 1.0, 1.0, fade))
			"tracer", "pellet":
				var start_pos: Vector2 = event.origin.lerp(event.payload, progress * 0.24)
				var end_pos: Vector2 = event.origin.lerp(event.payload, minf(1.0, progress * 1.45 + 0.18))
				draw_line(start_pos, end_pos, color, 2.8 if event.kind == "tracer" else 1.5)
			"muzzle_pistol":
				_draw_fx_cell(1, event.origin, 42.0 + 18.0 * fade, 0.0, Color(1.0, 1.0, 1.0, fade))
			"muzzle_shotgun":
				var muzzle_direction: Vector2 = event.payload
				_draw_fx_cell(2, event.origin + muzzle_direction * 12.0, 58.0 + 16.0 * fade, muzzle_direction.angle(), Color(1.0, 1.0, 1.0, fade))
			"impact":
				_draw_fx_cell(3, event.origin, 38.0 + progress * 18.0, event.payload.angle(), Color(1.0, 1.0, 1.0, fade))
			"impact_heavy":
				_draw_fx_cell(4, event.origin, 54.0 + progress * 24.0, event.payload.angle(), Color(1.0, 1.0, 1.0, fade))
			"echo":
				draw_circle(event.origin - event.payload * progress * 15.0, 13.0 - progress * 4.0, Color(color, 0.18 * fade))
				draw_circle(event.origin - event.payload * progress * 12.0, 5.0, Color(color, 0.55 * fade))
			"enemy_hit":
				_draw_fx_cell(5, event.origin, 48.0 + progress * 20.0, event.payload.angle(), Color(1.0, 0.86, 0.82, fade))
			"enemy_defeat":
				_draw_fx_cell(6, event.origin, 58.0 + progress * 44.0, progress * 0.4, Color(1.0, 1.0, 1.0, fade))
			"telegraph":
				var pulse := 0.72 + sin(progress * PI * 3.0) * 0.12
				_draw_fx_cell(7, event.origin, event.radius * pulse * 2.0, 0.0, Color(1.0, 1.0, 1.0, 0.54 * fade))
				draw_arc(event.origin, event.radius * pulse, 0.0, TAU, 48, Color(color, 0.72 * fade), 3.0 + (1.0 - progress) * 3.0)
				if progress < 0.72:
					draw_circle(event.origin, event.radius * 0.92, Color(color, 0.045 * fade))
			"loot":
				for index in range(6):
					var angle := TAU * float(index) / 6.0 - PI * 0.5
					var start: Vector2 = event.origin + Vector2.from_angle(angle) * (6.0 + progress * 12.0)
					var end: Vector2 = event.origin + Vector2.from_angle(angle) * (18.0 + progress * 34.0)
					draw_line(start, end, color, 2.0 * fade)
				draw_circle(event.origin + Vector2(0, -progress * 20.0), 8.0 * fade + 2.0, color)
			"status":
				var ring_radius: float = float(event.radius) * (0.55 + progress * 0.8)
				draw_arc(event.origin, ring_radius, 0.0, TAU, 32, color, 3.5 * fade)
				for index in range(6):
					var angle := TAU * float(index) / 6.0 + progress
					var tip: Vector2 = Vector2(event.origin) + Vector2.from_angle(angle) * ring_radius
					draw_line(tip - Vector2.from_angle(angle) * 7.0, tip, color, 2.4 * fade)
			_:
				if String(event.kind).begins_with("metro_skill_"):
					var index := int(String(event.kind).trim_prefix("metro_skill_"))
					var direction: Vector2 = event.payload
					var rotation := direction.angle() if index in [1, 2, 3, 7] else 0.0
					var scale_pulse := 0.88 + sin(progress * PI) * 0.18
					_draw_metro_fx_cell(
						index,
						event.origin + (direction * float(event.radius) * 0.18 if index in [1, 2, 7] else Vector2.ZERO),
						float(event.radius) * scale_pulse,
						rotation,
						Color(1.0, 1.0, 1.0, fade),
					)


func _draw_fx_cell(index: int, center: Vector2, draw_size: float, rotation: float, modulate: Color) -> void:
	if COMBAT_ATLAS == null or COMBAT_ATLAS.get_size() != Vector2(256, 128):
		draw_circle(center, maxf(3.0, draw_size * 0.16), modulate)
		return
	var column := index % 4
	var row := floori(float(index) / 4.0)
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		COMBAT_ATLAS,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(column * 64, row * 64, 64, 64),
		modulate
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_metro_fx_cell(index: int, center: Vector2, draw_size: float, rotation: float, modulate: Color) -> void:
	if METRO_ENEMY_SKILLS == null or METRO_ENEMY_SKILLS.get_size() != Vector2(512, 256):
		draw_arc(center, draw_size * 0.4, 0.0, TAU, 24, modulate, 3.0)
		return
	var column := index % 4
	var row := floori(float(index) / 4.0)
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		METRO_ENEMY_SKILLS,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(column * 128, row * 128, 128, 128),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
