extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")

enum MissionPhase { COLLECT_RECORDS, RESTORE_POWER, EVACUATE, COMPLETE, FAILED }

const MAP_SIZE := Vector2(2304.0, 1440.0)
const INTERACTION_DISTANCE := 86.0
const TOTAL_RECORDS := 3

@onready var player: Player = $Player
@onready var objective: Label = $Interface/TopBar/Objective
@onready var progress: Label = $Interface/TopBar/Progress
@onready var prompt_panel: ColorRect = $Interface/PromptPanel
@onready var prompt: Label = $Interface/PromptPanel/Prompt
@onready var complete_panel: ColorRect = $Interface/CompletePanel
@onready var health_status: Label = $Interface/TopBar/Health
@onready var result_heading: Label = $Interface/CompletePanel/Heading
@onready var result_summary: Label = $Interface/CompletePanel/Summary

var mission_phase := MissionPhase.COLLECT_RECORDS
var collected_records: Dictionary = {}
var power_restored := false
var interactables: Array[ObjectiveInteractable] = []


func _ready() -> void:
	_create_collision_walls()
	_create_mission_interactables()
	_create_patients()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.health, player.max_health)
	_update_mission_ui()
	queue_redraw()


func _process(_delta: float) -> void:
	var wants_to_interact := Input.is_action_just_pressed("interact")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		wants_to_interact = mobile_controls.consume_interact() or wants_to_interact

	if mission_phase == MissionPhase.COMPLETE or mission_phase == MissionPhase.FAILED:
		if wants_to_interact:
			get_tree().reload_current_scene()
		return

	var target := _nearest_interactable()
	prompt_panel.visible = target != null
	if target:
		prompt.text = target.get_prompt(collected_records.size(), power_restored)
		if wants_to_interact:
			_handle_interaction(target)


func _handle_interaction(target: ObjectiveInteractable) -> void:
	match target.kind:
		ObjectiveInteractable.Kind.RECORD:
			if not collected_records.has(target.objective_id):
				collected_records[target.objective_id] = true
				target.mark_complete()
				if collected_records.size() == TOTAL_RECORDS:
					mission_phase = MissionPhase.RESTORE_POWER
		ObjectiveInteractable.Kind.POWER:
			if collected_records.size() == TOTAL_RECORDS and not power_restored:
				power_restored = true
				mission_phase = MissionPhase.EVACUATE
				target.mark_complete()
		ObjectiveInteractable.Kind.EXIT:
			if power_restored:
				_complete_mission()
	_update_mission_ui()


func _complete_mission() -> void:
	mission_phase = MissionPhase.COMPLETE
	prompt_panel.visible = false
	complete_panel.visible = true
	result_heading.text = "撤离完成"
	result_summary.text = "已回收 3 份实验记录\n疗养院电力已恢复"
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	_stop_patients()


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_status.text = "生命 %d/%d" % [current, maximum]


func _on_player_died() -> void:
	mission_phase = MissionPhase.FAILED
	prompt_panel.visible = false
	complete_panel.visible = true
	result_heading.text = "行动失败"
	result_summary.text = "漂泊者已失去生命体征\n终末回廊连接中断"
	objective.text = "任务失败：行者未能撤离"
	_stop_patients()


func _stop_patients() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)


func _nearest_interactable() -> ObjectiveInteractable:
	var nearest: ObjectiveInteractable
	var nearest_distance := INTERACTION_DISTANCE
	for item in interactables:
		if item.completed:
			continue
		var distance := player.global_position.distance_to(item.global_position)
		if distance <= nearest_distance:
			nearest = item
			nearest_distance = distance
	return nearest


func _update_mission_ui() -> void:
	progress.text = "记录 %d/%d  ·  电力%s" % [collected_records.size(), TOTAL_RECORDS, "已恢复" if power_restored else "中断"]
	match mission_phase:
		MissionPhase.COLLECT_RECORDS:
			objective.text = "当前目标：搜索疗养院内的实验记录"
		MissionPhase.RESTORE_POWER:
			objective.text = "当前目标：前往地下维护区恢复电力"
		MissionPhase.EVACUATE:
			objective.text = "当前目标：前往紧急撤离出口"
		MissionPhase.COMPLETE:
			objective.text = "任务完成：疗养院异常路线已稳定"


