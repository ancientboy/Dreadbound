class_name SkillRangeDemo
extends Node2D

enum SkillMode {
	CLOSE_BURST,
	MID_BOLT,
	LONG_RIFT,
}

const STEADFAST_ATLAS: Texture2D = preload(
	"res://assets/art/vfx/profession_skills_steadfast.png"
)
const ARMORER_ATLAS: Texture2D = preload(
	"res://assets/art/vfx/profession_skills_armorer.png"
)
const RESONANT_ATLAS: Texture2D = preload(
	"res://assets/art/vfx/profession_skills_resonant.png"
)

const SKILLS := {
	SkillMode.CLOSE_BURST: {
		"name": "CLOSE · BLOOD BARRIER",
		"range": 170.0,
		"windup": 0.08,
		"active": 0.18,
		"recovery": 0.22,
		"cooldown": 0.62,
	},
	SkillMode.MID_BOLT: {
		"name": "MID · SURGICAL BOLT",
		"range": 390.0,
		"windup": 0.11,
		"active": 0.46,
		"recovery": 0.18,
		"cooldown": 0.78,
	},
	SkillMode.LONG_RIFT: {
		"name": "LONG · ANOMALY RIFT",
		"range": 600.0,
		"windup": 0.34,
		"active": 0.24,
		"recovery": 0.28,
		"cooldown": 1.12,
	},
}

@onready var _player := get_node("../Player") as Player
@onready var _rig := get_node("../Player/LayeredSkeletonRig") as LayeredSkeletonCharacter
@onready var _camera := get_node("../Player/Camera2D") as PlayerFeelCamera

var _mode := SkillMode.CLOSE_BURST
var _phase := "idle"
var _phase_time := 0.0
var _cooldown_left := 0.0
var _cast_origin := Vector2.ZERO
var _cast_direction := Vector2.RIGHT
var _cast_endpoint := Vector2.ZERO
var _hit_applied := false
var _targets: Array[Dictionary] = []


func _ready() -> void:
	z_index = 18
	_player.facing = Vector2.RIGHT
	_cast_origin = _player.global_position
	_cast_endpoint = _cast_origin + Vector2.RIGHT * skill_range()
	for mode in [SkillMode.CLOSE_BURST, SkillMode.MID_BOLT, SkillMode.LONG_RIFT]:
		_targets.append({
			"position": _player.global_position + Vector2.RIGHT * float(SKILLS[mode].range),
			"hit_flash": 0.0,
			"hit_count": 0,
			"mode": mode,
		})
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_4:
			set_skill_mode(SkillMode.CLOSE_BURST)
		KEY_5:
			set_skill_mode(SkillMode.MID_BOLT)
		KEY_6:
			set_skill_mode(SkillMode.LONG_RIFT)
	if event.is_action_pressed("use_skill"):
		trigger_skill()


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	for target in _targets:
		target.hit_flash = maxf(float(target.hit_flash) - delta, 0.0)
	if _phase != "idle":
		_phase_time += delta
		_advance_phase()
	queue_redraw()


func _advance_phase() -> void:
	var spec: Dictionary = SKILLS[_mode]
	match _phase:
		"windup":
			if _phase_time >= float(spec.windup):
				_phase = "active"
				_phase_time = 0.0
				_player._attack_flash = maxf(_player._attack_flash, 0.14)
				_camera.add_attack_shake(2.2 if _mode == SkillMode.CLOSE_BURST else 1.2)
		"active":
			var progress := phase_progress()
			if not _hit_applied and _should_apply_hit(progress):
				_apply_skill_hit()
			if _phase_time >= float(spec.active):
				_phase = "recovery"
				_phase_time = 0.0
		"recovery":
			if _phase_time >= float(spec.recovery):
				_phase = "idle"
				_phase_time = 0.0


func _should_apply_hit(progress: float) -> bool:
	match _mode:
		SkillMode.CLOSE_BURST:
			return progress >= 0.24
		SkillMode.MID_BOLT:
			return progress >= 0.92
		SkillMode.LONG_RIFT:
			return progress >= 0.18
	return false


func _apply_skill_hit() -> void:
	_hit_applied = true
	var impact_point := _cast_endpoint
	var radius := 82.0
	if _mode == SkillMode.CLOSE_BURST:
		impact_point = _cast_origin + _cast_direction * skill_range() * 0.58
		radius = 92.0
	elif _mode == SkillMode.LONG_RIFT:
		radius = 108.0
	for target in _targets:
		if (target.position as Vector2).distance_to(impact_point) <= radius:
			target.hit_flash = 0.22
			target.hit_count = int(target.hit_count) + 1
	_camera.add_attack_shake(
		4.6 if _mode == SkillMode.LONG_RIFT else (
			3.8 if _mode == SkillMode.CLOSE_BURST else 2.8
		)
	)


