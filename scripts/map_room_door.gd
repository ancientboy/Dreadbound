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
const FRAME_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/frame.png"
)
const LEFT_LEAF_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_left.png"
)
const RIGHT_LEAF_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/leaf_right.png"
)
const LINTEL_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/lintel.png"
)
const LOCKED_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/indicator_locked.png"
)
const OPEN_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/indicator_open.png"
)
const THRESHOLD_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/sample_room_v2/doors/threshold.png"
)

var direction: StringName = &"north"
var state := DoorState.SEALED
var open_progress := 0.0
var _blocker_shape: CollisionShape2D
var _left_leaf: Sprite2D
var _right_leaf: Sprite2D
var _locked_indicator: Sprite2D
var _open_indicator: Sprite2D
var _seal_glow: Polygon2D


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
	match direction:
		&"north":
			rotation = 0.0
		&"south":
			rotation = PI
		&"west":
			rotation = -PI * 0.5
		&"east":
			rotation = PI * 0.5


func unlock() -> void:
	if state != DoorState.SEALED:
		return
	state = DoorState.UNLOCKING
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	var status_tween := create_tween()
	status_tween.tween_property(_locked_indicator, "modulate:a", 0.0, 0.14)
	status_tween.tween_callback(func() -> void:
		_open_indicator.visible = true
	)
	status_tween.tween_property(_open_indicator, "modulate:a", 1.0, 0.16)
	var door_tween := create_tween().set_parallel(true)
	door_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	door_tween.tween_property(_left_leaf, "position:x", -92.0, 0.48)
	door_tween.tween_property(_right_leaf, "position:x", 92.0, 0.48)
	door_tween.tween_property(_seal_glow, "modulate:a", 0.0, 0.32)
	door_tween.tween_method(_set_open_progress, 0.0, 1.0, 0.48)
	door_tween.finished.connect(func() -> void:
		state = DoorState.OPEN
	)


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
	var threshold := _make_sprite("Threshold", THRESHOLD_TEXTURE, 0.17, -4)
	threshold.position = Vector2(0.0, 30.0)

	_left_leaf = _make_sprite("LeftLeaf", LEFT_LEAF_TEXTURE, 0.145, 0)
	_left_leaf.position = Vector2(-43.0, -8.0)
	_right_leaf = _make_sprite("RightLeaf", RIGHT_LEAF_TEXTURE, 0.145, 0)
	_right_leaf.position = Vector2(43.0, -8.0)

	var frame := _make_sprite("DoorFrame", FRAME_TEXTURE, 0.16, 3)
	frame.position = Vector2(0.0, -45.0)
	var lintel := _make_sprite("ForegroundLintel", LINTEL_TEXTURE, 0.205, 7)
	lintel.position = Vector2(0.0, -66.0)

	_locked_indicator = _make_sprite("LockedIndicator", LOCKED_TEXTURE, 0.22, 8)
	_locked_indicator.position = Vector2(0.0, -75.0)
	_open_indicator = _make_sprite("OpenIndicator", OPEN_TEXTURE, 0.22, 8)
	_open_indicator.position = Vector2(0.0, -75.0)
	_open_indicator.visible = false
	_open_indicator.modulate.a = 0.0

	_seal_glow = Polygon2D.new()
	_seal_glow.name = "LockField"
	_seal_glow.polygon = PackedVector2Array([
		Vector2(-63.0, -29.0),
		Vector2(63.0, -29.0),
		Vector2(63.0, 27.0),
		Vector2(-63.0, 27.0),
	])
	_seal_glow.color = Color(0.96, 0.13, 0.11, 0.1)
	_seal_glow.z_index = 2
	add_child(_seal_glow)


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


func _build_collision() -> void:
	var trigger := CollisionShape2D.new()
	trigger.name = "TraversalTrigger"
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(134.0, 122.0)
	trigger.shape = trigger_shape
	trigger.position = Vector2(0.0, 34.0)
	add_child(trigger)

	var blocker := StaticBody2D.new()
	blocker.name = "DoorBlocker"
	blocker.collision_layer = 1
	blocker.collision_mask = 1
	_blocker_shape = CollisionShape2D.new()
	var blocker_rectangle := RectangleShape2D.new()
	blocker_rectangle.size = Vector2(140.0, 34.0)
	_blocker_shape.shape = blocker_rectangle
	blocker.add_child(_blocker_shape)
	add_child(blocker)


func _set_open_progress(value: float) -> void:
	open_progress = clampf(value, 0.0, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if state != DoorState.OPEN or not body.is_in_group("player"):
		return
	traversal_requested.emit(self)
