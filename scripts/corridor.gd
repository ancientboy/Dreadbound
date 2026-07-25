extends Control

const UPGRADE_INFO := {
	"vitality": ["耐受训练", "生命上限 +10"],
	"mobility": ["神经校准", "移动速度 +8"],
	"weapons": ["武器适配", "近战 +4 / 手枪 +3"],
	"recovery": ["应急处理", "绷带恢复 +7"],
}
const PATH_BUTTONS := {
	"steadfast_guard": "SteadfastGuard", "steadfast_mender": "SteadfastMender",
	"armorer_calibration": "ArmorerCalibration", "armorer_mobility": "ArmorerMobility",
	"resonant_sense": "ResonantSense", "resonant_bargain": "ResonantBargain",
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
var walker_position := Vector2(350, 438)
var walker_velocity := Vector2.ZERO
var walker_facing := Vector2.RIGHT
var walk_phase := 0.0
var _move_touch := -1
var _touch_origin := Vector2.ZERO
var _touch_direction := Vector2.ZERO
const WALK_SPEED := 330.0
const TERMINAL_POSITION := Vector2(640, 285)
const CURATOR_POSITION := Vector2(640, 416)
const GATE_POSITION := Vector2(1045, 372)
const INTERACTION_RANGE := 118.0


func _ready() -> void:
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
	$HubActions/Deploy.pressed.connect(_deploy)
	$HubActions/OpenTerminal.pressed.connect(_open_terminal)
	$Margin/Layout/Actions/CloseTerminal.pressed.connect(_close_terminal)
	$Margin/Layout/Actions/Reset.pressed.connect(_reset_progress)
	$Margin/Layout/Actions/Warehouse.pressed.connect(_open_warehouse)
	world_button.pressed.connect(_toggle_world)
	_create_warehouse_panel()
	_refresh()
	if not GameState.corridor_intro_seen:
		GameState.corridor_intro_seen = true
		GameState.save_progress()
		feedback.text = "终末回廊已解锁：在此查看属性、强化身体、选择整备并再次投送。"
	HubHint.text = "移动靠近司仪、整备终端或投送门；按 E / 点击操作。"
	$HubActions.visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if $Margin.visible or warehouse_panel.visible:
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
	$HubActions.visible = not target.is_empty() and target.id != "curator"
	if target.is_empty():
		HubHint.text = "探索终末回廊  ·  WASD / 方向键移动  ·  靠近设施后交互"
	else:
		HubHint.text = "[E] %s" % target.prompt
	if Input.is_action_just_pressed("interact") and not target.is_empty():
		_activate_target(target.id)


func _input(event: InputEvent) -> void:
	if $Margin.visible or (warehouse_panel and warehouse_panel.visible):
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < size.x * 0.55:
			_move_touch = event.index
			_touch_origin = event.position
			_touch_direction = Vector2.ZERO
		elif not event.pressed and event.index == _move_touch:
			_move_touch = -1
			_touch_direction = Vector2.ZERO
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
		{"id": "gate", "position": GATE_POSITION, "prompt": "进入%s" % _world_name()},
	]
	for target in targets:
		if walker_position.distance_to(target.position) <= INTERACTION_RANGE:
			return target
	return {}


func _activate_target(id: String) -> void:
	match id:
		"curator":
			feedback.text = "阈值司仪：%s\n建议：%s" % [str(GameState.player_profile.get("last_observation", "尚无足够行动数据。")), "完成一次低噪声撤离试炼。" if int(GameState.player_profile.get("noise_actions", 0)) >= 4 else "继续选择可解释的风险，而非盲目深入。"]
			_open_terminal()
		"terminal": _open_terminal()
		"gate": _deploy()