func trigger_skill() -> bool:
	if _phase != "idle" or _cooldown_left > 0.0:
		return false
	_cast_origin = _player.global_position
	_cast_direction = _player.facing.normalized()
	if _cast_direction == Vector2.ZERO:
		_cast_direction = Vector2.RIGHT
	_cast_endpoint = _cast_origin + _cast_direction * skill_range()
	_phase = "windup"
	_phase_time = 0.0
	_hit_applied = false
	_cooldown_left = float(SKILLS[_mode].cooldown)
	_rig.set_ik_demo_mode(LayeredSkeletonCharacter.IKDemoMode.CAST)
	_player._attack_flash = maxf(_player._attack_flash, 0.08)
	queue_redraw()
	return true


func set_skill_mode(mode: SkillMode) -> void:
	_mode = mode
	_rig.set_ik_demo_mode(LayeredSkeletonCharacter.IKDemoMode.CAST)
	queue_redraw()


func current_skill_mode() -> SkillMode:
	return _mode


func selected_skill_name() -> String:
	return str(SKILLS[_mode].name)


func skill_range() -> float:
	return float(SKILLS[_mode].range)


func cooldown_left() -> float:
	return _cooldown_left


func current_phase() -> String:
	return _phase


func phase_progress() -> float:
	if _phase == "idle":
		return 0.0
	var duration := float(SKILLS[_mode].get(_phase, 1.0))
	return clampf(_phase_time / maxf(duration, 0.001), 0.0, 1.0)


func cast_endpoint() -> Vector2:
	return _cast_endpoint


func uses_existing_skill_atlases() -> bool:
	return (
		STEADFAST_ATLAS != null
		and ARMORER_ATLAS != null
		and RESONANT_ATLAS != null
		and STEADFAST_ATLAS.get_size() == Vector2(512, 512)
		and ARMORER_ATLAS.get_size() == Vector2(512, 512)
		and RESONANT_ATLAS.get_size() == Vector2(512, 512)
	)


func target_hit_count(mode: SkillMode) -> int:
	for target in _targets:
		if int(target.mode) == mode:
			return int(target.hit_count)
	return 0


func _draw() -> void:
	if not is_instance_valid(_player):
		return
	_draw_range_guides()
	_draw_targets()
	if _phase == "idle":
		return
	match _mode:
		SkillMode.CLOSE_BURST:
			_draw_close_burst()
		SkillMode.MID_BOLT:
			_draw_mid_bolt()
		SkillMode.LONG_RIFT:
			_draw_long_rift()


func _draw_range_guides() -> void:
	var origin := _player.global_position
	var direction := _player.facing.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for mode in [SkillMode.CLOSE_BURST, SkillMode.MID_BOLT, SkillMode.LONG_RIFT]:
		var distance := float(SKILLS[mode].range)
		var selected: bool = int(mode) == int(_mode)
		var color := Color("82f6d2") if selected else Color(0.33, 0.48, 0.47, 0.42)
		var endpoint := origin + direction * distance
		draw_dashed_line(origin + direction * 34.0, endpoint, color, 2.5 if selected else 1.0, 12.0)
		var side := Vector2(-direction.y, direction.x)
		draw_line(endpoint - side * 11.0, endpoint + side * 11.0, color, 2.5)
		if selected:
			draw_arc(endpoint, 15.0, 0.0, TAU, 24, Color(color, 0.72), 2.0)


