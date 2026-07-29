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
@onready var left_room := $Rooms/LeftRoom as MapRoomModule
@onready var right_room := $Rooms/RightRoom as MapRoomModule
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


func _physics_process(_delta: float) -> void:
	# Physics walls provide normal movement response. This final floor constraint
	# guarantees that neither the player nor an enemy can ever enter painted void.
	var active_room := left_room if _current_room == &"left" else right_room
	_keep_actor_on_floor(player, active_room)
	for enemy in get_tree().get_nodes_in_group(LEFT_ENCOUNTER):
		_keep_actor_on_floor(enemy as Node2D, left_room)
	for enemy in get_tree().get_nodes_in_group(ELITE_ENCOUNTER):
		_keep_actor_on_floor(enemy as Node2D, right_room)


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
	_set_camera_room(left_room)
	player.weapon_vfx = weapon_vfx
	rendered_character.select_preview_family(&"crowbar")


func _set_camera_room(room: MapRoomModule) -> void:
	var bounds := room.camera_bounds
	_current_room = room.room_id
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)


func _build_collision() -> void:
	# Each room owns a closed, hand-authored floor perimeter. Thick wall segments
	# follow that perimeter, including every diagonal edge and branch corridor.
	_add_room_boundary(left_room)
	_add_room_boundary(right_room)
	# Props already painted into the background also receive clipped footprint
	# collision. New v3 props are independent MapRoomObstacle nodes.
	var baked_prop_polygons: Array[PackedVector2Array] = [
		_scaled_polygon([Vector2(430, 118), Vector2(494, 108), Vector2(504, 242), Vector2(442, 252)]),
		_scaled_polygon([Vector2(258, 722), Vector2(340, 714), Vector2(356, 800), Vector2(276, 818)]),
		_scaled_polygon([Vector2(90, 334), Vector2(180, 322), Vector2(202, 388), Vector2(112, 404)]),
		_scaled_polygon([Vector2(1310, 310), Vector2(1412, 300), Vector2(1428, 356), Vector2(1322, 370)]),
		_scaled_polygon([Vector2(1112, 688), Vector2(1212, 678), Vector2(1230, 750), Vector2(1124, 766)]),
		_scaled_polygon([Vector2(1432, 620), Vector2(1508, 610), Vector2(1524, 692), Vector2(1446, 708)]),
	]
	for polygon in baked_prop_polygons:
		_add_static_polygon(polygon)


func _add_room_boundary(room: MapRoomModule) -> void:
	var outline := room.walkable_outline
	for index in outline.size():
		var start := room.to_global(outline[index])
		var finish := room.to_global(outline[(index + 1) % outline.size()])
		if _is_shared_doorway_edge(room.room_id, start, finish):
			continue
		_add_wall_segment(start, finish, 42.0, room.room_id)


func _is_shared_doorway_edge(
	room_id: StringName,
	start: Vector2,
	finish: Vector2,
) -> bool:
	if room_id == &"left":
		return start.x >= 1800.0 and finish.x >= 1800.0
	if room_id == &"right":
		return start.x <= 1500.0 and finish.x <= 1500.0
	return false


func _add_wall_segment(
	start: Vector2,
	finish: Vector2,
	thickness: float,
	room_id: StringName,
) -> void:
	var delta := finish - start
	var body := StaticBody2D.new()
	body.name = "%sBoundary" % String(room_id).capitalize()
	body.position = (start + finish) * 0.5
	body.rotation = delta.angle()
	body.set_meta(&"room_boundary", room_id)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "BoundarySegment"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(delta.length() + thickness, thickness)
	shape_node.shape = rectangle
	body.add_child(shape_node)
	$WorldCollision.add_child(body)


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


func _keep_actor_on_floor(actor: Node2D, room: MapRoomModule) -> void:
	if actor == null or room.contains_world_point(actor.global_position):
		return
	actor.global_position = room.nearest_walkable_world_point(actor.global_position)
	if actor is CharacterBody2D:
		(actor as CharacterBody2D).velocity = Vector2.ZERO


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
	var spawns := left_room.get_spawn_points(&"EnemySpawns")
	var labels := ["游荡病患", "回声病患", "失序病患"]
	for index in mini(spawns.size(), labels.size()):
		_spawn_patient(spawns[index].global_position, LEFT_ENCOUNTER, labels[index])


func _spawn_elite_encounter() -> void:
	var spawns := right_room.get_spawn_points(&"EnemySpawns")
	var labels := ["精英 · 异常病患", "精英 · 值守残影"]
	var health_scales := [1.7, 1.9]
	for index in mini(spawns.size(), labels.size()):
		_spawn_patient(
			spawns[index].global_position,
			ELITE_ENCOUNTER,
			labels[index],
			health_scales[index],
		)


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
	_set_camera_room(right_room)
	if _elite_started:
		return
	_elite_started = true
	_spawn_elite_encounter()
	objective_label.text = "精英房已锁定：清除异常后选择一条分支"
	state_label.text = "房间级镜头已切换 · 2 个精英目标"


func _on_left_room_entered(body: Node) -> void:
	if body == player:
		_set_camera_room(left_room)


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
		objective_label.text = "模块化战斗房：利用独立障碍物清除目标"
		state_label.text = "精确地面边界生效 · 中央闸门锁定 · 剩余 %d" % left_remaining
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
