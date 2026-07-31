class_name MapRoomDoor
extends Area2D

signal traversal_requested(door: MapRoomDoor)

enum DoorState {
	SEALED,
	UNLOCKING,
	OPEN,
	TRAVERSING,
}

const VALID_DIRECTIONS := ["north", "south", "west", "east"]
const SIDE_DOOR_VISUAL_RECESS := 48.0
const LEGACY_FRAME := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/frame.png"
)
const LEGACY_LEFT_LEAF := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_left.png"
)
const LEGACY_RIGHT_LEAF := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_right.png"
)
var direction: StringName = &"north"
var state := DoorState.SEALED
var open_progress := 0.0
var _blocker_shape: CollisionShape2D
var _left_leaf: Node2D
var _right_leaf: Node2D
var _locked_indicator: Polygon2D
var _open_indicator: Polygon2D
var _seal_glow: Polygon2D
var _slide_axis := Vector2.RIGHT
var _theme: RoomTheme
var _visual_profile: Dictionary = {}
var _left_closed_position := Vector2.ZERO
var _right_closed_position := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = 42 if _uses_containment_visuals() and direction == &"south" else 28
	body_entered.connect(_on_body_entered)
	_build_visuals()
	_build_collision()


func configure(
	new_direction: StringName,
	world_anchor: Vector2,
	new_theme: RoomTheme = null,
	new_visual_profile: Dictionary = {},
) -> void:
	assert(VALID_DIRECTIONS.has(String(new_direction)))
	direction = new_direction
	global_position = world_anchor
	_theme = new_theme
	_visual_profile = new_visual_profile.duplicate(true)
	rotation = 0.0
	if (
		direction == &"south"
		and not _uses_containment_visuals()
		and not bool(_visual_profile.get("preserve_authored_orientation", false))
	):
		rotation = PI


func unlock() -> void:
	if state != DoorState.SEALED:
		return
	state = DoorState.UNLOCKING
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	var status_tween := create_tween()
	status_tween.tween_property(_locked_indicator, "modulate:a", 0.0, 0.14)
	status_tween.tween_callback(func() -> void: _open_indicator.visible = true)
	status_tween.tween_property(_open_indicator, "modulate:a", 1.0, 0.16)
	var direction_travel_key := "%s_travel_distance" % String(direction)
	var travel_distance := (
		float(_visual_profile.get(
			direction_travel_key,
			_visual_profile.get("travel_distance", 58.0),
		))
		if direction == &"west" or direction == &"east"
		else float(_visual_profile.get(
			direction_travel_key,
			86.0 if _uses_containment_visuals() else 78.0,
		))
	)
	var travel := _slide_axis * travel_distance
	var door_tween := create_tween().set_parallel(true)
	door_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	door_tween.tween_property(
		_left_leaf,
		"position",
		_left_closed_position - travel,
		0.48,
	)
	door_tween.tween_property(
		_right_leaf,
		"position",
		_right_closed_position + travel,
		0.48,
	)
	door_tween.tween_property(_seal_glow, "modulate:a", 0.0, 0.32)
	door_tween.tween_method(_set_open_progress, 0.0, 1.0, 0.48)
	door_tween.finished.connect(func() -> void: state = DoorState.OPEN)


func begin_traversal() -> void:
	if state == DoorState.OPEN:
		state = DoorState.TRAVERSING


func inward_vector() -> Vector2:
	match direction:
		&"north":
			return Vector2.DOWN
		&"south":
			return Vector2.UP
		&"west":
			return Vector2.RIGHT
		&"east":
			return Vector2.LEFT
	return Vector2.ZERO


func outward_vector() -> Vector2:
	return -inward_vector()


static func opposite_direction(value: StringName) -> StringName:
	match value:
		&"north":
			return &"south"
		&"south":
			return &"north"
		&"west":
			return &"east"
		&"east":
			return &"west"
	return &""


