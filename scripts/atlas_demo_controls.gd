extends VBoxContainer

@onready var _skill_demo := get_node("../../../../SkillRangeDemo") as SkillRangeDemo
@onready var _mode_label := $ModeLabel as Label
@onready var _skill_label := $SkillLabel as Label
@onready var _player := get_node("../../../../Player") as Player
@onready var _humanoid_actions := (
	get_node("../../../../Player/UniversalHumanoidActionCharacter")
	as UniversalHumanoidActionCharacter
)


func _ready() -> void:
	$SkillButtons/Close.pressed.connect(
		_select_skill.bind(SkillRangeDemo.SkillMode.CLOSE_BURST),
	)
	$SkillButtons/Mid.pressed.connect(
		_select_skill.bind(SkillRangeDemo.SkillMode.MID_BOLT),
	)
	$SkillButtons/Long.pressed.connect(
		_select_skill.bind(SkillRangeDemo.SkillMode.LONG_RIFT),
	)
	$SkillButtons/Release.pressed.connect(_release_skill)
	$EquipmentButtons/Crowbar.pressed.connect(_select_weapon.bind(0))
	$EquipmentButtons/Bow.pressed.connect(_select_weapon.bind(1))
	$EquipmentButtons/Staff.pressed.connect(_select_weapon.bind(2))
	$OffhandButtons/Shield.pressed.connect(_select_offhand.bind("riot_shield"))
	$OffhandButtons/Codex.pressed.connect(_select_offhand.bind("field_codex"))
	$ActionPreviewButtons/Fists.pressed.connect(_select_action_preview.bind("unarmed"))
	$ActionPreviewButtons/Sword.pressed.connect(_select_action_preview.bind("sword"))
	$ActionPreviewButtons/Pistol.pressed.connect(_select_action_preview.bind("pistol"))
	$ActionPreviewButtons/Bow.pressed.connect(_select_action_preview.bind("bow"))
	$ActionPreviewButtons/Staff.pressed.connect(_select_action_preview.bind("spell"))
	$ActionPreviewButtons/Shield.pressed.connect(_select_action_preview.bind("shield"))
	$ActionPreviewButtons/Play.pressed.connect(_play_preview_action)
	_update_mode_label()
	_update_skill_label()
	_update_equipment_buttons()
	_update_action_preview()


func _process(_delta: float) -> void:
	_update_skill_label()
	_update_action_preview()


func _select_skill(mode: SkillRangeDemo.SkillMode) -> void:
	_skill_demo.set_skill_mode(mode)
	_update_skill_label()


func _release_skill() -> void:
	_skill_demo.trigger_skill()
	_update_skill_label()


func _select_weapon(slot_index: int) -> void:
	_player.select_demo_weapon_slot(slot_index)
	_update_mode_label()
	_update_equipment_buttons()


func _select_offhand(item_id: String) -> void:
	_player.select_demo_offhand(item_id)
	_update_mode_label()
	_update_equipment_buttons()


func _select_action_preview(family: String) -> void:
	_humanoid_actions.set_preview_weapon_family(family)
	_update_action_preview()


func _play_preview_action() -> void:
	_humanoid_actions.trigger_preview_attack()
	_update_action_preview()


func _update_action_preview() -> void:
	var family := _humanoid_actions.current_preview_weapon_family()
	var labels := {
		"unarmed": "双拳",
		"sword": "标准单手剑",
		"pistol": "标准手枪",
		"bow": "标准弓",
		"spell": "标准法杖",
		"shield": "标准盾牌",
	}
	$ActionPreviewLabel.text = "动作验收：%s　当前动作：%s" % [
		labels.get(family, "未选择"),
		_humanoid_actions.current_action_name(),
	]
	for entry in [
		["Fists", "unarmed", "双拳"],
		["Sword", "sword", "单手剑"],
		["Pistol", "pistol", "手枪"],
		["Bow", "bow", "弓"],
		["Staff", "spell", "法杖"],
		["Shield", "shield", "盾牌"],
	]:
		var button := $ActionPreviewButtons.get_node(entry[0]) as Button
		button.text = "%s%s" % ["● " if family == entry[1] else "", entry[2]]


func _update_mode_label() -> void:
	var profile := _player._weapon_attack_profile()
	_mode_label.text = "主手：%s　副手：%s\n普通攻击：%s　射程：%d　空格键/红色按钮攻击" % [
		_player.get_weapon_name(),
		EquipmentDatabase.get_item(_player.demo_offhand_item).get("name", "无"),
		_cast_label(str(profile.get("cast", ""))),
		int(_player._active_attack_range()),
	]


func _update_skill_label() -> void:
	if not is_instance_valid(_skill_demo):
		return
	var state := _skill_demo.current_phase().to_upper()
	if _skill_demo.cooldown_left() > 0.0 and state == "IDLE":
		state = "冷却 %.1f 秒" % _skill_demo.cooldown_left()
	elif state == "IDLE":
		state = "待命"
	elif state == "WINDUP":
		state = "蓄力"
	elif state == "ACTIVE":
		state = "释放"
	_skill_label.text = (
		"主动技能测试：%s　射程：%d　状态：%s"
		% [_skill_demo.selected_skill_name(), int(_skill_demo.skill_range()), state]
	)


func _update_equipment_buttons() -> void:
	var active_slot := int(_player.current_weapon)
	$EquipmentButtons/Crowbar.text = "%s主手 1：制式撬棍" % ("● " if active_slot == 0 else "")
	$EquipmentButtons/Bow.text = "%s主手 2：哀鸣骨弓" % ("● " if active_slot == 1 else "")
	$EquipmentButtons/Staff.text = "%s主手 3：裂隙法杖" % ("● " if active_slot == 2 else "")
	$OffhandButtons/Shield.text = "%s副手：折叠防暴盾" % (
		"● " if _player.demo_offhand_item == "riot_shield" else ""
	)
	$OffhandButtons/Codex.text = "%s副手：野战法典" % (
		"● " if _player.demo_offhand_item == "field_codex" else ""
	)


func _cast_label(cast_id: String) -> String:
	match cast_id:
		"sweep":
			return "近距离横扫"
		"draw_release":
			return "拉弓直线箭矢"
		"rift_channel":
			return "法杖异常连锁束"
		"hitscan", "marking_hitscan":
			return "单点射击"
		"cone", "heavy_cone":
			return "扇形喷射"
		"heavy_sweep":
			return "近距离重扫"
		"anomaly_sweep":
			return "异常武器横扫"
		"reaping_arc":
			return "镰刃重劈"
		"piercing_beam":
			return "贯穿光束"
	return "武器普通攻击"
