extends Control

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")

const UPGRADE_INFO := {
	"vitality": ["耐受训练", "生命上限 +10"],
	"mobility": ["神经校准", "移动速度 +8"],
	"weapons": ["武器适配", "近战 +4 / 手枪 +3"],
	"recovery": ["应急处理", "绷带恢复 +7"],
}
const PATH_BUTTONS := {
	"steadfast_guard": "SteadfastGuard", "steadfast_mender": "SteadfastMender",
	"steadfast_barrier": "SteadfastBarrier",
	"armorer_calibration": "ArmorerCalibration", "armorer_mobility": "ArmorerMobility",
	"armorer_alternation": "ArmorerAlternation",
	"resonant_sense": "ResonantSense", "resonant_bargain": "ResonantBargain",
	"resonant_ingestion": "ResonantIngestion",
}

@onready var currency: Label = $Margin/Layout/Header/Currency
@onready var report: Label = $Margin/Layout/Columns/Archive/Report
@onready var stats: Label = $Margin/Layout/Columns/Profile/Stats
@onready var feedback: Label = $Margin/Layout/Feedback
@onready var deploy_button: Button = $Margin/Layout/Actions/Deploy
@onready var world_button: Button = $Margin/Layout/Actions/SelectMetro
var warehouse_panel: ColorRect
var warehouse_list: VBoxContainer
var warehouse_detail: Label
var equip_button: Button
var salvage_button: Button
var selected_equipment_id := ""
var salvage_reward_panel: ColorRect
var salvage_reward_detail: Label
var walker_position := Vector2(640, 585)
var walker_velocity := Vector2.ZERO
var walker_facing := Vector2.RIGHT
var walk_phase := 0.0
var _move_touch := -1
var _touch_origin := Vector2.ZERO
var _touch_direction := Vector2.ZERO
var _hub_action_touch := -1
var mobile_terminal_panel: ColorRect
const WALK_SPEED := 330.0
const TERMINAL_POSITION := Vector2(640, 285)
const CURATOR_POSITION := Vector2(640, 416)
const SANATORIUM_GATE_POSITION := Vector2(250, 372)
const METRO_GATE_POSITION := Vector2(1030, 372)
const INTERACTION_RANGE := 118.0
var active_gate_world := "sanatorium"


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_responsive_ui)
	GameState.progress_changed.connect(_refresh)
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		button.pressed.connect(_purchase.bind(upgrade_id))
	for loadout_id in GameProgress.LOADOUTS:
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.pressed.connect(_select_loadout.bind(loadout_id))
	for node_id in GameProgress.PATH_NODES:
		var button := get_node("Margin/Layout/Columns/Paths/%s" % PATH_BUTTONS[node_id]) as Button
		button.pressed.connect(_unlock_path_node.bind(node_id))
	deploy_button.pressed.connect(_deploy)
	$HubActions/Deploy.pressed.connect(_deploy_selected_gate)
	$HubActions/OpenTerminal.pressed.connect(_open_terminal)
	$Margin/Layout/Actions/CloseTerminal.pressed.connect(_close_terminal)
	$Margin/Layout/Actions/Reset.pressed.connect(_reset_progress)
	$Margin/Layout/Actions/Warehouse.pressed.connect(_open_warehouse)
	# World selection lives at the physical legendary gates, never inside the terminal.
	world_button.visible = false
	deploy_button.visible = false
	_create_warehouse_panel()
	_create_salvage_reward_panel()
	_create_mobile_terminal_panel()
	_create_curator_controls()
	_create_respec_control()
	_refresh()
	if GameState.pathway_migration_refund > 0:
		feedback.text = "已修复旧档中的跨职业节点，并全额返还 %d 回响碎片。当前仅保留%s路线。" % [GameState.pathway_migration_refund, GameState.get_pathway_name()]
	if not GameState.corridor_intro_seen:
		GameState.corridor_intro_seen = true
		GameState.save_progress()
		feedback.text = "终末回廊已解锁：在此查看属性、强化身体、选择整备并再次投送。"
	$HubHint.text = "两扇传说门已开启：左侧疗养院，右侧潮没末班线。靠近后按 E / 点击进入。"
	$HubActions.visible = false
	_apply_responsive_ui()
	queue_redraw()