func _build_visuals() -> void:
	if _uses_containment_visuals():
		_build_containment_door_visuals()
		return
	if _visual_profile.has("art_texture_path"):
		_build_authored_tile_door_visuals()
		return
	if direction == &"west" or direction == &"east":
		_build_tile_door_visuals()
		return
	var frame_texture := LEGACY_FRAME
	var left_texture := LEGACY_LEFT_LEAF
	var right_texture := LEGACY_RIGHT_LEAF
	var visual_scale := 0.145

	var opening := Polygon2D.new()
	opening.name = "DoorOpening"
	opening.polygon = PackedVector2Array([
		Vector2(-64.0, -52.0),
		Vector2(64.0, -52.0),
		Vector2(64.0, 52.0),
		Vector2(-64.0, 52.0),
	])
	opening.color = Color(0.004, 0.014, 0.018, 1.0)
	opening.z_index = -6
	add_child(opening)

	var frame := _make_sprite("DoorFrame", frame_texture, visual_scale, 6)
	_left_leaf = _make_sprite("LeftLeaf", left_texture, visual_scale, 1)
	_right_leaf = _make_sprite("RightLeaf", right_texture, visual_scale, 1)
	frame.position = Vector2.ZERO

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = PackedVector2Array([
		Vector2(-54.0, -38.0),
		Vector2(54.0, -38.0),
		Vector2(54.0, 38.0),
		Vector2(-54.0, 38.0),
	])
	_seal_glow.color = Color(0.96, 0.13, 0.11, 0.075)
	_seal_glow.z_index = 3
	add_child(_seal_glow)

	_locked_indicator = _make_indicator(
		"LockedIndicator",
		_theme.door_locked_color if _theme != null else Color(1.0, 0.12, 0.08, 0.9),
	)
	_open_indicator = _make_indicator(
		"OpenIndicator",
		_theme.door_open_color if _theme != null else Color(0.18, 1.0, 0.72, 0.9),
	)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0
	_left_closed_position = _left_leaf.position
	_right_closed_position = _right_leaf.position


func _uses_containment_visuals() -> bool:
	return StringName(_visual_profile.get("style", &"")) == &"containment"


func _build_containment_door_visuals() -> void:
	_slide_axis = Vector2.RIGHT
	var visual_offset := Vector2.ZERO
	var leaf_color := (
		_theme.door_leaf_color
		if _theme != null
		else Color("142d36")
	)

	var opening := Polygon2D.new()
	opening.name = "DoorOpening"
	opening.polygon = PackedVector2Array([
		Vector2(-98, -58), Vector2(98, -58),
		Vector2(98, 58), Vector2(-98, 58),
	])
	opening.color = Color(0.012, 0.037, 0.046, 1.0)
	opening.z_index = -2
	opening.position = visual_offset
	add_child(opening)

	_left_leaf = _make_containment_leaf(
		"LeftLeaf",
		visual_offset + Vector2(-49, 0),
		leaf_color,
		false,
	)
	_right_leaf = _make_containment_leaf(
		"RightLeaf",
		visual_offset + Vector2(49, 0),
		leaf_color,
		true,
	)
	_left_closed_position = _left_leaf.position
	_right_closed_position = _right_leaf.position

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = PackedVector2Array([
		Vector2(-94, -54), Vector2(94, -54),
		Vector2(94, 54), Vector2(-94, 54),
	])
	_seal_glow.color = Color(0.78, 0.08, 0.055, 0.07)
	_seal_glow.z_index = 3
	_seal_glow.position = visual_offset
	add_child(_seal_glow)
	_locked_indicator = _make_indicator(
		"LockedIndicator",
		_theme.door_locked_color if _theme != null else Color(0.92, 0.14, 0.1, 0.9),
	)
	_open_indicator = _make_indicator(
		"OpenIndicator",
		_theme.door_open_color if _theme != null else Color(0.18, 0.9, 0.68, 0.9),
	)
	_locked_indicator.position = visual_offset + Vector2(82, 0)
	_open_indicator.position = visual_offset + Vector2(82, 0)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0


