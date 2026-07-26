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
const METRO_SHALLOW_ZONES := [Rect2(480, 704, 416, 192), Rect2(960, 704, 480, 192), Rect2(1504, 960, 704, 320)]
const METRO_DEEP_ZONES := [Rect2(960, 704, 480, 192), Rect2(1504, 960, 704, 320)]

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
var reward_chests: Array[RewardChest] = []
var run_equipment_rewards: Array[String] = []
var active_chest: RewardChest
var reward_panel: ColorRect
var reward_buttons: Array[Button] = []
var _loot_rng := RandomNumberGenerator.new()
var run_config: DynamicRunConfig
var director := DreadDirector.new()
var total_records := 3
var _director_tick := 0.0
var _recent_damage := 0.0
var _previous_health := 100
var metro_tide_level := 0
var metro_tide_timer := 0.0
var metro_noise := 0
var metro_train_window := -1.0
var metro_route := ""
var metro_water_damage_timer := 0.0
var metro_water_state := 0


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_responsive_ui)
	var run_seed: int = GameState.active_run_seed
	if run_seed == 0:
		run_seed = GameState.begin_run(1337 if OS.has_feature("editor") else 0)
	run_config = DynamicRunConfig.new(run_seed, GameState.selected_world)
	assert(run_config.validate())
	total_records = run_config.objective_count
	_create_collision_walls()
	fog_of_war.player = player
	minimap.player = player
	minimap.fog = fog_of_war
	minimap.run_config = run_config
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
	_create_reward_panel()
	_apply_responsive_ui()
	_loot_rng.randomize()
	if not GameState.corridor_unlocked:
		_show_notification("首次连接：左侧摇杆移动 · 攻击键战斗 · E键交互\n右上角地图可查看探索路线", 7.0)
	$Interface/TopBar/Title.text = "%s // %s" % [run_config.mission_title, run_config.action_code]
	if run_config.world_id == "metro":
		_show_notification("潮没末班线：潮位正在上升。收集信标、恢复信号并赶上撤离窗口。", 6.0)
	queue_redraw()


func _apply_responsive_ui(override_size := Vector2.ZERO) -> void:
	# All disaster worlds share this layout contract.  Keep HUD content inside the
	# actual browser canvas instead of assuming the 1280x720 design viewport.
	var viewport_size: Vector2 = override_size if override_size != Vector2.ZERO else get_viewport_rect().size
	var safe_margin := clampf(viewport_size.x * 0.018, 14.0, 28.0)
	var top_bar := $Interface/TopBar as ColorRect
	top_bar.position = Vector2(safe_margin, 16.0)
	top_bar.size = Vector2(maxf(760.0, viewport_size.x - safe_margin * 2.0), 76.0)
	var width := top_bar.size.x
	var title := $Interface/TopBar/Title as Label
	var controls := $Interface/TopBar/Controls as Label
	title.position = Vector2(16, 7)
	title.size = Vector2(width * 0.46, 24)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	$Interface/TopBar/Inventory.position = Vector2(width * 0.46, 7)
	$Interface/TopBar/Inventory.size = Vector2(width * 0.17, 24)
	$Interface/TopBar/Health.position = Vector2(width * 0.63, 7)
	$Interface/TopBar/Health.size = Vector2(width * 0.14, 24)
	controls.position = Vector2(width * 0.77, 7)
	controls.size = Vector2(width * 0.21 - 12, 24)
	controls.visible = width >= 1050.0
	$Interface/TopBar/Objective.position = Vector2(16, 39)
	$Interface/TopBar/Objective.size = Vector2(width * 0.48, 24)
	$Interface/TopBar/Objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	$Interface/TopBar/Weapon.position = Vector2(width * 0.48, 39)
	$Interface/TopBar/Weapon.size = Vector2(width * 0.22, 24)
	$Interface/TopBar/Progress.position = Vector2(width * 0.70, 39)
	$Interface/TopBar/Progress.size = Vector2(width * 0.28 - 12, 24)
	$Interface/TopBar/Progress.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	abandon_button.position = Vector2(0, 82)
	abandon_button.size = Vector2(142, 40)
	_layout_centered_panel(complete_panel, viewport_size, Vector2(600, 276), Vector2(32, 150))
	_layout_centered_panel(event_panel, viewport_size, Vector2(680, 380), Vector2(32, 150))
	if notification:
		notification.position = Vector2((viewport_size.x - minf(720.0, viewport_size.x - 64.0)) * 0.5, 104)
		notification.size = Vector2(minf(720.0, viewport_size.x - 64.0), 76)
	if reward_panel:
		_layout_centered_panel(reward_panel, viewport_size, Vector2(940, 410), Vector2(32, 140))


