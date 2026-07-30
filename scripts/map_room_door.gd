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

var direction: StringName = &"north"
var state := DoorState.SEALED
var open_progress := 0.0
var _blocker_shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = 32
	body_entered.connect(_on_body_entered)
	_build_collision()
	set_process(true)
	queue_redraw()


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
	queue_redraw()


func unlock() -> void:
	if state != DoorState.SEALED:
		return
	state = DoorState.UNLOCKING
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_open_progress, 0.0, 1.0, 0.42)
	tween.tween_callback(func() -> void:
		state = DoorState.OPEN
		queue_redraw()
	)


func begin_traversal() -> void:
	if state == DoorState.OPEN:
		state = DoorState.TRAVERSING
		queue_redraw()


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


func _build_collision() -> void:
	var trigger := CollisionShape2D.new()
	trigger.name = "TraversalTrigger"
	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(126.0, 118.0)
	trigger.shape = trigger_shape
	trigger.position = Vector2(0.0, 40.0)
	add_child(trigger)

	var blocker := StaticBody2D.new()
	blocker.name = "DoorBlocker"
	blocker.collision_layer = 1
	blocker.collision_mask = 1
	_blocker_shape = CollisionShape2D.new()
	var blocker_rectangle := RectangleShape2D.new()
	blocker_rectangle.size = Vector2(126.0, 30.0)
	_blocker_shape.shape = blocker_rectangle
	blocker.add_child(_blocker_shape)
	add_child(blocker)


func _set_open_progress(value: float) -> void:
	open_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if state != DoorState.OPEN or not body.is_in_group("player"):
		return
	traversal_requested.emit(self)


func _process(_delta: float) -> void:
	if state == DoorState.SEALED:
		queue_redraw()


func _draw() -> void:
	var pulse := 0.84 + sin(Time.get_ticks_msec() * 0.006) * 0.12
	var frame_color := Color(0.16, 0.34, 0.38, 1.0)
	var seal_color := Color(0.32, 0.92, 0.76, pulse)
	var panel_color := Color(0.055, 0.12, 0.14, 0.98)
	draw_rect(Rect2(-70.0, -18.0, 140.0, 36.0), frame_color, true)
	var panel_width := 58.0 * (1.0 - open_progress)
	if panel_width > 1.0:
		draw_rect(Rect2(-62.0, -13.0, panel_width, 26.0), panel_color, true)
		draw_rect(Rect2(4.0 + 58.0 * open_progress, -13.0, panel_width, 26.0), panel_color, true)
	if state == DoorState.SEALED or state == DoorState.UNLOCKING:
		var alpha := 1.0 - open_progress
		var animated_seal := Color(seal_color.r, seal_color.g, seal_color.b, seal_color.a * alpha)
		draw_line(Vector2(-54.0, 0.0), Vector2(54.0, 0.0), animated_seal, 5.0)
		draw_circle(Vector2.ZERO, 7.0, animated_seal)
	elif state == DoorState.OPEN:
		draw_line(Vector2(-48.0, 13.0), Vector2(48.0, 13.0), Color(0.42, 1.0, 0.82, 0.72), 3.0)
