class_name MobileControls
extends Control

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

const STICK_RADIUS := 82.0
const KNOB_RADIUS := 34.0
const ACTION_RADIUS := 62.0

var movement_vector := Vector2.ZERO
var _move_touch := -1
var _action_touch := -1
var _attack_touch := -1
var _item_touch := -1
var _switch_touch := -1
var _interact_queued := false
var _attack_queued := false
var _item_queued := false
var _switch_queued := false


func _ready() -> void:
	set_process_input(true)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag and event.index == _move_touch:
		_update_stick(event.position)


func consume_interact() -> bool:
	var was_pressed := _interact_queued
	_interact_queued = false
	return was_pressed


func consume_attack() -> bool:
	var was_pressed := _attack_queued
	_attack_queued = false
	return was_pressed


func consume_item() -> bool:
	var was_pressed := _item_queued
	_item_queued = false
	return was_pressed


func consume_switch_weapon() -> bool:
	var was_pressed := _switch_queued
	_switch_queued = false
	return was_pressed


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _move_touch == -1 and event.position.x < size.x * 0.5:
			_move_touch = event.index
			_update_stick(event.position)
		elif _attack_touch == -1 and event.position.distance_to(_attack_center()) <= ACTION_RADIUS * 1.45:
			_attack_touch = event.index
			_attack_queued = true
			queue_redraw()
		elif _action_touch == -1 and event.position.distance_to(_action_center()) <= ACTION_RADIUS * 1.45:
			_action_touch = event.index
			_interact_queued = true
			queue_redraw()
		elif _item_touch == -1 and event.position.distance_to(_item_center()) <= ACTION_RADIUS * 1.3:
			_item_touch = event.index
			_item_queued = true
			queue_redraw()
		elif _switch_touch == -1 and event.position.distance_to(_switch_center()) <= ACTION_RADIUS * 1.15:
			_switch_touch = event.index
			_switch_queued = true
			queue_redraw()
	elif event.index == _move_touch:
		_move_touch = -1
		movement_vector = Vector2.ZERO
		queue_redraw()
	elif event.index == _action_touch:
		_action_touch = -1
		queue_redraw()
	elif event.index == _attack_touch:
		_attack_touch = -1
		queue_redraw()
	elif event.index == _item_touch:
		_item_touch = -1
		queue_redraw()
	elif event.index == _switch_touch:
		_switch_touch = -1
		queue_redraw()


func _update_stick(touch_position: Vector2) -> void:
	var offset := touch_position - _stick_center()
	movement_vector = offset.limit_length(STICK_RADIUS) / STICK_RADIUS
	if movement_vector.length() < 0.12:
		movement_vector = Vector2.ZERO
	queue_redraw()


func _stick_center() -> Vector2:
	return Vector2(126.0, size.y - 126.0)


func _action_center() -> Vector2:
	return Vector2(size.x - 116.0, size.y - 122.0)


func _attack_center() -> Vector2:
	return Vector2(size.x - 270.0, size.y - 190.0)


func _item_center() -> Vector2:
	return Vector2(size.x - 404.0, size.y - 112.0)


func _switch_center() -> Vector2:
	return Vector2(size.x - 500.0, size.y - 206.0)


func _draw() -> void:
	var stick_center := _stick_center()
	var action_center := _action_center()
	var attack_center := _attack_center()
	var item_center := _item_center()
	var switch_center := _switch_center()
	draw_circle(stick_center, STICK_RADIUS, Color(0.04, 0.11, 0.1, 0.68))
	draw_arc(stick_center, STICK_RADIUS, 0.0, TAU, 48, Color(0.25, 0.58, 0.52, 0.72), 3.0)
	draw_circle(stick_center + movement_vector * STICK_RADIUS, KNOB_RADIUS, Color(0.27, 0.72, 0.63, 0.82))
	draw_circle(action_center, ACTION_RADIUS, Color(0.04, 0.15, 0.13, 0.86))
	draw_arc(action_center, ACTION_RADIUS, 0.0, TAU, 48, Color(0.25, 0.88, 0.76, 0.9), 4.0)
	if _action_touch != -1:
		draw_circle(action_center, ACTION_RADIUS - 8.0, Color(0.25, 0.88, 0.76, 0.25))
	draw_string(UI_FONT, action_center + Vector2(-8, 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("65e6cf"))
	draw_string(UI_FONT, action_center + Vector2(-14, 82), "交互", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.72, 0.66, 0.9))
	draw_circle(attack_center, ACTION_RADIUS, Color(0.14, 0.055, 0.05, 0.88))
	draw_arc(attack_center, ACTION_RADIUS, 0.0, TAU, 48, Color(0.75, 0.28, 0.24, 0.92), 4.0)
	if _attack_touch != -1:
		draw_circle(attack_center, ACTION_RADIUS - 8.0, Color(0.8, 0.25, 0.2, 0.28))
	draw_string(UI_FONT, attack_center + Vector2(-26, 8), "攻击", HORIZONTAL_ALIGNMENT_CENTER, 52, 20, Color("e8897f"))
	draw_circle(item_center, ACTION_RADIUS - 8.0, Color(0.08, 0.13, 0.075, 0.9))
	draw_arc(item_center, ACTION_RADIUS - 8.0, 0.0, TAU, 48, Color(0.48, 0.72, 0.49, 0.92), 3.0)
	if _item_touch != -1:
		draw_circle(item_center, ACTION_RADIUS - 15.0, Color(0.48, 0.72, 0.49, 0.24))
	draw_string(UI_FONT, item_center + Vector2(-26, 7), "绷带", HORIZONTAL_ALIGNMENT_CENTER, 52, 17, Color("9bd0a3"))
	draw_circle(switch_center, ACTION_RADIUS - 16.0, Color(0.06, 0.09, 0.12, 0.92))
	draw_arc(switch_center, ACTION_RADIUS - 16.0, 0.0, TAU, 40, Color(0.38, 0.61, 0.7, 0.9), 3.0)
	if _switch_touch != -1:
		draw_circle(switch_center, ACTION_RADIUS - 22.0, Color(0.38, 0.61, 0.7, 0.25))
	draw_string(UI_FONT, switch_center + Vector2(-23, 6), "切换", HORIZONTAL_ALIGNMENT_CENTER, 46, 15, Color("82b8c8"))