func _apply_responsive_ui(override_size := Vector2.ZERO) -> void:
	var viewport_size: Vector2 = override_size if override_size != Vector2.ZERO else get_viewport_rect().size
	var margin := $Margin as MarginContainer
	var inset := clampf(viewport_size.x * 0.025, 20.0, 42.0)
	margin.offset_left = inset
	margin.offset_right = -inset
	margin.offset_top = 20.0
	margin.offset_bottom = -20.0
	# The terminal must never become wider than its canvas.  The previous action
	# row alone requested 1232 px and caused every column to be centred offscreen.
	var compact := viewport_size.x < 1180.0
	$Margin/Layout.add_theme_constant_override("separation", 10 if compact else 18)
	$Margin/Layout/Columns.add_theme_constant_override("separation", 10 if compact else 18)
	$Margin/Layout/Actions.add_theme_constant_override("separation", 6 if compact else 18)
	var compact_column_widths := [180.0, 180.0, 210.0, 210.0]
	var columns := $Margin/Layout/Columns
	for index in range(columns.get_child_count()):
		var column := columns.get_child(index) as Control
		if column:
			var column_width: float = compact_column_widths[index] if compact else [220.0, 220.0, 280.0, 260.0][index]
			column.custom_minimum_size = Vector2(column_width, column.custom_minimum_size.y)
	for child in $Margin/Layout/Columns/Paths.get_children():
		if child is Button:
			child.custom_minimum_size.y = 40.0 if compact else 44.0
			child.add_theme_font_size_override("font_size", 12 if compact else 13)
	var compact_action_widths := [110.0, 150.0, 160.0, 190.0, 110.0]
	var normal_action_widths := [140.0, 180.0, 190.0, 260.0, 140.0]
	var actions := $Margin/Layout/Actions
	for index in range(actions.get_child_count()):
		var action := actions.get_child(index) as Button
		var action_width: float = compact_action_widths[index] if compact else normal_action_widths[index]
		action.custom_minimum_size = Vector2(action_width, action.custom_minimum_size.y)
		action.add_theme_font_size_override("font_size", 14 if compact else (20 if action.name == "Deploy" else 16))
	$Margin/Layout/Header/Title.add_theme_font_size_override("font_size", 24 if compact else 30)
	$Margin/Layout/Header/Currency.add_theme_font_size_override("font_size", 15 if compact else 18)
	$HubTitle.position = Vector2(inset, 24)
	$HubTitle.size = Vector2(viewport_size.x - inset * 2.0, 48)
	_layout_warehouse(viewport_size)
	_layout_salvage_reward(viewport_size)
	queue_redraw()


func _layout_warehouse(viewport_size: Vector2) -> void:
	if warehouse_panel == null:
		return
	var panel_width := minf(1050.0, viewport_size.x - 48.0)
	warehouse_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, 48)
	warehouse_panel.size = Vector2(panel_width, minf(590.0, viewport_size.y - 82.0))
	var title := warehouse_panel.get_child(0) as Label
	title.position = Vector2(24, 18)
	title.size = Vector2(panel_width - 48, 48)
	var list_width := (panel_width - 92.0) * 0.5
	var scroll := warehouse_panel.get_child(1) as ScrollContainer
	scroll.position = Vector2(28, 82)
	scroll.size = Vector2(list_width, warehouse_panel.size.y - 160)
	warehouse_list.custom_minimum_size = Vector2(list_width - 20, 0)
	warehouse_detail.position = Vector2(52 + list_width, 92)
	warehouse_detail.size = Vector2(list_width - 24, warehouse_panel.size.y - 260)
	equip_button.position = Vector2(52 + list_width, warehouse_panel.size.y - 154)
	equip_button.size = Vector2((list_width - 36) * 0.5, 58)
	salvage_button.position = Vector2(70 + list_width + equip_button.size.x, warehouse_panel.size.y - 154)
	salvage_button.size = equip_button.size
	var close := warehouse_panel.get_child(warehouse_panel.get_child_count() - 1) as Button
	close.position = Vector2((panel_width - 250) * 0.5, warehouse_panel.size.y - 72)
	close.size = Vector2(250, 52)


func _layout_salvage_reward(viewport_size: Vector2) -> void:
	if salvage_reward_panel == null:
		return
	var panel_width := minf(560.0, viewport_size.x - 48.0)
	var panel_height := minf(370.0, viewport_size.y - 72.0)
	salvage_reward_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	salvage_reward_panel.size = Vector2(panel_width, panel_height)
	var title := salvage_reward_panel.get_child(0) as Label
	title.position = Vector2(28, 26)
	title.size = Vector2(panel_width - 56, 42)
	salvage_reward_detail.position = Vector2(42, 98)
	salvage_reward_detail.size = Vector2(panel_width - 84, panel_height - 190)
	var close := salvage_reward_panel.get_child(salvage_reward_panel.get_child_count() - 1) as Button
	close.position = Vector2((panel_width - 230) * 0.5, panel_height - 76)
	close.size = Vector2(230, 48)


func _process(delta: float) -> void:
	if _terminal_is_open() or warehouse_panel.visible:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _move_touch != -1:
		direction = _touch_direction
	walker_velocity = direction * WALK_SPEED
	if direction.length() > 0.08:
		walker_position += walker_velocity * delta
		walker_position.x = clampf(walker_position.x, 115.0, size.x - 115.0)
		walker_position.y = clampf(walker_position.y, 165.0, size.y - 95.0)
		walker_facing = direction.normalized()
		walk_phase += delta * 13.0
		queue_redraw()
	var target := _nearby_target()
	_update_hub_actions(target)
	if target.is_empty():
		$HubHint.text = "探索终末回廊  ·  WASD / 方向键移动  ·  靠近设施后交互"
	else:
		$HubHint.text = "[E] %s" % target.prompt
	if Input.is_action_just_pressed("interact") and not target.is_empty():
		_activate_target(target.id)


func _input(event: InputEvent) -> void:
	if _terminal_is_open() or (warehouse_panel and warehouse_panel.visible):
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(_hub_action_center()) <= 76.0:
			_hub_action_touch = event.index
			var target := _nearby_target()
			if not target.is_empty():
				_activate_target(target.id)
			queue_redraw()
		elif event.pressed and event.position.x < size.x * 0.55:
			_move_touch = event.index
			_touch_origin = event.position
			_touch_direction = Vector2.ZERO
		elif not event.pressed and event.index == _move_touch:
			_move_touch = -1
			_touch_direction = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _hub_action_touch:
			_hub_action_touch = -1
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _move_touch:
		_touch_direction = (event.position - _touch_origin).limit_length(92.0) / 92.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := _nearby_target()
		if not target.is_empty() and event.position.distance_to(walker_position) < 170.0:
			_activate_target(target.id)


