class_name MapStyleDemo
extends Node2D

const MAP_SIZE := Vector2(1536.0, 1024.0)
const SAMPLE_ENCOUNTER := &"map_demo_sample"
const DOOR_GAP_HALF_WIDTH := 78.0
const CAMERA_COVER_OVERSCAN := 1.01
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")
const ROOM_DOOR_SCRIPT: Script = preload("res://scripts/map_room_door.gd")

@onready var modular_architecture := $ModularArchitecture as ModularHospitalRoom
@onready var player := $Player as Player
@onready var camera := $Player/Camera2D as Camera2D
@onready var rendered_character := $Player/RenderedAtlasCharacter as RenderedAtlasCharacter
@onready var weapon_vfx := $DemoWeaponVFX as DemoWeaponVFX
@onready var sample_room := $Rooms/SampleRoom as MapRoomModule
@onready var objective_label := $HUD/TopPanel/Margin/Rows/Objective as Label
@onready var state_label := $HUD/TopPanel/Margin/Rows/State as Label
@onready var title_label := $HUD/TopPanel/Margin/Rows/Title as Label
@onready var top_panel := $HUD/TopPanel as PanelContainer
@onready var return_button := $HUD/Return as Button

var room_variants: Array[Dictionary] = []
var current_room_index := 0
var activated_zone_count := 0
var variant_controls: HBoxContainer
var exit_doors: Array[MapRoomDoor] = []
var transition_fade: ColorRect
var transition_in_progress := false
var room_switching := false
var room_cleared := false
var active_boss: Node2D
var boss_reward_preview: Node2D


func _ready() -> void:
	room_variants = MapThemeCatalog.hospital_rooms()
	_apply_room_spec(room_variants[0])
	_configure_player()
	_build_collision()
	_create_variant_controls()
	_create_transition_fade()
	_create_exit_doors()
	get_viewport().size_changed.connect(_layout_hud)
	return_button.pressed.connect(_return_home)
	_activate_starting_zones()
	_update_encounter_state()
	_layout_hud()


func _physics_process(_delta: float) -> void:
	if transition_in_progress:
		_update_guided_camera()
		return
	_keep_actor_on_floor(player)
	for enemy in get_tree().get_nodes_in_group(SAMPLE_ENCOUNTER):
		_keep_actor_on_floor(enemy as Node2D)
	_update_guided_camera()
	_activate_entered_zone()


func _unhandled_key_input(event: InputEvent) -> void:
	if transition_in_progress:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_ESCAPE:
			_return_home()
		KEY_Q, KEY_COMMA:
			_show_room_variant(current_room_index - 1)
		KEY_E, KEY_PERIOD:
			_show_room_variant(current_room_index + 1)


func _configure_player() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.5
	camera.limit_smoothed = true
	camera.limit_left = roundi(sample_room.camera_bounds.position.x)
	camera.limit_top = roundi(sample_room.camera_bounds.position.y)
	camera.limit_right = roundi(sample_room.camera_bounds.end.x)
	camera.limit_bottom = roundi(sample_room.camera_bounds.end.y)
	player.weapon_vfx = weapon_vfx
	rendered_character.select_preview_family(&"crowbar")
	rendered_character.modulate = Color(0.84, 0.95, 1.0, 1.0)
	_fit_camera_to_viewport()
	_update_guided_camera()


func _fit_camera_to_viewport() -> void:
	var bounds := sample_room.camera_bounds
	var viewport_size := get_viewport_rect().size
	if not bounds.has_area() or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		camera.zoom = sample_room.camera_zoom
		return
	var cover_zoom := maxf(
		viewport_size.x / bounds.size.x,
		viewport_size.y / bounds.size.y,
	) * CAMERA_COVER_OVERSCAN * sample_room.camera_overscan
	var authored_zoom := maxf(sample_room.camera_zoom.x, sample_room.camera_zoom.y)
	var resolved_zoom := maxf(authored_zoom, cover_zoom)
	camera.zoom = Vector2.ONE * resolved_zoom