func _layout_centered_panel(panel: Control, viewport_size: Vector2, preferred: Vector2, padding: Vector2) -> void:
	if panel == null:
		return
	var panel_size := Vector2(minf(preferred.x, viewport_size.x - padding.x * 2.0), minf(preferred.y, viewport_size.y - padding.y))
	panel.size = panel_size
	panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, maxf(108.0, (viewport_size.y - panel_size.y) * 0.5))


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
	_director_tick += delta
	_recent_damage = maxf(_recent_damage - delta * 0.08, 0.0)
	if _director_tick >= 1.0 and mission_phase < MissionPhase.COMPLETE:
		_director_tick = 0.0
		var ammo_ratio := float(player.ammo + player.shells) / float(player.max_ammo + player.max_shells)
		var decision := director.update(1.0, float(player.health) / player.max_health, ammo_ratio, _unrevealed_room_count(), _recent_damage, enemies_defeated >= 3)
		if decision == "relief":
			_add_pickup(ResourcePickup.Kind.BANDAGE, player.global_position + player.facing * 92.0)
			_show_notification("导演干预：检测到资源短缺，附近出现一次补给机会", 3.5)
		elif decision == "escalate":
			_spawn_crawler_wave()
			_show_notification("导演干预：长时间低压，侧翼出现追击信号", 3.5)
	if run_config and run_config.world_id == "metro" and mission_phase < MissionPhase.COMPLETE:
		_update_metro_pressure(delta)
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
	var chest := _nearest_reward_chest()
	if chest:
		prompt_panel.visible = true
		prompt.text = chest.get_prompt()
		if wants_to_interact:
			_open_reward_chest(chest)
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
		if run_config.world_id == "metro" and not metro_route.is_empty() and target.kind == ObjectiveInteractable.Kind.EXIT and target.objective_id != "metro_exit_%s" % metro_route:
			prompt.text = "列车未停靠此站 // 前往%s站台" % ("北" if metro_route == "north" else "南")
		else:
			prompt.text = target.get_prompt(collected_records.size(), power_restored, total_records)
		if wants_to_interact:
			_handle_interaction(target)


func _handle_interaction(target: ObjectiveInteractable) -> void:
	match target.kind:
		ObjectiveInteractable.Kind.RECORD:
			if not collected_records.has(target.objective_id):
				collected_records[target.objective_id] = true
				target.mark_complete()
				if collected_records.size() == total_records:
					mission_phase = MissionPhase.RESTORE_POWER
					_show_notification("%s已集齐：选择北站台高架慢线或南站台淹没快线" % run_config.objective_noun if run_config.world_id == "metro" else "三份记录已集齐：前往地下维护区恢复电力", 4.0)
		ObjectiveInteractable.Kind.POWER:
			if collected_records.size() == total_records and not power_restored:
				if run_config.world_id == "metro":
					_activate_metro_route(target)
				else:
					power_restored = true
					mission_phase = MissionPhase.EVACUATE
					target.mark_complete()
					boss.activate(player)
					_show_notification("警报：电力恢复，缝合主任已苏醒！\n出口现已开放，战斗或绕行撤离", 5.0)
				_play_cue(150.0, 0.35)
				if run_config.causal_chain == "spore_bloom" and event_results.any(func(result): return "污染药柜：强行开启" in result):
					_spawn_crawler_wave()
					_show_notification("因果回响：孢子污染沿供电管线扩散，额外威胁苏醒", 4.5)
				queue_redraw()
		ObjectiveInteractable.Kind.EXIT:
			if power_restored and (run_config.world_id != "metro" or (target.objective_id == "metro_exit_%s" % metro_route and metro_train_window > 0.0)):
				_complete_mission()
	_update_mission_ui()


