class_name MobileControls
extends Control

@export var movement_only := false

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const MOBILE_CONTROL_ICONS: Texture2D = preload("res://assets/art/ui/mobile_controls.png")

const STICK_RADIUS := 82.0
const KNOB_RADIUS := 34.0
const ACTION_RADIUS := 62.0

var movement_vector := Vector2.ZERO
var _move_touch := -1
var _action_touch := -1
var _attack_touch := -1
var _item_touch := -1
var _switch_touch := -1
var _item_switch_touch := -1
var _trait_touch := -1
var _skill_touch := -1
var _interact_queued := false
var _attack_queued := false
var _item_queued := false
var _switch_queued := false
var _item_switch_queued := false
var _trait_queued := false
var _skill_queued := false


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


func consume_switch_item() -> bool:
	var was_pressed := _item_switch_queued
	_item_switch_queued = false
	return was_pressed


func consume_trait() -> bool:
	var was_pressed := _trait_queued
	_trait_queued = false
	return was_pressed


func consume_skill() -> bool:
	var was_pressed := _skill_queued
	_skill_queued = false
	return was_pressed


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _move_touch == -1 and event.position.x < size.x * 0.5:
			_move_touch = event.index
			_update_stick(event.position)
		elif movement_only:
			return
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
		elif _item_switch_touch == -1 and event.position.distance_to(_item_switch_center()) <= ACTION_RADIUS:
			_item_switch_touch = event.index
			_item_switch_queued = true
			queue_redraw()
		elif _switch_touch == -1 and event.position.distance_to(_switch_center()) <= ACTION_RADIUS * 1.15:
			_switch_touch = event.index
			_switch_queued = true
			queue_redraw()
		elif _trait_touch == -1 and event.position.distance_to(_trait_center()) <= 48.0:
			_trait_touch = event.index
			_trait_queued = true
			queue_redraw()
		elif _skill_touch == -1 and event.position.distance_to(_skill_center()) <= 52.0:
			_skill_touch = event.index
			_skill_queued = true
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
	elif event.index == _item_switch_touch:
		_item_switch_touch = -1
		queue_redraw()
	elif event.index == _trait_touch:
		_trait_touch = -1
		queue_redraw()
	elif event.index == _skill_touch:
		_skill_touch = -1
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


func _item_switch_center() -> Vector2:
	return Vector2(size.x - 520.0, size.y - 104.0)


func _trait_center() -> Vector2:
	return Vector2(size.x - 390.0, size.y - 230.0)


func _skill_center() -> Vector2:
	return Vector2(size.x - 270.0, size.y - 340.0)


