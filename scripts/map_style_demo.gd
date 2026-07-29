class_name MapStyleDemo
extends Node2D

const ART_SCALE := 2.0
const MAP_SIZE := Vector2(3344.0, 1882.0)
const LEFT_ROOM_BOUNDS := Rect2(0.0, 0.0, 1652.0, 1882.0)
const RIGHT_ROOM_BOUNDS := Rect2(1652.0, 0.0, 1692.0, 1882.0)
const LEFT_ENCOUNTER := &"map_demo_left"
const ELITE_ENCOUNTER := &"map_demo_elite"
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")

@onready var player := $Player as Player
@onready var camera := $Player/Camera2D as Camera2D
@onready var rendered_character := $Player/RenderedAtlasCharacter as RenderedAtlasCharacter
@onready var weapon_vfx := $DemoWeaponVFX as DemoWeaponVFX
@onready var gate_collision := $WorldCollision/CentralGate/CollisionShape2D as CollisionShape2D
@onready var gate_visual := $Foreground/CentralGateVisual as Polygon2D
@onready var objective_label := $HUD/TopPanel/Margin/Rows/Objective as Label
@onready var state_label := $HUD/TopPanel/Margin/Rows/State as Label
@onready var branch_hint := $HUD/BranchHint as Label
@onready var top_panel := $HUD/TopPanel as PanelContainer
@onready var return_button := $HUD/Return as Button

var _elite_started := false
var _selected_branch := ""
var _current_room := &"left"


func _ready() -> void:
	_configure_player()
	_build_collision()
	_connect_areas()
	get_viewport().size_changed.connect(_layout_hud)
	return_button.pressed.connect(_return_home)
	_spawn_left_encounter()
	_update_encounter_state()
	_layout_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.physical_keycode == KEY_ESCAPE:
			_return_home()


func _configure_player() -> void:
	camera.zoom = Vector2(1.24, 1.24)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_smoothed = true
	_set_camera_room(LEFT_ROOM_BOUNDS, &"left")
	player.weapon_vfx = weapon_vfx
	rendered_character.select_preview_family(&"crowbar")


func _set_camera_room(bounds: Rect2, room_name: StringName) -> void:
	_current_room = room_name
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)


func _build_collision() -> void:
	# The demo art is enlarged without enlarging the player. Collision follows the
	# visible floor edges with polygons so diagonal walls no longer feel passable.
	var wall_polygons: Array[PackedVector2Array] = [
		PackedVector2Array([
			Vector2(-48, -48), Vector2(MAP_SIZE.x + 48, -48),
			Vector2(MAP_SIZE.x + 48, 48), Vector2(-48, 48),
		]),
		PackedVector2Array([
			Vector2(-48, MAP_SIZE.y - 48), Vector2(MAP_SIZE.x + 48, MAP_SIZE.y - 48),
			Vector2(MAP_SIZE.x + 48, MAP_SIZE.y + 48), Vector2(-48, MAP_SIZE.y + 48),
		]),
		PackedVector2Array([
			Vector2(-48, -48), Vector2(48, -48),
			Vector2(48, MAP_SIZE.y + 48), Vector2(-48, MAP_SIZE.y + 48),
		]),
		PackedVector2Array([
			Vector2(MAP_SIZE.x - 48, -48), Vector2(MAP_SIZE.x + 48, -48),
			Vector2(MAP_SIZE.x + 48, MAP_SIZE.y + 48), Vector2(MAP_SIZE.x - 48, MAP_SIZE.y + 48),
		]),
		# The two voids taper toward the doorway instead of using rectangular blockers.
		PackedVector2Array([
			Vector2(1336, 0), Vector2(1788, 0), Vector2(1788, 590),
			Vector2(1712, 650), Vector2(1336, 616),
		]),
		PackedVector2Array([
			Vector2(1380, 1160), Vector2(1784, 1128), Vector2(1852, 1192),
			Vector2(1852, MAP_SIZE.y), Vector2(1380, MAP_SIZE.y),
		]),
		# Solid props use clipped corners that match their oblique silhouettes.
		_scaled_polygon([Vector2(430, 118), Vector2(494, 108), Vector2(504, 242), Vector2(442, 252)]),
		_scaled_polygon([Vector2(258, 722), Vector2(340, 714), Vector2(356, 800), Vector2(276, 818)]),
		_scaled_polygon([Vector2(90, 334), Vector2(180, 322), Vector2(202, 388), Vector2(112, 404)]),
		_scaled_polygon([Vector2(1310, 310), Vector2(1412, 300), Vector2(1428, 356), Vector2(1322, 370)]),
		_scaled_polygon([Vector2(1112, 688), Vector2(1212, 678), Vector2(1230, 750), Vector2(1124, 766)]),
		_scaled_polygon([Vector2(1432, 620), Vector2(1508, 610), Vector2(1524, 692), Vector2(1446, 708)]),
	]
	for polygon in wall_polygons:
		_add_static_polygon(polygon)