func _make_containment_leaf(
	node_name: String,
	center_position: Vector2,
	color: Color,
	mirror_details: bool,
) -> Polygon2D:
	var leaf := Polygon2D.new()
	leaf.name = node_name
	leaf.position = center_position
	leaf.polygon = PackedVector2Array([
		Vector2(-49, -58), Vector2(49, -58),
		Vector2(49, 58), Vector2(-49, 58),
	])
	leaf.color = color
	leaf.z_index = 2
	add_child(leaf)
	_add_frame_part(leaf, "InsetPanel", Rect2(-41, -49, 82, 98), color.lightened(0.08))
	_add_frame_part(leaf, "UpperEdge", Rect2(-40, -48, 80, 4), Color(0.31, 0.46, 0.51, 0.42))
	_add_frame_part(leaf, "LowerEdge", Rect2(-40, 44, 80, 4), Color(0.02, 0.07, 0.085, 0.78))
	var seam_x := -48.0 if mirror_details else 45.0
	_add_frame_part(leaf, "CenterSeam", Rect2(seam_x, -56, 3, 112), Color("061920"))
	var brace_x := 23.0 if mirror_details else -34.0
	_add_frame_part(leaf, "Brace", Rect2(brace_x, -31, 11, 62), Color(0.12, 0.25, 0.29, 0.92))
	_add_door_theme_stencil(leaf, Vector2(82, 98), mirror_details)
	return leaf


func _build_tile_door_visuals() -> void:
	if _visual_profile.has("art_texture_path"):
		_build_authored_tile_door_visuals()
		return
	_slide_axis = Vector2.DOWN
	var visual_offset := outward_vector() * SIDE_DOOR_VISUAL_RECESS
	var recess_shadow := Polygon2D.new()
	recess_shadow.name = "DoorRecessShadow"
	recess_shadow.polygon = PackedVector2Array([
		Vector2(-38, -62), Vector2(38, -62), Vector2(38, 62), Vector2(-38, 62),
	])
	recess_shadow.color = Color(0.005, 0.014, 0.018, 0.76)
	recess_shadow.z_index = -4
	recess_shadow.position = visual_offset
	add_child(recess_shadow)

	var opening := Polygon2D.new()
	opening.name = "DoorOpening"
	opening.polygon = PackedVector2Array([
		Vector2(-25, -47), Vector2(25, -47), Vector2(25, 47), Vector2(-25, 47),
	])
	opening.color = Color(0.009, 0.026, 0.031, 1.0)
	opening.z_index = -2
	opening.position = visual_offset
	add_child(opening)

	var frame := Node2D.new()
	frame.name = "DoorFrame"
	frame.z_index = 6
	frame.position = visual_offset
	add_child(frame)
	var frame_color := _theme.door_frame_color if _theme != null else Color("38565b")
	_add_frame_part(frame, "UpperPost", Rect2(-36, -60, 72, 14), frame_color.lightened(0.12))
	_add_frame_part(frame, "LowerPost", Rect2(-36, 46, 72, 14), frame_color.darkened(0.16))
	_add_frame_part(frame, "InnerRail", Rect2(-36, -46, 14, 92), frame_color.lightened(0.08))
	_add_frame_part(frame, "OuterRail", Rect2(22, -46, 14, 92), frame_color.lightened(0.08))
	_add_frame_part(frame, "UpperHighlight", Rect2(-31, -57, 62, 3), Color(0.65, 0.84, 0.84, 0.72))
	_add_frame_part(frame, "InnerRailHighlight", Rect2(-31, -42, 3, 84), Color(0.62, 0.82, 0.81, 0.52))
	_add_frame_part(frame, "OuterRailShadow", Rect2(29, -42, 4, 84), Color(0.04, 0.12, 0.14, 0.75))
	_add_frame_part(frame, "UpperAnchor", Rect2(-40, -40, 7, 18), Color("20373d"))
	_add_frame_part(frame, "LowerAnchor", Rect2(-40, 22, 7, 18), Color("20373d"))
	_add_frame_part(frame, "ControlHousing", Rect2(24, -16, 18, 32), Color("183239"))
	_add_frame_part(frame, "ControlInset", Rect2(28, -10, 10, 20), Color("071a20"))
	_add_door_warning_marks(frame)
	if direction == &"east":
		frame.scale.x = -1.0

	_left_leaf = _make_tile_leaf("LeftLeaf", visual_offset + Vector2(0, -24))
	_right_leaf = _make_tile_leaf("RightLeaf", visual_offset + Vector2(0, 24))
	_left_closed_position = _left_leaf.position
	_right_closed_position = _right_leaf.position

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = PackedVector2Array([
		Vector2(-19, -45), Vector2(19, -45), Vector2(19, 45), Vector2(-19, 45),
	])
	_seal_glow.color = Color(0.95, 0.12, 0.08, 0.075)
	_seal_glow.z_index = 3
	_seal_glow.position = visual_offset
	add_child(_seal_glow)
	_locked_indicator = _make_indicator(
		"LockedIndicator",
		_theme.door_locked_color if _theme != null else Color(1.0, 0.12, 0.08, 0.9),
	)
	_open_indicator = _make_indicator(
		"OpenIndicator",
		_theme.door_open_color if _theme != null else Color(0.18, 1.0, 0.72, 0.9),
	)
	_locked_indicator.position = visual_offset + Vector2(33, 0)
	_open_indicator.position = visual_offset + Vector2(33, 0)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0


