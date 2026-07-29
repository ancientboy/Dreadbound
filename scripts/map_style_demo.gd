class_name MapStyleDemo
extends Node2D

const MAP_SIZE := Vector2(1672.0, 941.0)
const LEFT_ENCOUNTER := &"map_demo_left"
const ELITE_ENCOUNTER := &"map_demo_elite"
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")

@onready var player := $Player as Player
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
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_SIZE.x)
	camera.limit_bottom = int(MAP_SIZE.y)
	camera.zoom = Vector2(1.08, 1.08)
	player.weapon_vfx = weapon_vfx
	rendered_character.select_preview_family(&"crowbar")


func _build_collision() -> void:
	# The collision remains ordinary axis-aligned 2D. The generated oblique walls
	# are a presentation layer, so existing four-direction characters stay valid.
	var walls := [
		Rect2(-32, -32, MAP_SIZE.x + 64, 48),
		Rect2(-32, MAP_SIZE.y - 16, MAP_SIZE.x + 64, 48),
		Rect2(-32, -32, 48, MAP_SIZE.y + 64),
		Rect2(MAP_SIZE.x - 16, -32, 48, MAP_SIZE.y + 64),
		# Void above and below the narrow connection between both combat rooms.
		Rect2(668, 0, 226, 315),
		Rect2(690, 580, 236, 361),
		# Large props that must read as solid cover.
		Rect2(430, 108, 74, 144),
		Rect2(258, 714, 98, 104),
		Rect2(90, 322, 112, 82),
		Rect2(1310, 300, 118, 70),
		Rect2(1112, 678, 118, 88),
		Rect2(1432, 610, 92, 98),
	]
	for wall in walls:
		_add_static_rect(wall)


func _add_static_rect(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	body.add_child(shape_node)
	$WorldCollision.add_child(body)


func _connect_areas() -> void:
	$Triggers/EliteRoom.body_entered.connect(_on_elite_room_entered)
	$Triggers/UpperBranch.body_entered.connect(
		func(body: Node): _select_branch(body, "上层维护线"),
	)
	$Triggers/LowerBranch.body_entered.connect(
		func(body: Node): _select_branch(body, "下层病房线"),
	)


func _spawn_left_encounter() -> void:
	_spawn_patient(Vector2(390, 320), LEFT_ENCOUNTER, "游荡病患")
	_spawn_patient(Vector2(520, 470), LEFT_ENCOUNTER, "回声病患")
	_spawn_patient(Vector2(330, 610), LEFT_ENCOUNTER, "失序病患")


func _spawn_elite_encounter() -> void:
	_spawn_patient(Vector2(1110, 330), ELITE_ENCOUNTER, "精英 · 异常病患", 1.7)
	_spawn_patient(Vector2(1240, 560), ELITE_ENCOUNTER, "精英 · 值守残影", 1.9)


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
	if body != player or _elite_started:
		return
	_elite_started = true
	_spawn_elite_encounter()
	objective_label.text = "精英房已锁定：清除异常后选择一条分支"
	state_label.text = "空间结构重新闭合 · 2 个精英目标"


func _update_encounter_state() -> void:
	var left_remaining := get_tree().get_nodes_in_group(LEFT_ENCOUNTER).size()
	var elite_remaining := get_tree().get_nodes_in_group(ELITE_ENCOUNTER).size()
	if left_remaining > 0:
		objective_label.text = "普通战房：清除目标，验证大空间战斗可读性"
		state_label.text = "中央闸门锁定 · 剩余 %d" % left_remaining
		return
	if not gate_collision.disabled:
		gate_collision.set_deferred("disabled", true)
		gate_visual.hide()
	if not _elite_started:
		objective_label.text = "中央连廊已开启：前往右侧精英房"
		state_label.text = "验证窄口、遮挡与镜头过渡"
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
