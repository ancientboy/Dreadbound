class_name CombatFX
extends Node2D

## Lightweight atlas-backed combat presentation. Effects use a fixed event pool so
## repeated fights on mobile do not continually allocate nodes or particles.
const MAX_EVENTS := 48
const COMBAT_ATLAS: Texture2D = preload("res://assets/art/vfx/combat_core.png")
const METRO_ENEMY_SKILLS: Texture2D = preload("res://assets/art/vfx/metro_enemy_skills.png")
const SANATORIUM_ENEMY_SKILLS: Texture2D = preload("res://assets/art/vfx/sanatorium_enemy_skills.png")
const BASIC_MELEE_CRESCENT: Texture2D = preload("res://assets/art/vfx/basic_melee_crescent.svg")
const PROFESSION_SKILL_ATLASES := {
	"steadfast": preload("res://assets/art/vfx/profession_skills_steadfast.png"),
	"armorer": preload("res://assets/art/vfx/profession_skills_armorer.png"),
	"resonant": preload("res://assets/art/vfx/profession_skills_resonant.png"),
}
const PROFESSION_ATTACK_ATLASES := {
	"steadfast": preload("res://assets/art/vfx/profession_attack_modes_steadfast.png"),
	"armorer": preload("res://assets/art/vfx/profession_attack_modes_armorer.png"),
	"resonant": preload("res://assets/art/vfx/profession_attack_modes_resonant.png"),
}

var _events: Array[Dictionary] = []
var _camera: Camera2D
var _target_lock: Node2D


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


func weapon_swing_styled(origin: Vector2, direction: Vector2, radius: float, color: Color) -> void:
	# Ordinary melee attacks use a lightweight trail derived from the equipped
	# weapon profile. The old combat-atlas crescent is reserved for legacy
	# authored effects and must not leak into weapon-driven basic attacks.
	_spawn("weapon_swing", origin, direction, radius, 0.14, color)
	_kick_camera(1.6)


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


func bow_shot_styled(origin: Vector2, end: Vector2, color: Color) -> void:
	_spawn("arrow", origin, end, 0.0, 0.16, color)
	_kick_camera(1.2)


func rail_shot_styled(origin: Vector2, end: Vector2, color: Color) -> void:
	_spawn("rail_beam", origin, end, 0.0, 0.13, color)
	_kick_camera(3.2)


func arcane_chain_styled(origin: Vector2, end: Vector2, color: Color) -> void:
	_spawn("arcane_chain", origin, end, 0.0, 0.22, color)
	_spawn("status", origin, Vector2.ZERO, 18.0, 0.26, color)
	_kick_camera(1.8)


func movement_echo(position: Vector2, facing_direction: Vector2, color: Color, resonant := false) -> void:
	_spawn("echo", position - facing_direction * 8.0, facing_direction, 0.0, 0.22 if resonant else 0.14, color)


func enemy_hit(
	_position: Vector2,
	_direction: Vector2,
	heavy := false,
	_color := Color("e69372"),
) -> void:
	# Enemy bodies already flash, stagger and recoil in their own damage
	# handlers. Keep the tactile camera response, but do not stack a detached
	# atlas spark over every target.
	_kick_camera(1.7 if heavy else 0.7)


func enemy_defeat(position: Vector2, color := Color("cc6c63"), large := false) -> void:
	_spawn("enemy_defeat", position, Vector2.ZERO, 0.0, 0.52 if large else 0.34, color)
	_kick_camera(5.0 if large else 1.5)


func attack_telegraph(position: Vector2, radius: float, duration: float, color := Color("e36c4d")) -> void:
	_spawn("telegraph", position, Vector2.ZERO, radius, duration, color)


func loot_burst(position: Vector2, color := Color("56d9c6")) -> void:
	_spawn("loot", position, Vector2.ZERO, 0.0, 0.32, color)


func impact(position: Vector2, direction: Vector2, heavy := false) -> void:
	impact_styled(position, direction, heavy, Color("f2dca1") if heavy else Color("9fe2d0"))


func impact_styled(position: Vector2, direction: Vector2, heavy: bool, color: Color) -> void:
	_spawn("impact_heavy" if heavy else "impact", position, direction, 0.0, 0.14 if heavy else 0.10, color)


func status_burst(position: Vector2, status: String) -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_status(status)
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


func sanatorium_enemy_skill(kind: String, position: Vector2, direction := Vector2.DOWN, size := 96.0, duration := 0.32) -> void:
	var skill_index: int = int({
		"patient_claw": 0,
		"crawler_lunge": 1,
		"orderly_heavy": 2,
		"director_sweep": 3,
		"director_slam": 4,
		"director_mutation": 5,
		"patient_grasp": 6,
		"crawler_tear": 7,
	}.get(kind, -1))
	if skill_index < 0:
		return
	_spawn("sanatorium_skill_%d" % skill_index, position, direction, size, duration, Color.WHITE)