func _build_authored_tile_door_visuals() -> void:
	var texture_path := String(_visual_profile["art_texture_path"])
	assert(
		ResourceLoader.exists(texture_path),
		"Authored door texture does not exist: %s" % texture_path,
	)
	var door_texture := load(texture_path) as Texture2D
	assert(door_texture != null, "Authored door texture must be a Texture2D")
	var source_key := "%s_source_region" % String(direction)
	var source_region: Rect2 = _visual_profile.get(source_key, Rect2())
	assert(source_region.has_area(), "Authored door requires a source region")
	var visual_scale_key := "%s_visual_scale" % String(direction)
	var visual_scale := float(_visual_profile.get(
		visual_scale_key,
		_visual_profile.get("visual_scale", 1.0),
	))
	var split_axis_key := "%s_split_axis" % String(direction)
	var split_axis := StringName(_visual_profile.get(
		split_axis_key,
		_visual_profile.get("split_axis", &"horizontal"),
	))
	assert(
		split_axis == &"horizontal" or split_axis == &"vertical",
		"Authored door split axis must be horizontal or vertical",
	)
	_slide_axis = Vector2.DOWN if split_axis == &"vertical" else Vector2.RIGHT
	var recess := float(_visual_profile.get(
		"side_visual_recess",
		SIDE_DOOR_VISUAL_RECESS,
	))
	var visual_offset := outward_vector() * recess

	var opening := Polygon2D.new()
	opening.name = "DoorOpening"
	var opening_half_size := source_region.size * visual_scale * 0.5
	opening.polygon = PackedVector2Array([
		Vector2(-opening_half_size.x, -opening_half_size.y),
		Vector2(opening_half_size.x, -opening_half_size.y),
		opening_half_size,
		Vector2(-opening_half_size.x, opening_half_size.y),
	])
	opening.color = Color(0.004, 0.014, 0.018, 1.0)
	opening.z_index = -2
	opening.position = visual_offset
	add_child(opening)

	var frame := Node2D.new()
	frame.name = "DoorFrame"
	frame.position = visual_offset
	frame.z_index = 6
	add_child(frame)

	var first_region: Rect2
	var second_region: Rect2
	var first_position: Vector2
	var second_position: Vector2
	if split_axis == &"vertical":
		var half_height := source_region.size.y * 0.5
		first_region = Rect2(
			source_region.position,
			Vector2(source_region.size.x, half_height),
		)
		second_region = Rect2(
			source_region.position + Vector2(0, half_height),
			Vector2(source_region.size.x, half_height),
		)
		first_position = visual_offset + Vector2(
			0,
			-half_height * visual_scale * 0.5,
		)
		second_position = visual_offset + Vector2(
			0,
			half_height * visual_scale * 0.5,
		)
	else:
		var half_width := source_region.size.x * 0.5
		first_region = Rect2(
			source_region.position,
			Vector2(half_width, source_region.size.y),
		)
		second_region = Rect2(
			source_region.position + Vector2(half_width, 0),
			Vector2(half_width, source_region.size.y),
		)
		first_position = visual_offset + Vector2(
			-half_width * visual_scale * 0.5,
			0,
		)
		second_position = visual_offset + Vector2(
			half_width * visual_scale * 0.5,
			0,
		)
	_left_leaf = _make_authored_leaf(
		"LeftLeaf",
		door_texture,
		first_region,
		first_position,
		visual_scale,
	)
	_right_leaf = _make_authored_leaf(
		"RightLeaf",
		door_texture,
		second_region,
		second_position,
		visual_scale,
	)
	_left_closed_position = _left_leaf.position
	_right_closed_position = _right_leaf.position

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = opening.polygon
	_seal_glow.color = Color(0.95, 0.12, 0.08, 0.055)
	_seal_glow.position = visual_offset
	_seal_glow.z_index = 3
	add_child(_seal_glow)
	_locked_indicator = _make_indicator(
		"LockedIndicator",
		_theme.door_locked_color if _theme != null else Color(1.0, 0.12, 0.08, 0.9),
	)
	_open_indicator = _make_indicator(
		"OpenIndicator",
		_theme.door_open_color if _theme != null else Color(0.18, 1.0, 0.72, 0.9),
	)
	var indicator_offset := opening_half_size.x + 8.0
	_locked_indicator.position = visual_offset + Vector2(indicator_offset, 0)
	_open_indicator.position = visual_offset + Vector2(indicator_offset, 0)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0