func _create_mission_interactables() -> void:
	_add_interactable(ObjectiveInteractable.Kind.RECORD, "record_01", "病房区实验记录", Vector2(672, 256))
	_add_interactable(ObjectiveInteractable.Kind.RECORD, "record_02", "护理站实验记录", Vector2(1184, 480))
	_add_interactable(ObjectiveInteractable.Kind.RECORD, "record_03", "档案室实验记录", Vector2(1952, 288))
	_add_interactable(ObjectiveInteractable.Kind.POWER, "basement_power", "地下室发电机", Vector2(1760, 1184))
	_add_interactable(ObjectiveInteractable.Kind.EXIT, "extraction_gate", "紧急撤离出口", Vector2(224, 1184))


func _create_patients() -> void:
	for spawn_position in [Vector2(736, 560), Vector2(1216, 784), Vector2(1888, 640), Vector2(1696, 1088)]:
		var patient := Patient.new()
		patient.position = spawn_position
		patient.target = player
		add_child(patient)


func _add_interactable(kind: ObjectiveInteractable.Kind, id: String, label: String, at: Vector2) -> void:
	var item := ObjectiveInteractable.new()
	item.kind = kind
	item.objective_id = id
	item.display_name = label
	item.position = at
	add_child(item)
	interactables.append(item)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("101514"))
	_draw_grid()
	_draw_zones()
	for wall in _wall_rectangles():
		draw_rect(wall, Color("39423d"))
		draw_rect(wall, Color("59635c"), false, 2.0)


func _draw_grid() -> void:
	for x in range(0, int(MAP_SIZE.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), Color(0.13, 0.17, 0.16, 0.3), 1.0)
	for y in range(0, int(MAP_SIZE.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), Color(0.13, 0.17, 0.16, 0.3), 1.0)


func _draw_zones() -> void:
	var zones := [
		[Rect2(96, 160, 320, 320), "入口大厅"],
		[Rect2(480, 128, 416, 352), "病房区"],
		[Rect2(992, 288, 384, 384), "护理站"],
		[Rect2(1696, 128, 480, 320), "实验档案室"],
		[Rect2(1504, 960, 576, 320), "地下维护区"],
		[Rect2(96, 1024, 352, 256), "撤离区"],
	]
	for zone in zones:
		draw_rect(zone[0], Color("18211f"))
		draw_rect(zone[0], Color("27332f"), false, 2.0)
		draw_string(UI_FONT, zone[0].position + Vector2(24, 42), zone[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("617269"))


func _create_collision_walls() -> void:
	for wall_rect in _wall_rectangles():
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = wall_rect.size
		collision.shape = shape
		body.position = wall_rect.get_center()
		body.add_child(collision)
		add_child(body)


func _wall_rectangles() -> Array[Rect2]:
	return [
		Rect2(0, 0, MAP_SIZE.x, 32), Rect2(0, MAP_SIZE.y - 32, MAP_SIZE.x, 32),
		Rect2(0, 0, 32, MAP_SIZE.y), Rect2(MAP_SIZE.x - 32, 0, 32, MAP_SIZE.y),
		# Patient wing partitions, with door-sized gaps.
		Rect2(448, 32, 32, 256), Rect2(448, 416, 32, 288),
		Rect2(896, 32, 32, 352), Rect2(896, 512, 32, 320),
		# Nurse station and central circulation.
		Rect2(960, 256, 448, 32), Rect2(960, 672, 192, 32), Rect2(1280, 672, 128, 32),
		Rect2(1408, 256, 32, 192), Rect2(1408, 576, 32, 384),
		# Archive wing.
		Rect2(1664, 96, 544, 32), Rect2(1664, 448, 224, 32), Rect2(2016, 448, 192, 32),
		Rect2(1664, 96, 32, 160), Rect2(1664, 384, 32, 256), Rect2(2208, 96, 32, 544),
		# Basement corridors.
		Rect2(1472, 928, 736, 32), Rect2(1472, 1280, 736, 32),
		Rect2(1472, 928, 32, 160), Rect2(1472, 1216, 32, 96), Rect2(2208, 928, 32, 384),
		# Extraction approach and lower corridor cover.
		Rect2(64, 992, 416, 32), Rect2(64, 1280, 416, 32),
		Rect2(480, 992, 32, 96), Rect2(480, 1216, 32, 96),
		Rect2(512, 896, 320, 32), Rect2(960, 896, 544, 32),
	]