func _nearby_target() -> Dictionary:
	var targets := [
		{"id": "curator", "position": CURATOR_POSITION, "prompt": "与阈值司仪同步行动档案"},
		{"id": "terminal", "position": TERMINAL_POSITION, "prompt": "接入行者整备终端"},
		{"id": "sanatorium_gate", "position": SANATORIUM_GATE_POSITION, "prompt": "进入废弃疗养院", "world": "sanatorium"},
		{"id": "metro_gate", "position": METRO_GATE_POSITION, "prompt": "进入潮没末班线", "world": "metro"},
	]
	for target in targets:
		if walker_position.distance_to(target.position) <= INTERACTION_RANGE:
			return target
	return {}


func _activate_target(id: String) -> void:
	match id:
		"curator":
			var trial := GameState.get_curator_trial()
			feedback.text = "%s\n%s" % [str(GameState.player_profile.get("last_observation", "尚无足够行动数据。")), "当前试炼：%s · %s" % [trial.title, trial.description] if not trial.is_empty() else "尚未采纳试炼；可在终端档案区选择。"]
			_open_terminal()
		"terminal": _open_terminal()
		"sanatorium_gate": _deploy_world("sanatorium")
		"metro_gate": _deploy_world("metro")


func _update_hub_actions(target: Dictionary) -> void:
	var has_target: bool = not target.is_empty() and target.id != "curator"
	$HubActions.visible = has_target
	if not has_target:
		return
	var is_gate := str(target.id).ends_with("_gate")
	$HubActions/OpenTerminal.visible = not is_gate
	$HubActions/Deploy.visible = is_gate
	if is_gate:
		active_gate_world = str(target.world)
		$HubActions/Deploy.text = str(target.prompt)


func _refresh() -> void:
	currency.text = "回响碎片  %d    ·    因果残片  %d" % [GameState.echo_shards, GameState.causality_fragments]
	var values := GameState.get_player_stats()
	stats.text = "生命上限       %d\n移动速度       %d\n近战伤害       %d\n手枪伤害       %d\n绷带恢复       %d" % [values.max_health, int(values.movement_speed), values.melee_damage, values.ranged_damage, values.bandage_heal]
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		var level := int(GameState.upgrades[upgrade_id])
		var cost := GameState.get_upgrade_cost(upgrade_id)
		var maximum := GameState.get_upgrade_max_level(upgrade_id)
		button.text = "%s  Lv.%d/%d\n%s%s" % [UPGRADE_INFO[upgrade_id][0], level, maximum, UPGRADE_INFO[upgrade_id][1], "  ·  %d 碎片" % cost if cost > 0 else "  ·  已满级"]
		button.disabled = cost == 0 or GameState.echo_shards < cost
	for loadout_id in GameProgress.LOADOUTS:
		var loadout: Dictionary = GameProgress.LOADOUTS[loadout_id]
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.text = "%s%s\n%s" % ["▶ " if GameState.selected_loadout == loadout_id else "", loadout.name, loadout.description]
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		var path_name: String = GameProgress.PATHWAY_NAMES.get(str(node.path), "未知途径")
		var button := get_node("Margin/Layout/Columns/Paths/%s" % PATH_BUTTONS[node_id]) as Button
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		var anchor_needed := GameState.selected_pathway.is_empty()
		var locked_path := not GameState.selected_pathway.is_empty() and GameState.selected_pathway != str(node.path)
		var missing_requirement := not str(node.get("requires", "")).is_empty() and not GameState.unlocked_path_nodes.has(str(node.requires))
		button.visible = (str(node.get("requires", "")).is_empty() if GameState.selected_pathway.is_empty() else str(node.path) == GameState.selected_pathway)
		var anchor_text := "锚定 %s：%d 碎片 + %d 因果残片\n" % [path_name, int(GameProgress.PATHWAY_ANCHOR_COST.echo_shards), int(GameProgress.PATHWAY_ANCHOR_COST.causality_fragments)] if anchor_needed else ""
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "%s · " % path_name, str(node.name), "已锚定" if unlocked else anchor_text + ("前置节点未锚定" if missing_requirement else ("已选择%s" % GameState.get_pathway_name() if locked_path else "%s · %d 碎片" % [str(node.description), int(node.cost)]))]
		button.disabled = unlocked or locked_path or missing_requirement or GameState.echo_shards < int(node.cost) + (int(GameProgress.PATHWAY_ANCHOR_COST.echo_shards) if anchor_needed else 0) or GameState.causality_fragments < int(node.get("fragment_cost", 0)) + (int(GameProgress.PATHWAY_ANCHOR_COST.causality_fragments) if anchor_needed else 0)
	var respec := get_node_or_null("Margin/Layout/Columns/Paths/RespecPathway") as Button
	if respec:
		respec.disabled = GameState.pathway_respec_used or GameState.selected_pathway.is_empty()
	world_button.text = "传说门选择副本"
	deploy_button.text = "请在回廊进入传说门"
	$HubActions/Deploy.text = "进入%s" % _world_name()
	if GameState.last_run.is_empty():
		report.text = "尚无行动记录。\n疗养院连接等待校准。"
	else:
		var run: Dictionary = GameState.last_run
		var gear_count: int = run.get("equipment_rewards", []).size()
		var dynamic: Dictionary = run.get("dynamic_run", {})
		var milestones: Array = run.get("milestone_rewards", [])
		var milestone_text := ""
		for reward in milestones:
			milestone_text += "\n因果里程碑  +%d %s" % [int(reward.get("causality_fragments", 0)), str(reward.get("title", ""))]
		for reward in run.get("trial_rewards", []):
			milestone_text += "\n司仪试炼  +%d 因果残片 · %s" % [int(reward.get("causality_fragments", 0)), str(reward.get("title", ""))]
		report.text = "%s\n行动代码  %s\n任务契约  %s\n目标完成  %d\n风险事件  %d/2\n现场碎片  %d\n装备回收  %d\n清除威胁  %d%s\n\n司仪观察：%s" % ["撤离成功" if run.success else "行动失败", dynamic.get("action_code", "旧版行动"), dynamic.get("mission", "档案回收"), run.records, run.get("events_resolved", 0), run.carried_shards, gear_count, run.enemies_defeated, milestone_text, str(GameState.player_profile.get("last_observation", "尚无足够行动数据。"))]
	queue_redraw()
	if mobile_terminal_panel and mobile_terminal_panel.visible:
		_refresh_mobile_terminal()


