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
	if direction == &"south" and not _uses_containment_visuals():
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
	var travel_distance := (
		86.0
		if _uses_containment_visuals()
		else (58.0 if direction == &"west" or direction == &"east" else 78.0)
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
	var recess := float(_visual_profile.get("recess", 58.0))
	var visual_offset := outward_vector() * recess
	var frame_color := (
		_theme.door_frame_color
		if _theme != null
		else Color("293f4b")
	)
	var leaf_color := (
		_theme.door_leaf_color
		if _theme != null
		else Color("142d36")
	)

	var recess_shadow := Polygon2D.new()
	recess_shadow.name = "DoorRecessShadow"
	recess_shadow.polygon = PackedVector2Array([
		Vector2(-112, -62), Vector2(112, -62),
		Vector2(112, 62), Vector2(-112, 62),
	])
	recess_shadow.color = Color(0.018, 0.047, 0.058, 1.0)
	recess_shadow.z_index = -5
	recess_shadow.position = visual_offset
	add_child(recess_shadow)

	var opening := Polygon2D.new()
	opening.name = "DoorOpening"
	opening.polygon = PackedVector2Array([
		Vector2(-92, -40), Vector2(92, -40),
		Vector2(92, 40), Vector2(-92, 40),
	])
	opening.color = Color(0.025, 0.065, 0.078, 1.0)
	opening.z_index = -2
	opening.position = visual_offset
	add_child(opening)

	var frame := Node2D.new()
	frame.name = "DoorFrame"
	frame.z_index = 6
	frame.position = visual_offset
	add_child(frame)
	_add_frame_part(frame, "UpperBeam", Rect2(-104, -58, 208, 18), frame_color.lightened(0.08))
	_add_frame_part(frame, "LowerBeam", Rect2(-104, 40, 208, 18), frame_color.darkened(0.13))
	_add_frame_part(frame, "LeftPost", Rect2(-104, -40, 18, 80), frame_color)
	_add_frame_part(frame, "RightPost", Rect2(86, -40, 18, 80), frame_color)
	_add_frame_part(frame, "UpperInset", Rect2(-84, -52, 168, 4), Color(0.34, 0.48, 0.54, 0.42))
	_add_frame_part(frame, "LowerInset", Rect2(-84, 47, 168, 4), Color(0.025, 0.075, 0.09, 0.82))
	_add_frame_part(frame, "LeftClamp", Rect2(-112, -27, 12, 54), Color("1b3039"))
	_add_frame_part(frame, "RightClamp", Rect2(100, -27, 12, 54), Color("1b3039"))
	_add_frame_part(frame, "ControlHousing", Rect2(88, -17, 22, 34), Color("173039"))
	_add_frame_part(frame, "ControlInset", Rect2(94, -10, 10, 20), Color("092029"))

	_left_leaf = _make_containment_leaf(
		"LeftLeaf",
		visual_offset + Vector2(-43, 0),
		leaf_color,
		false,
	)
	_right_leaf = _make_containment_leaf(
		"RightLeaf",
		visual_offset + Vector2(43, 0),
		leaf_color,
		true,
	)
	_left_closed_position = _left_leaf.position
	_right_closed_position = _right_leaf.position

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = PackedVector2Array([
		Vector2(-82, -33), Vector2(82, -33),
		Vector2(82, 33), Vector2(-82, 33),
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
	_locked_indicator.position = visual_offset + Vector2(99, 0)
	_open_indicator.position = visual_offset + Vector2(99, 0)
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
		Vector2(-43, -35), Vector2(43, -35),
		Vector2(43, 35), Vector2(-43, 35),
	])
	leaf.color = color
	leaf.z_index = 2
	add_child(leaf)
	_add_frame_part(leaf, "InsetPanel", Rect2(-35, -27, 70, 54), color.lightened(0.08))
	_add_frame_part(leaf, "UpperEdge", Rect2(-34, -26, 68, 3), Color(0.31, 0.46, 0.51, 0.42))
	_add_frame_part(leaf, "LowerEdge", Rect2(-34, 23, 68, 3), Color(0.02, 0.07, 0.085, 0.78))
	var seam_x := -42.0 if mirror_details else 39.0
	_add_frame_part(leaf, "CenterSeam", Rect2(seam_x, -34, 3, 68), Color("061920"))
	var brace_x := 20.0 if mirror_details else -29.0
	_add_frame_part(leaf, "Brace", Rect2(brace_x, -19, 9, 38), Color(0.12, 0.25, 0.29, 0.92))
	return leaf


func _build_tile_door_visuals() -> void:
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
	return leaf


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