func _complete_mission() -> void:
	mission_phase = MissionPhase.COMPLETE
	prompt_panel.visible = false
	complete_panel.visible = true
	result_heading.text = "撤离完成"
	result_summary.text = "已完成%s %d/%d · 风险事件 %d/2\n现场回响碎片 %d · 行动代码 %s\n返回终末回廊后进行结算" % [run_config.objective_noun, collected_records.size(), total_records, event_results.size(), player.echo_shards, run_config.action_code]
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
		var summary := {"action_code": run_config.action_code, "mission": run_config.mission_title, "causal_chain": run_config.causal_chain, "director_log": director.decision_log, "world": run_config.world_id, "noise": metro_noise, "tide_level": metro_tide_level}
		state.settle_run(not abandoned and mission_phase == MissionPhase.COMPLETE, collected_records.size(), player.echo_shards, enemies_defeated, event_results.size(), run_equipment_rewards, summary)
	get_tree().change_scene_to_file("res://scenes/corridor.tscn")


func _on_abandon_pressed() -> void:
	if _abandon_armed_until == 0:
		_abandon_armed_until = Time.get_ticks_msec() + 3000
		abandon_button.text = "再次点击确认撤回"
		return
	_return_to_corridor(true)


func _on_player_health_changed(current: int, maximum: int) -> void:
	if current < _previous_health:
		_recent_damage = clampf(_recent_damage + float(_previous_health - current) / maximum, 0.0, 1.0)
	_previous_health = current
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
				player.add_echo_shards(2 if run_config.causal_chain == "quiet_signal" else 1)
				event_results.append("回响病房：远程封锁")
		"archive_whisper":
			if take_risk:
				player.add_echo_shards(3)
				player.take_damage(8, player.global_position)
				event_results.append("低语档案：接受记忆")
			else:
				player.add_ammo(3)
				event_results.append("低语档案：烧毁副本")
		"power_surge":
			if take_risk:
				player.add_shells(3)
				_spawn_crawler_wave()
				event_results.append("过载回路：导出能量")
			else:
				player.add_stimulants(1)
				event_results.append("过载回路：安全旁路")
		"floating_locker":
			if take_risk:
				player.add_bandages(1)
				metro_tide_level = mini(metro_tide_level + 1, 2)
				event_results.append("漂浮失物柜：强取密封包")
			else: event_results.append("漂浮失物柜：放弃")
		"wrong_announcement":
			if take_risk:
				player.add_echo_shards(4)
				_spawn_crawler_wave()
				event_results.append("错误报站：跟随伪信号")
			else:
				metro_noise += 1
				event_results.append("错误报站：忽略")
		"help_carriage":
			if take_risk:
				player.add_ammo(6)
				_spawn_crawler_wave()
				event_results.append("求救车厢：开门")
			else:
				player.add_echo_shards(2)
				event_results.append("求救车厢：远程回应")
		"breaker_bypass":
			if take_risk:
				metro_train_window += 20.0 if metro_train_window > 0.0 else 0.0
				metro_noise += 3
				event_results.append("断路器旁路：短接")
			else:
				player.add_stimulants(1)
				event_results.append("断路器旁路：保守")
	active_event.mark_resolved()
	active_event = null
	event_panel.visible = false
	_set_gameplay_paused(false)
	progress.text = "%s %d/%d  ·  事件 %d/2" % [run_config.objective_noun, collected_records.size(), total_records, event_results.size()]


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
	if run_config.world_id == "metro":
		var tide_names := ["干燥", "浸水", "深水"]
		var train := "未校准" if metro_train_window < 0.0 else "%ds" % ceili(metro_train_window)
		progress.text = "%s %d/%d · 潮位%s · 噪音%d · 车次%s" % [run_config.objective_noun, collected_records.size(), total_records, tide_names[metro_tide_level], metro_noise, train]
		var route_text := "选择北/南站台道岔" if metro_route.is_empty() else ("赶往%s站台，在车门关闭前登车" % ("北" if metro_route == "north" else "南"))
		objective.text = "当前目标：%s" % ("校准车次信标" if mission_phase == MissionPhase.COLLECT_RECORDS else ("选择撤离站台" if mission_phase == MissionPhase.RESTORE_POWER else route_text))
		return
	progress.text = "%s %d/%d  ·  电力%s" % [run_config.objective_noun, collected_records.size(), total_records, "已恢复" if power_restored else "中断"]
	match mission_phase:
		MissionPhase.COLLECT_RECORDS:
			objective.text = "当前目标：%s · 搜索 %d 个%s" % [run_config.mission_title, total_records, run_config.objective_noun]
		MissionPhase.RESTORE_POWER:
			objective.text = "当前目标：前往地下维护区恢复电力"
		MissionPhase.EVACUATE:
			objective.text = "当前目标：前往紧急撤离出口"
		MissionPhase.COMPLETE:
			objective.text = "任务完成：疗养院异常路线已稳定"


