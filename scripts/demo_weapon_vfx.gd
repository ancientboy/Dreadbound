class_name DemoWeaponVFX
extends Node2D

## Shared scalable weapon effects used by both the permanent action demo and
## the formal player presentation. Most geometry stays procedural; only
## signature melee gear uses authored HD textures with runtime motion.
const MAX_EVENTS := 24
const MELEE_VISUAL_SCALE := 0.78
const MELEE_BACK_LAYER := 0
const MELEE_FRONT_LAYER := 80
const BASIC_MELEE_CRESCENT: Texture2D = preload("res://assets/art/vfx/basic_melee_crescent.svg")
const MELEE_TEXTURES := {
	&"echo_cross": preload(
		"res://assets/art/vfx/melee_hd/runtime/echo_cross_slash.png"
	),
	&"reaper_arc": preload(
		"res://assets/art/vfx/melee_hd/runtime/director_reaper_arc.png"
	),
}
const MELEE_PROFILES := {
	&"sword": {
		"style": &"light_arc",
		"rotation": -0.10,
		"delay": 0.08,
		"duration": 0.30,
		"reach": 92.0,
		"shake": 2.6,
	},
	&"heavy_blade": {
		"style": &"heavy_arc",
		"rotation": -PI * 0.5,
		"delay": 0.15,
		"duration": 0.42,
		"reach": 106.0,
		"shake": 5.0,
	},
	&"crowbar": {
		"style": &"blunt_arc",
		"rotation": 0.0,
		"delay": 0.11,
		"duration": 0.32,
		"reach": 88.0,
		"shake": 3.4,
	},
	&"insulated_crowbar": {
		"style": &"electric_arc",
		"rotation": 0.0,
		"delay": 0.11,
		"duration": 0.34,
		"reach": 92.0,
		"shake": 3.6,
	},
	&"echo_edge": {
		"style": &"hd",
		"texture": &"echo_cross",
		"size": 174.0,
		"pivot": Vector2(0.50, 0.50),
		"rotation": -0.10,
		"delay": 0.09,
		"duration": 0.34,
		"reach": 96.0,
		"shake": 3.0,
	},
	&"volatile_edge": {
		"style": &"rift_arc",
		"rotation": -0.18,
		"delay": 0.12,
		"duration": 0.40,
		"reach": 102.0,
		"shake": 4.4,
	},
	&"director_reaper": {
		"style": &"hd",
		"texture": &"reaper_arc",
		"size": 202.0,
		"pivot": Vector2(0.50, 0.50),
		"rotation": 0.0,
		"delay": 0.13,
		"duration": 0.44,
		"reach": 112.0,
		"shake": 4.2,
	},
	&"director_reaper_awakened": {
		"style": &"hd",
		"texture": &"reaper_arc",
		"size": 230.0,
		"pivot": Vector2(0.50, 0.50),
		"rotation": 0.0,
		"delay": 0.12,
		"duration": 0.47,
		"reach": 126.0,
		"shake": 5.0,
	},
	&"director_reaper_final": {
		"style": &"hd",
		"texture": &"reaper_arc",
		"size": 258.0,
		"pivot": Vector2(0.50, 0.50),
		"rotation": 0.0,
		"delay": 0.10,
		"duration": 0.52,
		"reach": 142.0,
		"shake": 6.0,
	},
}
const FAMILY_COLORS := {
	&"sword": Color("d7e4e8"),
	&"crowbar": Color("d8bd83"),
	&"echo_edge": Color("54efd2"),
	&"insulated_crowbar": Color("7dd8ef"),
	&"volatile_edge": Color("b66cff"),
	&"director_reaper": Color("e57a6e"),
	&"director_reaper_awakened": Color("ff6d72"),
	&"director_reaper_final": Color("ff466c"),
	&"pistol": Color("79d8e8"),
	&"balanced_pistol": Color("74ddf4"),
	&"breach_shotgun": Color("ffae61"),
	&"nullpoint_sidearm": Color("71e6ff"),
	&"siege_core": Color("ff8755"),
	&"conductor_railgun": Color("79e9ff"),
	&"conductor_railgun_awakened": Color("9ba8ff"),
	&"conductor_railgun_final": Color("d194ff"),
	&"staff": Color("9ee8ff"),
	&"echo_staff": Color("bd75ff"),
	&"bow": Color("cfe7d7"),
	&"mourning_bow": Color("a8e7ee"),
}