func _make_authored_leaf(
	node_name: String,
	texture: Texture2D,
	source_region: Rect2,
	center_position: Vector2,
	visual_scale: float,
) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = source_region
	var leaf := Sprite2D.new()
	leaf.name = node_name
	leaf.texture = atlas
	leaf.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.position = center_position
	leaf.scale = Vector2.ONE * visual_scale
	leaf.z_index = 2
	add_child(leaf)
	return leaf


func _add_frame_part(
	parent_node: Node2D,
	node_name: String,
	bounds: Rect2,
	color := Color(0.35, 0.55, 0.57, 1.0),
) -> Polygon2D:
	var part := Polygon2D.new()
	part.name = node_name
	part.polygon = PackedVector2Array([
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		bounds.end,
		Vector2(bounds.position.x, bounds.end.y),
	])
	part.color = color
	parent_node.add_child(part)
	return part


func _add_door_warning_marks(frame: Node2D) -> void:
	for index in 3:
		var mark := Polygon2D.new()
		mark.name = "WarningMark%d" % (index + 1)
		var y_pos := -46.0 + index * 14.0
		mark.polygon = PackedVector2Array([
			Vector2(26, y_pos),
			Vector2(35, y_pos + 5),
			Vector2(35, y_pos + 9),
			Vector2(26, y_pos + 4),
		])
		mark.color = Color(0.86, 0.66, 0.22, 0.78)
		frame.add_child(mark)


func _make_tile_leaf(node_name: String, center_position: Vector2) -> Polygon2D:
	var leaf := Polygon2D.new()
	leaf.name = node_name
	leaf.position = center_position
	leaf.polygon = PackedVector2Array([
		Vector2(-19, -23), Vector2(19, -23), Vector2(19, 23), Vector2(-19, 23),
	])
	leaf.color = (
		_theme.door_leaf_color
		if _theme != null
		else Color(0.12, 0.27, 0.3, 1.0)
	)
	leaf.z_index = 2
	add_child(leaf)
	_add_frame_part(leaf, "InsetPanel", Rect2(-14, -17, 28, 32), Color("25444a"))
	_add_frame_part(leaf, "InnerHighlight", Rect2(-11, -15, 3, 27), Color(0.43, 0.68, 0.69, 0.48))
	_add_frame_part(leaf, "CenterSeam", Rect2(-2, -23, 4, 46), Color("081c22"))
	_add_door_theme_stencil(leaf, Vector2(28, 32), node_name == "RightLeaf")
	return leaf


func _add_door_theme_stencil(
	parent_node: Node2D,
	bounds: Vector2,
	mirror_details: bool,
) -> void:
	var stencil := Node2D.new()
	stencil.name = "ThemeStencil"
	stencil.z_index = 5
	parent_node.add_child(stencil)
	var mark_color: Color = _visual_profile.get(
		"mark_color",
		Color(0.38, 0.82, 0.76, 0.56),
	)
	var mark_id := StringName(_visual_profile.get("theme_mark", &"medical_cross"))
	if mark_id == &"containment_warning":
		_add_containment_warning_stencil(stencil, bounds, mark_color)
	else:
		_add_medical_stencil(stencil, bounds, mark_color, mirror_details)