func _purchase(upgrade_id: String) -> void:
	feedback.text = "%s已完成，下一次投送生效。" % UPGRADE_INFO[upgrade_id][0] if GameState.purchase_upgrade(upgrade_id) else "资源不足或该强化已达到上限。"


func _select_loadout(loadout_id: String) -> void:
	if GameState.select_loadout(loadout_id):
		feedback.text = "已选择%s，下一次投送携带该配置。" % GameProgress.LOADOUTS[loadout_id].name


func _unlock_path_node(node_id: String) -> void:
	var node: Dictionary = GameProgress.PATH_NODES[node_id]
	feedback.text = "%s已锚定：%s" % [str(node.name), str(node.description)] if GameState.unlock_path_node(node_id) else "无法锚定：需先选择该职业、满足前置节点，并支付回响碎片与首次锚定的因果残片。"


func _deploy() -> void:
	_deploy_world(GameState.selected_world)


func _deploy_selected_gate() -> void:
	_deploy_world(active_gate_world)


func _deploy_world(world: String) -> void:
	GameState.selected_world = world
	GameState.save_progress()
	deploy_button.disabled = true
	feedback.text = "正在建立%s连接……" % _world_name()
	GameState.begin_run()
	get_tree().change_scene_to_file("res://scenes/metro.tscn" if GameState.selected_world == "metro" else "res://scenes/main.tscn")


func _toggle_world() -> void:
	# Kept as a safe no-op for old saves. Legendary gates own world selection now.
	feedback.text = "请返回回廊，靠近对应传说门进入副本。"


func _world_name() -> String:
	return "潮没末班线" if GameState.selected_world == "metro" else "废弃疗养院"