var _events: Array[Dictionary] = []
var _last_effect := &""
var _last_family := &""
var _last_direction := Vector2.RIGHT


func _ready() -> void:
	set_as_top_level(true)
	for index in MAX_EVENTS:
		var sprite := _make_melee_sprite()
		var trail := _make_melee_sprite()
		_events.append({
			"active": false,
			"sprite": sprite,
			"trail": trail,
		})


func _process(delta: float) -> void:
	var redraw := false
	for event in _events:
		if not event.active:
			continue
		event.age += delta
		if event.age >= event.delay + event.duration:
			event.active = false
			_hide_melee_sprites(event)
		elif event.kind == &"melee":
			_update_melee_sprites(event)
		redraw = true
	if redraw:
		queue_redraw()


func play_melee(origin: Vector2, direction: Vector2, family: StringName) -> void:
	var color := _family_color(family)
	var profile: Dictionary = MELEE_PROFILES.get(family, MELEE_PROFILES[&"sword"])
	var cardinal_direction := _cardinal_direction(direction)
	var effect_origin := melee_effect_origin(origin, cardinal_direction, family)
	var remaining_reach := maxf(
		float(profile.reach) - origin.distance_to(effect_origin),
		24.0,
	)
	_spawn(
		&"melee",
		effect_origin,
		cardinal_direction,
		remaining_reach,
		float(profile.delay),
		float(profile.duration),
		color,
		family,
	)
	_last_effect = &"melee"
	_last_family = family
	_last_direction = cardinal_direction
	_kick_camera(float(profile.shake), minf(float(profile.duration) * 0.42, 0.18))


func play_ballistic(
	origin: Vector2,
	direction: Vector2,
	family: StringName,
	reach := 300.0,
) -> void:
	var color := _family_color(family)
	var effect_kind := &"ballistic"
	if family in [&"breach_shotgun", &"siege_core"]:
		effect_kind = &"shotgun"
	elif family in [
		&"conductor_railgun",
		&"conductor_railgun_awakened",
		&"conductor_railgun_final",
	]:
		effect_kind = &"rail"
	_spawn(
		effect_kind,
		origin,
		direction.normalized(),
		maxf(reach, 24.0),
		0.16,
		0.34,
		color,
		family,
	)
	_last_effect = effect_kind
	_last_family = family
	_last_direction = direction.normalized()
	_kick_camera(4.0 if effect_kind != &"ballistic" else 2.0, 0.13)


func play_arcane(
	origin: Vector2,
	direction: Vector2,
	family: StringName,
	reach := 260.0,
) -> void:
	var color := _family_color(family)
	_spawn(
		&"arcane",
		origin,
		direction.normalized(),
		maxf(reach, 24.0),
		0.04,
		0.62,
		color,
		family,
	)
	_last_effect = &"arcane"
	_last_family = family
	_last_direction = direction.normalized()
	_kick_camera(2.4, 0.16)


func play_bow(
	origin: Vector2,
	direction: Vector2,
	family: StringName,
	reach := 320.0,
) -> void:
	var color := _family_color(family)
	_spawn(
		&"bow",
		origin,
		direction.normalized(),
		maxf(reach, 24.0),
		0.04,
		0.48,
		color,
		family,
	)
	_last_effect = &"bow"
	_last_family = family
	_last_direction = direction.normalized()
	_kick_camera(1.4, 0.10)


func active_effect_count() -> int:
	var count := 0
	for event in _events:
		if event.active:
			count += 1
	return count


func last_effect() -> StringName:
	return _last_effect


func last_family() -> StringName:
	return _last_family


func last_direction() -> Vector2:
	return _last_direction


func melee_texture_id(family: StringName) -> StringName:
	var profile: Dictionary = MELEE_PROFILES.get(family, MELEE_PROFILES[&"sword"])
	return profile.get("texture", &"") as StringName