func _create_variant_controls() -> void:
	variant_controls = HBoxContainer.new()
	variant_controls.name = "RoomVariantControls"
	variant_controls.add_theme_constant_override("separation", 8)
	$HUD.add_child(variant_controls)
	var previous := Button.new()
	previous.text = "‹ 上一房型"
	previous.theme = top_panel.theme
	previous.pressed.connect(func() -> void: _show_room_variant(current_room_index - 1))
	variant_controls.add_child(previous)
	var next := Button.new()
	next.text = "下一房型 ›"
	next.theme = top_panel.theme
	next.pressed.connect(func() -> void: _show_room_variant(current_room_index + 1))
	variant_controls.add_child(next)


func _show_room_variant(index: int, entry_direction: StringName = &"") -> void:
	if room_variants.is_empty() or room_switching:
		return
	room_switching = true
	current_room_index = posmod(index, room_variants.size())
	var spec := room_variants[current_room_index]
	for enemy in get_tree().get_nodes_in_group(SAMPLE_ENCOUNTER):
		enemy.free()
	if is_instance_valid(boss_reward_preview):
		boss_reward_preview.free()
	active_boss = null
	boss_reward_preview = null
	_clear_children($Rooms/SampleRoom/EncounterZones)
	_clear_children($WorldCollision)
	_clear_exit_doors()
	activated_zone_count = 0
	room_cleared = false

	_apply_room_spec(spec)
	$Rooms/SampleRoom/Obstacles.visible = false

	_build_zones(spec["zones"])
	_build_collision()
	_create_exit_doors()
	var entrance := _door_for_direction(entry_direction)
	if entrance != null:
		player.global_position = entrance.global_position + entrance.outward_vector() * 54.0
	else:
		player.global_position = spec["spawn"]
	_configure_player()
	_activate_starting_zones()
	title_label.text = "医院主题房型 · %s" % spec["title"]
	objective_label.text = (
		"Boss 房：大型画布、障碍导航、阶段槽位与封门流程"
		if spec["room_kind"] == "boss"
		else "RoomBuilder：固定网格、自动墙线、预设门槽、导航与镜头约束"
	)
	room_switching = false
	_update_encounter_state()


func _create_transition_fade() -> void:
	transition_fade = ColorRect.new()
	transition_fade.name = "RoomTransitionFade"
	transition_fade.color = Color(0.006, 0.018, 0.024, 0.0)
	transition_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_fade.position = Vector2.ZERO
	transition_fade.size = get_viewport_rect().size
	$HUD.add_child(transition_fade)


func _create_exit_doors() -> void:
	for direction_value in sample_room.door_directions:
		var door := ROOM_DOOR_SCRIPT.new() as MapRoomDoor
		door.name = "Door_%s" % String(direction_value).capitalize()
		door.configure(
			StringName(direction_value),
			sample_room.door_anchor_world(StringName(direction_value)),
			modular_architecture.theme if modular_architecture.visible else null,
			room_variants[current_room_index].get("door_profile", {}),
		)
		sample_room.add_child(door)
		door.traversal_requested.connect(_on_door_traversal_requested)
		exit_doors.append(door)


func _clear_exit_doors() -> void:
	for door in exit_doors:
		if is_instance_valid(door):
			door.free()
	exit_doors.clear()


func _door_for_direction(direction_value: StringName) -> MapRoomDoor:
	if direction_value == &"":
		return null
	for door in exit_doors:
		if door.direction == direction_value:
			return door
	return null


func _unlock_exit_doors() -> void:
	if room_cleared:
		return
	room_cleared = true
	for door in exit_doors:
		door.unlock()
	objective_label.text = "房间已清理，独立门扇正在滑入墙体 · 请选择出口"
	state_label.text = "门洞碰撞已开放，走近任意青色出口即可进入"


