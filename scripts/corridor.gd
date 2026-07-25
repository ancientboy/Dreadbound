extends Control

const UPGRADE_INFO := {
	"vitality": ["耐受训练", "生命上限 +10"],
	"mobility": ["神经校准", "移动速度 +8"],
	"weapons": ["武器适配", "近战 +4 / 手枪 +3"],
	"recovery": ["应急处理", "绷带恢复 +7"],
}

@onready var currency: Label = $Margin/Layout/Header/Currency
@onready var report: Label = $Margin/Layout/Columns/Archive/Report
@onready var stats: Label = $Margin/Layout/Columns/Profile/Stats
@onready var feedback: Label = $Margin/Layout/Feedback
@onready var deploy_button: Button = $Margin/Layout/Actions/Deploy
var warehouse_panel: ColorRect
var warehouse_list: VBoxContainer
var warehouse_detail: Label
var equip_button: Button
var salvage_button: Button
var selected_equipment_id := ""


func _ready() -> void:
	GameState.progress_changed.connect(_refresh)
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		button.pressed.connect(_purchase.bind(upgrade_id))
	for loadout_id in GameProgress.LOADOUTS:
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.pressed.connect(_select_loadout.bind(loadout_id))
	deploy_button.pressed.connect(_deploy)
	$Margin/Layout/Actions/Reset.pressed.connect(_reset_progress)
	$Margin/Layout/Actions/Warehouse.pressed.connect(_open_warehouse)
	_create_warehouse_panel()
	_refresh()
	if not GameState.corridor_intro_seen:
		GameState.corridor_intro_seen = true
		GameState.save_progress()
		feedback.text = "终末回廊已解锁：在此查看属性、强化身体、选择整备并再次投送。"


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
	if GameState.last_run.is_empty():
		report.text = "尚无行动记录。\n疗养院连接等待校准。"
	else:
		var run: Dictionary = GameState.last_run
		var gear_count: int = run.get("equipment_rewards", []).size()
		report.text = "%s\n实验记录  %d/3\n风险事件  %d/2\n现场碎片  %d\n任务奖励  %d\n装备回收  %d\n清除威胁  %d" % ["撤离成功" if run.success else "行动失败", run.records, run.get("events_resolved", 0), run.carried_shards, run.mission_reward, gear_count, run.enemies_defeated]
	queue_redraw()


func _purchase(upgrade_id: String) -> void:
	feedback.text = "%s已完成，下一次投送生效。" % UPGRADE_INFO[upgrade_id][0] if GameState.purchase_upgrade(upgrade_id) else "资源不足或该强化已达到上限。"


func _select_loadout(loadout_id: String) -> void:
	if GameState.select_loadout(loadout_id):
		feedback.text = "已选择%s，下一次投送携带该配置。" % GameProgress.LOADOUTS[loadout_id].name


func _deploy() -> void:
	deploy_button.disabled = true
	feedback.text = "正在建立疗养院连接……"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _reset_progress() -> void:
	GameState.reset_progress()
	feedback.text = "局外进度已清除。"


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07110f"))
	# Monumental corridor silhouette, cyan anomaly core and terminal scan lines.
	for index in range(7):
		var inset := 36.0 + index * 54.0
		var alpha := 0.18 - index * 0.018
		draw_line(Vector2(inset, 0), Vector2(360 + index * 35, size.y), Color(0.13, 0.34, 0.29, alpha), 3.0)
		draw_line(Vector2(size.x - inset, 0), Vector2(size.x - 360 - index * 35, size.y), Color(0.13, 0.34, 0.29, alpha), 3.0)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.44), 170.0, Color(0.08, 0.5, 0.42, 0.055))
	draw_circle(Vector2(size.x * 0.5, size.y * 0.44), 82.0, Color(0.19, 0.9, 0.74, 0.05))
	draw_arc(Vector2(size.x * 0.5, size.y * 0.44), 118.0, 0.0, TAU, 72, Color(0.22, 0.79, 0.66, 0.16), 2.0)
	for y in range(10, int(size.y), 8):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.4, 0.8, 0.7, 0.012), 1.0)
	draw_rect(Rect2(30, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.76))
	draw_rect(Rect2(378, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.76))
	draw_rect(Rect2(726, 112, size.x - 756, size.y - 220), Color(0.015, 0.055, 0.049, 0.76))


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
