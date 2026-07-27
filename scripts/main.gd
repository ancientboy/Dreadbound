extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const PATIENT_SCENE: PackedScene = preload("res://scenes/entities/patient.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/entities/pickup.tscn")
const CRAWLER_SCENE: PackedScene = preload("res://scenes/entities/crawler.tscn")
const ORDERLY_SCENE: PackedScene = preload("res://scenes/entities/orderly.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/entities/boss.tscn")
const DROWNED_SCENE: PackedScene = preload("res://scenes/entities/drowned.tscn")
const CONDUCTOR_SCENE: PackedScene = preload("res://scenes/entities/conductor.tscn")
const LAST_TRAIN_SCENE: PackedScene = preload("res://scenes/entities/last_train_boss.tscn")
const SIGNAL_ANCHOR_SCENE: PackedScene = preload("res://scenes/entities/signal_anchor.tscn")
const SANATORIUM_TILESET: Texture2D = preload("res://assets/art/worlds/sanatorium/sanatorium_tileset.png")
const SANATORIUM_PROPS: Texture2D = preload("res://assets/art/worlds/sanatorium/sanatorium_props.png")
const SANATORIUM_OBJECTIVE_LIGHTING: Texture2D = preload("res://assets/art/vfx/sanatorium_objective_lighting.png")
const METRO_TILESET: Texture2D = preload("res://assets/art/worlds/metro/metro_tileset.png")
const METRO_PROPS: Texture2D = preload("res://assets/art/worlds/metro/metro_props.png")
const METRO_FLOOD_LAYERS: Texture2D = preload("res://assets/art/vfx/metro_flood_layers.png")
const METRO_MAINTENANCE_ATLAS: Texture2D = preload("res://assets/art/worlds/metro/metro_maintenance_atlas.png")
const STORY_NPC_PORTRAITS: Texture2D = preload("res://assets/art/characters/npcs/story_npc_portraits.png")
const PROGRESSION_STATUS_ICONS: Texture2D = preload("res://assets/art/ui/progression_status_icons.png")
const MILESTONE_FEEDBACK: Texture2D = preload("res://assets/art/vfx/milestone_feedback.png")

enum MissionPhase { COLLECT_RECORDS, RESTORE_POWER, EVACUATE, COMPLETE, FAILED }

const MAP_SIZE := Vector2(2304.0, 1440.0)
const INTERACTION_DISTANCE := 86.0
const METRO_SHALLOW_ZONES := [Rect2(480, 704, 416, 192), Rect2(960, 704, 480, 192), Rect2(1504, 960, 704, 320)]
const METRO_DEEP_ZONES := [Rect2(960, 704, 480, 192), Rect2(1504, 960, 704, 320)]
const METRO_FLOODGATE_POSITION := Vector2(1456, 864)
const METRO_DRAINED_ZONE := Rect2(960, 704, 480, 192)
const METRO_FLOODGATE_DURATION := 28.0
const METRO_ZERO_ROUTE_DURATION := 42.0
const METRO_HIDDEN_GATE_RECT := Rect2(1472, 1088, 32, 128)
const METRO_NPC_POSITION := Vector2(1344, 1136)
const METRO_HIDDEN_ARCHIVE_POSITION := Vector2(1888, 1136)

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
var audio_settings_button: Button
var audio_settings_panel: DreadboundAudioSettingsPanel

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
var reward_chests: Array[RewardChest] = []
var run_equipment_rewards: Array[String] = []
var run_material_rewards := {}
var run_loot_log: Array[Dictionary] = []
var _rare_material_pity := 0
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
var world_rules: WorldRules
var ticket_recovery_used := false
var signal_anchors: Array[SignalAnchor] = []
var whistle_cooldown := 0.0
var whistle_uses := 0
var metro_missed_train := false
var metro_floodgate_timer := 0.0
var run_elapsed := 0.0
var boss_defeated := false
var pathway_status_label: Label
var pathway_status_icons: HBoxContainer
var narrative_portrait: TextureRect
var milestone_feedback: TextureRect
var milestone_caption: Label
var _status_icon_signature := ""
var metro_zero_route_timer := 0.0
var metro_switch_failures := 0
var curator_contract := {}
var curator_effects := {}
var curator_floodgate_used := false
var narrative_chapter := {}
var active_narrative := {}
var active_narrative_target: ObjectiveInteractable
var hidden_gate: StaticBody2D
var content_catalog := ContentCatalog.new()
var enemy_affixes := EnemyAffixSystem.new()
var encountered_affixes: Array[Dictionary] = []
var _enemy_ordinal := 0


func _ready() -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world(GameState.selected_world)
	get_viewport().size_changed.connect(_apply_responsive_ui)
	var run_seed: int = GameState.active_run_seed
	if run_seed == 0:
		run_seed = GameState.begin_run(1337 if OS.has_feature("editor") else 0)
	run_config = DynamicRunConfig.new(run_seed, GameState.selected_world, GameState.selected_difficulty)
	narrative_chapter = GameState.dungeon_chapter(run_config.world_id)
	if bool(narrative_chapter.get("hidden_open", false)):
		run_config.revealed_secret_regions.append("lost_passenger_level" if run_config.world_id == "metro" else "sealed_archive")
	curator_contract = GameState.get_curator_trial()
	curator_effects = GameState.get_active_contract_effects()
	world_rules = WorldRules.new(run_config.world_id)
	assert(run_config.validate())
	_apply_curator_contract()
	total_records = run_config.objective_count
	_create_collision_walls()
	fog_of_war.player = player
	minimap.player = player
	minimap.fog = fog_of_war
	minimap.run_config = run_config
	fog_of_war.exploration_changed.connect(minimap.queue_redraw)
	minimap.expanded_changed.connect(_on_map_expanded_changed)
	_create_mission_interactables()
	_create_persistent_narrative()
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
	player.noise_generated.connect(_on_player_noise_generated)
	player.equipment_trait_used.connect(_on_equipment_trait_used)
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
	_create_audio_settings()
	_apply_responsive_ui()
	_loot_rng.randomize()
	if not GameState.corridor_unlocked:
		_show_notification("首次连接：左侧摇杆移动 · 攻击键战斗 · E键交互\n右上角地图可查看探索路线", 7.0)
	$Interface/TopBar/Title.text = "%s // %s" % [run_config.mission_title, run_config.action_code]
	if run_config.world_id == "metro":
		var contract_note := "\n司仪契约：%s" % str(curator_contract.title) if not curator_contract.is_empty() else ""
		var chapter_note := "\n%s：%s" % [str(narrative_chapter.get("title", "")), str(narrative_chapter.get("briefing", ""))]
		_show_notification("潮没末班线：潮位正在上升。收集信标、恢复信号并赶上撤离窗口。%s%s" % [contract_note, chapter_note], 8.0)
	else:
		var chapter_note := "%s：%s" % [str(narrative_chapter.get("title", "")), str(narrative_chapter.get("briefing", ""))]
		_show_notification("废弃疗养院已读取你的历史。\n%s" % chapter_note, 7.0)
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
	if audio_settings_button:
		audio_settings_button.position = Vector2(width - 104, 82)
		audio_settings_button.size = Vector2(104, 40)
	_layout_centered_panel(complete_panel, viewport_size, Vector2(600, 276), Vector2(32, 150))
	_layout_centered_panel(event_panel, viewport_size, Vector2(680, 380), Vector2(32, 150))
	_layout_complete_contents()
	_layout_event_contents()
	if notification:
		notification.position = Vector2((viewport_size.x - minf(720.0, viewport_size.x - 64.0)) * 0.5, 104)
		notification.size = Vector2(minf(720.0, viewport_size.x - 64.0), 76)
	if pathway_status_label:
		pathway_status_label.position = Vector2((viewport_size.x - minf(720.0, viewport_size.x - 64.0)) * 0.5, 178)
		pathway_status_label.size = Vector2(minf(720.0, viewport_size.x - 64.0), 28)
	if pathway_status_icons:
		pathway_status_icons.position = Vector2(pathway_status_label.position.x - 112.0, 174)
	if reward_panel:
		_layout_centered_panel(reward_panel, viewport_size, Vector2(720, 610), Vector2(24, 48))
		_layout_reward_contents()


func _create_audio_settings() -> void:
	audio_settings_button = Button.new()
	audio_settings_button.name = "OpenInGameAudioSettings"
	audio_settings_button.text = "声音"
	audio_settings_button.tooltip_text = "音乐与音效设置"
	audio_settings_button.add_theme_font_override("font", UI_FONT)
	audio_settings_button.add_theme_font_size_override("font_size", 16)
	audio_settings_button.pressed.connect(func(): audio_settings_panel.toggle())
	$Interface/TopBar.add_child(audio_settings_button)
	audio_settings_panel = DreadboundAudioSettingsPanel.new()
	$Interface.add_child(audio_settings_panel)
	audio_settings_panel.configure(UI_FONT)