func melee_uses_hd_texture(family: StringName) -> bool:
	var profile: Dictionary = MELEE_PROFILES.get(family, MELEE_PROFILES[&"sword"])
	return profile.get("style", &"") == &"hd"


func melee_uses_crescent(family: StringName) -> bool:
	return not melee_uses_hd_texture(family)


func melee_layer_for_direction(direction: Vector2) -> int:
	return (
		MELEE_BACK_LAYER
		if _cardinal_direction(direction).y < -0.5
		else MELEE_FRONT_LAYER
	)


func melee_effect_origin(
	origin: Vector2,
	direction: Vector2,
	family: StringName,
) -> Vector2:
	var profile: Dictionary = MELEE_PROFILES.get(family, MELEE_PROFILES[&"sword"])
	var cardinal_direction := _cardinal_direction(direction)
	var cast_offset := clampf(float(profile.reach) * 0.56, 48.0, 68.0)
	return origin + cardinal_direction * cast_offset


func _family_color(family: StringName) -> Color:
	return FAMILY_COLORS.get(family, Color("9ee8ff"))


func _spawn(
	kind: StringName,
	origin: Vector2,
	direction: Vector2,
	reach: float,
	delay: float,
	duration: float,
	color: Color,
	family: StringName,
) -> void:
	for event in _events:
		if event.active:
			continue
		event.active = true
		event.kind = kind
		event.origin = origin
		event.direction = direction
		event.reach = reach
		event.delay = delay
		event.duration = duration
		event.age = 0.0
		event.color = color
		event.family = family
		_prepare_melee_sprites(event)
		queue_redraw()
		return


func _make_melee_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.visible = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = additive
	add_child(sprite)
	return sprite


func _prepare_melee_sprites(event: Dictionary) -> void:
	_hide_melee_sprites(event)
	if event.kind != &"melee":
		return
	var profile: Dictionary = MELEE_PROFILES.get(
		event.family as StringName,
		MELEE_PROFILES[&"sword"],
	)
	if profile.get("style", &"") != &"hd":
		return
	var texture := MELEE_TEXTURES[profile.texture] as Texture2D
	var pivot := profile.pivot as Vector2
	for sprite_key in [&"sprite", &"trail"]:
		var sprite := event[sprite_key] as Sprite2D
		sprite.texture = texture
		sprite.offset = -Vector2(texture.get_size()) * pivot
		sprite.z_as_relative = false
		sprite.z_index = melee_layer_for_direction(event.direction)


func _hide_melee_sprites(event: Dictionary) -> void:
	for sprite_key in [&"sprite", &"trail"]:
		var sprite := event.get(sprite_key) as Sprite2D
		if is_instance_valid(sprite):
			sprite.visible = false


func _update_melee_sprites(event: Dictionary) -> void:
	var local_age: float = event.age - event.delay
	if local_age < 0.0:
		_hide_melee_sprites(event)
		return
	var progress := clampf(local_age / float(event.duration), 0.0, 1.0)
	var profile: Dictionary = MELEE_PROFILES.get(
		event.family as StringName,
		MELEE_PROFILES[&"sword"],
	)
	if profile.get("style", &"") != &"hd":
		_hide_melee_sprites(event)
		return
	var texture := MELEE_TEXTURES[profile.texture] as Texture2D
	var direction := event.direction as Vector2
	var normal := direction.orthogonal()
	var reveal := smoothstep(0.0, 0.16, progress)
	var fade := 1.0 - smoothstep(0.58, 1.0, progress)
	var sweep := ease(clampf(progress / 0.64, 0.0, 1.0), -1.45)
	var max_edge := maxf(texture.get_width(), texture.get_height())
	var base_scale := float(profile.size) * MELEE_VISUAL_SCALE / max_edge
	var rotation := (
		direction.angle()
		+ float(profile.rotation)
		+ lerpf(-0.30, 0.10, sweep)
	)
	var position_offset := direction * lerpf(-8.0, 8.0, sweep)
	position_offset += normal * sin(progress * PI) * 3.0

	var sprite := event.sprite as Sprite2D
	sprite.visible = fade > 0.001
	sprite.position = event.origin + position_offset
	sprite.rotation = rotation
	sprite.scale = Vector2.ONE * base_scale * lerpf(0.72, 1.04, reveal)
	sprite.modulate = Color(1.0, 1.0, 1.0, fade * reveal)

	var trail := event.trail as Sprite2D
	trail.visible = progress > 0.04 and fade > 0.001
	trail.position = event.origin + position_offset - direction * 4.0
	trail.rotation = rotation - 0.12
	trail.scale = Vector2.ONE * base_scale * lerpf(0.68, 0.98, reveal)
	trail.modulate = Color(event.color, fade * reveal * 0.24)