func _create_mission_interactables() -> void:
	for index in range(total_records):
		_add_interactable(ObjectiveInteractable.Kind.RECORD, "objective_%02d" % index, "%s %d" % [run_config.objective_noun, index + 1], run_config.objective_positions[index])
	if run_config.world_id == "metro":
		_add_interactable(ObjectiveInteractable.Kind.POWER, "metro_north_switch", "北站台道岔 · 高架慢线", run_config.metro_route_positions.north.switch)
		_add_interactable(ObjectiveInteractable.Kind.POWER, "metro_south_switch", "南站台道岔 · 淹没快线", run_config.metro_route_positions.south.switch)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "metro_exit_north", "北站台末班车", run_config.metro_route_positions.north.exit)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "metro_exit_south", "南站台末班车", run_config.metro_route_positions.south.exit)
	else:
		_add_interactable(ObjectiveInteractable.Kind.POWER, "basement_power", "供电稳定节点", run_config.power_position)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "extraction_gate", "动态撤离出口", run_config.exit_position)


func _create_patients() -> void:
	for spawn_position in run_config.patient_spawns:
		var patient := PATIENT_SCENE.instantiate() as Patient
		patient.position = spawn_position
		patient.target = player
		if run_config.world_id == "metro":
			patient.movement_speed = 96.0
			patient.max_health = 62
			patient.enemy_label = "溺行者"
		patient.tree_exiting.connect(_on_enemy_removed.bind(patient))
		add_child(patient)


func _create_crawlers() -> void:
	for spawn_position in run_config.crawler_spawns:
		var crawler := CRAWLER_SCENE.instantiate() as Crawler
		crawler.position = spawn_position
		crawler.target = player
		crawler.tree_exiting.connect(_on_enemy_removed.bind(crawler))
		add_child(crawler)


func _create_orderlies() -> void:
	for spawn_position in run_config.orderly_spawns:
		var orderly := ORDERLY_SCENE.instantiate() as Orderly
		orderly.position = spawn_position
		orderly.target = player
		if run_config.world_id == "metro":
			orderly.max_health = 130
			orderly.attack_damage = 24
			orderly.enemy_label = "检票员"
		orderly.tree_exiting.connect(_on_enemy_removed.bind(orderly))
		add_child(orderly)


func _create_boss() -> void:
	boss = BOSS_SCENE.instantiate() as SanatoriumBoss
	boss.position = run_config.boss_position
	boss.target = player
	if run_config.world_id == "metro":
		boss.boss_label = "末班列车 · 车长回声"
		boss.max_health = 360
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	add_child(boss)


func _on_enemy_removed(enemy: Node) -> void:
	if enemy.get("health") != null and int(enemy.get("health")) <= 0:
		enemies_defeated += 1
		if enemy is SanatoriumBoss:
			_spawn_reward_chest(enemy.global_position)
		else:
			_drop_for_enemy(enemy, _loot_rng.randf())