func _refresh() -> void:
	currency.text = "回响碎片  %d    ·    因果残片  %d" % [GameState.echo_shards, GameState.causality_fragments]
	var values := GameState.get_player_stats()
	stats.text = "生命上限       %d\n移动速度       %d\n近战伤害       %d\n手枪伤害       %d\n绷带恢复       %d" % [values.max_health, int(values.movement_speed), values.melee_damage, values.ranged_damage, values.bandage_heal]
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		var level := int(GameState.upgrades[upgrade_id])
		var cost := GameState.get_upgrade_cost(upgrade_id)
		button.text = "%s  Lv.%d/%d\n%s%s" % [UPGRADE_INFO[upgrade_id][0], level, GameProgress.UPGRADE_MAX_LEVEL, UPGRADE_INFO[upgrade_id][1], "  ·  %d 碎片" % cost if cost > 0 else "  ·  已满级"]
		button.disabled = cost == 0 or GameState.echo_shards < cost
	for loadout_id in GameProgress.LOADOUTS:
		var loadout: Dictionary = GameProgress.LOADOUTS[loadout_id]
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.text = "%s%s\n%s" % ["▶ " if GameState.selected_loadout == loadout_id else "", loadout.name, loadout.description]
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		var path_name := {"steadfast": "坚守者", "armorer": "武装师", "resonant": "共鸣者"}.get(str(node.path), "未知途径")
		var button := get_node("Margin/Layout/Columns/Paths/%s" % PATH_BUTTONS[node_id]) as Button
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "%s · " % path_name, str(node.name), "已锚定" if unlocked else "%s · %d 碎片" % [str(node.description), int(node.cost)]]
		button.disabled = unlocked or GameState.echo_shards < int(node.cost)
	world_button.text = "切换至%s" % ("废弃疗养院" if GameState.selected_world == "metro" else "潮没末班线")
	deploy_button.text = "投送：%s" % _world_name()
	$HubActions/Deploy.text = "进入%s" % _world_name()
	if GameState.last_run.is_empty():
		report.text = "尚无行动记录。\n疗养院连接等待校准。"
	else:
		var run: Dictionary = GameState.last_run
		var gear_count: int = run.get("equipment_rewards", []).size()
		var dynamic: Dictionary = run.get("dynamic_run", {})
		report.text = "%s\n行动代码  %s\n任务契约  %s\n目标完成  %d\n风险事件  %d/2\n现场碎片  %d\n装备回收  %d\n清除威胁  %d\n\n司仪观察：%s" % ["撤离成功" if run.success else "行动失败", dynamic.get("action_code", "旧版行动"), dynamic.get("mission", "档案回收"), run.records, run.get("events_resolved", 0), run.carried_shards, gear_count, run.enemies_defeated, str(GameState.player_profile.get("last_observation", "尚无足够行动数据。"))]
	queue_redraw()


func _purchase(upgrade_id: String) -> void:
	feedback.text = "%s已完成，下一次投送生效。" % UPGRADE_INFO[upgrade_id][0] if GameState.purchase_upgrade(upgrade_id) else "资源不足或该强化已达到上限。"


func _select_loadout(loadout_id: String) -> void:
	if GameState.select_loadout(loadout_id):
		feedback.text = "已选择%s，下一次投送携带该配置。" % GameProgress.LOADOUTS[loadout_id].name


func _unlock_path_node(node_id: String) -> void:
	var node: Dictionary = GameProgress.PATH_NODES[node_id]
	feedback.text = "%s已锚定：%s" % [str(node.name), str(node.description)] if GameState.unlock_path_node(node_id) else "无法锚定该节点：需要更多回响碎片，或它已生效。"


func _deploy() -> void:
	deploy_button.disabled = true
	feedback.text = "正在建立%s连接……" % _world_name()
	GameState.begin_run()
	get_tree().change_scene_to_file("res://scenes/metro.tscn" if GameState.selected_world == "metro" else "res://scenes/main.tscn")


func _toggle_world() -> void:
	GameState.selected_world = "metro" if GameState.selected_world == "sanatorium" else "sanatorium"
	GameState.save_progress()
	feedback.text = "投送目标已切换：%s" % _world_name()
	_refresh()


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
	# Gate changes hue slightly for the flooded world.
	var gate_color := Color("6098f5") if GameState.selected_world == "metro" else Color("5ce8cf")
	draw_circle(GATE_POSITION, 102, Color(gate_color, 0.1))
	draw_arc(GATE_POSITION, 98, -2.05, 2.05, 48, gate_color, 12.0)
	draw_arc(GATE_POSITION, 68, -2.05, 2.05, 48, Color(gate_color, 0.48), 2.0)
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
	if $Margin.visible:
		draw_rect(Rect2(30, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(378, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(726, 112, size.x - 756, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))


func _open_terminal() -> void:
	$Margin.visible = true
	$HubTitle.visible = false
	$HubHint.visible = false
	$HubActions.visible = false
	queue_redraw()


func _close_terminal() -> void:
	$Margin.visible = false
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
	warehouse_panel.z_index = 100
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
	if GameState.disassemble_item(selected_equipment_id):
		feedback.text = "装备已拆解为回响碎片。"
		selected_equipment_id = ""
		_refresh_warehouse()
		_refresh()