func _layout_centered_panel(panel: Control, viewport_size: Vector2, preferred: Vector2, padding: Vector2) -> void:
	if panel == null:
		return
	var panel_size := Vector2(minf(preferred.x, viewport_size.x - padding.x * 2.0), minf(preferred.y, viewport_size.y - padding.y))
	panel.size = panel_size
	panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, maxf(108.0, (viewport_size.y - panel_size.y) * 0.5))


func _layout_event_contents() -> void:
	var width := event_panel.size.x
	event_title.position = Vector2(28, 24)
	event_title.size = Vector2(width - 56, 48)
	if narrative_portrait:
		narrative_portrait.position = Vector2(38, 82)
		narrative_portrait.size = Vector2(126, 126)
	event_description.position = Vector2(180 if narrative_portrait and narrative_portrait.visible else 42, 84)
	event_description.size = Vector2(width - (222 if narrative_portrait and narrative_portrait.visible else 84), 118)
	var button_width := (width - 126) * 0.5
	event_choice_a.position = Vector2(42, 232)
	event_choice_a.size = Vector2(button_width, 92)
	event_choice_b.position = Vector2(84 + button_width, 232)
	event_choice_b.size = Vector2(button_width, 92)
	event_choice_a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_choice_b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _layout_complete_contents() -> void:
	var width := complete_panel.size.x
	result_heading.position = Vector2(28, 28)
	result_heading.size = Vector2(width - 56, 58)
	result_summary.position = Vector2(34, 94)
	result_summary.size = Vector2(width - 68, 86)
	$Interface/CompletePanel/Restart.position = Vector2(30, 184)
	$Interface/CompletePanel/Restart.size = Vector2(width - 60, 30)
	return_button.position = Vector2((width - 260) * 0.5, 210)
	return_button.size = Vector2(260, 54)


func _layout_reward_contents() -> void:
	var width := reward_panel.size.x
	var height := reward_panel.size.y
	var title := reward_panel.get_child(0) as Label
	title.position = Vector2(28, 22)
	title.size = Vector2(width - 56, 56)
	var gap := 10.0
	var card_height := maxf(56.0, (height - 176.0 - gap * 2.0) / 3.0)
	for index in range(reward_buttons.size()):
		reward_buttons[index].position = Vector2(35, 88 + index * (card_height + gap))
		reward_buttons[index].size = Vector2(width - 70, card_height)
		reward_buttons[index].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_buttons[index].add_theme_font_size_override("font_size", 13 if card_height < 100.0 else 16)
	var note := reward_panel.get_child(reward_panel.get_child_count() - 1) as Label
	note.position = Vector2(32, height - 52)
	note.size = Vector2(width - 64, 36)


func _on_map_expanded_changed(expanded: bool) -> void:
	var gameplay_active := mission_phase != MissionPhase.COMPLETE and mission_phase != MissionPhase.FAILED
	player.set_physics_process(gameplay_active and not expanded)
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		mobile_controls.visible = not expanded
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(gameplay_active and not expanded)


func _process(delta: float) -> void:
	run_elapsed += delta
	whistle_cooldown = maxf(whistle_cooldown - delta, 0.0)
	if _notification_timer > 0.0:
		_notification_timer -= delta
		if _notification_timer <= 0.0 and notification:
				notification.visible = false
	_update_pathway_status()
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
		if target.kind == ObjectiveInteractable.Kind.SECRET and not GameState.dungeon_hidden_open("metro", "lost_passenger_level"):
			prompt.text = "维护层封闭 // 林雾说下一次潮汐会改变门锁"
		elif run_config.world_id == "metro" and not metro_route.is_empty() and target.kind == ObjectiveInteractable.Kind.EXIT and target.objective_id != "metro_exit_%s" % metro_route:
			prompt.text = "列车未停靠此站 // 前往%s站台" % ("北" if metro_route == "north" else "南")
		else:
			prompt.text = target.get_prompt(collected_records.size(), power_restored, total_records)
		if wants_to_interact:
			_handle_interaction(target)


