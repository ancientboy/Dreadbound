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
const LEGACY_FRAME := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/frame.png"
)
const LEGACY_LEFT_LEAF := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_left.png"
)
const LEGACY_RIGHT_LEAF := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_right.png"
)
const WEST_FRAME := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/west_frame_v2.png"
)
const WEST_LEFT_LEAF := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/west_leaf_left_v2.png"
)
const WEST_RIGHT_LEAF := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/west_leaf_right_v2.png"
)
const EAST_FRAME := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/east_frame_v2.png"
)
const EAST_LEFT_LEAF := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/east_leaf_left_v2.png"
)
const EAST_RIGHT_LEAF := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/doors/east_leaf_right_v2.png"
)

var direction: StringName = &"north"
var state := DoorState.SEALED
var open_progress := 0.0
var _blocker_shape: CollisionShape2D
var _left_leaf: Sprite2D
var _right_leaf: Sprite2D
var _locked_indicator: Polygon2D
var _open_indicator: Polygon2D
var _seal_glow: Polygon2D
var _slide_axis := Vector2.RIGHT


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = 28
	body_entered.connect(_on_body_entered)
	_build_visuals()
	_build_collision()


func configure(new_direction: StringName, world_anchor: Vector2) -> void:
	assert(VALID_DIRECTIONS.has(String(new_direction)))
	direction = new_direction
	global_position = world_anchor
	rotation = 0.0
	if direction == &"north":
		rotation = 0.0
	elif direction == &"south":
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
	var travel := _slide_axis * 78.0
	var door_tween := create_tween().set_parallel(true)
	door_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	door_tween.tween_property(_left_leaf, "position", -travel, 0.48)
	door_tween.tween_property(_right_leaf, "position", travel, 0.48)
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
	var frame_texture := LEGACY_FRAME
	var left_texture := LEGACY_LEFT_LEAF
	var right_texture := LEGACY_RIGHT_LEAF
	var visual_scale := 0.145
	if direction == &"west":
		frame_texture = WEST_FRAME
		left_texture = WEST_LEFT_LEAF
		right_texture = WEST_RIGHT_LEAF
		visual_scale = 0.205
		_slide_axis = Vector2(1.0, -0.11).normalized()
	elif direction == &"east":
		frame_texture = EAST_FRAME
		left_texture = EAST_LEFT_LEAF
		right_texture = EAST_RIGHT_LEAF
		visual_scale = 0.205
		_slide_axis = Vector2(1.0, 0.11).normalized()

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
		Color(1.0, 0.12, 0.08, 0.9),
	)
	_open_indicator = _make_indicator(
		"OpenIndicator",
		Color(0.18, 1.0, 0.72, 0.9),
	)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0


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
	indicator.position = Vector2(0.0, -69.0)
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