func _on_door_traversal_requested(door: MapRoomDoor) -> void:
	if transition_in_progress or not room_cleared:
		return
	_traverse_door(door)


func _traverse_door(door: MapRoomDoor) -> void:
	transition_in_progress = true
	var chosen_direction := door.direction
	var entry_direction := MapRoomDoor.opposite_direction(chosen_direction)
	var target_room_index := _find_connected_room(chosen_direction)
	door.begin_traversal()
	for other_door in exit_doors:
		if other_door != door:
			other_door.monitoring = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	var saved_collision_layer := player.collision_layer
	var saved_collision_mask := player.collision_mask
	player.collision_layer = 0
	player.collision_mask = 0
	objective_label.text = "正在通过 %s 出口…" % _direction_label(chosen_direction)

	var exit_tween := create_tween().set_parallel(true)
	exit_tween.tween_property(
		player,
		"global_position",
		door.global_position + door.outward_vector() * 88.0,
		0.38,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	exit_tween.tween_property(transition_fade, "color:a", 1.0, 0.28)
	await exit_tween.finished

	_show_room_variant(target_room_index, entry_direction)
	var entrance := _door_for_direction(entry_direction)
	if entrance != null:
		var enter_tween := create_tween().set_parallel(true)
		enter_tween.tween_property(
			player,
			"global_position",
			entrance.global_position + entrance.inward_vector() * 92.0,
			0.44,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		enter_tween.tween_property(transition_fade, "color:a", 0.0, 0.3)
		await enter_tween.finished
	else:
		transition_fade.color.a = 0.0

	player.collision_layer = saved_collision_layer
	player.collision_mask = saved_collision_mask
	player.set_physics_process(true)
	transition_in_progress = false
	_update_encounter_state()


func _find_connected_room(exit_direction: StringName) -> int:
	var required_entry := MapRoomDoor.opposite_direction(exit_direction)
	var directional_offset: int = {
		&"north": 1,
		&"east": 2,
		&"south": 3,
		&"west": 4,
	}.get(exit_direction, 1)
	for step in room_variants.size():
		var candidate_index := posmod(
			current_room_index + directional_offset + step,
			room_variants.size(),
		)
		if candidate_index == current_room_index:
			continue
		var candidate: Dictionary = room_variants[candidate_index]
		if _spec_door_directions(candidate).has(String(required_entry)):
			return candidate_index
	return posmod(current_room_index + 1, room_variants.size())


func _apply_room_spec(spec: Dictionary) -> bool:
	assert(spec.has("grid_cells"), "Map demo only accepts RoomBuilder room specs")
	modular_architecture.visible = true
	modular_architecture.build_from_spec(spec)
	sample_room.apply_built_spec(spec, modular_architecture)
	$ThemeGrade.color = modular_architecture.theme.ambient_tint
	return true


func _spec_door_directions(spec: Dictionary) -> PackedStringArray:
	if spec.has("door_directions"):
		return spec["door_directions"]
	var result := PackedStringArray()
	for door_spec in spec.get("door_sockets", []):
		result.append(String(door_spec["direction"]))
	return result


func _direction_label(direction_value: StringName) -> String:
	match direction_value:
		&"north":
			return "北侧"
		&"south":
			return "前门"
		&"west":
			return "左侧"
		&"east":
			return "右侧"
	return "未知"


func _build_zones(zone_specs: Array) -> void:
	var container := $Rooms/SampleRoom/EncounterZones
	for zone_spec in zone_specs:
		var zone := MapEncounterZone.new()
		zone.name = String(zone_spec["id"])
		zone.zone_id = zone_spec["id"]
		zone.trigger_bounds = zone_spec["bounds"]
		zone.starts_active = zone_spec["starts_active"]
		zone.enemy_labels = zone_spec["labels"]
		container.add_child(zone)
		var spawns := Node2D.new()
		spawns.name = "EnemySpawns"
		zone.add_child(spawns)
		for spawn_position in zone_spec["spawns"]:
			var marker := Marker2D.new()
			marker.position = spawn_position
			spawns.add_child(marker)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()


func _update_guided_camera() -> void:
	var guided_position := sample_room.guided_camera_world_point(player.global_position)
	camera.position = guided_position - player.global_position


func _build_collision() -> void:
	_build_polygon_collision(sample_room.walkable_outline, true)
	for blocked_outline in sample_room.blocked_outlines:
		_build_polygon_collision(blocked_outline, false)


func _build_polygon_collision(outline: PackedVector2Array, cut_door_gaps: bool) -> void:
	for index in outline.size():
		var start := sample_room.to_global(outline[index])
		var finish := sample_room.to_global(outline[(index + 1) % outline.size()])
		if cut_door_gaps and _add_segment_with_door_gap(start, finish):
			continue
		_add_wall_segment(start, finish, 28.0)


func _add_segment_with_door_gap(start: Vector2, finish: Vector2) -> bool:
	var segment_length := start.distance_to(finish)
	if segment_length <= DOOR_GAP_HALF_WIDTH * 2.5:
		return false
	for direction_value in sample_room.door_directions:
		var anchor := sample_room.door_anchor_world(StringName(direction_value))
		var closest := Geometry2D.get_closest_point_to_segment(anchor, start, finish)
		if closest.distance_to(anchor) > 3.0:
			continue
		if closest.distance_to(start) <= DOOR_GAP_HALF_WIDTH:
			continue
		if closest.distance_to(finish) <= DOOR_GAP_HALF_WIDTH:
			continue
		var tangent := start.direction_to(finish)
		_add_wall_segment(
			start,
			closest - tangent * DOOR_GAP_HALF_WIDTH,
			28.0,
		)
		_add_wall_segment(
			closest + tangent * DOOR_GAP_HALF_WIDTH,
			finish,
			28.0,
		)
		return true
	return false


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


func _activate_starting_zones() -> void:
	for child in $Rooms/SampleRoom/EncounterZones.get_children():
		var zone := child as MapEncounterZone
		if zone != null and zone.starts_active:
			_activate_zone(zone)


func _activate_entered_zone() -> void:
	for child in $Rooms/SampleRoom/EncounterZones.get_children():
		var zone := child as MapEncounterZone
		if (
			zone != null
			and not zone.activated
			and zone.contains_world_point(player.global_position)
		):
			_activate_zone(zone)


func _activate_zone(zone: MapEncounterZone) -> void:
	zone.activate()
	activated_zone_count += 1
	var spawns := zone.get_spawn_points()
	for index in mini(spawns.size(), zone.enemy_labels.size()):
		var enemy := PATIENT_SCENE.instantiate() as Patient
		enemy.position = spawns[index].global_position
		enemy.target = player
		enemy.enemy_label = zone.enemy_labels[index]
		enemy.add_to_group(SAMPLE_ENCOUNTER)
		enemy.tree_exited.connect(_on_enemy_removed)
		$Enemies.add_child(enemy)
	if sample_room.room_kind == "boss" and active_boss == null:
		_spawn_configured_boss()
	_update_encounter_state()


func _spawn_configured_boss() -> void:
	var boss_spec: Dictionary = room_variants[current_room_index].get("boss", {})
	assert(not boss_spec.is_empty(), "Boss rooms require a boss configuration")
	var scene_path := String(boss_spec.get("scene", ""))
	assert(ResourceLoader.exists(scene_path), "Boss scene does not exist: %s" % scene_path)
	var boss_scene := load(scene_path) as PackedScene
	active_boss = boss_scene.instantiate() as Node2D
	assert(active_boss != null, "Configured boss scene must instantiate a Node2D")
	active_boss.global_position = _content_slot_world_position(
		StringName(boss_spec["spawn_slot"]),
	)
	active_boss.set_meta(
		&"phase_thresholds",
		boss_spec.get("phase_thresholds", PackedFloat32Array()),
	)
	active_boss.set_meta(
		&"summon_points",
		_content_slot_world_positions(boss_spec.get("summon_slots", PackedStringArray())),
	)
	active_boss.add_to_group(SAMPLE_ENCOUNTER)
	active_boss.tree_exited.connect(_on_enemy_removed)
	$Enemies.add_child(active_boss)
	if active_boss.has_method("activate"):
		active_boss.call("activate", player)


func _content_slot_world_position(slot_id: StringName) -> Vector2:
	var marker := modular_architecture.content_slots.get_node_or_null(
		NodePath(String(slot_id).to_pascal_case()),
	) as Marker2D
	assert(marker != null, "Room content slot does not exist: %s" % slot_id)
	return marker.global_position


func _content_slot_world_positions(slot_ids: PackedStringArray) -> PackedVector2Array:
	var result := PackedVector2Array()
	for slot_id in slot_ids:
		result.append(_content_slot_world_position(StringName(slot_id)))
	return result


func _on_enemy_removed() -> void:
	if not room_switching:
		call_deferred("_update_encounter_state")


func _update_encounter_state() -> void:
	if room_switching:
		return
	var remaining := get_tree().get_nodes_in_group(SAMPLE_ENCOUNTER).size()
	var total_zones := $Rooms/SampleRoom/EncounterZones.get_child_count()
	if remaining > 0:
		objective_label.text = (
			"Boss 房已封锁：击败首领后开启出口"
			if sample_room.room_kind == "boss"
			else "医院主题：推进并清除当前区域"
		)
		state_label.text = "房型 %d/%d · 区域 %d/%d · 当前敌人 %d" % [
			current_room_index + 1,
			room_variants.size(),
			activated_zone_count,
			total_zones,
			remaining,
		]
		return
	if activated_zone_count < total_zones:
		objective_label.text = "当前区域已清除，继续探索房间"
		state_label.text = "镜头跟随 · 未进入区域不会提前刷怪"
		return
	if sample_room.room_kind == "boss":
		_spawn_boss_reward_preview()
	_unlock_exit_doors()


func _spawn_boss_reward_preview() -> void:
	if boss_reward_preview != null:
		return
	var boss_spec: Dictionary = room_variants[current_room_index].get("boss", {})
	boss_reward_preview = Node2D.new()
	boss_reward_preview.name = "BossRewardPreview"
	boss_reward_preview.global_position = _content_slot_world_position(
		StringName(boss_spec["reward_slot"]),
	)
	var glow := Polygon2D.new()
	glow.name = "RewardGlow"
	glow.polygon = PackedVector2Array([
		Vector2(0, -42),
		Vector2(36, -20),
		Vector2(36, 20),
		Vector2(0, 42),
		Vector2(-36, 20),
		Vector2(-36, -20),
	])
	glow.color = theme_reward_color()
	boss_reward_preview.add_child(glow)
	$Rooms/SampleRoom.add_child(boss_reward_preview)


func theme_reward_color() -> Color:
	var color := modular_architecture.theme.door_open_color
	return Color(color.r, color.g, color.b, 0.48)


func _return_home() -> void:
	get_tree().change_scene_to_file("res://scenes/startup.tscn")


func _layout_hud() -> void:
	var viewport_size := get_viewport_rect().size
	_fit_camera_to_viewport()
	if transition_fade != null:
		transition_fade.size = viewport_size
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
		variant_controls.position = Vector2(12.0, 150.0)
	else:
		return_button.offset_left = 18.0
		return_button.offset_top = 18.0
		return_button.offset_right = 150.0
		return_button.offset_bottom = 62.0
		top_panel.offset_left = 170.0
		top_panel.offset_top = 18.0
		top_panel.offset_right = viewport_size.x - 170.0
		top_panel.offset_bottom = 94.0
		variant_controls.position = Vector2(
			viewport_size.x * 0.5 - 116.0,
			104.0,
		)