func _drop_for_enemy(enemy: Node, roll: float) -> ResourcePickup:
	var kind := ResourcePickup.Kind.ECHO_SHARD
	var amount := 1
	var threshold := 0.38
	if enemy is Crawler:
		kind = ResourcePickup.Kind.AMMO
		amount = 3
		threshold = 0.52
	elif enemy is Orderly:
		kind = ResourcePickup.Kind.SHELLS if roll < 0.24 else ResourcePickup.Kind.SEDATIVE
		amount = 2 if kind == ResourcePickup.Kind.SHELLS else 1
		threshold = 0.34
	elif enemy is Patient:
		kind = ResourcePickup.Kind.BANDAGE if roll < 0.16 else ResourcePickup.Kind.ECHO_SHARD
		threshold = 0.42
	if roll > threshold:
		return null
	var pickup := PICKUP_SCENE.instantiate() as ResourcePickup
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = enemy.global_position
	add_child.call_deferred(pickup)
	return pickup


func _spawn_reward_chest(at: Vector2) -> RewardChest:
	var chest := RewardChest.new()
	chest.position = at
	var pool := EquipmentDatabase.metro_reward_pool() if run_config.world_id == "metro" else EquipmentDatabase.reward_pool()
	pool.shuffle()
	chest.candidates.assign(pool.slice(0, 3))
	add_child.call_deferred(chest)
	reward_chests.append(chest)
	_show_notification("主要威胁已清除：异常回收箱已生成\n可选择一件装备，成功撤离后入库", 5.0)
	return chest


func _nearest_reward_chest() -> RewardChest:
	var nearest: RewardChest
	var nearest_distance := INTERACTION_DISTANCE
	for chest in reward_chests:
		if not is_instance_valid(chest) or chest.opened:
			continue
		var distance := player.global_position.distance_to(chest.global_position)
		if distance <= nearest_distance:
			nearest = chest
			nearest_distance = distance
	return nearest


func _open_reward_chest(chest: RewardChest) -> void:
	active_chest = chest
	for index in range(3):
		var item := EquipmentDatabase.get_item(chest.candidates[index])
		reward_buttons[index].text = "%s · %s\n评级 %d\n%s" % [item.quality, item.name, item.rating, item.description]
	reward_panel.visible = true
	prompt_panel.visible = false
	_set_gameplay_paused(true)


func _choose_reward(index: int) -> void:
	if active_chest == null or index < 0 or index >= active_chest.candidates.size():
		return
	var item_id := active_chest.candidates[index]
	run_equipment_rewards.append(item_id)
	var item := EquipmentDatabase.get_item(item_id)
	active_chest.mark_opened()
	active_chest = null
	reward_panel.visible = false
	_set_gameplay_paused(false)
	_show_notification("已暂存：%s\n成功撤离后转入终末回廊仓库" % item.name, 4.0)


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
	for index in range(run_config.side_contracts.size()):
		var event_id: String = run_config.side_contracts[index]
		var at: Vector2 = DynamicRunConfig.CONTENT_SLOTS[(absi(run_config.seed) + index * 5) % DynamicRunConfig.CONTENT_SLOTS.size()]
		if run_config.world_id == "metro":
			var metro_events := ["floating_locker", "wrong_announcement", "help_carriage", "breaker_bypass"]
			var metro_id: String = metro_events[(absi(run_config.seed) + index) % metro_events.size()]
			match metro_id:
				"floating_locker": _add_risk_event(metro_id, "漂浮失物柜", "密封包正在水面上翻转。取走补给会破坏防水层。", "强取：补给 + 潮位上升", "放弃：保持干燥", at)
				"wrong_announcement": _add_risk_event(metro_id, "错误报站", "广播指向一条未标注的站台。", "跟随：碎片 + 敌袭", "忽略：记录噪音", at)
				"help_carriage": _add_risk_event(metro_id, "求救车厢", "车厢内的求救灯仍在闪烁。", "开门：补给 + 敌袭", "远程回应：少量碎片", at)
				"breaker_bypass": _add_risk_event(metro_id, "断路器旁路", "短接能压缩车次等待，但会惊动整座站台。", "短接：车次 +20 秒 · 高噪音", "保守：获得兴奋剂", at)
			continue
		match event_id:
			"medicine_cabinet":
				_add_risk_event(event_id, "污染药柜", "柜门后的药品仍可使用，但内部孢子浓度正在上升。\n强行开启可获得绷带和弹药，同时承受污染伤害。", "强行开启：补给 + 受伤", "封存药柜：安全离开", at)
			"echo_ward":
				_add_risk_event(event_id, "回响病房", "高密度碎片与墙后爬行声产生共振。", "深入取样：5 碎片 + 敌袭", "远程封锁：安全碎片", at)
			"archive_whisper":
				_add_risk_event(event_id, "低语档案", "档案正在复述并不属于你的记忆。接受它可获得回响，但会损伤神经。", "接受记忆：3 碎片 + 受伤", "烧毁副本：少量弹药", at)
			"power_surge":
				_add_risk_event(event_id, "过载回路", "异常电流可转化为霰弹能源，但会唤醒附近爬行者。", "导出能量：霰弹 + 敌袭", "安全旁路：兴奋剂", at)