func _draw_targets() -> void:
	var fallback_font := ThemeDB.fallback_font
	for target in _targets:
		var position := target.position as Vector2
		var selected: bool = int(target.mode) == int(_mode)
		var flash := float(target.hit_flash) > 0.0
		var color := Color("fff0a6") if flash else (
			Color("82f6d2") if selected else Color("809590")
		)
		draw_circle(position, 22.0, Color(color, 0.12))
		draw_arc(position, 22.0, 0.0, TAU, 28, color, 3.0 if selected else 1.5)
		draw_line(position + Vector2(0.0, 22.0), position + Vector2(0.0, 54.0), color, 4.0)
		draw_line(position + Vector2(-15.0, 36.0), position + Vector2(15.0, 36.0), color, 3.0)
		var label := "%dm" % int(float(SKILLS[int(target.mode)].range) / 10.0)
		draw_string(
			fallback_font,
			position + Vector2(-17.0, 78.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			50.0,
			16,
			color,
		)


func _draw_close_burst() -> void:
	var spec: Dictionary = SKILLS[_mode]
	var progress := phase_progress()
	var center := _cast_origin + _cast_direction * float(spec.range) * 0.55
	if _phase == "windup":
		var charge_size := lerpf(34.0, 74.0, progress)
		_draw_atlas_cell(STEADFAST_ATLAS, 0, 0, center, charge_size, progress * 0.2)
		draw_arc(center, 48.0, -0.7, 0.7, 20, Color(0.55, 0.9, 1.0, 0.65), 2.0)
	elif _phase == "active":
		var frame := clampi(floori(progress * 4.0), 0, 3)
		var size := lerpf(118.0, 224.0, progress)
		_draw_atlas_cell(
			STEADFAST_ATLAS,
			frame,
			1,
			center,
			size,
			_cast_direction.angle(),
			Color(1.0, 1.0, 1.0, 1.0 - progress * 0.22),
		)
		draw_arc(
			_cast_origin,
			float(spec.range) * (0.55 + progress * 0.45),
			_cast_direction.angle() - 0.72,
			_cast_direction.angle() + 0.72,
			32,
			Color(1.0, 0.2, 0.42, 0.68 * (1.0 - progress)),
			5.0,
		)


func _draw_mid_bolt() -> void:
	var progress := phase_progress()
	if _phase == "windup":
		var muzzle := _cast_origin + _cast_direction * 48.0
		_draw_atlas_cell(ARMORER_ATLAS, 1, 0, muzzle, lerpf(46.0, 92.0, progress), _cast_direction.angle())
	elif _phase == "active":
		var eased := 1.0 - pow(1.0 - progress, 2.4)
		var projectile := _cast_origin.lerp(_cast_endpoint, eased)
		for index in range(4):
			var trail_position := projectile - _cast_direction * float(index + 1) * 24.0
			_draw_atlas_cell(
				ARMORER_ATLAS,
				2,
				0,
				trail_position,
				64.0 - index * 9.0,
				_cast_direction.angle(),
				Color(1.0, 1.0, 1.0, 0.62 - index * 0.11),
			)
		draw_line(_cast_origin + _cast_direction * 42.0, projectile, Color(1.0, 0.5, 0.2, 0.48), 3.0)
		if progress > 0.82:
			_draw_atlas_cell(
				ARMORER_ATLAS,
				2,
				2,
				_cast_endpoint,
				lerpf(78.0, 154.0, (progress - 0.82) / 0.18),
				0.0,
			)


func _draw_long_rift() -> void:
	var progress := phase_progress()
	if _phase == "windup":
		var telegraph_size := lerpf(112.0, 210.0, progress)
		_draw_atlas_cell(
			RESONANT_ATLAS,
			0,
			2,
			_cast_endpoint,
			telegraph_size,
			progress * 0.7,
			Color(1.0, 1.0, 1.0, 0.56 + progress * 0.4),
		)
		draw_arc(
			_cast_endpoint,
			108.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * progress,
			48,
			Color("8e8cff"),
			4.0,
		)
		var orb := _cast_origin.lerp(_cast_endpoint, progress * 0.26)
		_draw_atlas_cell(RESONANT_ATLAS, 2, 1, orb, 66.0 + progress * 34.0, progress * 1.8)
	elif _phase == "active":
		var frame := clampi(floori(progress * 4.0), 0, 3)
		_draw_atlas_cell(
			RESONANT_ATLAS,
			frame,
			3,
			_cast_endpoint,
			lerpf(156.0, 254.0, sin(progress * PI)),
			0.0,
		)
		draw_circle(_cast_endpoint, 92.0 * progress, Color(0.16, 0.12, 0.5, 0.26 * (1.0 - progress)))


func _draw_atlas_cell(
	atlas: Texture2D,
	column: int,
	row: int,
	center: Vector2,
	draw_size: float,
	rotation := 0.0,
	modulate := Color.WHITE,
) -> void:
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		atlas,
		Rect2(Vector2(-draw_size, -draw_size) * 0.5, Vector2(draw_size, draw_size)),
		Rect2(column * 128.0, row * 128.0, 128.0, 128.0),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