func _draw() -> void:
	var stick_center := _stick_center()
	draw_circle(stick_center, STICK_RADIUS, Color(0.04, 0.11, 0.1, 0.68))
	draw_arc(stick_center, STICK_RADIUS, 0.0, TAU, 48, Color(0.25, 0.58, 0.52, 0.72), 3.0)
	_draw_control_icon(0, stick_center, 76.0, Color(0.78, 0.9, 0.86, 0.58))
	draw_circle(stick_center + movement_vector * STICK_RADIUS, KNOB_RADIUS, Color(0.27, 0.72, 0.63, 0.82))
	if movement_only:
		draw_string(
			UI_FONT,
			stick_center + Vector2(-36, 116),
			"移动",
			HORIZONTAL_ALIGNMENT_CENTER,
			72,
			15,
			Color(0.55, 0.8, 0.73, 0.9),
		)
		return
	var action_center := _action_center()
	var attack_center := _attack_center()
	var item_center := _item_center()
	var switch_center := _switch_center()
	var item_switch_center := _item_switch_center()
	var trait_center := _trait_center()
	var skill_center := _skill_center()
	draw_circle(action_center, ACTION_RADIUS, Color(0.04, 0.15, 0.13, 0.86))
	draw_arc(action_center, ACTION_RADIUS, 0.0, TAU, 48, Color(0.25, 0.88, 0.76, 0.9), 4.0)
	if _action_touch != -1:
		draw_circle(action_center, ACTION_RADIUS - 8.0, Color(0.25, 0.88, 0.76, 0.25))
	_draw_control_icon(1, action_center, 52.0)
	draw_string(UI_FONT, action_center + Vector2(-14, 82), "交互", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.72, 0.66, 0.9))
	draw_circle(attack_center, ACTION_RADIUS, Color(0.14, 0.055, 0.05, 0.88))
	draw_arc(attack_center, ACTION_RADIUS, 0.0, TAU, 48, Color(0.75, 0.28, 0.24, 0.92), 4.0)
	if _attack_touch != -1:
		draw_circle(attack_center, ACTION_RADIUS - 8.0, Color(0.8, 0.25, 0.2, 0.28))
	_draw_control_icon(2, attack_center, 54.0)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.get_skill_name() != "未选择流派":
		var remaining := player.get_skill_cooldown()
		draw_circle(skill_center, 44.0, Color(0.08, 0.06, 0.15, 0.92))
		draw_arc(skill_center, 44.0, 0.0, TAU, 36, Color("b47cff") if remaining <= 0.0 else Color("71588a"), 3.0)
		if _skill_touch != -1:
			draw_circle(skill_center, 35.0, Color(0.7, 0.48, 1.0, 0.22))
		draw_string(UI_FONT, skill_center + Vector2(-34, 5), "技能" if remaining <= 0.0 else "%ds" % ceili(remaining), HORIZONTAL_ALIGNMENT_CENTER, 68, 15, Color("dcc7ff"))
	draw_circle(item_center, ACTION_RADIUS - 8.0, Color(0.08, 0.13, 0.075, 0.9))
	draw_arc(item_center, ACTION_RADIUS - 8.0, 0.0, TAU, 48, Color(0.48, 0.72, 0.49, 0.92), 3.0)
	if _item_touch != -1:
		draw_circle(item_center, ACTION_RADIUS - 15.0, Color(0.48, 0.72, 0.49, 0.24))
	var item_label := player.get_selected_item_name() if player else "道具"
	_draw_control_icon(3, item_center, 48.0)
	draw_string(UI_FONT, item_center + Vector2(-38, 70), item_label, HORIZONTAL_ALIGNMENT_CENTER, 76, 13, Color("9bd0a3"))
	draw_circle(switch_center, ACTION_RADIUS - 16.0, Color(0.06, 0.09, 0.12, 0.92))
	draw_arc(switch_center, ACTION_RADIUS - 16.0, 0.0, TAU, 40, Color(0.38, 0.61, 0.7, 0.9), 3.0)
	if _switch_touch != -1:
		draw_circle(switch_center, ACTION_RADIUS - 22.0, Color(0.38, 0.61, 0.7, 0.25))
	_draw_control_icon(4, switch_center, 42.0)
	draw_circle(item_switch_center, 36.0, Color(0.1, 0.08, 0.12, 0.92))
	draw_arc(item_switch_center, 36.0, 0.0, TAU, 36, Color(0.65, 0.48, 0.72, 0.9), 3.0)
	if _item_switch_touch != -1:
		draw_circle(item_switch_center, 29.0, Color(0.65, 0.48, 0.72, 0.25))
	_draw_control_icon(5, item_switch_center, 38.0)
	var state := get_node_or_null("/root/GameState")
	if state and state.has_equipment_trait("noise_lure"):
		draw_circle(trait_center, 38.0, Color(0.14, 0.11, 0.04, 0.92))
		draw_arc(trait_center, 38.0, 0.0, TAU, 36, Color("e8b45f"), 3.0)
		if _trait_touch != -1:
			draw_circle(trait_center, 30.0, Color(0.9, 0.65, 0.2, 0.25))
		var scene := get_tree().current_scene
		var remaining := float(scene.get("whistle_cooldown")) if scene and scene.get("whistle_cooldown") != null else 0.0
		if remaining <= 0.0:
			_draw_control_icon(6, trait_center, 38.0)
		else:
			draw_string(UI_FONT, trait_center + Vector2(-20, 6), "%ds" % ceili(remaining), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color("f0c873"))
	if player and player.pathway_effects:
		var y := 114.0
		for status in player.pathway_effects.statuses():
			var suffix := " %.1fs" % float(status.remaining) if float(status.remaining) >= 0.0 else ""
			draw_string(UI_FONT, Vector2(22, y), "%s%s" % [str(status.name), suffix], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, status.color)
			y += 22.0


func _draw_control_icon(index: int, center: Vector2, draw_size: float, modulate := Color.WHITE) -> void:
	if MOBILE_CONTROL_ICONS == null or MOBILE_CONTROL_ICONS.get_size() != Vector2(256, 128):
		return
	draw_texture_rect_region(
		MOBILE_CONTROL_ICONS,
		Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size),
		Rect2((index % 4) * 64, floori(float(index) / 4.0) * 64, 64, 64),
		modulate,
	)