func _scaled_polygon(source: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in source:
		result.append(point * ART_SCALE)
	return result


func _add_static_polygon(polygon: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	var shape_node := CollisionPolygon2D.new()
	shape_node.polygon = polygon
	body.add_child(shape_node)
	$WorldCollision.add_child(body)


func _connect_areas() -> void:
	$Triggers/EliteRoom.body_entered.connect(_on_elite_room_entered)
	$Triggers/LeftRoom.body_entered.connect(_on_left_room_entered)
	$Triggers/UpperBranch.body_entered.connect(
		func(body: Node): _select_branch(body, "上层维护线"),
	)
	$Triggers/LowerBranch.body_entered.connect(
		func(body: Node): _select_branch(body, "下层病房线"),
	)
	for fade_zone in $Foreground/FadeZones.get_children():
		var area := fade_zone as Area2D
		var wall := $Foreground.get_node_or_null(String(area.name).trim_suffix("Fade"))
		if wall == null:
			continue
		area.body_entered.connect(_on_wall_fade_entered.bind(wall))
		area.body_exited.connect(_on_wall_fade_exited.bind(wall))


func _spawn_left_encounter() -> void:
	_spawn_patient(Vector2(650, 560), LEFT_ENCOUNTER, "游荡病患")
	_spawn_patient(Vector2(1040, 930), LEFT_ENCOUNTER, "回声病患")
	_spawn_patient(Vector2(590, 1320), LEFT_ENCOUNTER, "失序病患")


func _spawn_elite_encounter() -> void:
	_spawn_patient(Vector2(2220, 620), ELITE_ENCOUNTER, "精英 · 异常病患", 1.7)
	_spawn_patient(Vector2(2580, 1160), ELITE_ENCOUNTER, "精英 · 值守残影", 1.9)


func _spawn_patient(
	position_value: Vector2,
	encounter_group: StringName,
	label_value: String,
	health_scale := 1.0,
) -> void:
	var enemy := PATIENT_SCENE.instantiate() as Patient
	enemy.position = position_value
	enemy.target = player
	enemy.enemy_label = label_value
	enemy.max_health = roundi(float(enemy.max_health) * health_scale)
	enemy.add_to_group(encounter_group)
	enemy.tree_exited.connect(_on_enemy_removed.bind(encounter_group))
	$Enemies.add_child(enemy)


func _on_enemy_removed(_encounter_group: StringName) -> void:
	call_deferred("_update_encounter_state")


func _on_elite_room_entered(body: Node) -> void:
	if body != player:
		return
	_set_camera_room(RIGHT_ROOM_BOUNDS, &"right")
	if _elite_started:
		return
	_elite_started = true
	_spawn_elite_encounter()
	objective_label.text = "精英房已锁定：清除异常后选择一条分支"
	state_label.text = "房间级镜头已切换 · 2 个精英目标"


func _on_left_room_entered(body: Node) -> void:
	if body == player:
		_set_camera_room(LEFT_ROOM_BOUNDS, &"left")


func _on_wall_fade_entered(body: Node, wall: CanvasItem) -> void:
	if body != player:
		return
	var tween := create_tween()
	tween.tween_property(wall, "modulate:a", 0.28, 0.16)


func _on_wall_fade_exited(body: Node, wall: CanvasItem) -> void:
	if body != player:
		return
	var tween := create_tween()
	tween.tween_property(wall, "modulate:a", 1.0, 0.2)


func _update_encounter_state() -> void:
	var left_remaining := get_tree().get_nodes_in_group(LEFT_ENCOUNTER).size()
	var elite_remaining := get_tree().get_nodes_in_group(ELITE_ENCOUNTER).size()
	if left_remaining > 0:
		objective_label.text = "大房间战斗：探索空间并清除目标"
		state_label.text = "中央闸门锁定 · 剩余 %d" % left_remaining
		return
	if not gate_collision.disabled:
		gate_collision.set_deferred("disabled", true)
		gate_visual.hide()
	if not _elite_started:
		objective_label.text = "中央连廊已开启：前往右侧精英房"
		state_label.text = "镜头只显示当前房间，不提前暴露后续路线"
		return
	if elite_remaining > 0:
		objective_label.text = "精英战房：清除异常目标"
		state_label.text = "路线分支封锁 · 剩余 %d" % elite_remaining
		return
	objective_label.text = "验证完成：前往右上或右下出口选择路线"
	state_label.text = "两个分支出口已开放"
	branch_hint.show()


func _select_branch(body: Node, branch_name: String) -> void:
	if body != player or not _elite_started:
		return
	if get_tree().get_nodes_in_group(ELITE_ENCOUNTER).size() > 0:
		return
	_selected_branch = branch_name
	branch_hint.text = "已选择：%s\n这里最终可连接事件房、商店或 Boss 路线" % _selected_branch
	branch_hint.show()


func _return_home() -> void:
	get_tree().change_scene_to_file("res://scenes/startup.tscn")


func _layout_hud() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 760.0
	if compact:
		return_button.offset_left = 12.0
		return_button.offset_top = 10.0
		return_button.offset_right = 134.0
		return_button.offset_bottom = 50.0
		top_panel.offset_left = 12.0
		top_panel.offset_top = 58.0
		top_panel.offset_right = viewport_size.x - 12.0
		top_panel.offset_bottom = 142.0
	else:
		return_button.offset_left = 18.0
		return_button.offset_top = 18.0
		return_button.offset_right = 150.0
		return_button.offset_bottom = 62.0
		top_panel.offset_left = 170.0
		top_panel.offset_top = 18.0
		top_panel.offset_right = viewport_size.x - 170.0
		top_panel.offset_bottom = 94.0