func _add_medical_stencil(
	stencil: Node2D,
	bounds: Vector2,
	color: Color,
	mirror_details: bool,
) -> void:
	var scale_factor := clampf(minf(bounds.x / 82.0, bounds.y / 98.0), 0.42, 1.0)
	var cross := Polygon2D.new()
	cross.name = "MedicalCross"
	cross.polygon = PackedVector2Array([
		Vector2(-4, -17), Vector2(4, -17), Vector2(4, -5),
		Vector2(16, -5), Vector2(16, 5), Vector2(4, 5),
		Vector2(4, 17), Vector2(-4, 17), Vector2(-4, 5),
		Vector2(-16, 5), Vector2(-16, -5), Vector2(-4, -5),
	])
	cross.color = color
	cross.scale = Vector2.ONE * scale_factor
	stencil.add_child(cross)
	var stripe := Line2D.new()
	stripe.name = "IsolationStripe"
	stripe.points = PackedVector2Array([
		Vector2(-bounds.x * 0.34, bounds.y * 0.34),
		Vector2(bounds.x * 0.34, bounds.y * 0.34),
	])
	stripe.width = maxf(1.5, 3.0 * scale_factor)
	stripe.default_color = Color(color.r, color.g, color.b, color.a * 0.72)
	stripe.antialiased = true
	stencil.add_child(stripe)
	if mirror_details:
		stencil.scale.x = -1.0


func _add_containment_warning_stencil(
	stencil: Node2D,
	bounds: Vector2,
	color: Color,
) -> void:
	var scale_factor := clampf(minf(bounds.x / 82.0, bounds.y / 98.0), 0.42, 1.0)
	var triangle := Line2D.new()
	triangle.name = "WarningTriangle"
	triangle.points = PackedVector2Array([
		Vector2(0, -25), Vector2(23, 19), Vector2(-23, 19), Vector2(0, -25),
	])
	triangle.width = 3.2
	triangle.default_color = color
	triangle.antialiased = true
	triangle.scale = Vector2.ONE * scale_factor
	stencil.add_child(triangle)
	var alert_bar := _add_frame_part(
		stencil,
		"AlertBar",
		Rect2(-2.5, -12, 5, 18),
		color,
	)
	alert_bar.scale = Vector2.ONE * scale_factor
	var alert_dot := _add_frame_part(
		stencil,
		"AlertDot",
		Rect2(-2.5, 10, 5, 5),
		color,
	)
	alert_dot.scale = Vector2.ONE * scale_factor
	var lower_stripe := Line2D.new()
	lower_stripe.name = "ContainmentStripe"
	lower_stripe.points = PackedVector2Array([
		Vector2(-bounds.x * 0.34, bounds.y * 0.38),
		Vector2(bounds.x * 0.34, bounds.y * 0.38),
	])
	lower_stripe.width = maxf(1.5, 3.0 * scale_factor)
	lower_stripe.default_color = Color(color.r, color.g, color.b, color.a * 0.68)
	lower_stripe.antialiased = true
	stencil.add_child(lower_stripe)


func _make_sprite(
	node_name: String,
	texture: Texture2D,
	uniform_scale: float,
	layer: int,
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.z_index = layer
	add_child(sprite)
	return sprite


func _make_indicator(node_name: String, color: Color) -> Polygon2D:
	var indicator := Polygon2D.new()
	indicator.name = node_name
	indicator.polygon = PackedVector2Array([
		Vector2(-7.0, -3.0),
		Vector2(7.0, -3.0),
		Vector2(7.0, 3.0),
		Vector2(-7.0, 3.0),
	])
	indicator.position = Vector2(0.0, -52.0)
	indicator.color = color
	indicator.z_index = 9
	add_child(indicator)
	return indicator


func _build_collision() -> void:
	var trigger := CollisionShape2D.new()
	trigger.name = "TraversalTrigger"
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(134.0, 122.0)
	trigger.shape = trigger_shape
	trigger.position = inward_vector() * 30.0
	add_child(trigger)

	var blocker := StaticBody2D.new()
	blocker.name = "DoorBlocker"
	blocker.collision_layer = 1
	blocker.collision_mask = 1
	_blocker_shape = CollisionShape2D.new()
	_blocker_shape.name = "CollisionShape2D"
	var blocker_rectangle := RectangleShape2D.new()
	blocker_rectangle.size = (
		Vector2(34.0, 142.0)
		if direction == &"west" or direction == &"east"
		else Vector2(142.0, 34.0)
	)
	_blocker_shape.shape = blocker_rectangle
	blocker.add_child(_blocker_shape)
	add_child(blocker)


func _set_open_progress(value: float) -> void:
	open_progress = clampf(value, 0.0, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if state != DoorState.OPEN or not body.is_in_group("player"):
		return
	traversal_requested.emit(self)
