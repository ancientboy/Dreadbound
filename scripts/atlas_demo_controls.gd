extends VBoxContainer

const ACTION_LABELS := {
	&"idle": "空手待机",
	&"attack_melee": "剑攻击 / 空手基准攻击",
	&"one_hand_melee_idle": "剑待机",
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
}

@onready var _character := get_node(
	"../../../../Player/RenderedAtlasCharacter",
) as RenderedAtlasCharacter
@onready var _mode_label := $ModeLabel as Label
@onready var _demo_attack_button := $"../../../DemoAttackButton" as Button


func _ready() -> void:
	_connect_action($SwordButtons/Idle, &"one_hand_melee_idle")
	_connect_action($SwordButtons/Attack, &"attack_melee")
	_connect_action($PistolButtons/Idle, &"pistol_idle")
	_connect_action($PistolButtons/AimDown, &"pistol_aim_down")
	_connect_action($PistolButtons/Aim, &"pistol_aim")
	_connect_action($PistolButtons/AimUp, &"pistol_aim_up")
	_connect_action($PistolButtons/Shoot, &"pistol_shoot")
	_connect_action($PistolButtons/Reload, &"pistol_reload")
	_connect_action($StaffButtons/Enter, &"spell_enter")
	_connect_action($StaffButtons/Idle, &"spell_idle")
	_connect_action($StaffButtons/Shoot, &"spell_shoot")
	_connect_action($StaffButtons/Exit, &"spell_exit")
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
