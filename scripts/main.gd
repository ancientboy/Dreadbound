extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/entities/pickup.tscn")
const CRAWLER_SCENE: PackedScene = preload("res://scenes/entities/crawler.tscn")
const ORDERLY_SCENE: PackedScene = preload("res://scenes/entities/orderly.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/entities/boss.tscn")

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
@onready var fog_of_war: FogOfWar = $FogOfWar
@onready var minimap: SanatoriumMinimap = $Interface/Minimap
@onready var inventory_status: Label = $Interface/TopBar/Inventory
@onready var weapon_status: Label = $Interface/TopBar/Weapon
@onready var abandon_button: Button = $Interface/TopBar/Abandon
@onready var return_button: Button = $Interface/CompletePanel/Return
@onready var event_panel: ColorRect = $Interface/EventPanel
@onready var event_title: Label = $Interface/EventPanel/Title
@onready var event_description: Label = $Interface/EventPanel/Description
@onready var event_choice_a: Button = $Interface/EventPanel/ChoiceA
@onready var event_choice_b: Button = $Interface/EventPanel/ChoiceB

var mission_phase := MissionPhase.COLLECT_RECORDS
var collected_records: Dictionary = {}
var power_restored := false
var interactables: Array[ObjectiveInteractable] = []
var enemies_defeated := 0
var _run_settled := false
var _abandon_armed_until := 0
var risk_events: Array[RiskEvent] = []
var active_event: RiskEvent
var event_results: Array[String] = []
var boss: SanatoriumBoss
var notification: Label
var _notification_timer := 0.0
var _sound_player: AudioStreamPlayer