func _reset_progress() -> void:
	GameState.reset_progress()
	feedback.text = "局外进度已清除。"


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("071311"))
	# A layered, walkable chamber: floor lanes, pillars, the Curator's dais and a live gate.
	for y in range(140, int(size.y), 58):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.1, 0.27, 0.23, 0.27), 1.0)
	for x in range(80, int(size.x), 132):
		draw_line(Vector2(x, 112), Vector2(x, size.y), Color(0.08, 0.22, 0.19, 0.24), 1.0)
	var floor := PackedVector2Array([Vector2(86, size.y), Vector2(size.x - 86, size.y), Vector2(size.x - 202, 184), Vector2(202, 184)])
	draw_colored_polygon(floor, Color("102a25"))
	draw_polyline(floor + PackedVector2Array([floor[0]]), Color("3a8070"), 3.0)
	for pillar_x in [185.0, size.x - 185.0]:
		draw_rect(Rect2(pillar_x - 24, 146, 48, size.y - 205), Color("0b211d"))
		draw_line(Vector2(pillar_x - 24, 146), Vector2(pillar_x - 24, size.y - 58), Color("29594e"), 3.0)
	# Archive terminal and Curator dais.
	draw_circle(TERMINAL_POSITION, 88, Color(0.08, 0.34, 0.29, 0.2))
	draw_rect(Rect2(TERMINAL_POSITION - Vector2(58, 84), Vector2(116, 168)), Color("09231f"))
	draw_rect(Rect2(TERMINAL_POSITION - Vector2(58, 84), Vector2(116, 168)), Color("4bd3b8"), false, 3.0)
	draw_line(TERMINAL_POSITION + Vector2(-38, -25), TERMINAL_POSITION + Vector2(38, -25), Color("77f2d8"), 3.0)
	draw_circle(CURATOR_POSITION, 56, Color(0.23, 0.77, 0.67, 0.14))
	draw_arc(CURATOR_POSITION, 56, 0, TAU, 48, Color("5de0c5"), 2.0)
	draw_circle(CURATOR_POSITION + Vector2(0, -14), 13, Color("b3dbd0"))
	draw_colored_polygon(PackedVector2Array([CURATOR_POSITION + Vector2(-22, 28), CURATOR_POSITION + Vector2(22, 28), CURATOR_POSITION + Vector2(14, -4), CURATOR_POSITION + Vector2(-14, -4)]), Color("355f57"))
	# Each unlocked disaster world has a permanent, visible legendary gate.
	_draw_legend_gate(SANATORIUM_GATE_POSITION, Color("5ce8cf"), "废弃疗养院", "医疗异化 · 供电撤离")
	_draw_legend_gate(METRO_GATE_POSITION, Color("6098f5"), "潮没末班线", "涨潮迷失 · 末班撤离")
	# Animated Drifter. The gait reacts to actual movement instead of a static icon.
	var bob := sin(walk_phase) * 3.0 if walker_velocity.length() > 2.0 else sin(Time.get_ticks_msec() * 0.002) * 1.2
	draw_circle(walker_position + Vector2(0, -25 + bob), 13, Color("c3d9d1"))
	draw_colored_polygon(PackedVector2Array([walker_position + Vector2(-18, -10 + bob), walker_position + Vector2(18, -10 + bob), walker_position + Vector2(23, 26), walker_position + Vector2(-23, 26)]), Color("62847b"))
	var stride := sin(walk_phase) * 9.0 if walker_velocity.length() > 2.0 else 0.0
	draw_line(walker_position + Vector2(-8, 22), walker_position + Vector2(-12 + stride, 40), Color("2e4a43"), 7.0)
	draw_line(walker_position + Vector2(8, 22), walker_position + Vector2(12 - stride, 40), Color("2e4a43"), 7.0)
	draw_circle(walker_position + walker_facing * 23 + Vector2(0, bob), 4, Color("72f1d7"))
	for y in range(10, int(size.y), 8):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.4, 0.8, 0.7, 0.012), 1.0)
	if _terminal_is_open():
		draw_rect(Rect2(30, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(378, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(726, 112, size.x - 756, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
	else:
		_draw_mobile_hub_controls()


func _draw_legend_gate(position: Vector2, color: Color, title: String, subtitle: String) -> void:
	var is_near := walker_position.distance_to(position) <= INTERACTION_RANGE
	draw_circle(position, 116, Color(color, 0.17 if is_near else 0.09))
	draw_arc(position, 100, -2.12, 2.12, 48, color, 14.0 if is_near else 10.0)
	draw_arc(position, 70, -2.12, 2.12, 48, Color(color, 0.55), 2.0)
	draw_line(position + Vector2(-83, 92), position + Vector2(83, 92), Color(color, 0.62), 2.0)
	draw_string(UI_FONT, position + Vector2(-112, 138), title, HORIZONTAL_ALIGNMENT_CENTER, 224, 24, Color("d6f6ed"))
	draw_string(UI_FONT, position + Vector2(-130, 166), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 260, 15, Color(color, 0.88))


func _open_terminal() -> void:
	$Background.color = Color(0.004, 0.024, 0.021, 0.985)
	$Margin.visible = not _is_portrait()
	if _is_portrait():
		_refresh_mobile_terminal()
		mobile_terminal_panel.visible = true
	$HubTitle.visible = false
	$HubHint.visible = false
	$HubActions.visible = false
	queue_redraw()


func _close_terminal() -> void:
	$Margin.visible = false
	$Background.color = Color(0.015, 0.032, 0.031, 0)
	if mobile_terminal_panel:
		mobile_terminal_panel.visible = false
	$HubTitle.visible = true
	$HubHint.visible = true
	$HubActions.visible = false
	queue_redraw()


func _create_warehouse_panel() -> void:
	warehouse_panel = ColorRect.new()
	warehouse_panel.position = Vector2(115, 65)
	warehouse_panel.size = Vector2(1050, 590)
	warehouse_panel.color = Color(0.008, 0.035, 0.032, 0.985)
	warehouse_panel.visible = false
	# The warehouse is opened from inside the terminal.  It must sit above both
	# terminal variants (desktop Margin and the mobile terminal at z=140),
	# otherwise its controls are visible but unreachable on phone canvases.
	warehouse_panel.z_index = 200
	add_child(warehouse_panel)
	var title := Label.new()
	title.position = Vector2(30, 22)
	title.size = Vector2(990, 48)
	title.text = "异常装备回收仓库 // EQUIPMENT ARCHIVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("62dec6"))
	warehouse_panel.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(35, 88)
	scroll.size = Vector2(480, 410)
	warehouse_panel.add_child(scroll)
	warehouse_list = VBoxContainer.new()
	warehouse_list.custom_minimum_size = Vector2(455, 0)
	warehouse_list.add_theme_constant_override("separation", 7)
	scroll.add_child(warehouse_list)
	warehouse_detail = Label.new()
	warehouse_detail.position = Vector2(550, 105)
	warehouse_detail.size = Vector2(455, 265)
	warehouse_detail.text = "选择一件装备查看评级与属性。"
	warehouse_detail.add_theme_font_size_override("font_size", 19)
	warehouse_detail.add_theme_color_override("font_color", Color("a7bbb4"))
	warehouse_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse_panel.add_child(warehouse_detail)
	equip_button = Button.new()
	equip_button.position = Vector2(550, 390)
	equip_button.size = Vector2(215, 62)
	equip_button.text = "装备"
	equip_button.pressed.connect(_equip_selected)
	warehouse_panel.add_child(equip_button)
	salvage_button = Button.new()
	salvage_button.position = Vector2(790, 390)
	salvage_button.size = Vector2(215, 62)
	salvage_button.text = "拆解"
	salvage_button.pressed.connect(_salvage_selected)
	warehouse_panel.add_child(salvage_button)
	var close := Button.new()
	close.position = Vector2(390, 515)
	close.size = Vector2(270, 55)
	close.text = "返回整备终端"
	close.pressed.connect(func(): warehouse_panel.visible = false)
	warehouse_panel.add_child(close)


func _create_salvage_reward_panel() -> void:
	salvage_reward_panel = ColorRect.new()
	salvage_reward_panel.name = "SalvageReward"
	salvage_reward_panel.color = Color(0.008, 0.04, 0.035, 0.995)
	salvage_reward_panel.visible = false
	# This is the final feedback surface: it must sit above the warehouse and
	# the terminal on both desktop and mobile, so a successful dismantle is never
	# mistaken for a silent loss of equipment.
	salvage_reward_panel.z_index = 260
	add_child(salvage_reward_panel)
	var title := Label.new()
	title.text = "回收结算完成"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("79ead2"))
	salvage_reward_panel.add_child(title)
	salvage_reward_detail = Label.new()
	salvage_reward_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	salvage_reward_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	salvage_reward_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	salvage_reward_detail.add_theme_font_size_override("font_size", 20)
	salvage_reward_detail.add_theme_color_override("font_color", Color("d5f4ea"))
	salvage_reward_panel.add_child(salvage_reward_detail)
	var close := Button.new()
	close.text = "确认收取"
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func(): salvage_reward_panel.visible = false)
	salvage_reward_panel.add_child(close)


func _is_portrait() -> bool:
	# Mobile browser chrome often leaves a nearly-square game canvas even while
	# the physical device is landscape. Use the scrollable terminal there too.
	return size.y > size.x * 0.72 or size.x < 1180.0


func _terminal_is_open() -> bool:
	return $Margin.visible or (mobile_terminal_panel and mobile_terminal_panel.visible)


func _mobile_panel_width() -> float:
	return minf(size.x - 28.0, 760.0)


func _create_mobile_terminal_panel() -> void:
	mobile_terminal_panel = ColorRect.new()
	mobile_terminal_panel.name = "MobileTerminal"
	mobile_terminal_panel.color = Color(0.006, 0.028, 0.025, 0.995)
	mobile_terminal_panel.visible = false
	mobile_terminal_panel.z_index = 140
	add_child(mobile_terminal_panel)


func _create_curator_controls() -> void:
	var archive := $Margin/Layout/Columns/Archive as VBoxContainer
	var view := Button.new()
	view.name = "CuratorTrial"
	view.custom_minimum_size = Vector2(0, 46)
	view.text = "采纳 / 暂缓司仪试炼"
	view.pressed.connect(_toggle_curator_trial)
	archive.add_child(view)
	var reset := Button.new()
	reset.name = "ResetCurator"
	reset.custom_minimum_size = Vector2(0, 42)
	reset.text = "重置司仪观察"
	reset.pressed.connect(_reset_curator_profile)
	archive.add_child(reset)


func _create_respec_control() -> void:
	var button := Button.new()
	button.name = "RespecPathway"
	button.custom_minimum_size = Vector2(0, 44)
	button.text = "有限重构职业 · 1 因果残片（仅一次）"
	button.disabled = GameState.pathway_respec_used or GameState.selected_pathway.is_empty()
	button.pressed.connect(_respec_pathway)
	$Margin/Layout/Columns/Paths.add_child(button)


func _toggle_curator_trial() -> void:
	if GameState.get_curator_trial().is_empty():
		_accept_trial()
	else:
		_dismiss_trial()


func _refresh_mobile_terminal() -> void:
	if mobile_terminal_panel == null:
		return
	for child in mobile_terminal_panel.get_children():
		child.queue_free()
	var panel_width := _mobile_panel_width()
	mobile_terminal_panel.position = Vector2((size.x - panel_width) * 0.5, 12.0)
	mobile_terminal_panel.size = Vector2(panel_width, size.y - 24.0)
	var header := Label.new()
	header.position = Vector2(18, 16)
	header.size = Vector2(panel_width - 36, 34)
	header.text = "行者整备终端"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color("62dec6"))
	mobile_terminal_panel.add_child(header)
	var currency_label := Label.new()
	currency_label.position = Vector2(18, 52)
	currency_label.size = Vector2(panel_width - 36, 27)
	currency_label.text = "回响碎片 %d  ·  因果残片 %d" % [GameState.echo_shards, GameState.causality_fragments]
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.add_theme_font_size_override("font_size", 16)
	mobile_terminal_panel.add_child(currency_label)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 88)
	scroll.size = Vector2(panel_width - 28, mobile_terminal_panel.size.y - 164)
	mobile_terminal_panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(panel_width - 50, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_mobile_terminal_section(content, "漂泊者档案", stats.text)
	_mobile_terminal_section(content, "上次行动", report.text)
	_mobile_terminal_section(content, "阈值司仪 · 行动档案", _curator_profile_text())
	var trial := GameState.get_curator_trial()
	var trial_action := Button.new()
	trial_action.custom_minimum_size = Vector2(0, 54)
	trial_action.text = "暂缓当前试炼" if not trial.is_empty() else "采纳一项可选试炼"
	trial_action.pressed.connect(_dismiss_trial if not trial.is_empty() else _accept_trial)
	content.add_child(trial_action)
	var reset_profile := Button.new()
	reset_profile.custom_minimum_size = Vector2(0, 48)
	reset_profile.text = "重置司仪观察（不影响装备与成长）"
	reset_profile.pressed.connect(_reset_curator_profile)
	content.add_child(reset_profile)
	_mobile_terminal_section(content, "出发整备", "在这里调整配置；副本入口请返回回廊使用对应传说门。")
	for loadout_id in GameProgress.LOADOUTS:
		var loadout: Dictionary = GameProgress.LOADOUTS[loadout_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.text = "%s%s\n%s" % ["▶ " if GameState.selected_loadout == loadout_id else "", loadout.name, loadout.description]
		button.pressed.connect(_select_loadout.bind(loadout_id))
		content.add_child(button)
	_mobile_terminal_section(content, "永久强化", "选择强化，下一次投送生效。")
	for upgrade_id in UPGRADE_INFO:
		var level := int(GameState.upgrades[upgrade_id])
		var cost := GameState.get_upgrade_cost(upgrade_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.text = "%s  Lv.%d/%d\n%s" % [UPGRADE_INFO[upgrade_id][0], level, GameState.get_upgrade_max_level(upgrade_id), "%s · %d 碎片" % [UPGRADE_INFO[upgrade_id][1], cost] if cost > 0 else "已满级"]
		button.disabled = cost == 0 or GameState.echo_shards < cost
		button.pressed.connect(_purchase.bind(upgrade_id))
		content.add_child(button)
	_mobile_terminal_section(content, "阈值途径 · 职业成长", "首次锚定消耗 8 回响碎片 + 1 因果残片，并选定一条职业路线；该职业会开放两项基础强化的 Lv.4–6。因果残片可通过分解回响/异常装备获得。")
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		if (GameState.selected_pathway.is_empty() and not str(node.get("requires", "")).is_empty()) or (not GameState.selected_pathway.is_empty() and str(node.path) != GameState.selected_pathway):
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		var anchor_needed := GameState.selected_pathway.is_empty()
		var locked_path := not GameState.selected_pathway.is_empty() and GameState.selected_pathway != str(node.path)
		var missing_requirement := not str(node.get("requires", "")).is_empty() and not GameState.unlocked_path_nodes.has(str(node.requires))
		var cost_text := "%s · %d 碎片" % [str(node.description), int(node.cost)]
		if int(node.get("fragment_cost", 0)) > 0:
			cost_text += " + %d 因果残片" % int(node.fragment_cost)
		if anchor_needed:
			cost_text = "锚定%s：8 碎片 + 1 因果残片\n%s" % [GameProgress.PATHWAY_NAMES[str(node.path)], cost_text]
		elif locked_path:
			cost_text = "已选择%s职业" % GameState.get_pathway_name()
		elif missing_requirement:
			cost_text = "需先锚定前置节点"
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "", str(node.name), "已锚定" if unlocked else cost_text]
		button.disabled = unlocked or locked_path or missing_requirement or GameState.echo_shards < int(node.cost) + (8 if anchor_needed else 0) or GameState.causality_fragments < int(node.get("fragment_cost", 0)) + (1 if anchor_needed else 0)
		button.pressed.connect(_unlock_path_node.bind(node_id))
		content.add_child(button)
	var respec := Button.new()
	respec.custom_minimum_size = Vector2(0, 52)
	respec.text = "有限重构职业 · 1 因果残片（仅一次）"
	respec.disabled = GameState.pathway_respec_used or GameState.selected_pathway.is_empty()
	respec.pressed.connect(_respec_pathway)
	content.add_child(respec)
	var actions := HBoxContainer.new()
	actions.position = Vector2(14, mobile_terminal_panel.size.y - 66)
	actions.size = Vector2(panel_width - 28, 52)
	actions.add_theme_constant_override("separation", 10)
	mobile_terminal_panel.add_child(actions)
	var warehouse := Button.new()
	warehouse.text = "装备仓库"
	warehouse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warehouse.pressed.connect(_open_warehouse)
	actions.add_child(warehouse)
	var close := Button.new()
	close.text = "返回回廊"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(_close_terminal)
	actions.add_child(close)


func _mobile_terminal_section(parent: VBoxContainer, title: String, body: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("6cd7c0"))
	parent.add_child(heading)
	var text := Label.new()
	text.text = body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 15)
	text.add_theme_color_override("font_color", Color("a7bbb4"))
	parent.add_child(text)


func _curator_profile_text() -> String:
	var profile: Dictionary = GameState.player_profile
	var trial := GameState.get_curator_trial()
	var lines := [str(profile.get("last_observation", "尚无足够行动数据。")), "行动 %d · 成功 %d · 静默撤离 %d · 风险选择 %d · 清除威胁 %d" % [int(profile.get("runs", 0)), int(profile.get("successful_runs", 0)), int(profile.get("quiet_successes", 0)), int(profile.get("events_taken", 0)), int(profile.get("threats_cleared", 0))]]
	lines.append("依据：%s" % "；".join(GameState.curator_evidence()))
	if not trial.is_empty():
		lines.append("试炼：%s // %s // 奖励 %s" % [trial.title, trial.description, trial.reward_text])
	var recent: Array = profile.get("recent_runs", [])
	for run in recent:
		lines.append("%s · %s · 噪音%d · 事件%d" % ["地铁" if str(run.get("world", "")) == "metro" else "疗养院", "撤离" if bool(run.get("success", false)) else "失联", int(run.get("noise", 0)), int(run.get("events", 0))])
	return "\n".join(lines)


func _accept_trial() -> void:
	feedback.text = "阈值司仪：试炼已采纳；依据、条件与奖励均已写入档案。" if GameState.accept_curator_trial() else "阈值司仪：当前世界可用试炼均已完成或暂缓。"
	_refresh()


func _dismiss_trial() -> void:
	feedback.text = "阈值司仪：已暂缓该方向，不会重复强制提示。" if GameState.dismiss_curator_trial() else "当前没有可暂缓的试炼。"
	_refresh()


func _reset_curator_profile() -> void:
	GameState.reset_curator_profile()
	feedback.text = "阈值司仪观察已重置；装备、货币与职业成长未改变。"
	_refresh()


func _respec_pathway() -> void:
	feedback.text = "职业锚点已重构；已返还全部职业投入（锚定、节点碎片与节点残片），并扣除 1 因果残片重构费。" if GameState.respec_pathway() else "无法重构：每个存档仅限一次，并需要 1 因果残片。"
	_refresh()


func _hub_stick_center() -> Vector2:
	return Vector2(106.0, size.y - 108.0)


func _hub_action_center() -> Vector2:
	return Vector2(size.x - 104.0, size.y - 106.0)


func _draw_mobile_hub_controls() -> void:
	var stick := _hub_stick_center()
	var action := _hub_action_center()
	var knob := stick + _touch_direction * 58.0
	draw_circle(stick, 72.0, Color(0.025, 0.12, 0.1, 0.8))
	draw_arc(stick, 72.0, 0.0, TAU, 48, Color("478f80"), 3.0)
	draw_circle(knob, 28.0, Color("5acdb5"))
	draw_circle(action, 58.0, Color(0.035, 0.16, 0.14, 0.92))
	draw_arc(action, 58.0, 0.0, TAU, 48, Color("69e4cd"), 4.0)
	if _hub_action_touch != -1:
		draw_circle(action, 48.0, Color(0.35, 0.92, 0.8, 0.28))
	draw_string(UI_FONT, action + Vector2(-12, 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("8bf1db"))
	draw_string(UI_FONT, stick + Vector2(-27, 104), "移动", HORIZONTAL_ALIGNMENT_CENTER, 54, 14, Color("8db8ad"))
	draw_string(UI_FONT, action + Vector2(-27, 84), "交互", HORIZONTAL_ALIGNMENT_CENTER, 54, 14, Color("8db8ad"))


func _open_warehouse() -> void:
	selected_equipment_id = ""
	_refresh_warehouse()
	warehouse_panel.visible = true


func _refresh_warehouse() -> void:
	for child in warehouse_list.get_children():
		child.queue_free()
	var counts := {}
	for item_id in GameState.equipment_inventory:
		counts[item_id] = int(counts.get(item_id, 0)) + 1
	for item_id in counts:
		var item := EquipmentDatabase.get_item(item_id)
		var button := Button.new()
		var equipped_mark := "◆ " if GameState.equipped.values().has(item_id) else ""
		button.text = "%s[%s] %s  ×%d  ·  评级 %d" % [equipped_mark, item.quality, item.name, counts[item_id], item.rating]
		button.custom_minimum_size = Vector2(450, 54)
		button.pressed.connect(_select_equipment.bind(item_id))
		warehouse_list.add_child(button)
	equip_button.disabled = true
	salvage_button.disabled = true
	warehouse_detail.text = "仓库容量 %d/%d\n\n选择一件装备查看评级与属性。" % [GameState.equipment_inventory.size(), GameProgress.MAX_EQUIPMENT]


func _select_equipment(item_id: String) -> void:
	selected_equipment_id = item_id
	var item := EquipmentDatabase.get_item(item_id)
	var equipped_mark := "\n\n当前已装备" if GameState.equipped.get(item.slot, "") == item_id else ""
	warehouse_detail.text = "%s // %s\n评级 %d\n槽位：%s\n\n%s%s" % [item.quality, item.name, item.rating, "武器" if item.slot == "weapon" else "护符", item.description, equipped_mark]
	equip_button.disabled = false
	salvage_button.disabled = GameState.equipped.values().has(item_id) and GameState.equipment_inventory.count(item_id) <= 1


func _equip_selected() -> void:
	if GameState.equip_item(selected_equipment_id):
		feedback.text = "装备已同步，下一次投送生效。"
		_refresh_warehouse()
		_refresh()


func _salvage_selected() -> void:
	var item := EquipmentDatabase.get_item(selected_equipment_id)
	var rewards := GameState.get_disassembly_rewards(item)
	if GameState.disassemble_item(selected_equipment_id):
		var fragment_text := "\n因果残片  +%d" % int(rewards.causality_fragments) if int(rewards.causality_fragments) > 0 else ""
		feedback.text = "已拆解 %s：+%d 回响碎片%s" % [str(item.name), int(rewards.echo_shards), " · +%d 因果残片" % int(rewards.causality_fragments) if int(rewards.causality_fragments) > 0 else ""]
		salvage_reward_detail.text = "已分解\n%s · %s\n\n获得\n回响碎片  +%d%s" % [str(item.quality), str(item.name), int(rewards.echo_shards), fragment_text]
		_layout_salvage_reward(get_viewport_rect().size)
		salvage_reward_panel.visible = true
		selected_equipment_id = ""
		_refresh_warehouse()
		_refresh()
