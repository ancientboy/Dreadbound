extends VBoxContainer

const ACTION_LABELS := {
	&"idle": "空手待机",
	&"attack_melee": "标准剑攻击（透明武器层）",
	&"one_hand_melee_idle": "标准剑待机（透明武器层）",
	&"pistol_idle": "手枪待机",
	&"pistol_aim_down": "手枪向下瞄准",
	&"pistol_aim": "手枪平瞄",
	&"pistol_aim_up": "手枪向上瞄准",
	&"pistol_shoot": "手枪射击",
	&"pistol_reload": "手枪换弹",
	&"spell_enter": "进入法杖施法",
	&"spell_idle": "法杖待机",
	&"spell_shoot": "法杖施法",
	&"spell_exit": "退出法杖施法",
	&"bow_idle": "持弓待机",
	&"bow_draw": "搭箭拉弓",
	&"bow_aim": "持续瞄准",
	&"bow_release": "放箭收势",
	&"shield_raise": "举盾",
	&"shield_block": "持续格挡",
	&"shield_hit": "格挡受击",
	&"shield_bash": "盾击",
}

const MELEE_EQUIPMENT := [
	{"family": &"crowbar", "label": "制式撬棍"},
	{"family": &"echo_edge", "label": "回响切割器"},
	{"family": &"insulated_crowbar", "label": "绝缘撬棍"},
	{"family": &"volatile_edge", "label": "失控回响刃"},
	{"family": &"director_reaper", "label": "主任的缝合镰 · 基础（0–2）"},
	{"family": &"director_reaper_awakened", "label": "主任的缝合镰 · 觉醒（3–4）"},
	{"family": &"director_reaper_final", "label": "主任的缝合镰 · 完全体（5）"},
]

const FIREARM_EQUIPMENT := [
	{"family": &"pistol", "label": "标准手枪 · 动作参考"},
	{"family": &"balanced_pistol", "label": "平衡手枪"},
	{"family": &"breach_shotgun", "label": "破门霰弹枪"},
	{"family": &"nullpoint_sidearm", "label": "零点标记枪"},
	{"family": &"siege_core", "label": "围城火力核心"},
	{"family": &"conductor_railgun", "label": "末班导轨枪 · 基础（0–2）"},
	{"family": &"conductor_railgun_awakened", "label": "末班导轨枪 · 觉醒（3–4）"},
	{"family": &"conductor_railgun_final", "label": "末班导轨枪 · 完全体（5）"},
]

@onready var _character := get_node(
	"../../../../Player/RenderedAtlasCharacter",
) as RenderedAtlasCharacter
@onready var _mode_label := $ModeLabel as Label
@onready var _melee_selector := $MeleeEquipment as OptionButton
@onready var _firearm_selector := $FirearmEquipment as OptionButton
@onready var _demo_attack_button := $"../../../DemoAttackButton" as Button