func profession_skill(kind: String, position: Vector2, direction := Vector2.DOWN, size := 96.0, duration := 0.36) -> void:
	var skill_index: int = int({
		"barrier_counter": 0,
		"last_stand": 1,
		"sacrifice_medic": 2,
		"choke_control": 3,
		"weakpoint_sniper": 4,
		"heavy_suppression": 5,
		"demolition_traps": 6,
		"relic_engineer": 7,
		"psychic_sense": 8,
		"anomaly_ingestion": 9,
		"echo_summoner": 10,
		"aberrant_form": 11,
	}.get(kind, -1))
	if skill_index < 0:
		return
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play_style(kind)
	_spawn("profession_skill_%d" % skill_index, position, direction, size, duration, Color.WHITE)


func profession_attack(pathway: String, attack_kind: String, position: Vector2, direction := Vector2.DOWN, size := 96.0, reach := 0.0, duration := 0.24) -> void:
	if not PROFESSION_ATTACK_ATLASES.has(pathway):
		return
	var mode_index: int = int({"melee": 0, "ranged": 1, "shotgun": 2}.get(attack_kind, -1))
	if mode_index < 0:
		return
	var event := _spawn("profession_attack_%s_%d" % [pathway, mode_index], position, direction, size, duration, Color.WHITE)
	if not event.is_empty():
		event.reach = reach


func set_target_lock(target: Node2D) -> void:
	_target_lock = target
	queue_redraw()


func _spawn(kind: String, origin: Vector2, payload: Vector2, radius: float, duration: float, color: Color) -> Dictionary:
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
		return event
	return {}


func _kick_camera(amount: float) -> void:
	if _camera != null:
		if _camera.has_method("add_attack_shake"):
			_camera.call("add_attack_shake", amount)
		else:
			_camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
			var reset := create_tween()
			reset.tween_property(_camera, "offset", Vector2.ZERO, 0.08)


func _draw() -> void:
	if is_instance_valid(_target_lock):
		var lock_pulse := 0.72 + sin(Time.get_ticks_msec() * 0.012) * 0.12
		var lock_center := _target_lock.global_position + Vector2(0, 12)
		draw_arc(lock_center, 22.0 * lock_pulse, 0.12, PI - 0.12, 18, Color("9ee8ff"), 1.8)
		draw_arc(lock_center, 22.0 * lock_pulse, PI + 0.12, TAU - 0.12, 18, Color("9ee8ff"), 1.8)
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
			"weapon_swing":
				var swing_direction: Vector2 = event.payload.normalized()
				var swing_angle := swing_direction.angle()
				var presentation_scale := lerpf(
					0.96,
					1.0,
					ease(clampf(progress / 0.12, 0.0, 1.0), -1.8),
				)
				var crescent_width := clampf(event.radius * 1.48, 112.0, 164.0)
				var crescent_size := (
					Vector2(crescent_width, crescent_width * 0.75)
					* presentation_scale
				)
				var crescent_center: Vector2 = (
					Vector2(event.origin)
					+ swing_direction * clampf(event.radius * 0.44, 34.0, 54.0)
				)
				_draw_melee_crescent_texture(
					crescent_center,
					swing_angle,
					crescent_size,
					Color(color.lightened(0.26), fade * 0.92),
				)
			"tracer", "pellet":
				var start_pos: Vector2 = event.origin.lerp(event.payload, progress * 0.24)
				var end_pos: Vector2 = event.origin.lerp(event.payload, minf(1.0, progress * 1.45 + 0.18))
				draw_line(start_pos, end_pos, color, 2.8 if event.kind == "tracer" else 1.5)
			"arrow":
				var arrow_start: Vector2 = event.origin.lerp(event.payload, progress * 0.82)
				var arrow_end: Vector2 = event.origin.lerp(event.payload, minf(1.0, progress * 0.82 + 0.12))
				draw_line(arrow_start, arrow_end, color, 2.4)
				var arrow_direction := arrow_start.direction_to(arrow_end)
				draw_line(arrow_end, arrow_end - arrow_direction.rotated(0.55) * 8.0, color, 1.8)
				draw_line(arrow_end, arrow_end - arrow_direction.rotated(-0.55) * 8.0, color, 1.8)
			"rail_beam":
				var beam_end: Vector2 = event.origin.lerp(event.payload, minf(1.0, progress * 2.2))
				draw_line(event.origin, beam_end, Color(color, 0.28), 8.0 * fade + 2.0)
				draw_line(event.origin, beam_end, color, 2.8)
			"arcane_chain":
				var segment_count := 8
				var previous: Vector2 = event.origin
				for segment in range(1, segment_count + 1):
					var ratio := float(segment) / float(segment_count)
					var next: Vector2 = event.origin.lerp(event.payload, ratio)
					var normal: Vector2 = Vector2(event.origin).direction_to(event.payload).orthogonal()
					next += normal * sin(float(segment) * 2.7 + progress * 15.0) * 5.0 * fade
					draw_line(previous, next, color, 3.2 - ratio * 1.2)
					previous = next
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
				elif String(event.kind).begins_with("sanatorium_skill_"):
					var index := int(String(event.kind).trim_prefix("sanatorium_skill_"))
					var direction: Vector2 = event.payload
					var rotation := direction.angle() + PI * 0.5 if index in [0, 1, 2, 3, 6, 7] else 0.0
					var scale_pulse := 0.82 + sin(progress * PI) * 0.26
					_draw_sanatorium_fx_cell(
						index,
						event.origin + (direction * float(event.radius) * 0.16 if index in [0, 1, 2, 3, 6, 7] else Vector2.ZERO),
						float(event.radius) * scale_pulse,
						rotation,
						Color(1.0, 1.0, 1.0, fade),
					)
				elif String(event.kind).begins_with("profession_skill_"):
					var index := int(String(event.kind).trim_prefix("profession_skill_"))
					var direction: Vector2 = event.payload
					var rotation := direction.angle() + PI * 0.5 if index in [3, 4, 5] else 0.0
					var scale_pulse := 0.82 + sin(progress * PI) * 0.24
					_draw_profession_fx_cell(
						index,
						progress,
						event.origin + (direction * float(event.radius) * 0.12 if index in [3, 4, 5] else Vector2.ZERO),
						float(event.radius) * scale_pulse,
						rotation,
						Color(1.0, 1.0, 1.0, fade),
					)
				elif String(event.kind).begins_with("profession_attack_"):
					var tokens := String(event.kind).trim_prefix("profession_attack_").split("_")
					if tokens.size() != 2:
						continue
					var pathway := str(tokens[0])
					var mode_index := int(tokens[1])
					var direction: Vector2 = event.payload
					var travel := 0.18 if mode_index == 1 else (0.12 if mode_index == 0 else 0.2)
					var reach := float(event.get("reach", 0.0))
					var travel_distance := minf(reach * progress * 1.35, reach) if mode_index == 1 else reach * travel
					_draw_profession_attack_cell(
						pathway,
						mode_index,
						progress,
						event.origin + direction * travel_distance,
						float(event.radius) * (0.82 + sin(progress * PI) * 0.2),
						direction.angle(),
						Color(1.0, 1.0, 1.0, fade),
					)


