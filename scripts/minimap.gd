class_name SanatoriumMinimap
extends Control

signal expanded_changed(expanded: bool)

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.woff")
const MINI_RADIUS := 68.0

var player: Player
var fog: FogOfWar
var run_config: DynamicRunConfig
var expanded := false
var _last_player_position := Vector2.INF


func _ready() -> void:
	set_process_input(true)
	queue_redraw()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("map_toggle"):
		set_expanded(not expanded)
	if is_instance_valid(player) and not player.global_position.is_equal_approx(_last_player_position):
		_last_player_position = player.global_position
		queue_redraw()


func _input(event: InputEvent) -> void:
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		position = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		position = event.position
	if not pressed:
		return
	if expanded or position.distance_to(_mini_center()) <= MINI_RADIUS + 18.0:
		set_expanded(not expanded)
		get_viewport().set_input_as_handled()


func set_expanded(value: bool) -> void:
	if expanded == value:
		return
	expanded = value
	expanded_changed.emit(expanded)
	queue_redraw()


func _mini_center() -> Vector2:
	return Vector2(size.x - 92.0, 166.0)


func _draw() -> void:
	if expanded:
		_draw_expanded_map()
	else:
		_draw_minimap()


func _draw_minimap() -> void:
	var center := _mini_center()
	draw_circle(center, MINI_RADIUS + 5.0, Color(0.01, 0.035, 0.032, 0.94))
	draw_arc(center, MINI_RADIUS + 5.0, 0.0, TAU, 64, Color(0.23, 0.78, 0.68, 0.85), 3.0)
	var map_rect := Rect2(center - Vector2(54, 34), Vector2(108, 68))
	_draw_map_contents(map_rect, false)
	draw_string(UI_FONT, center + Vector2(-25, 91), "点击地图", HORIZONTAL_ALIGNMENT_CENTER, 50, 12, Color(0.4, 0.7, 0.64, 0.9))


func _draw_expanded_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.015, 0.014, 0.93))
	var panel := Rect2(size * 0.5 - Vector2(430, 270), Vector2(860, 540))
	draw_rect(panel, Color(0.025, 0.065, 0.058, 0.98))
	draw_rect(panel, Color(0.24, 0.74, 0.64, 0.85), false, 3.0)
	draw_string(UI_FONT, panel.position + Vector2(32, 48), "废弃疗养院 // 探索地图", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("62dec7"))
	draw_string(UI_FONT, panel.position + Vector2(panel.size.x - 190, 44), "点击任意位置关闭", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("6f958c"))
	_draw_map_contents(Rect2(panel.position + Vector2(54, 78), panel.size - Vector2(108, 130)), true)
	draw_circle(panel.position + Vector2(62, panel.size.y - 26), 5.0, Color("55e8ce"))
	draw_string(UI_FONT, panel.position + Vector2(76, panel.size.y - 21), "当前位置", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7fb1a6"))


func _draw_map_contents(target_rect: Rect2, show_labels: bool) -> void:
	var scale_factor := minf(target_rect.size.x / SanatoriumLayout.MAP_SIZE.x, target_rect.size.y / SanatoriumLayout.MAP_SIZE.y)
	var drawn_size := SanatoriumLayout.MAP_SIZE * scale_factor
	var origin := target_rect.get_center() - drawn_size * 0.5
	var room_index := 0
	for room in SanatoriumLayout.rooms():
		var room_rect := Rect2(origin + room.rect.position * scale_factor, room.rect.size * scale_factor)
		var reveal := fog.get_reveal_progress(room.id) if is_instance_valid(fog) else 0.0
		var fill := Color(0.11, 0.28, 0.24, 0.88) if reveal > 0.0 else Color(0.035, 0.065, 0.06, 0.92)
		draw_rect(room_rect, fill)
		draw_rect(room_rect, Color(0.29, 0.55, 0.48, 0.8 if reveal > 0.0 else 0.3), false, 2.0 if show_labels else 1.0)
		if show_labels:
			var dynamic_name: String = run_config.room_role(room_index) if run_config else str(room.name)
			var name: String = dynamic_name if reveal > 0.0 else "未探索"
			draw_string(UI_FONT, room_rect.position + Vector2(6, 18), name, HORIZONTAL_ALIGNMENT_LEFT, room_rect.size.x - 12, 13, Color(0.54, 0.72, 0.66, 0.9))
		room_index += 1
	if is_instance_valid(player):
		var marker := origin + player.global_position * scale_factor
		draw_circle(marker, 7.0 if show_labels else 3.5, Color("55e8ce"))
		draw_arc(marker, 12.0 if show_labels else 6.0, 0.0, TAU, 24, Color(0.33, 0.91, 0.81, 0.35), 2.0)