func _unrevealed_room_count() -> int:
	var count := 0
	for value in fog_of_war.reveal_progress.values():
		if float(value) < 0.95:
			count += 1
	return count


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


func _update_metro_pressure(delta: float) -> void:
	metro_tide_timer += delta
	if metro_tide_timer >= 45.0 and metro_tide_level < 2:
		metro_tide_timer = 0.0
		metro_tide_level += 1
		_show_notification("潮位上升：%s区域%s。" % ["浸水" if metro_tide_level == 1 else "深水", "会减速；高架路线仍可通行" if metro_tide_level == 1 else "开始持续伤害，低层捷径已不可取"], 4.0)
		queue_redraw()
	if metro_train_window > 0.0:
		metro_train_window -= delta
		if metro_train_window <= 0.0:
			metro_train_window = 35.0
			metro_noise += 1
			_show_notification("错过末班车：备用道岔响应，补救车次开放 35 秒。", 5.0)
	_update_mission_ui()
	_update_metro_water_state(delta)


func _activate_metro_route(target: ObjectiveInteractable) -> void:
	metro_route = "north" if target.objective_id == "metro_north_switch" else "south"
	power_restored = true
	mission_phase = MissionPhase.EVACUATE
	target.mark_complete()
	for item in interactables:
		if item.kind == ObjectiveInteractable.Kind.POWER and item != target:
			item.mark_complete()
	boss.activate(player)
	metro_train_window = 115.0 if metro_route == "north" else 70.0
	if metro_route == "north":
		metro_noise += 1
		_show_notification("高架慢线已校准：北站台 115 秒窗口。路线更长，但可避开深水。\n车长回声是可选回收目标，不必击杀。", 6.0)
	else:
		metro_noise += 2
		_spawn_crawler_wave()
		_show_notification("淹没快线已校准：南站台 70 秒窗口。路线更短，但必须穿过积水。\n车长回声是可选回收目标，不必击杀。", 6.0)
	queue_redraw()


func _metro_water_depth_at(position: Vector2) -> int:
	if metro_tide_level <= 0:
		return 0
	for zone in METRO_SHALLOW_ZONES:
		if zone.has_point(position):
			if metro_tide_level >= 2:
				return 2 if METRO_DEEP_ZONES.any(func(deep_zone): return deep_zone.has_point(position)) else 1
			return 1
	return 0


func _update_metro_water_state(delta: float) -> void:
	var next_state := _metro_water_depth_at(player.global_position)
	if next_state != metro_water_state:
		metro_water_state = next_state
		if metro_water_state == 1:
			_show_notification("进入浸水区：移动速度降低。", 2.0)
		elif metro_water_state == 2:
			_show_notification("进入深水区：持续受损，尽快离开或使用兴奋剂冲刺。", 2.5)
		else:
			_show_notification("已回到干燥高地。", 1.5)
		queue_redraw()
	player.environment_speed_multiplier = 0.68 if metro_water_state == 1 else (0.46 if metro_water_state == 2 else 1.0)
	if metro_water_state == 2:
		metro_water_damage_timer += delta
		if metro_water_damage_timer >= 1.2:
			metro_water_damage_timer = 0.0
			player.take_damage(4, player.global_position - Vector2(0, 1))
	else:
		metro_water_damage_timer = 0.0


