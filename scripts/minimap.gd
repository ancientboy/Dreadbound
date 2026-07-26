class_name SanatoriumMinimap
extends Control

signal expanded_changed(expanded: bool)

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const MINI_RADIUS := 68.0

var player: Player
var fog: FogOfWar
var run_config: DynamicRunConfig
var expanded := false
var _last_player_position := Vector2.INF
var map_button: Button


func _ready() -> void:
	set_process_input(true)
	map_button = Button.new()
	map_button.name = "MapTouchTarget"
	map_button.flat = true
	map_button.focus_mode = Control.FOCUS_NONE
	map_button.self_modulate = Color(1, 1, 1, 0)
	map_button.mouse_filter = Control.MOUSE_FILTER_STOP
	map_button.pressed.connect(func(): set_expanded(not expanded))
	add_child(map_button)
	_layout_touch_target()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and map_button:
		_layout_touch_target()
		queue_redraw()


func _layout_touch_target() -> void:
	if expanded:
		map_button.position = Vector2.ZERO
		map_button.size = size
	else:
		map_button.position = _mini_center() - Vector2(90, 90)
		map_button.size = Vector2(180, 190)


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
	_layout_touch_target()
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
	var map_rect := Rect2(center - Vector2(58, 39), Vector2(116, 78))
	_draw_map_contents(map_rect, false)
	draw_string(UI_FONT, center + Vector2(-25, 91), "点击地图", HORIZONTAL_ALIGNMENT_CENTER, 50, 12, Color(0.4, 0.7, 0.64, 0.9))


func _draw_expanded_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.015, 0.014, 0.93))
	var panel_size := Vector2(minf(860.0, size.x - 28.0), minf(540.0, size.y - 28.0))
	var panel := Rect2(size * 0.5 - panel_size * 0.5, panel_size)
	draw_rect(panel, Color(0.025, 0.065, 0.058, 0.98))
	draw_rect(panel, Color(0.24, 0.74, 0.64, 0.85), false, 3.0)
	var map_title := run_config.map_title() if run_config else "行动地图"
	draw_string(UI_FONT, panel.position + Vector2(24, 42), "%s // 探索地图" % map_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("62dec7"))
	draw_string(UI_FONT, panel.position + Vector2(panel.size.x - 160, 40), "点击关闭", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("6f958c"))
	_draw_map_contents(Rect2(panel.position + Vector2(54, 78), panel.size - Vector2(108, 130)), true)
	draw_circle(panel.position + Vector2(62, panel.size.y - 26), 5.0, Color("55e8ce"))
	draw_string(UI_FONT, panel.position + Vector2(76, panel.size.y - 21), "当前位置", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7fb1a6"))


func _draw_map_contents(target_rect: Rect2, show_labels: bool) -> void:
	var world_size := run_config.map_size() if run_config else Vector2(2304.0, 1440.0)
	var scale_factor := minf(target_rect.size.x / world_size.x, target_rect.size.y / world_size.y)
	var drawn_size := world_size * scale_factor
	var origin := target_rect.get_center() - drawn_size * 0.5
	var regions: Array[Dictionary] = []
	if run_config:
		regions.assign(run_config.map_regions())
	if run_config and run_config.world_id == "metro" and regions.size() > 1:
		for index in range(regions.size() - 1):
			var from_rect: Rect2 = regions[index].rect
			var to_rect: Rect2 = regions[index + 1].rect
			draw_line(origin + from_rect.get_center() * scale_factor, origin + to_rect.get_center() * scale_factor, Color(0.35, 0.72, 0.86, 0.82), 3.0 if show_labels else 2.0)
	for region in regions:
		var region_rect: Rect2 = region.rect
		var room_rect := Rect2(origin + region_rect.position * scale_factor, region_rect.size * scale_factor)
		var reveal := fog.get_world_reveal_at(region_rect.get_center()) if is_instance_valid(fog) else 0.0
		var metro := run_config != null and run_config.world_id == "metro"
		var fill := (Color(0.12, 0.34, 0.48, 0.98) if metro else Color(0.11, 0.4, 0.32, 0.98)) if reveal > 0.0 else Color(0.055, 0.09, 0.105, 0.98)
		draw_rect(room_rect, fill)
		draw_rect(room_rect, Color(0.34, 0.72, 0.75, 0.95 if reveal > 0.0 else 0.58), false, 2.0 if show_labels else 1.4)
		if show_labels:
			var name: String = str(region.name) if reveal > 0.0 else "未探索"
			draw_string(UI_FONT, room_rect.position + Vector2(6, 18), name, HORIZONTAL_ALIGNMENT_LEFT, room_rect.size.x - 12, 13, Color(0.54, 0.72, 0.66, 0.9))
	if run_config and show_labels:
		for objective_position in run_config.objective_positions:
			var marker_position := origin + objective_position * scale_factor
			draw_circle(marker_position, 4.0, Color("e4bd67"))
		if run_config.world_id == "metro":
			_draw_route_marker(origin, scale_factor, run_config.metro_route_positions.north.exit, "北")
			_draw_route_marker(origin, scale_factor, run_config.metro_route_positions.south.exit, "南")
	if is_instance_valid(player):
		var marker := origin + player.global_position * scale_factor
		draw_circle(marker, 7.0 if show_labels else 3.5, Color("55e8ce"))
		draw_arc(marker, 12.0 if show_labels else 6.0, 0.0, TAU, 24, Color(0.33, 0.91, 0.81, 0.35), 2.0)


func _draw_route_marker(origin: Vector2, scale_factor: float, world_position: Vector2, label: String) -> void:
	var marker_position := origin + world_position * scale_factor
	draw_circle(marker_position, 5.0, Color("79c4e1"))
	draw_string(UI_FONT, marker_position + Vector2(8, -6), "%s站台" % label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9dd9ee"))