func _handle_interaction(target: ObjectiveInteractable) -> void:
	match target.kind:
		ObjectiveInteractable.Kind.RECORD:
			if run_config.world_id == "metro" and run_config.mission_id == "switch_zero":
				_handle_metro_switch_lock(target)
			elif not collected_records.has(target.objective_id):
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
					for item in interactables:
						if item.kind == ObjectiveInteractable.Kind.EXIT:
							item.mark_active()
					boss.activate(player)
					(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("director_windup")
					(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world(run_config.world_id, true, metro_tide_level > 0)
					_show_notification("警报：电力恢复，缝合主任已苏醒！\n出口现已开放，战斗或绕行撤离", 5.0)
				(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("objective")
				if run_config.causal_chain == "spore_bloom" and event_results.any(func(result): return "污染药柜：强行开启" in result):
					_spawn_crawler_wave()
					_show_notification("因果回响：孢子污染沿供电管线扩散，额外威胁苏醒", 4.5)
				queue_redraw()
		ObjectiveInteractable.Kind.EXIT:
			if power_restored and (run_config.world_id != "metro" or (target.objective_id == "metro_exit_%s" % metro_route and metro_train_window > 0.0)):
				_complete_mission()
		ObjectiveInteractable.Kind.FLOODGATE:
			_activate_metro_floodgate(target)
		ObjectiveInteractable.Kind.NPC:
			_open_persistent_narrative(target)
		ObjectiveInteractable.Kind.SECRET:
			if GameState.dungeon_hidden_open("metro", "lost_passenger_level"):
				target.mark_complete()
				_open_hidden_gate()
			else:
				_show_notification("门锁拒绝当前行动代码。这里等待的是你下一次进入后的选择。", 4.0)
	_update_mission_ui()


func _complete_mission() -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("extract")
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
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world("corridor")
	if _run_settled:
		return
	_run_settled = true
	var state := get_node_or_null("/root/GameState")
	if state:
		var summary := {"action_code": run_config.action_code, "mission": run_config.mission_title, "mission_id": run_config.mission_id, "causal_chain": run_config.causal_chain, "director_log": director.decision_log, "world": run_config.world_id, "difficulty": run_config.difficulty_id, "noise": metro_noise, "tide_level": metro_tide_level, "metro_route": metro_route, "missed_train": metro_missed_train, "whistle_uses": whistle_uses, "duration": run_elapsed, "anomaly_pressure": player.pathway_effects.anomaly_pressure, "boss_defeated": boss_defeated, "switch_failures": metro_switch_failures, "curator_floodgate_used": curator_floodgate_used, "enemy_affixes": encountered_affixes, "material_rewards": run_material_rewards.duplicate(true), "loot_log": run_loot_log.duplicate(true)}
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
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("warning")
	active_event = risk_event
	if narrative_portrait:
		narrative_portrait.visible = false
	event_title.text = risk_event.title
	event_description.text = risk_event.description
	event_choice_a.text = risk_event.choice_a
	event_choice_b.text = risk_event.choice_b
	event_panel.visible = true
	_layout_event_contents()
	prompt_panel.visible = false
	_set_gameplay_paused(true)


func _resolve_active_event(take_risk: bool) -> void:
	if not active_narrative.is_empty():
		_resolve_persistent_narrative(take_risk)
		return
	if active_event == null:
		return
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("interact")
	var resolved_event_id := active_event.event_id
	var behavior_data: Dictionary = active_event.behavior_data
	var pathway_bonus := player.pathway_effects.on_risk_event(take_risk)
	if pathway_bonus > 0:
		player.add_echo_shards(pathway_bonus)
		player.play_profession_skill("anomaly_ingestion")
		_show_notification("异常摄取：额外获得 %d 碎片，异化压力升至 %d。" % [pathway_bonus, player.pathway_effects.anomaly_pressure], 3.0)
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
		_:
			var choices: Array = behavior_data.get("choices", [])
			var selected: Dictionary = choices[0 if take_risk else 1] if choices.size() == 2 else {}
			var cost_level := int(selected.get("cost_level", 1))
			if take_risk:
				player.add_echo_shards(2 + cost_level)
				if cost_level >= 3:
					player.take_damage(10, player.global_position)
			else:
				player.add_ammo(2 + cost_level)
			event_results.append("%s：%s" % [str(behavior_data.get("title", "高压选择")), str(selected.get("label", "已选择"))])
	active_event.mark_resolved()
	var selected_choice: Dictionary = {}
	var behavior_choices: Array = behavior_data.get("choices", [])
	if behavior_choices.size() == 2:
		selected_choice = behavior_choices[0 if take_risk else 1]
	var event_type := str(selected_choice.get("event_type", "risk_choice"))
	var context := {
		"took_risk": take_risk,
		"cost_level": int(selected_choice.get("cost_level", 1)),
		"anonymous": "anonymous" in str(behavior_data.get("event_type", "")) or "anonymous" in event_type,
		"public": "public" in str(behavior_data.get("event_type", "")) or "public" in event_type,
		"resources_at_choice": player.echo_shards + player.ammo + player.shells,
		"time_pressure": metro_train_window if run_config.world_id == "metro" else run_elapsed,
	}
	GameState.record_human_choice(event_type, resolved_event_id, str(selected_choice.get("label", "risk" if take_risk else "safe")), context, {"summary": event_results[-1]})
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
		_apply_difficulty_to_enemy(crawler, "爬行者")
		crawler.tree_exiting.connect(_on_enemy_removed.bind(crawler))
		add_child(crawler)


func _update_mission_ui() -> void:
	var contract_prefix := "[契约 %s] " % str(curator_contract.title) if not curator_contract.is_empty() else ""
	if run_config.world_id == "metro":
		var tide_names := ["干燥", "浸水", "深水"]
		var train := "未校准" if metro_train_window < 0.0 else "%ds" % ceili(metro_train_window)
		var gate := " · 水闸%ds" % ceili(metro_floodgate_timer) if metro_floodgate_timer > 0.0 else ""
		if metro_zero_route_timer > 0.0:
			gate += " · 零号高架%ds" % ceili(metro_zero_route_timer)
		progress.text = "%s %d/%d · 潮位%s · 噪音%d · 车次%s%s" % [run_config.objective_noun, collected_records.size(), total_records, tide_names[metro_tide_level], metro_noise, train, gate]
		var route_text := "选择北/南站台道岔" if metro_route.is_empty() else ("赶往%s站台，在车门关闭前登车" % ("北" if metro_route == "north" else "南"))
		if run_config.mission_id == "switch_zero":
			var next_lock := "零号主控台" if mission_phase != MissionPhase.COLLECT_RECORDS else _metro_next_switch_name()
			objective.text = "%s当前目标：%s" % [contract_prefix, "按序校准%s" % next_lock if mission_phase == MissionPhase.COLLECT_RECORDS else route_text]
		else:
			objective.text = "%s当前目标：%s" % [contract_prefix, "确认失联车次信标" if mission_phase == MissionPhase.COLLECT_RECORDS else ("选择撤离站台" if mission_phase == MissionPhase.RESTORE_POWER else route_text)]
		return
	progress.text = "%s %d/%d  ·  电力%s" % [run_config.objective_noun, collected_records.size(), total_records, "已恢复" if power_restored else "中断"]
	match mission_phase:
		MissionPhase.COLLECT_RECORDS:
			objective.text = "%s当前目标：%s · 搜索 %d 个%s" % [contract_prefix, run_config.mission_title, total_records, run_config.objective_noun]
		MissionPhase.RESTORE_POWER:
			objective.text = "当前目标：前往地下维护区恢复电力"
		MissionPhase.EVACUATE:
			objective.text = "当前目标：前往紧急撤离出口"
		MissionPhase.COMPLETE:
			objective.text = "任务完成：疗养院异常路线已稳定"


func _create_mission_interactables() -> void:
	for index in range(total_records):
		var id := "objective_%02d" % index
		var label := "%s %d" % [run_config.objective_noun, index + 1]
		if run_config.world_id == "metro" and run_config.mission_id == "switch_zero":
			id = "metro_switch_lock_%d" % index
			label = "零号%s" % DynamicRunConfig.METRO_SWITCH_LOCK_NAMES[index]
		_add_interactable(ObjectiveInteractable.Kind.RECORD, id, label, run_config.objective_positions[index])
	if run_config.world_id == "metro":
		_add_interactable(ObjectiveInteractable.Kind.POWER, "metro_north_switch", "北站台道岔 · 高架慢线", run_config.metro_route_positions.north.switch)
		_add_interactable(ObjectiveInteractable.Kind.POWER, "metro_south_switch", "南站台道岔 · 淹没快线", run_config.metro_route_positions.south.switch)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "metro_exit_north", "北站台末班车", run_config.metro_route_positions.north.exit)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "metro_exit_south", "南站台末班车", run_config.metro_route_positions.south.exit)
		_add_interactable(ObjectiveInteractable.Kind.FLOODGATE, "metro_emergency_floodgate", "应急水闸 · 中央低层", METRO_FLOODGATE_POSITION)
	else:
		_add_interactable(ObjectiveInteractable.Kind.POWER, "basement_power", "供电稳定节点", run_config.power_position)
		_add_interactable(ObjectiveInteractable.Kind.EXIT, "extraction_gate", "动态撤离出口", run_config.exit_position)


func _create_persistent_narrative() -> void:
	if run_config.world_id != "metro":
		_add_interactable(
			ObjectiveInteractable.Kind.NPC,
			"sanatorium_memory",
			str(narrative_chapter.get("npc_title", "失忆病人 · 沈岚")),
			Vector2(800, 480),
		)
		if bool(narrative_chapter.get("hidden_open", false)):
			_add_interactable(ObjectiveInteractable.Kind.NPC, "sanatorium_archive", "隐藏病历室 · 周衡", Vector2(1184, 480))
		return
	var already_open := bool(narrative_chapter.get("hidden_open", false))
	if already_open:
		_add_interactable(
			ObjectiveInteractable.Kind.NPC,
			"metro_hidden_archive",
			str(narrative_chapter.get("npc_title", "维护层向导 · 林雾")),
			METRO_HIDDEN_ARCHIVE_POSITION,
		)
	else:
		_add_interactable(
			ObjectiveInteractable.Kind.NPC,
			"linye_story",
			str(narrative_chapter.get("npc_title", "失踪乘客 · 林雾")),
			METRO_NPC_POSITION,
		)
	_add_interactable(
		ObjectiveInteractable.Kind.SECRET,
		"lost_passenger_gate",
		"失踪乘客维护层",
		Vector2(METRO_HIDDEN_GATE_RECT.position.x - 44.0, METRO_HIDDEN_GATE_RECT.get_center().y),
	)
	_add_interactable(ObjectiveInteractable.Kind.NPC, "xuzhao_memory", "修表匠 · 许照", Vector2(1040, 1008))
	_add_interactable(ObjectiveInteractable.Kind.NPC, "ticket_echo_memory", "无票者七号", Vector2(1780, 980))
	if already_open:
		_open_hidden_gate()
	else:
		hidden_gate = _create_blocking_body(METRO_HIDDEN_GATE_RECT)


func _open_persistent_narrative(target: ObjectiveInteractable) -> void:
	if target.objective_id in ["xuzhao_memory", "ticket_echo_memory"]:
		var npc_name := "许照" if target.objective_id == "xuzhao_memory" else "无票者七号"
		active_narrative = {
			"npc_title": npc_name,
			"npc_description": "%s记得当前章节“%s”，也记得林雾上一次如何看待你。其后续身份会随名单与阵营控制变化。" % [npc_name, str(narrative_chapter.get("title", ""))],
			"choice_a": str(narrative_chapter.get("choice_a", "听完")),
			"choice_b": str(narrative_chapter.get("choice_b", "离开")),
			"choice_a_id": str(narrative_chapter.get("choice_a_id", "")),
			"choice_b_id": str(narrative_chapter.get("choice_b_id", "")),
			"cause": str(narrative_chapter.get("cause", "")),
		}
	elif target.objective_id == "metro_hidden_archive":
		active_narrative = _hidden_archive_presentation()
	else:
		active_narrative = narrative_chapter.duplicate(true)
	active_narrative_target = target
	event_title.text = str(active_narrative.get("npc_title", active_narrative.get("title", "副本记忆")))
	_set_narrative_portrait(target)
	var cause := str(active_narrative.get("cause", ""))
	event_description.text = str(active_narrative.get("npc_description", active_narrative.get("briefing", "")))
	if not cause.is_empty() and not cause.contains("第一次进入"):
		event_description.text += "\n\n变化来源：%s" % cause
	event_choice_a.text = str(active_narrative.get("choice_a", "继续"))
	event_choice_b.text = str(active_narrative.get("choice_b", "离开"))
	event_panel.visible = true
	_layout_event_contents()
	prompt_panel.visible = false
	_set_gameplay_paused(true)


func _resolve_persistent_narrative(choose_a: bool) -> void:
	var choice_key := "choice_a_id" if choose_a else "choice_b_id"
	var choice := str(active_narrative.get(choice_key, ""))
	var result := GameState.resolve_dungeon_narrative(run_config.world_id, choice)
	if not bool(result.get("accepted", false)):
		_show_notification("这段记忆没有回应当前选择。", 3.0)
	else:
		event_results.append("剧情：%s" % str(result.get("summary", "")))
		var resolved_target_id := str(active_narrative_target.objective_id) if active_narrative_target else ""
		if active_narrative_target:
			active_narrative_target.mark_complete()
		if resolved_target_id in ["metro_hidden_archive", "sanatorium_archive"]:
			var hidden_loot := LootDatabase.source_reward(run_config.world_id, "hidden")
			for material_id in hidden_loot:
				_collect_run_material(str(material_id), int(hidden_loot[material_id]), "hidden")
		if bool(result.get("hidden_opened", false)):
			_open_hidden_gate()
			_add_hidden_archive_interaction()
		var unique_offer := str(result.get("unique_offer", ""))
		if not unique_offer.is_empty() and not run_equipment_rewards.has(unique_offer) and GameState.dungeon_reward_pool([unique_offer]).has(unique_offer):
			run_equipment_rewards.append(unique_offer)
			_show_notification("%s\n剧情唯一物品已暂存，成功撤离后入库。" % str(result.get("summary", "")), 6.0)
		else:
			_show_notification(str(result.get("summary", "")), 6.0)
		narrative_chapter = GameState.dungeon_chapter(run_config.world_id)
	active_narrative = {}
	active_narrative_target = null
	event_panel.visible = false
	_set_gameplay_paused(false)
	_update_mission_ui()
	queue_redraw()


func _hidden_archive_presentation() -> Dictionary:
	var chapter := GameState.dungeon_chapter("metro")
	var continuing_npc := str(chapter.get("chapter", "")) in ["guided_aftermath", "resistance_aftermath"]
	return {
		"title": str(chapter.get("title", "失踪乘客维护层")),
		"npc_title": str(chapter.get("npc_title", "失踪乘客名单")),
		"npc_description": "%s\n墙上的名单同时记录生者与回声。你上一次的决定让这扇门出现在地图上。" % str(chapter.get("npc_description", "")),
		"choice_a": "保存名单：让林雾继续辨认" if continuing_npc else "面对回声：承认因果",
		"choice_b": "抹除名单：阻止阵营利用" if continuing_npc else "切断回声：永久静默",
		"choice_a_id": "preserve_manifest" if continuing_npc else "face_echo",
		"choice_b_id": "erase_manifest" if continuing_npc else "silence_echo",
		"cause": str(chapter.get("cause", "")),
	}


func _open_hidden_gate() -> void:
	if is_instance_valid(hidden_gate):
		hidden_gate.queue_free()
	hidden_gate = null
	if not run_config.revealed_secret_regions.has("lost_passenger_level"):
		run_config.revealed_secret_regions.append("lost_passenger_level")
	if minimap:
		minimap.queue_redraw()
	queue_redraw()


func _add_hidden_archive_interaction() -> void:
	if interactables.any(func(item): return item.objective_id == "metro_hidden_archive"):
		return
	_add_interactable(
		ObjectiveInteractable.Kind.NPC,
		"metro_hidden_archive",
		"失踪乘客名单",
		METRO_HIDDEN_ARCHIVE_POSITION,
	)


func _create_blocking_body(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)
	return body


func _metro_next_switch_name() -> String:
	var order_index := collected_records.size()
	if order_index >= run_config.metro_switch_order.size():
		return "零号主控台"
	return "零号%s" % DynamicRunConfig.METRO_SWITCH_LOCK_NAMES[run_config.metro_switch_order[order_index]]


func _handle_metro_switch_lock(target: ObjectiveInteractable) -> void:
	if target.completed:
		return
	var expected_index := run_config.metro_switch_order[collected_records.size()]
	var actual_index := int(target.objective_id.trim_prefix("metro_switch_lock_"))
	if actual_index != expected_index:
		metro_switch_failures += 1
		metro_noise += 2
		metro_tide_timer += 18.0
		for item in interactables:
			if item.objective_id.begins_with("metro_switch_lock_"):
				item.completed = false
				item.queue_redraw()
		collected_records.clear()
		_spawn_crawler_wave()
		_show_notification("道岔反冲：序列重置，低层进水加快，检票员正在靠近。", 4.5)
		_update_mission_ui()
		return
	collected_records[target.objective_id] = true
	target.mark_complete()
	if collected_records.size() == total_records:
		mission_phase = MissionPhase.RESTORE_POWER
		_show_notification("零号道岔已取得控制权：前往任一站台确认改线。中央高架会短暂开启。", 5.0)
	_update_mission_ui()


func _create_patients() -> void:
	for spawn_position in run_config.patient_spawns:
		var patient := (DROWNED_SCENE.instantiate() if run_config.world_id == "metro" else PATIENT_SCENE.instantiate()) as Patient
		patient.position = spawn_position
		patient.target = player
		_apply_difficulty_to_enemy(patient, "溺行者" if run_config.world_id == "metro" else "病患")
		if patient is Drowned:
			patient.water_depth_provider = _metro_water_depth_at
		patient.tree_exiting.connect(_on_enemy_removed.bind(patient))
		add_child(patient)


func _create_crawlers() -> void:
	for spawn_position in run_config.crawler_spawns:
		var crawler := CRAWLER_SCENE.instantiate() as Crawler
		crawler.position = spawn_position
		crawler.target = player
		_apply_difficulty_to_enemy(crawler, "爬行者")
		crawler.tree_exiting.connect(_on_enemy_removed.bind(crawler))
		add_child(crawler)


func _create_orderlies() -> void:
	for spawn_position in run_config.orderly_spawns:
		var orderly := (CONDUCTOR_SCENE.instantiate() if run_config.world_id == "metro" else ORDERLY_SCENE.instantiate()) as Orderly
		orderly.position = spawn_position
		orderly.target = player
		_apply_difficulty_to_enemy(orderly, "检票员" if run_config.world_id == "metro" else "护理员")
		if orderly is Conductor:
			orderly.noise_provider = func(): return metro_noise
			orderly.route_provider = _metro_intercept_candidates
		orderly.tree_exiting.connect(_on_enemy_removed.bind(orderly))
		add_child(orderly)


func _create_boss() -> void:
	boss = (LAST_TRAIN_SCENE.instantiate() if run_config.world_id == "metro" else BOSS_SCENE.instantiate()) as SanatoriumBoss
	boss.position = run_config.boss_position
	boss.target = player
	var difficulty := GameState.get_difficulty()
	boss.max_health = int(round(boss.max_health * float(difficulty.enemy_health)))
	var variant := GameState.dungeon_boss_variant(run_config.world_id)
	boss.max_health = int(round(boss.max_health * float(variant.get("health", 1.0))))
	boss.configure_history_variant(variant)
	boss.health = boss.max_health
	if boss is LastTrainBoss:
		boss.encounter_provider = func(): return {"anchors": get_tree().get_nodes_in_group("signal_anchors").size(), "tide": metro_tide_level, "window": metro_train_window}
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	add_child(boss)


func _apply_difficulty_to_enemy(enemy: Node, base_name := "威胁") -> void:
	var difficulty := GameState.get_difficulty()
	if enemy.get("max_health") != null:
		enemy.max_health = int(round(int(enemy.max_health) * float(difficulty.enemy_health)))
		if enemy.get("health") != null:
			enemy.health = enemy.max_health
	if enemy.get("attack_damage") != null:
		enemy.attack_damage = int(round(int(enemy.attack_damage) * float(difficulty.enemy_damage)))
	var affix := enemy_affixes.apply(enemy, run_config.difficulty_id, run_config.seed, _enemy_ordinal, base_name)
	_enemy_ordinal += 1
	if not str(affix.get("id", "")).is_empty():
		encountered_affixes.append({"id": affix.id, "name": affix.name, "effect": affix.effect})


func _on_enemy_removed(enemy: Node) -> void:
	if enemy.get("health") != null and int(enemy.get("health")) <= 0:
		enemies_defeated += 1
		if enemy is SanatoriumBoss:
			boss_defeated = true
			_show_milestone_feedback(0, "首领已击败")
			var boss_loot := LootDatabase.boss_reward(run_config.world_id)
			var material_id := str(boss_loot.get("material", ""))
			if not material_id.is_empty():
				_collect_run_material(material_id, int(boss_loot.get("amount", 1)), "boss")
				_show_notification("首领核心已暂存：%s ×%d\n成功撤离后转入材料库" % [str(ExchangeEvolution.MATERIALS[material_id].name), int(boss_loot.get("amount", 1))], 4.5)
			_spawn_reward_chest(enemy.global_position)
		else:
			_drop_for_enemy(enemy, _loot_rng.randf())


func _drop_for_enemy(enemy: Node, roll: float) -> ResourcePickup:
	var family := LootDatabase.enemy_family(enemy, run_config.world_id)
	var result := LootDatabase.roll_enemy(
		run_config.world_id,
		family,
		roll,
		float(GameState.get_difficulty().loot_bonus),
		float(enemy.get_meta("dreadbound_drop_bonus", 0.0)),
		_rare_material_pity,
	)
	if result.is_empty():
		_rare_material_pity += 1
		return null
	var kind_names := {
		"bandage": ResourcePickup.Kind.BANDAGE,
		"echo_shard": ResourcePickup.Kind.ECHO_SHARD,
		"ammo": ResourcePickup.Kind.AMMO,
		"shells": ResourcePickup.Kind.SHELLS,
		"sedative": ResourcePickup.Kind.SEDATIVE,
		"stimulant": ResourcePickup.Kind.STIMULANT,
		"material": ResourcePickup.Kind.MATERIAL,
	}
	var kind := int(kind_names.get(str(result.kind), ResourcePickup.Kind.ECHO_SHARD))
	var pickup := PICKUP_SCENE.instantiate() as ResourcePickup
	pickup.kind = kind
	pickup.amount = int(result.get("amount", 1))
	if kind == ResourcePickup.Kind.MATERIAL:
		pickup.material_id = str(result.get("id", ""))
		pickup.material_collected.connect(_collect_run_material)
		_rare_material_pity = 0 if bool(result.get("rare", false)) or str(result.get("source", "")) == "rare_pity" else _rare_material_pity + 1
	else:
		_rare_material_pity += 1
	pickup.position = enemy.global_position
	player.combat_fx.loot_burst(pickup.position, _pickup_color(kind))
	add_child.call_deferred(pickup)
	return pickup


func _pickup_color(kind: int) -> Color:
	var colors := [Color("8fc6a1"), Color("45d8c3"), Color("d0a75a"), Color("c77b52"), Color("8ca7c7"), Color("d18b9f"), Color("c892ff")]
	return colors[int(kind)]


func _collect_run_material(material_id: String, amount: int, source := "enemy") -> void:
	if not ExchangeEvolution.MATERIALS.has(material_id) or amount <= 0:
		return
	run_material_rewards[material_id] = int(run_material_rewards.get(material_id, 0)) + amount
	run_loot_log.append({"kind": "material", "id": material_id, "amount": amount, "source": source})
	var name := str(ExchangeEvolution.MATERIALS[material_id].name)
	_show_notification("材料暂存：%s ×%d\n撤离成功后入库" % [name, amount], 2.5)


func _spawn_reward_chest(at: Vector2) -> RewardChest:
	var chest := RewardChest.new()
	chest.position = at
	var pool := GameState.dungeon_reward_pool(world_rules.reward_pool())
	if pool.size() < 3:
		pool = world_rules.reward_pool()
	pool.shuffle()
	chest.candidates.assign(pool.slice(0, 3))
	var difficulty := GameState.get_difficulty()
	var boss_item := EquipmentDatabase.boss_growth_item(run_config.world_id)
	if _loot_rng.randf() <= float(difficulty.boss_drop) and GameState.dungeon_reward_pool([boss_item]).has(boss_item):
		chest.candidates[0] = boss_item
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
	var authored := content_catalog.behavior_events_for(run_config.world_id)
	if not authored.is_empty():
		var start := absi(run_config.seed) % authored.size()
		for index in range(mini(2, authored.size())):
			var event: Dictionary = authored[(start + index) % authored.size()]
			var at: Vector2 = DynamicRunConfig.CONTENT_SLOTS[(absi(run_config.seed) + index * 5) % DynamicRunConfig.CONTENT_SLOTS.size()]
			_add_behavior_event(str(event.id), event, at)
		return
	for index in range(run_config.side_contracts.size()):
		var event_id: String = run_config.side_contracts[index]
		var at: Vector2 = DynamicRunConfig.CONTENT_SLOTS[(absi(run_config.seed) + index * 5) % DynamicRunConfig.CONTENT_SLOTS.size()]
		if run_config.world_id == "metro":
			var metro_events := world_rules.event_ids()
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


func _add_behavior_event(id: String, data: Dictionary, at: Vector2) -> void:
	var choices: Array = data.get("choices", [])
	if choices.size() != 2:
		return
	var risk_event := RiskEvent.new()
	risk_event.event_id = id
	risk_event.title = str(data.get("title", "高压情境"))
	risk_event.description = "%s\n系统会记录真实代价、是否公开以及你当时拥有的资源。" % str(data.get("description", ""))
	risk_event.choice_a = str(choices[0].get("label", "选择一"))
	risk_event.choice_b = str(choices[1].get("label", "选择二"))
	risk_event.behavior_data = data.duplicate(true)
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
	item.world_id = run_config.world_id
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
			metro_missed_train = true
			var has_ticket := GameState.has_equipment_trait("missed_train_recovery") and not ticket_recovery_used
			ticket_recovery_used = ticket_recovery_used or has_ticket
			metro_train_window = world_rules.train_window(metro_route, has_ticket, true) + float(curator_effects.get("recovery_window_bonus", 0.0))
			metro_noise += 1
			_show_notification("末班票根解析出隐藏车次：补救窗口延长至 %d 秒。" % int(metro_train_window) if has_ticket else "错过末班车：备用道岔响应，补救车次开放 %d 秒。" % int(metro_train_window), 5.0)
	if metro_floodgate_timer > 0.0:
		metro_floodgate_timer = maxf(metro_floodgate_timer - delta, 0.0)
		if is_zero_approx(metro_floodgate_timer):
			_show_notification("应急水闸失压：低层通道再次被深水淹没。", 3.5)
			queue_redraw()
	if metro_zero_route_timer > 0.0:
		metro_zero_route_timer = maxf(metro_zero_route_timer - delta, 0.0)
		if is_zero_approx(metro_zero_route_timer):
			_show_notification("零号高架失去供电：中央低层重新被潮水吞没。", 3.5)
			queue_redraw()
	_update_mission_ui()
	_update_metro_water_state(delta)


func _activate_metro_route(target: ObjectiveInteractable) -> void:
	if run_config.mission_id == "switch_zero":
		var selected_route := "north" if target.objective_id == "metro_north_switch" else "south"
		if selected_route != run_config.metro_switch_route:
			_show_notification("零号控制权指向%s站台：另一条线路仍被潮水锁死。" % ("北" if run_config.metro_switch_route == "north" else "南"), 3.5)
			return
	metro_route = "north" if target.objective_id == "metro_north_switch" else "south"
	power_restored = true
	mission_phase = MissionPhase.EVACUATE
	target.mark_complete()
	for item in interactables:
		if item.kind == ObjectiveInteractable.Kind.POWER and item != target:
			item.mark_complete()
	boss.activate(player)
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("conductor_windup")
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world(run_config.world_id, true, metro_tide_level > 0)
	_spawn_signal_anchors()
	metro_train_window = world_rules.train_window(metro_route, false)
	if run_config.mission_id == "switch_zero":
		metro_zero_route_timer = METRO_ZERO_ROUTE_DURATION + float(curator_effects.get("zero_route_bonus", 0.0))
		_show_notification("零号改线成立：中央高架已排干 %d 秒。沿高架前往%s站台，绕开低层深水。" % [int(metro_zero_route_timer), "北" if metro_route == "north" else "南"], 5.5)
	if metro_route == "north":
		metro_noise += 1
		_show_notification("高架慢线已校准：北站台 115 秒窗口。路线更长，但可避开深水。\n车长回声是可选回收目标，不必击杀。", 6.0)
	else:
		metro_noise += 2
		_spawn_crawler_wave()
		_show_notification("淹没快线已校准：南站台 70 秒窗口。路线更短，但必须穿过积水。\n车长回声是可选回收目标，不必击杀。", 6.0)
	queue_redraw()


func _activate_metro_floodgate(target: ObjectiveInteractable) -> void:
	if run_config.world_id != "metro" or target.completed:
		return
	if metro_tide_level < 1:
		_show_notification("水位尚未压到闸门，先继续推进。", 2.5)
		return
	target.mark_complete()
	curator_floodgate_used = true
	metro_floodgate_timer = METRO_FLOODGATE_DURATION + float(curator_effects.get("floodgate_bonus", 0.0))
	metro_noise += 1
	_show_notification("应急水闸开启：中央低层通道排水 %d 秒。快速穿越，但检票员已听见闸门。" % int(metro_floodgate_timer), 5.0)
	queue_redraw()


func _apply_curator_contract() -> void:
	if curator_contract.is_empty():
		return
	# These modifiers are announced before input begins and only affect stated
	# systems. They never touch hit chance, hidden damage, seeds, or exits.
	metro_tide_timer += float(curator_effects.get("tide_advance", 0.0))
	metro_tide_timer -= float(curator_effects.get("tide_delay", 0.0))
	if run_config.world_id == "sanatorium" and bool(curator_effects.get("boss_mark", false)):
		_show_notification("阈值司仪裁决：缝合主任已被标记为本次行动的可选裁决目标。", 4.0)


func _metro_water_depth_at(position: Vector2) -> int:
	if metro_tide_level <= 0:
		return 0
	for zone in METRO_SHALLOW_ZONES:
		if zone.has_point(position):
			if (metro_floodgate_timer > 0.0 or metro_zero_route_timer > 0.0) and METRO_DRAINED_ZONE.has_point(position):
				return 0
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
	player.environment_speed_multiplier = world_rules.water_speed_multiplier(metro_water_state, GameState.has_equipment_trait("reduce_water_penalty"))
	player.environment_water_depth = metro_water_state
	if metro_water_state == 2:
		metro_water_damage_timer += delta
		if metro_water_damage_timer >= 1.2:
			metro_water_damage_timer = 0.0
			player.take_damage(4, player.global_position - Vector2(0, 1))
	else:
		metro_water_damage_timer = 0.0


func _on_player_noise_generated(amount: int) -> void:
	if run_config.world_id != "metro":
		return
	metro_noise += amount


func _metro_intercept_candidates() -> Array[Vector2]:
	var candidates: Array[Vector2] = [Vector2(1376, 608), Vector2(1504, 832)]
	# The active station exit is deliberately absent: interception may pressure a
	# connector, never the sole extraction point.
	if metro_route == "north":
		candidates.append(Vector2(1664, 512))
	elif metro_route == "south":
		candidates.append(Vector2(1472, 992))
	return candidates


func _spawn_signal_anchors() -> void:
	if run_config.world_id != "metro" or not signal_anchors.is_empty():
		return
	var offsets := [Vector2(-120, -72), Vector2(126, 76)]
	for offset in offsets:
		var anchor := SIGNAL_ANCHOR_SCENE.instantiate() as SignalAnchor
		anchor.position = boss.position + offset
		anchor.tree_exiting.connect(_on_signal_anchor_removed.bind(anchor))
		add_child(anchor)
		signal_anchors.append(anchor)
	_show_notification("车长回声已接入 2 个信号锚：破坏它们可提前进入验票弱化阶段。", 5.0)


func _on_signal_anchor_removed(anchor: SignalAnchor) -> void:
	signal_anchors.erase(anchor)
	_show_notification("信号锚已切断：剩余 %d。" % signal_anchors.size(), 2.5)


func _on_equipment_trait_used(trait_id: String) -> void:
	if trait_id != "noise_lure" or run_config.world_id != "metro":
		return
	if whistle_cooldown > 0.0:
		_show_notification("站务员哨冷却中：%d 秒" % ceili(whistle_cooldown), 1.5)
		return
	whistle_cooldown = 12.0
	whistle_uses += 1
	metro_noise += 4
	for enemy in get_tree().get_nodes_in_group("metro_enemies"):
		if enemy is Patient or enemy is Orderly:
			enemy._last_seen_position = player.global_position
			enemy._memory_timer = 9.0
	_show_notification("站务员哨已鸣响：附近威胁正在调查你发声的位置。", 3.0)


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
	pathway_status_label = Label.new()
	pathway_status_label.position = Vector2(365, 168)
	pathway_status_label.size = Vector2(550, 28)
	pathway_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pathway_status_label.add_theme_font_override("font", UI_FONT)
	pathway_status_label.add_theme_font_size_override("font_size", 15)
	pathway_status_label.add_theme_color_override("font_color", Color("d4c079"))
	$Interface.add_child(pathway_status_label)
	pathway_status_icons = HBoxContainer.new()
	pathway_status_icons.name = "PathwayStatusIcons"
	pathway_status_icons.position = Vector2(253, 164)
	pathway_status_icons.add_theme_constant_override("separation", 4)
	$Interface.add_child(pathway_status_icons)
	narrative_portrait = TextureRect.new()
	narrative_portrait.name = "NarrativePortrait"
	narrative_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	narrative_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	narrative_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	narrative_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	narrative_portrait.visible = false
	event_panel.add_child(narrative_portrait)
	milestone_feedback = TextureRect.new()
	milestone_feedback.name = "MilestoneFeedback"
	milestone_feedback.size = Vector2(220, 220)
	milestone_feedback.position = Vector2((get_viewport_rect().size.x - 220.0) * 0.5, 210)
	milestone_feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	milestone_feedback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	milestone_feedback.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	milestone_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	milestone_feedback.z_index = 500
	milestone_feedback.visible = false
	$Interface.add_child(milestone_feedback)
	milestone_caption = Label.new()
	milestone_caption.position = Vector2(-100, 184)
	milestone_caption.size = Vector2(420, 40)
	milestone_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	milestone_caption.add_theme_font_override("font", UI_FONT)
	milestone_caption.add_theme_font_size_override("font_size", 22)
	milestone_caption.add_theme_color_override("font_color", Color("e4eee9"))
	milestone_feedback.add_child(milestone_caption)


func _update_pathway_status() -> void:
	if pathway_status_label == null or player == null or player.pathway_effects == null:
		return
	var parts: Array[String] = []
	for status in player.pathway_effects.statuses():
		parts.append("%s%s" % [str(status.name), " %.1fs" % float(status.remaining) if float(status.remaining) >= 0.0 else ""])
	if whistle_cooldown > 0.0 and GameState.has_equipment_trait("noise_lure"):
		parts.append("站务员哨 %.1fs" % whistle_cooldown)
	pathway_status_label.text = "  ·  ".join(parts)
	pathway_status_label.visible = not parts.is_empty()
	_refresh_status_icons(player.pathway_effects.statuses())


func _refresh_status_icons(statuses: Array[Dictionary]) -> void:
	if pathway_status_icons == null:
		return
	var signature := ",".join(statuses.map(func(status): return str(status.get("id", ""))))
	if signature == _status_icon_signature:
		pathway_status_icons.visible = not statuses.is_empty()
		return
	_status_icon_signature = signature
	for child in pathway_status_icons.get_children():
		child.queue_free()
	var index_by_id := {"guard": 0, "calibration": 1, "anomaly": 2, "freeze": 3, "paralyze": 4, "weakpoint": 5}
	for status in statuses:
		var index := int(index_by_id.get(str(status.get("id", "")), -1))
		if index < 0:
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.texture = _atlas_texture(PROGRESSION_STATUS_ICONS, Rect2(index * 32, 64, 32, 32))
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.tooltip_text = str(status.get("name", "状态"))
		pathway_status_icons.add_child(icon)
	pathway_status_icons.visible = not statuses.is_empty()


func _show_milestone_feedback(index: int, caption: String) -> void:
	if milestone_feedback == null or MILESTONE_FEEDBACK == null or MILESTONE_FEEDBACK.get_size() != Vector2(768, 192):
		return
	milestone_feedback.texture = _atlas_texture(MILESTONE_FEEDBACK, Rect2(clampi(index, 0, 3) * 192, 0, 192, 192))
	milestone_feedback.position = Vector2((get_viewport_rect().size.x - 220.0) * 0.5, 210)
	milestone_feedback.modulate = Color(1, 1, 1, 0)
	milestone_feedback.scale = Vector2(0.75, 0.75)
	milestone_feedback.visible = true
	milestone_caption.text = caption
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(milestone_feedback, "modulate", Color.WHITE, 0.18)
	tween.tween_property(milestone_feedback, "scale", Vector2.ONE, 0.22)
	tween.chain().tween_interval(1.15)
	tween.chain().set_parallel(true)
	tween.tween_property(milestone_feedback, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_property(milestone_feedback, "position:y", 184.0, 0.35)
	tween.chain().tween_callback(func(): milestone_feedback.visible = false)


func _set_narrative_portrait(target: ObjectiveInteractable) -> void:
	if narrative_portrait == null:
		return
	var index := -1
	match target.objective_id:
		"sanatorium_memory":
			index = 2 if target.display_name.contains("周衡") else 1
		"sanatorium_archive":
			index = 2
		"linye_story":
			index = 3
		"xuzhao_memory":
			index = 4
		"ticket_echo_memory":
			index = 5
		"metro_hidden_archive":
			index = 3 if target.display_name.contains("林雾") else -1
	if index < 0 or STORY_NPC_PORTRAITS == null or STORY_NPC_PORTRAITS.get_size() != Vector2(576, 384):
		narrative_portrait.visible = false
		return
	narrative_portrait.texture = _atlas_texture(STORY_NPC_PORTRAITS, Rect2((index % 3) * 192, floori(float(index) / 3.0) * 192, 192, 192))
	narrative_portrait.visible = true


func _atlas_texture(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	return texture


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
		button.position = Vector2(35, 88 + index * 145)
		button.size = Vector2(650, 135)
		button.add_theme_font_override("font", UI_FONT)
		button.add_theme_font_size_override("font_size", 16)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _draw() -> void:
	var metro := run_config != null and run_config.world_id == "metro"
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("10223a") if metro else (Color("15201c") if power_restored else Color("101514")))
	if metro:
		_draw_metro_floor()
	if not metro:
		_draw_sanatorium_passages()
		_draw_grid()
	_draw_zones()
	# Flood layers must be drawn after authored room tiles. The old order painted
	# the rooms over the water, making tide level 2 mechanically active but
	# visually dry.
	if metro and metro_tide_level > 0:
		for zone in METRO_SHALLOW_ZONES:
			var deep := metro_tide_level >= 2 and METRO_DEEP_ZONES.any(func(deep_zone): return deep_zone == zone)
			_draw_metro_water_zone(zone, deep)
		if metro_floodgate_timer > 0.0:
			_draw_metro_room(METRO_DRAINED_ZONE, 5)
			_draw_metro_flood_cell(7, Rect2(METRO_DRAINED_ZONE.get_center() - Vector2(64, 64), Vector2(128, 128)), Color(0.9, 1.0, 1.0, 0.85))
			draw_rect(METRO_DRAINED_ZONE, Color("96e7ef"), false, 4.0)
		elif metro_zero_route_timer > 0.0:
			_draw_metro_room(METRO_DRAINED_ZONE, 6)
			draw_rect(METRO_DRAINED_ZONE, Color("a4f6cf"), false, 4.0)
	if metro:
		if metro_route == "north":
			draw_line(DynamicRunConfig.METRO_NORTH_SWITCH, DynamicRunConfig.METRO_NORTH_EXIT, Color("a4f6cf"), 5.0)
		elif metro_route == "south":
			draw_line(DynamicRunConfig.METRO_SOUTH_SWITCH, DynamicRunConfig.METRO_SOUTH_EXIT, Color("f0b568"), 5.0)
		if run_config.revealed_secret_regions.has("lost_passenger_level"):
			var secret_rect: Rect2 = DynamicRunConfig.METRO_SECRET_REGION.rect
			_draw_metro_maintenance_level(secret_rect)
	for wall in _wall_rectangles():
		if metro:
			_draw_metro_wall(wall)
		else:
			_draw_sanatorium_wall(wall)
	if not metro:
		_draw_sanatorium_props()
		_draw_sanatorium_lights()
	else:
		_draw_metro_props()
	if metro and player and GameState.has_equipment_trait("noise_lure") and whistle_cooldown <= 0.0:
		draw_arc(player.global_position, 280.0, 0.0, TAU, 72, Color(0.91, 0.7, 0.3, 0.22), 2.0)


func _draw_grid() -> void:
	for x in range(0, int(MAP_SIZE.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), Color(0.13, 0.17, 0.16, 0.3), 1.0)
	for y in range(0, int(MAP_SIZE.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), Color(0.13, 0.17, 0.16, 0.3), 1.0)


func _draw_metro_floor() -> void:
	if METRO_TILESET == null or METRO_TILESET.get_size() != Vector2(256, 256):
		return
	var floor_tiles := [0, 16, 17, 32]
	for y in range(0, int(MAP_SIZE.y), 32):
		for x in range(0, int(MAP_SIZE.x), 32):
			var variant: int = floor_tiles[posmod(floori(float(x) / 32.0) + floori(float(y) / 32.0), floor_tiles.size())]
			_draw_metro_tile(Rect2(x, y, 32, 32), variant, Color(0.72, 0.79, 0.83, 0.9))
	# Twin rail beds establish both authored routes even before one route is powered.
	for rail_y in [512, 544, 896, 928]:
		for x in range(32, int(MAP_SIZE.x) - 32, 32):
			_draw_metro_tile(Rect2(x, rail_y, 32, 32), 8 + posmod(floori(float(x) / 32.0), 4), Color(0.82, 0.86, 0.88, 0.96))


func _draw_metro_room(room_rect: Rect2, room_index: int) -> void:
	if METRO_TILESET == null or METRO_TILESET.get_size() != Vector2(256, 256):
		draw_rect(room_rect, Color("142b40"))
		return
	for y in range(int(room_rect.position.y), int(room_rect.end.y), 32):
		for x in range(int(room_rect.position.x), int(room_rect.end.x), 32):
			var edge_row := y >= int(room_rect.end.y) - 32
			var tile_index := 16 + posmod(room_index + floori(float(x) / 32.0), 4) if edge_row else 32 + posmod(room_index + floori(float(x + y) / 32.0), 4)
			_draw_metro_tile(Rect2(x, y, 32, 32), tile_index, Color(0.82, 0.86, 0.88, 0.94))


func _draw_metro_water_zone(zone: Rect2, deep: bool) -> void:
	for y in range(int(zone.position.y), int(zone.end.y), 32):
		for x in range(int(zone.position.x), int(zone.end.x), 32):
			var tile_index := 46 + posmod(floori(float(x + y) / 32.0), 2) if deep else 41 + posmod(floori(float(x + y) / 32.0), 5)
			_draw_metro_tile(
				Rect2(x, y, minf(32.0, zone.end.x - x), minf(32.0, zone.end.y - y)),
				tile_index,
				Color(0.52, 0.78, 0.9, 0.98) if deep else Color(0.62, 0.82, 0.9, 0.92),
			)
	if METRO_FLOOD_LAYERS != null and METRO_FLOOD_LAYERS.get_size() == Vector2(512, 256):
		var surface_index := 1 if deep else 0
		for y in range(int(zone.position.y), int(zone.end.y), 128):
			for x in range(int(zone.position.x), int(zone.end.x), 128):
				_draw_metro_flood_cell(
					surface_index,
					Rect2(x, y, minf(128.0, zone.end.x - x), minf(128.0, zone.end.y - y)),
					Color(0.78, 0.9, 1.0, 0.76 if deep else 0.52),
				)
		# A wall-waterline strip and advancing front make the flooded room read
		# as occupied volume instead of merely a blue floor recolor.
		for x in range(int(zone.position.x), int(zone.end.x), 128):
			_draw_metro_flood_cell(
				3,
				Rect2(x, zone.position.y - 24.0, minf(128.0, zone.end.x - x), 96.0),
				Color(0.8, 0.92, 1.0, 0.82 if deep else 0.48),
			)
	draw_rect(zone, Color("7fd9ed") if deep else Color("52a9c7"), false, 3.0)


func _draw_metro_flood_cell(index: int, destination: Rect2, modulate := Color.WHITE) -> void:
	if METRO_FLOOD_LAYERS == null or METRO_FLOOD_LAYERS.get_size() != Vector2(512, 256):
		return
	draw_texture_rect_region(
		METRO_FLOOD_LAYERS,
		destination,
		Rect2((index % 4) * 128, floori(float(index) / 4.0) * 128, 128, 128),
		modulate,
	)


func _draw_metro_wall(wall_rect: Rect2) -> void:
	if METRO_TILESET == null or METRO_TILESET.get_size() != Vector2(256, 256):
		draw_rect(wall_rect, Color("39423d"))
		draw_rect(wall_rect, Color("59635c"), false, 2.0)
		return
	for y in range(int(wall_rect.position.y), int(wall_rect.end.y), 32):
		for x in range(int(wall_rect.position.x), int(wall_rect.end.x), 32):
			var tile_index := 2 + posmod(floori(float(x + y) / 32.0), 4)
			_draw_metro_tile(Rect2(x, y, 32, 32), tile_index, Color(0.78, 0.8, 0.8, 0.98))
	draw_rect(wall_rect, Color("6f7e83"), false, 2.0)


func _draw_metro_tile(destination: Rect2, tile_index: int, modulate := Color.WHITE) -> void:
	draw_texture_rect_region(
		METRO_TILESET,
		destination,
		Rect2((tile_index % 8) * 32, floori(float(tile_index) / 8.0) * 32, 32, 32),
		modulate,
	)


func _draw_metro_props() -> void:
	var placements := [
		[0, Vector2(224, 280), 112.0], [2, Vector2(672, 330), 112.0],
		[3, Vector2(1120, 350), 112.0], [7, Vector2(1600, 300), 112.0],
		[1, Vector2(760, 760), 104.0], [8, Vector2(1090, 820), 96.0],
		[9, Vector2(1360, 720), 128.0], [7, Vector2(1664, 1100), 112.0],
		[2, Vector2(1920, 1120), 112.0], [1, Vector2(480, 1120), 104.0],
	]
	for placement in placements:
		_draw_metro_prop(int(placement[0]), placement[1], float(placement[2]))


func _draw_metro_maintenance_level(secret_rect: Rect2) -> void:
	draw_rect(secret_rect, Color(0.04, 0.055, 0.075, 0.96), true)
	if METRO_MAINTENANCE_ATLAS != null and METRO_MAINTENANCE_ATLAS.get_size() == Vector2(512, 256):
		for y in range(int(secret_rect.position.y), int(secret_rect.end.y), 128):
			for x in range(int(secret_rect.position.x), int(secret_rect.end.x), 128):
				draw_texture_rect_region(
					METRO_MAINTENANCE_ATLAS,
					Rect2(x, y, 128, 128).intersection(secret_rect),
					Rect2(0, 0, 128, 128),
					Color(0.7, 0.76, 0.82, 0.9),
				)
		var props := [
			[2, secret_rect.position + Vector2(76, 76)],
			[3, secret_rect.position + Vector2(secret_rect.size.x - 88, 82)],
			[4, secret_rect.position + Vector2(96, secret_rect.size.y - 90)],
			[7, secret_rect.position + Vector2(secret_rect.size.x - 110, secret_rect.size.y - 88)],
		]
		for spec in props:
			var index := int(spec[0])
			var center: Vector2 = spec[1]
			draw_texture_rect_region(
				METRO_MAINTENANCE_ATLAS,
				Rect2(center - Vector2(58, 58), Vector2(116, 116)),
				Rect2((index % 4) * 128, floori(float(index) / 4.0) * 128, 128, 128),
			)
	draw_rect(secret_rect, Color("8d68b3"), false, 3.0)
	draw_string(UI_FONT, secret_rect.position + Vector2(24, 38), "失踪乘客维护层 // 名单与排水记录", HORIZONTAL_ALIGNMENT_LEFT, secret_rect.size.x - 48, 18, Color("d9b8ef"))


func _draw_metro_prop(index: int, center: Vector2, draw_size: float) -> void:
	if METRO_PROPS == null or METRO_PROPS.get_size() != Vector2(512, 384):
		draw_rect(Rect2(center - Vector2.ONE * 24.0, Vector2.ONE * 48.0), Color("33434a"))
		return
	draw_texture_rect_region(
		METRO_PROPS,
		Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size),
		Rect2((index % 4) * 128, floori(float(index) / 4.0) * 128, 128, 128),
	)


func _draw_sanatorium_passages() -> void:
	if SANATORIUM_TILESET == null or SANATORIUM_TILESET.get_size() != Vector2(256, 256):
		return
	for y in range(0, int(MAP_SIZE.y), 32):
		for x in range(0, int(MAP_SIZE.x), 32):
			var variant := posmod(floori(float(x) / 32.0) + floori(float(y) / 32.0), 3)
			draw_texture_rect_region(
				SANATORIUM_TILESET,
				Rect2(x, y, minf(32.0, MAP_SIZE.x - x), minf(32.0, MAP_SIZE.y - y)),
				Rect2(variant * 32, 0, 32, 32),
				Color(0.48, 0.52, 0.48, 0.58),
			)


func _draw_zones() -> void:
	var metro := run_config != null and run_config.world_id == "metro"
	if metro:
		var metro_index := 0
		for region in run_config.map_regions():
			var room_rect: Rect2 = region.rect
			_draw_metro_room(room_rect, metro_index)
			draw_rect(room_rect, Color("527f91"), false, 2.0)
			draw_string(UI_FONT, room_rect.position + Vector2(24, 42), str(region.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("86b9ce"))
			metro_index += 1
		return
	var room_index := 0
	for room in SanatoriumLayout.rooms():
		_draw_sanatorium_room(room.rect, room_index)
		draw_rect(room.rect, Color("27332f"), false, 2.0)
		draw_string(UI_FONT, room.rect.position + Vector2(24, 42), run_config.room_role(room_index), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("617269"))
		room_index += 1


func _draw_sanatorium_room(room_rect: Rect2, room_index: int) -> void:
	draw_rect(room_rect, Color("171b19"))
	if SANATORIUM_TILESET == null or SANATORIUM_TILESET.get_size() != Vector2(256, 256):
		return
	var source_index := room_index % 4
	for y in range(int(room_rect.position.y), int(room_rect.end.y), 32):
		for x in range(int(room_rect.position.x), int(room_rect.end.x), 32):
			var variant := (source_index + floori(float(x + y) / 32.0)) % 4
			draw_texture_rect_region(
				SANATORIUM_TILESET,
				Rect2(x, y, minf(32.0, room_rect.end.x - x), minf(32.0, room_rect.end.y - y)),
				Rect2(variant * 32, 0, 32, 32),
				Color(0.74, 0.77, 0.71, 0.82)
			)


func _draw_sanatorium_wall(wall_rect: Rect2) -> void:
	draw_rect(wall_rect, Color("303734"))
	if SANATORIUM_TILESET == null or SANATORIUM_TILESET.get_size() != Vector2(256, 256):
		draw_rect(wall_rect, Color("59635c"), false, 2.0)
		return
	for y in range(int(wall_rect.position.y), int(wall_rect.end.y), 32):
		for x in range(int(wall_rect.position.x), int(wall_rect.end.x), 32):
			draw_texture_rect_region(
				SANATORIUM_TILESET,
				Rect2(x, y, minf(32.0, wall_rect.end.x - x), minf(32.0, wall_rect.end.y - y)),
				Rect2(2 * 32, 1 * 32, 32, 32),
				Color(0.78, 0.8, 0.75, 0.94)
			)
	draw_rect(wall_rect, Color("6b766e"), false, 2.0)


func _draw_sanatorium_props() -> void:
	var placements := [
		[0, Vector2(176, 210), 104.0], [0, Vector2(336, 210), 104.0],
		[4, Vector2(576, 206), 112.0], [2, Vector2(768, 220), 96.0],
		[6, Vector2(1152, 400), 120.0], [3, Vector2(1304, 408), 96.0],
		[5, Vector2(1568, 1096), 112.0], [7, Vector2(1792, 1190), 96.0],
		[8, Vector2(1680, 302), 104.0], [9, Vector2(2050, 302), 96.0],
		[10, Vector2(1110, 800), 112.0], [11, Vector2(318, 1192), 112.0],
	]
	for placement in placements:
		_draw_sanatorium_prop(int(placement[0]), placement[1], float(placement[2]))


func _draw_sanatorium_lights() -> void:
	if SANATORIUM_OBJECTIVE_LIGHTING == null or SANATORIUM_OBJECTIVE_LIGHTING.get_size() != Vector2(512, 256):
		return
	var placements := [
		Vector2(520, 520), Vector2(920, 520), Vector2(1310, 520),
		Vector2(1560, 720), Vector2(1900, 720), Vector2(1110, 960),
		Vector2(660, 1120), Vector2(1650, 1180),
	]
	for center in placements:
		draw_texture_rect_region(
			SANATORIUM_OBJECTIVE_LIGHTING,
			Rect2(center - Vector2(96, 40), Vector2(192, 80)),
			Rect2(128, 128, 128, 128),
			Color(0.72, 0.78, 0.68, 0.46),
		)


func _draw_sanatorium_prop(index: int, center: Vector2, draw_size: float) -> void:
	if SANATORIUM_PROPS == null or SANATORIUM_PROPS.get_size() != Vector2(512, 384):
		draw_rect(Rect2(center - Vector2.ONE * 24.0, Vector2.ONE * 48.0), Color("39433f"))
		return
	var column := index % 4
	var row := floori(float(index) / 4.0)
	draw_texture_rect_region(
		SANATORIUM_PROPS,
		Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size),
		Rect2(column * 128, row * 128, 128, 128)
	)


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
