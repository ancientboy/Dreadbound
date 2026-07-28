extends VBoxContainer

@onready var _player := get_node("../../../../Player") as Player
@onready var _mode_label := $ModeLabel as Label


func _ready() -> void:
	# This is deliberately a character lab, not an equipment test bench.
	# It is locked to the screenshot-approved v11 martial-artist atlases.
	_mode_label.text = "当前模型：武斗师 v11　动作：待机\n移动：摇杆或方向键　攻击：空格或红色按钮"


func _process(_delta: float) -> void:
	if _player == null or _player._dead:
		return
	if _player.velocity.length() > 2.0:
		_mode_label.text = "当前模型：武斗师 v11　动作：行走\n移动：摇杆或方向键　攻击：空格或红色按钮"
	elif _player._attack_flash > 0.0:
		_mode_label.text = "当前模型：武斗师 v11　动作：空手攻击\n移动：摇杆或方向键　攻击：空格或红色按钮"
	else:
		_mode_label.text = "当前模型：武斗师 v11　动作：待机\n移动：摇杆或方向键　攻击：空格或红色按钮"
