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
		report.text = "%s\n实验记录  %d/3\n风险事件  %d/2\n现场碎片  %d\n任务奖励  %d\n带回总计  %d\n清除威胁  %d" % ["撤离成功" if run.success else "行动失败", run.records, run.get("events_resolved", 0), run.carried_shards, run.mission_reward, run.banked_shards, run.enemies_defeated]


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
