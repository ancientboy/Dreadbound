class_name MapStyleDemo
extends Node2D

const MAP_SIZE := Vector2(3344.0, 1882.0)
const SAMPLE_ENCOUNTER := &"map_demo_sample"
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")

@onready var player := $Player as Player
@onready var camera := $Player/Camera2D as Camera2D
@onready var rendered_character := $Player/RenderedAtlasCharacter as RenderedAtlasCharacter
@onready var weapon_vfx := $DemoWeaponVFX as DemoWeaponVFX
@onready var sample_room := $Rooms/SampleRoom as MapRoomModule
@onready var foreground_walls := $Foreground/WallsForeground as Sprite2D
@onready var objective_label := $HUD/TopPanel/Margin/Rows/Objective as Label
@onready var state_label := $HUD/TopPanel/Margin/Rows/State as Label
@onready var top_panel := $HUD/TopPanel as PanelContainer
@onready var return_button := $HUD/Return as Button


func _ready() -> void:
	_configure_player()
	_build_collision()
	_connect_areas()
	get_viewport().size_changed.connect(_layout_hud)
	return_button.pressed.connect(_return_home)
	_spawn_encounter()
	_update_encounter_state()
	_layout_hud()


func _physics_process(_delta: float) -> void:
	_keep_actor_on_floor(player)
	for enemy in get_tree().get_nodes_in_group(SAMPLE_ENCOUNTER):
		_keep_actor_on_floor(enemy as Node2D)


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.physical_keycode == KEY_ESCAPE:
			_return_home()


func _configure_player() -> void:
	camera.zoom = Vector2(1.28, 1.28)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_smoothed = true
	camera.limit_left = roundi(sample_room.camera_bounds.position.x)
	camera.limit_top = roundi(sample_room.camera_bounds.position.y)
	camera.limit_right = roundi(sample_room.camera_bounds.end.x)
	camera.limit_bottom = roundi(sample_room.camera_bounds.end.y)
	player.weapon_vfx = weapon_vfx
	rendered_character.select_preview_family(&"crowbar")


func _build_collision() -> void:
	var outline := sample_room.walkable_outline
	for index in outline.size():
		var start := sample_room.to_global(outline[index])
		var finish := sample_room.to_global(outline[(index + 1) % outline.size()])
		_add_wall_segment(start, finish, 54.0)


func _add_wall_segment(start: Vector2, finish: Vector2, thickness: float) -> void:
	var delta := finish - start
	var body := StaticBody2D.new()
	body.name = "SampleRoomBoundary"
	body.position = (start + finish) * 0.5
	body.rotation = delta.angle()
	body.set_meta(&"room_boundary", sample_room.room_id)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "BoundarySegment"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(delta.length() + thickness, thickness)
	shape_node.shape = rectangle
	body.add_child(shape_node)
	$WorldCollision.add_child(body)


func _keep_actor_on_floor(actor: Node2D) -> void:
	if actor == null or sample_room.contains_world_point(actor.global_position):
		return
	actor.global_position = sample_room.nearest_walkable_world_point(actor.global_position)
	if actor is CharacterBody2D:
		(actor as CharacterBody2D).velocity = Vector2.ZERO


func _connect_areas() -> void:
	$Foreground/FadeZone.body_entered.connect(_on_wall_fade_entered)
	$Foreground/FadeZone.body_exited.connect(_on_wall_fade_exited)


func _spawn_encounter() -> void:
	var spawns := sample_room.get_spawn_points(&"EnemySpawns")
	var labels := ["游荡病患", "回声病患", "值守残影", "失序病患"]
	for index in mini(spawns.size(), labels.size()):
		var enemy := PATIENT_SCENE.instantiate() as Patient
		enemy.position = spawns[index].global_position
		enemy.target = player
		enemy.enemy_label = labels[index]
		enemy.add_to_group(SAMPLE_ENCOUNTER)
		enemy.tree_exited.connect(_on_enemy_removed)
		$Enemies.add_child(enemy)


func _on_enemy_removed() -> void:
	call_deferred("_update_encounter_state")


func _on_wall_fade_entered(body: Node) -> void:
	if body != player:
		return
	create_tween().tween_property(foreground_walls, "modulate:a", 0.24, 0.16)


func _on_wall_fade_exited(body: Node) -> void:
	if body != player:
		return
	create_tween().tween_property(foreground_walls, "modulate:a", 1.0, 0.2)


func _update_encounter_state() -> void:
	var remaining := get_tree().get_nodes_in_group(SAMPLE_ENCOUNTER).size()
	if remaining > 0:
		objective_label.text = "精细样板房：利用床位、担架和掩体清除目标"
		state_label.text = "独立地面 / 墙体 / 家具 · 剩余 %d" % remaining
		return
	objective_label.text = "样板房验证完成"
	state_label.text = "物品朝向、精确碰撞、遮挡与主要动线已验证"


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