func _ready() -> void:
	_create_collision_walls()
	fog_of_war.player = player
	minimap.player = player
	minimap.fog = fog_of_war
	fog_of_war.exploration_changed.connect(minimap.queue_redraw)
	minimap.expanded_changed.connect(_on_map_expanded_changed)
	_create_mission_interactables()
	_create_patients()
	_create_crawlers()
	_create_orderlies()
	_create_boss()
	_create_pickups()
	_create_risk_events()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.inventory_changed.connect(_on_inventory_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.utility_changed.connect(_on_utility_changed)
	player.selected_item_changed.connect(_on_selected_item_changed)
	abandon_button.pressed.connect(_on_abandon_pressed)
	return_button.pressed.connect(_return_to_corridor)
	event_choice_a.pressed.connect(_resolve_active_event.bind(true))
	event_choice_b.pressed.connect(_resolve_active_event.bind(false))
	_on_player_health_changed(player.health, player.max_health)
	_on_inventory_changed(player.bandages, player.echo_shards)
	_on_weapon_changed(player.get_weapon_name(), player.ammo)
	_on_selected_item_changed(player.get_selected_item_name(), player.get_selected_item_count())
	_update_mission_ui()
	_create_feedback_layer()
	if not GameState.corridor_unlocked:
		_show_notification("首次连接：左侧摇杆移动 · 攻击键战斗 · E键交互\n右上角地图可查看探索路线", 7.0)
	queue_redraw()


func _on_map_expanded_changed(expanded: bool) -> void:
	var gameplay_active := mission_phase != MissionPhase.COMPLETE and mission_phase != MissionPhase.FAILED
	player.set_physics_process(gameplay_active and not expanded)
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		mobile_controls.visible = not expanded
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(gameplay_active and not expanded)


func _process(delta: float) -> void:
	if _notification_timer > 0.0:
		_notification_timer -= delta
		if _notification_timer <= 0.0 and notification:
			notification.visible = false
	if _abandon_armed_until > 0 and Time.get_ticks_msec() > _abandon_armed_until:
		_abandon_armed_until = 0
		abandon_button.text = "撤回回廊"
	var wants_to_interact := Input.is_action_just_pressed("interact")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		wants_to_interact = mobile_controls.consume_interact() or wants_to_interact

	if mission_phase == MissionPhase.COMPLETE or mission_phase == MissionPhase.FAILED:
		if wants_to_interact:
			_return_to_corridor()
		return
	if active_event:
		return

	var risk_event := _nearest_risk_event()
	if risk_event:
		prompt_panel.visible = true
		prompt.text = risk_event.get_prompt()
		if wants_to_interact:
			_open_risk_event(risk_event)
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
					_show_notification("三份记录已集齐：前往地下维护区恢复电力", 4.0)
		ObjectiveInteractable.Kind.POWER:
			if collected_records.size() == TOTAL_RECORDS and not power_restored:
				power_restored = true
				mission_phase = MissionPhase.EVACUATE
				target.mark_complete()
				boss.activate(player)
				_show_notification("警报：电力恢复，缝合主任已苏醒！\n出口现已开放，战斗或绕行撤离", 5.0)
				_play_cue(150.0, 0.35)
				queue_redraw()
		ObjectiveInteractable.Kind.EXIT:
			if power_restored:
				_complete_mission()
	_update_mission_ui()


func _complete_mission() -> void:
	mission_phase = MissionPhase.COMPLETE
	prompt_panel.visible = false
	complete_panel.visible = true
	result_heading.text = "撤离完成"
	result_summary.text = "已回收 3 份实验记录 · 风险事件 %d/2\n现场回响碎片 %d\n返回终末回廊后进行结算" % [event_results.size(), player.echo_shards]
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	_stop_patients()
	return_button.visible = true
	abandon_button.visible = false


func _return_to_corridor(abandoned := false) -> void:
	if _run_settled:
		return
	_run_settled = true
	var state := get_node_or_null("/root/GameState")
	if state:
		state.settle_run(not abandoned and mission_phase == MissionPhase.COMPLETE, collected_records.size(), player.echo_shards, enemies_defeated, event_results.size())
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")


func _on_abandon_pressed() -> void:
	if _abandon_armed_until == 0:
		_abandon_armed_until = Time.get_ticks_msec() + 3000
		abandon_button.text = "再次点击确认撤回"
		return
	_return_to_corridor(true)


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_status.text = "生命 %d/%d" % [current, maximum]


func _on_inventory_changed(bandages: int, echo_shards: int) -> void:
	inventory_status.text = "绷带%d 镇静%d 兴奋%d · 碎片%d" % [bandages, player.sedatives, player.stimulants, echo_shards]


func _on_weapon_changed(weapon_name: String, ammo: int) -> void:
	var supply := "霰弹 %d/%d" % [player.shells, player.max_shells] if player.current_weapon == Player.Weapon.SHOTGUN else "弹药 %d/%d" % [ammo, player.max_ammo]
	weapon_status.text = "武器 %s  ·  %s" % [weapon_name, supply]


func _on_utility_changed(sedatives: int, duration: float) -> void:
	inventory_status.text = "绷带%d 镇静%d 兴奋%d · 碎片%d" % [player.bandages, sedatives, player.stimulants, player.echo_shards]
	if duration > 0.0:
		inventory_status.tooltip_text = "镇静效果 %.0f 秒" % duration
	else:
		inventory_status.tooltip_text = "镇静剂 %d/2" % sedatives


func _on_selected_item_changed(item_name: String, count: int) -> void:
	inventory_status.text = "当前 %s×%d · 绷%d 镇%d 兴%d" % [item_name, count, player.bandages, player.sedatives, player.stimulants]


func _on_player_died() -> void:
	mission_phase = MissionPhase.FAILED
	prompt_panel.visible = false
	complete_panel.visible = true
	result_heading.text = "行动失败"
	result_summary.text = "漂泊者已失去生命体征\n终末回廊连接中断"
	objective.text = "任务失败：行者未能撤离"
	_stop_patients()
	return_button.visible = true
	abandon_button.visible = false


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


func _nearest_risk_event() -> RiskEvent:
	var nearest: RiskEvent
	var nearest_distance := INTERACTION_DISTANCE
	for risk_event in risk_events:
		if risk_event.resolved:
			continue
		var distance := player.global_position.distance_to(risk_event.global_position)
		if distance <= nearest_distance:
			nearest = risk_event
			nearest_distance = distance
	return nearest


func _open_risk_event(risk_event: RiskEvent) -> void:
	active_event = risk_event
	event_title.text = risk_event.title
	event_description.text = risk_event.description
	event_choice_a.text = risk_event.choice_a
	event_choice_b.text = risk_event.choice_b
	event_panel.visible = true
	prompt_panel.visible = false
	_set_gameplay_paused(true)


func _resolve_active_event(take_risk: bool) -> void:
	if active_event == null:
		return
	match active_event.event_id:
		"medicine_cabinet":
			if take_risk:
				player.add_bandages(1)
				player.add_ammo(8)
				player.take_damage(15, player.global_position)
				event_results.append("污染药柜：强行开启")
			else:
				event_results.append("污染药柜：封存")
		"echo_ward":
			if take_risk:
				player.add_echo_shards(5)
				_spawn_crawler_wave()
				event_results.append("回响病房：深入取样")
			else:
				player.add_echo_shards(1)
				event_results.append("回响病房：远程封锁")
	active_event.mark_resolved()
	active_event = null
	event_panel.visible = false
	_set_gameplay_paused(false)
	progress.text = "记录 %d/%d  ·  事件 %d/2" % [collected_records.size(), TOTAL_RECORDS, event_results.size()]


func _set_gameplay_paused(paused: bool) -> void:
	player.set_physics_process(not paused)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(not paused)
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		mobile_controls.visible = not paused
		mobile_controls.set_process_input(not paused)


func _spawn_crawler_wave() -> void:
	for offset in [Vector2(-90, 30), Vector2(100, -20)]:
		var crawler := CRAWLER_SCENE.instantiate() as Crawler
		crawler.position = player.global_position + offset
		crawler.target = player
		crawler.tree_exiting.connect(_on_enemy_removed.bind(crawler))
		add_child(crawler)


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
	for spawn_position in [Vector2(736, 400), Vector2(1216, 560), Vector2(1888, 360), Vector2(1696, 1088)]:
		var patient := PATIENT_SCENE.instantiate() as Patient
		patient.position = spawn_position
		patient.target = player
		patient.tree_exiting.connect(_on_enemy_removed.bind(patient))
		add_child(patient)


func _create_crawlers() -> void:
	for spawn_position in [Vector2(1120, 400), Vector2(1984, 256), Vector2(1584, 1184)]:
		var crawler := CRAWLER_SCENE.instantiate() as Crawler
		crawler.position = spawn_position
		crawler.target = player
		crawler.tree_exiting.connect(_on_enemy_removed.bind(crawler))
		add_child(crawler)


func _create_orderlies() -> void:
	for spawn_position in [Vector2(1370, 770), Vector2(2080, 1110)]:
		var orderly := ORDERLY_SCENE.instantiate() as Orderly
		orderly.position = spawn_position
		orderly.target = player
		orderly.tree_exiting.connect(_on_enemy_removed.bind(orderly))
		add_child(orderly)


func _create_boss() -> void:
	boss = BOSS_SCENE.instantiate() as SanatoriumBoss
	boss.position = Vector2(720, 1160)
	boss.target = player
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	add_child(boss)


func _on_enemy_removed(enemy: Node) -> void:
	if enemy.get("health") != null and int(enemy.get("health")) <= 0:
		enemies_defeated += 1


func _create_pickups() -> void:
	_add_pickup(ResourcePickup.Kind.BANDAGE, Vector2(352, 416))
	_add_pickup(ResourcePickup.Kind.BANDAGE, Vector2(1088, 608))
	_add_pickup(ResourcePickup.Kind.BANDAGE, Vector2(2048, 384))
	_add_pickup(ResourcePickup.Kind.ECHO_SHARD, Vector2(800, 224), 2)
	_add_pickup(ResourcePickup.Kind.ECHO_SHARD, Vector2(1280, 352), 3)
	_add_pickup(ResourcePickup.Kind.ECHO_SHARD, Vector2(1840, 1200), 4)
	_add_pickup(ResourcePickup.Kind.AMMO, Vector2(576, 416), 6)
	_add_pickup(ResourcePickup.Kind.AMMO, Vector2(1344, 608), 8)
	_add_pickup(ResourcePickup.Kind.AMMO, Vector2(2112, 224), 8)
	_add_pickup(ResourcePickup.Kind.SHELLS, Vector2(1248, 800), 4)
	_add_pickup(ResourcePickup.Kind.SHELLS, Vector2(2032, 1056), 3)
	_add_pickup(ResourcePickup.Kind.SEDATIVE, Vector2(864, 768), 1)
	_add_pickup(ResourcePickup.Kind.SEDATIVE, Vector2(1792, 704), 1)
	_add_pickup(ResourcePickup.Kind.STIMULANT, Vector2(1536, 1040), 1)


func _create_risk_events() -> void:
	_add_risk_event("medicine_cabinet", "污染药柜", "柜门后的药品仍可使用，但内部孢子浓度正在上升。\n强行开启可获得绷带和弹药，同时承受污染伤害。", "强行开启：补给 + 受伤", "封存药柜：安全离开", Vector2(1056, 800))
	_add_risk_event("echo_ward", "回响病房", "病房内存在高密度回响碎片，爬行声正在墙后聚集。\n深入取样可获得更多碎片，但会惊动附近威胁。", "深入取样：5 碎片 + 敌袭", "远程封锁：1 碎片", Vector2(1904, 736))


func _add_risk_event(id: String, title: String, description: String, choice_a: String, choice_b: String, at: Vector2) -> void:
	var risk_event := RiskEvent.new()
	risk_event.event_id = id
	risk_event.title = title
	risk_event.description = description
	risk_event.choice_a = choice_a
	risk_event.choice_b = choice_b
	risk_event.position = at
	add_child(risk_event)
	risk_events.append(risk_event)


func _add_pickup(kind: ResourcePickup.Kind, at: Vector2, amount := 1) -> void:
	var pickup := PICKUP_SCENE.instantiate() as ResourcePickup
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = at
	add_child(pickup)


func _add_interactable(kind: ObjectiveInteractable.Kind, id: String, label: String, at: Vector2) -> void:
	var item := ObjectiveInteractable.new()
	item.kind = kind
	item.objective_id = id
	item.display_name = label
	item.position = at
	add_child(item)
	interactables.append(item)


func _create_feedback_layer() -> void:
	notification = Label.new()
	notification.position = Vector2(365, 96)
	notification.size = Vector2(550, 72)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification.add_theme_font_override("font", UI_FONT)
	notification.add_theme_font_size_override("font_size", 18)
	notification.add_theme_color_override("font_color", Color("8ff0d8"))
	notification.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	$Interface.add_child(notification)
	_sound_player = AudioStreamPlayer.new()
	add_child(_sound_player)


func _show_notification(message: String, duration := 3.5) -> void:
	if notification == null:
		return
	notification.text = message
	notification.visible = true
	_notification_timer = duration


func _play_cue(frequency: float, duration: float) -> void:
	if _sound_player == null:
		return
	var sample_rate := 11025
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for index in range(frames):
		var envelope := 1.0 - float(index) / frames
		var sample := int(sin(TAU * frequency * index / sample_rate) * 5000.0 * envelope)
		bytes[index * 2] = sample & 0xff
		bytes[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	_sound_player.stream = stream
	_sound_player.play()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("15201c") if power_restored else Color("101514"))
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
	for room in SanatoriumLayout.rooms():
		draw_rect(room.rect, Color("18211f"))
		draw_rect(room.rect, Color("27332f"), false, 2.0)
		draw_string(UI_FONT, room.rect.position + Vector2(24, 42), room.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("617269"))


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