func _cardinal_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return Vector2.RIGHT
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _kick_camera(strength: float, duration: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("add_attack_shake"):
		camera.call("add_attack_shake", strength, duration)


func _draw() -> void:
	for event in _events:
		if not event.active or event.age < event.delay:
			continue
		var progress: float = clampf(
			(event.age - event.delay) / event.duration,
			0.0,
			1.0,
		)
		match event.kind as StringName:
			&"melee":
				_draw_melee_accents(event, progress)
			&"ballistic", &"shotgun", &"rail":
				_draw_ballistic(event, progress)
			&"arcane":
				_draw_arcane(event, progress)
			&"bow":
				_draw_bow(event, progress)


func _draw_melee_accents(event: Dictionary, progress: float) -> void:
	var origin: Vector2 = event.origin
	var direction: Vector2 = event.direction
	var color: Color = event.color
	var profile: Dictionary = MELEE_PROFILES.get(
		event.family as StringName,
		MELEE_PROFILES[&"sword"],
	)
	if profile.get("style", &"") != &"hd":
		_draw_procedural_melee(event, progress, profile)
		return
	var fade := 1.0 - smoothstep(0.62, 1.0, progress)
	var radius := float(event.reach)
	var tip := origin + direction * radius
	for index in range(4):
		var spark_angle := direction.angle() + lerpf(-0.36, 0.36, float(index) / 3.0)
		var spark_length := (10.0 + index * 3.0) * fade
		draw_line(
			tip,
			tip + Vector2.from_angle(spark_angle) * spark_length,
			Color(color.lightened(0.55), 0.85 * fade),
			1.5,
			true,
		)
	if progress > 0.56:
		_draw_impact(
			origin + direction * radius,
			color,
			(progress - 0.56) / 0.44,
			true,
		)


func _draw_procedural_melee(
	event: Dictionary,
	progress: float,
	profile: Dictionary,
) -> void:
	var origin: Vector2 = event.origin
	var direction: Vector2 = event.direction
	var color: Color = event.color
	var style := profile.get("style", &"light_arc") as StringName
	var fade := 1.0 - smoothstep(0.50, 1.0, progress)
	var presentation_scale := lerpf(
		0.96,
		1.0,
		ease(clampf(progress / 0.14, 0.0, 1.0), -1.8),
	)
	var draw_size := Vector2(132.0, 99.0)
	match style:
		&"heavy_arc":
			draw_size = Vector2(164.0, 123.0)
		&"blunt_arc":
			draw_size = Vector2(124.0, 93.0)
		&"electric_arc":
			draw_size = Vector2(134.0, 100.5)
		&"rift_arc":
			draw_size = Vector2(150.0, 112.5)
	draw_size *= presentation_scale

	# The asset is already a complete, transparent crescent. Never rebuild its
	# inner edge from radial points, which was the source of the center bulge.
	var rotation := direction.angle() + float(profile.rotation)
	draw_set_transform(origin, rotation, Vector2.ONE)
	draw_texture_rect(
		BASIC_MELEE_CRESCENT,
		Rect2(-draw_size * 0.54, draw_size * 1.08),
		false,
		Color(color, fade * 0.18),
	)
	draw_texture_rect(
		BASIC_MELEE_CRESCENT,
		Rect2(-draw_size * 0.5, draw_size),
		false,
		Color(color.lightened(0.24), fade * 0.92),
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ballistic(event: Dictionary, progress: float) -> void:
	var origin: Vector2 = event.origin
	var direction: Vector2 = event.direction
	var color: Color = event.color
	var reach: float = event.reach
	var kind: StringName = event.kind
	var flight := clampf(progress / 0.72, 0.0, 1.0)
	var projectile := origin + direction * reach * ease(flight, -1.8)
	var muzzle_fade := 1.0 - smoothstep(0.0, 0.24, progress)
	_draw_muzzle(origin, direction, color, muzzle_fade, kind != &"ballistic")
	if kind == &"shotgun":
		for index in range(7):
			var spread := lerpf(-0.28, 0.28, float(index) / 6.0)
			var pellet_direction := direction.rotated(spread)
			var pellet_end := origin + pellet_direction * reach * minf(flight * 1.25, 1.0)
			var pellet_start := pellet_end - pellet_direction * (34.0 + index % 2 * 8.0)
			draw_line(
				pellet_start,
				pellet_end,
				Color(color, 0.74 * (1.0 - progress)),
				1.7,
				true,
			)
	elif kind == &"rail":
		var beam_end := origin + direction * reach * minf(flight * 1.45, 1.0)
		var beam_fade := 1.0 - smoothstep(0.42, 1.0, progress)
		draw_line(origin, beam_end, Color(color, 0.18 * beam_fade), 18.0, true)
		draw_line(origin, beam_end, Color(color, 0.52 * beam_fade), 8.0, true)
		draw_line(origin, beam_end, Color.WHITE, 2.2 * beam_fade, true)
	else:
		var tail := projectile - direction * (52.0 + 28.0 * flight)
		draw_line(tail, projectile, Color(color, 0.20), 9.0, true)
		draw_line(tail, projectile, Color(color, 0.82), 3.0, true)
		draw_circle(projectile, 3.2, Color.WHITE)
	if progress > 0.66:
		_draw_impact(
			origin + direction * reach,
			color,
			(progress - 0.66) / 0.34,
			kind != &"ballistic",
		)


func _draw_arcane(event: Dictionary, progress: float) -> void:
	var origin: Vector2 = event.origin
	var direction: Vector2 = event.direction
	var normal := direction.orthogonal()
	var color: Color = event.color
	var reach: float = event.reach
	var charge := clampf(progress / 0.28, 0.0, 1.0)
	var flight := clampf((progress - 0.20) / 0.55, 0.0, 1.0)
	var impact_progress := clampf((progress - 0.68) / 0.32, 0.0, 1.0)
	var orb := origin + direction * reach * ease(flight, -1.45)
	var charge_fade := 1.0 - smoothstep(0.24, 0.48, progress)
	draw_circle(origin, 18.0 * charge, Color(color, 0.12 * charge_fade))
	draw_arc(
		origin,
		24.0 * charge,
		-progress * 6.0,
		TAU - progress * 6.0,
		32,
		Color(color.lightened(0.3), 0.9 * charge_fade),
		2.0,
		true,
	)
	if flight > 0.0 and flight < 1.0:
		var points := PackedVector2Array()
		for index in range(16):
			var ratio := float(index) / 15.0
			var trail_ratio := clampf(flight - (1.0 - ratio) * 0.25, 0.0, 1.0)
			var point := origin + direction * reach * ease(trail_ratio, -1.45)
			point += normal * sin(ratio * 15.0 - progress * 22.0) * 7.0 * ratio
			points.append(point)
		draw_polyline(points, Color(color, 0.22), 11.0, true)
		draw_polyline(points, Color(color, 0.88), 3.2, true)
		draw_circle(orb, 13.0, Color(color, 0.24))
		draw_circle(orb, 6.0, Color(color.lightened(0.48), 0.94))
		draw_circle(orb, 2.2, Color.WHITE)
	if impact_progress > 0.0:
		var endpoint := origin + direction * reach
		_draw_rune(endpoint, color, impact_progress)
		_draw_impact(endpoint, color, impact_progress, true)


func _draw_bow(event: Dictionary, progress: float) -> void:
	var origin: Vector2 = event.origin
	var direction: Vector2 = event.direction
	var color: Color = event.color
	var reach: float = event.reach
	var flight := clampf(progress / 0.76, 0.0, 1.0)
	var tip := origin + direction * reach * ease(flight, -1.5)
	var tail := tip - direction * 24.0
	draw_line(tail - direction * 30.0, tip, Color(color, 0.22), 7.0, true)
	draw_line(tail, tip, Color(color.lightened(0.34), 0.96), 2.2, true)
	draw_line(
		tail,
		tail - direction.rotated(0.68) * 8.0,
		Color(color, 0.9),
		1.6,
		true,
	)
	draw_line(
		tail,
		tail - direction.rotated(-0.68) * 8.0,
		Color(color, 0.9),
		1.6,
		true,
	)
	draw_line(
		tip,
		tip - direction.rotated(0.48) * 8.0,
		Color.WHITE,
		1.8,
		true,
	)
	draw_line(
		tip,
		tip - direction.rotated(-0.48) * 8.0,
		Color.WHITE,
		1.8,
		true,
	)
	if progress > 0.70:
		_draw_impact(
			origin + direction * reach,
			color,
			(progress - 0.70) / 0.30,
			false,
		)


func _draw_arc_ribbon(
	center: Vector2,
	inner_radius: float,
	outer_radius: float,
	start_angle: float,
	end_angle: float,
	color: Color,
) -> void:
	var points := PackedVector2Array()
	var segments := 22
	for index in range(segments + 1):
		var ratio := float(index) / float(segments)
		points.append(
			center + Vector2.from_angle(lerpf(start_angle, end_angle, ratio)) * outer_radius
		)
	for index in range(segments, -1, -1):
		var ratio := float(index) / float(segments)
		points.append(
			center + Vector2.from_angle(lerpf(start_angle, end_angle, ratio)) * inner_radius
		)
	draw_colored_polygon(points, color)


func _draw_muzzle(
	origin: Vector2,
	direction: Vector2,
	color: Color,
	fade: float,
	heavy: bool,
) -> void:
	if fade <= 0.0:
		return
	var normal := direction.orthogonal()
	var length := (42.0 if heavy else 28.0) * fade
	var width := (19.0 if heavy else 13.0) * fade
	draw_line(
		origin - direction * 3.0,
		origin + direction * length,
		Color(color.lightened(0.42), 0.88 * fade),
		maxf(width * 0.68, 0.5),
		true,
	)
	draw_line(
		origin + direction * length * 0.30,
		origin + direction * length * 0.58 + normal * width,
		Color(color, 0.72 * fade),
		2.4,
		true,
	)
	draw_line(
		origin + direction * length * 0.30,
		origin + direction * length * 0.58 - normal * width,
		Color(color, 0.72 * fade),
		2.4,
		true,
	)
	draw_circle(origin + direction * 5.0, 12.0 * fade, Color.WHITE)


func _draw_impact(
	position: Vector2,
	color: Color,
	progress: float,
	heavy: bool,
) -> void:
	var fade := 1.0 - progress
	var radius := lerpf(5.0, 34.0 if heavy else 23.0, progress)
	draw_circle(position, radius * 0.55, Color(color, 0.16 * fade))
	draw_arc(position, radius, 0.0, TAU, 28, Color(color, 0.86 * fade), 3.0, true)
	for index in range(8 if heavy else 6):
		var angle := TAU * float(index) / float(8 if heavy else 6) + progress * 0.35
		var start := position + Vector2.from_angle(angle) * radius * 0.48
		var end := position + Vector2.from_angle(angle) * radius * (1.35 + index % 2 * 0.25)
		draw_line(start, end, Color(color.lightened(0.36), 0.9 * fade), 2.0, true)


func _draw_rune(position: Vector2, color: Color, progress: float) -> void:
	var fade := 1.0 - progress
	var radius := lerpf(12.0, 42.0, minf(progress * 1.4, 1.0))
	draw_arc(
		position,
		radius,
		-progress * 2.0,
		TAU - progress * 2.0,
		36,
		Color(color, 0.84 * fade),
		2.2,
		true,
	)
	for index in range(6):
		var angle := TAU * float(index) / 6.0 + progress
		var point := position + Vector2.from_angle(angle) * radius
		draw_circle(point, 2.6, Color(color.lightened(0.42), 0.9 * fade))