func _draw_melee_crescent_texture(
	center: Vector2,
	rotation: float,
	draw_size: Vector2,
	color: Color,
) -> void:
	# Use one authored silhouette for the whole lifetime. Scaling and fading the
	# texture cannot introduce the inward bulge created by the old radial mesh.
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect(
		BASIC_MELEE_CRESCENT,
		Rect2(-draw_size * 0.54, draw_size * 1.08),
		false,
		Color(color, color.a * 0.20),
	)
	draw_texture_rect(
		BASIC_MELEE_CRESCENT,
		Rect2(-draw_size * 0.5, draw_size),
		false,
		color,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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


func _draw_sanatorium_fx_cell(index: int, center: Vector2, draw_size: float, rotation: float, modulate: Color) -> void:
	if SANATORIUM_ENEMY_SKILLS == null or SANATORIUM_ENEMY_SKILLS.get_size() != Vector2(512, 256):
		draw_arc(center, draw_size * 0.4, 0.0, TAU, 24, modulate, 3.0)
		return
	var column := index % 4
	var row := floori(float(index) / 4.0)
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		SANATORIUM_ENEMY_SKILLS,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(column * 128, row * 128, 128, 128),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_profession_fx_cell(index: int, progress: float, center: Vector2, draw_size: float, rotation: float, modulate: Color) -> void:
	var pathway: String = ["steadfast", "armorer", "resonant"][clampi(floori(float(index) / 4.0), 0, 2)]
	var atlas: Texture2D = PROFESSION_SKILL_ATLASES.get(pathway)
	if atlas == null or atlas.get_size() != Vector2(512, 512):
		draw_arc(center, draw_size * 0.4, 0.0, TAU, 24, modulate, 3.0)
		return
	var row := index % 4
	var frame := clampi(floori(progress * 4.0), 0, 3)
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		atlas,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(frame * 128, row * 128, 128, 128),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_profession_attack_cell(pathway: String, mode_index: int, progress: float, center: Vector2, draw_size: float, rotation: float, modulate: Color) -> void:
	var atlas: Texture2D = PROFESSION_ATTACK_ATLASES.get(pathway)
	if atlas == null or atlas.get_size() != Vector2(512, 384):
		draw_arc(center, draw_size * 0.4, rotation - 0.5, rotation + 0.5, 16, modulate, 3.0)
		return
	var frame := clampi(floori(progress * 4.0), 0, 3)
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		atlas,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(frame * 128, clampi(mode_index, 0, 2) * 128, 128, 128),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