func _ready() -> void:
	for equipment in MELEE_EQUIPMENT:
		_melee_selector.add_item(str(equipment.label))
	_melee_selector.item_selected.connect(_select_melee_equipment)
	for equipment in FIREARM_EQUIPMENT:
		_firearm_selector.add_item(str(equipment.label))
	_firearm_selector.item_selected.connect(_select_firearm_equipment)
	_connect_action($SwordButtons/Idle, &"one_hand_melee_idle")
	_connect_action($SwordButtons/Attack, &"attack_melee")
	$SwordButtons/CrowbarIdle.pressed.connect(
		_play_selected_melee_action.bind(&"one_hand_melee_idle"),
	)
	$SwordButtons/CrowbarAttack.pressed.connect(
		_play_selected_melee_action.bind(&"attack_melee"),
	)
	$PistolButtons/Idle.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_idle"),
	)
	$PistolButtons/AimDown.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_aim_down"),
	)
	$PistolButtons/Aim.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_aim"),
	)
	$PistolButtons/AimUp.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_aim_up"),
	)
	$PistolButtons/Shoot.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_shoot"),
	)
	$PistolButtons/Reload.pressed.connect(
		_play_selected_firearm_action.bind(&"pistol_reload"),
	)
	_connect_action($StaffButtons/Enter, &"spell_enter")
	_connect_action($StaffButtons/Idle, &"spell_idle")
	_connect_action($StaffButtons/Shoot, &"spell_shoot")
	_connect_action($StaffButtons/Exit, &"spell_exit")
	_connect_action($BowButtons/Idle, &"bow_idle")
	_connect_action($BowButtons/Draw, &"bow_draw")
	_connect_action($BowButtons/Aim, &"bow_aim")
	_connect_action($BowButtons/Release, &"bow_release")
	_connect_action($ShieldButtons/Raise, &"shield_raise")
	_connect_action($ShieldButtons/Block, &"shield_block")
	_connect_action($ShieldButtons/Hit, &"shield_hit")
	_connect_action($ShieldButtons/Bash, &"shield_bash")
	$BaselineButtons/Unarmed.pressed.connect(_select_unarmed)
	$BaselineButtons/Hit.pressed.connect(_trigger_hit)
	$BaselineButtons/Death.pressed.connect(_trigger_death)
	$BaselineButtons/Reset.pressed.connect(_reset_demo)
	_demo_attack_button.pressed.connect(_trigger_demo_attack)
	_show_action(&"idle")


func _connect_action(button: Button, action_name: StringName) -> void:
	button.pressed.connect(_play_action.bind(action_name))


func _play_action(action_name: StringName) -> void:
	if is_instance_valid(_character) and _character.play_preview_action(action_name):
		_show_action(action_name)


func _select_melee_equipment(index: int) -> void:
	if index < 0 or index >= MELEE_EQUIPMENT.size():
		return
	_play_selected_melee_action(&"one_hand_melee_idle")


func _play_selected_melee_action(action_name: StringName) -> void:
	if not is_instance_valid(_character):
		return
	var equipment: Dictionary = MELEE_EQUIPMENT[_melee_selector.selected]
	_character.select_preview_family(equipment.family)
	if _character.play_preview_action(action_name):
		_mode_label.text = "当前动作：%s · %s · 专属透明武器层" % [
			str(equipment.label),
			"待机" if action_name == &"one_hand_melee_idle" else "攻击",
		]


func _select_firearm_equipment(index: int) -> void:
	if index < 0 or index >= FIREARM_EQUIPMENT.size():
		return
	_play_selected_firearm_action(&"pistol_idle")


func _play_selected_firearm_action(action_name: StringName) -> void:
	if not is_instance_valid(_character):
		return
	var equipment: Dictionary = FIREARM_EQUIPMENT[_firearm_selector.selected]
	_character.select_preview_family(equipment.family)
	if _character.play_preview_action(action_name):
		_mode_label.text = "当前动作：%s · %s · 专属透明武器层" % [
			str(equipment.label),
			str(ACTION_LABELS.get(action_name, String(action_name))),
		]


func _select_unarmed() -> void:
	if not is_instance_valid(_character):
		return
	_character.select_preview_family(&"unarmed")
	_show_action(&"idle")


func _trigger_hit() -> void:
	var player := _character.get_parent() as Player
	if player != null and not player._dead:
		player.take_damage(1, player.global_position + Vector2.RIGHT * 40.0)
		_show_action(&"hit")


func _trigger_death() -> void:
	var player := _character.get_parent() as Player
	if player != null and not player._dead:
		player.take_damage(player.health, player.global_position + Vector2.RIGHT * 40.0)
		_show_action(&"death")


func _trigger_demo_attack() -> void:
	if not is_instance_valid(_character):
		return
	var player := _character.get_parent() as Player
	if player == null or player._dead:
		return
	var action_name := _character.selected_preview_attack()
	if _character.play_preview_action(action_name):
		_show_action(action_name)


func _reset_demo() -> void:
	get_tree().reload_current_scene()


func _show_action(action_name: StringName) -> void:
	var label := str(ACTION_LABELS.get(action_name, String(action_name)))
	_mode_label.text = "当前动作：%s · 原始动作帧序列" % label