func _create_feedback_layer() -> void:
	notification = Label.new()
	notification.position = Vector2(365, 96)
	notification.size = Vector2(550, 72)
	notification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _create_reward_panel() -> void:
	reward_panel = ColorRect.new()
	reward_panel.position = Vector2(170, 160)
	reward_panel.size = Vector2(940, 410)
	reward_panel.color = Color(0.012, 0.045, 0.042, 0.98)
	reward_panel.visible = false
	reward_panel.z_index = 120
	$Interface.add_child(reward_panel)
	var title := Label.new()
	title.position = Vector2(30, 25)
	title.size = Vector2(880, 55)
	title.text = "异常回收协议 // 选择一项奖励"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("69e4cd"))
	reward_panel.add_child(title)
	for index in range(3):
		var button := Button.new()
		button.position = Vector2(35 + index * 300, 105)
		button.size = Vector2(270, 225)
		button.add_theme_font_override("font", UI_FONT)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_choose_reward.bind(index))
		reward_panel.add_child(button)
		reward_buttons.append(button)
	var note := Label.new()
	note.position = Vector2(40, 350)
	note.size = Vector2(860, 35)
	note.text = "只能选择一项 · 奖励在成功撤离后入库 · 主动撤回或死亡将失去"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_override("font", UI_FONT)
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color("78958d"))
	reward_panel.add_child(note)
	_apply_responsive_ui()


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
	var metro := run_config != null and run_config.world_id == "metro"
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("10223a") if metro else (Color("15201c") if power_restored else Color("101514")))
	if metro:
		# Tide is a playable surface, not background decoration: these are the low routes
		# that slow the walker at level 1 and become damaging deep water at level 2.
		for y in range(96, int(MAP_SIZE.y), 168):
			draw_line(Vector2(32, y + 12), Vector2(MAP_SIZE.x - 32, y + 12), Color(0.28, 0.72, 0.9, 0.22), 2.0)
		if metro_tide_level > 0:
			for zone in METRO_SHALLOW_ZONES:
				var deep := metro_tide_level >= 2 and METRO_DEEP_ZONES.any(func(deep_zone): return deep_zone == zone)
				draw_rect(zone, Color("174d6d") if deep else Color("17607b"), true)
				draw_rect(zone, Color("7fd9ed") if deep else Color("52a9c7"), false, 3.0)
				for x in range(int(zone.position.x) + 20, int(zone.end.x), 46):
					draw_line(Vector2(x, zone.position.y + 18), Vector2(x + 20, zone.position.y + 18), Color(0.68, 0.94, 1.0, 0.38), 2.0)
		if metro_route == "north":
			draw_line(DynamicRunConfig.METRO_NORTH_SWITCH, DynamicRunConfig.METRO_NORTH_EXIT, Color("a4f6cf"), 5.0)
		elif metro_route == "south":
			draw_line(DynamicRunConfig.METRO_SOUTH_SWITCH, DynamicRunConfig.METRO_SOUTH_EXIT, Color("f0b568"), 5.0)
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
	var room_index := 0
	for room in SanatoriumLayout.rooms():
		var metro := run_config != null and run_config.world_id == "metro"
		draw_rect(room.rect, Color("142b40") if metro else Color("18211f"))
		draw_rect(room.rect, Color("3a7090") if metro else Color("27332f"), false, 2.0)
		draw_string(UI_FONT, room.rect.position + Vector2(24, 42), run_config.room_role(room_index), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("86b9ce") if metro else Color("617269"))
		room_index += 1


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
	var walls: Array[Rect2] = [
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
	if run_config:
		match absi(run_config.seed) % 3:
			0: walls.append(Rect2(832, 896, 64, 32))
			1: walls.append(Rect2(1408, 448, 32, 64))
			2: walls.append(Rect2(1888, 448, 64, 32))
	return walls
