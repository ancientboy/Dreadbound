extends VBoxContainer

@onready var _skill_demo := get_node("../../../../SkillRangeDemo") as SkillRangeDemo
@onready var _mode_label := $ModeLabel as Label
@onready var _skill_label := $SkillLabel as Label


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
	_update_mode_label()
	_update_skill_label()


func _process(_delta: float) -> void:
	_update_skill_label()


func _select_skill(mode: SkillRangeDemo.SkillMode) -> void:
	_skill_demo.set_skill_mode(mode)
	_update_skill_label()


func _release_skill() -> void:
	_skill_demo.trigger_skill()
	_update_skill_label()


func _update_mode_label() -> void:
	_mode_label.text = "ACTIVE: PURE 2D ATLAS · SPACE ATTACK · H HIT · K DEATH"


func _update_skill_label() -> void:
	if not is_instance_valid(_skill_demo):
		return
	var state := _skill_demo.current_phase().to_upper()
	if _skill_demo.cooldown_left() > 0.0 and state == "IDLE":
		state = "COOLDOWN %.1fs" % _skill_demo.cooldown_left()
	_skill_label.text = (
		"SKILL: %s · RANGE %d · %s"
		% [_skill_demo.selected_skill_name(), int(_skill_demo.skill_range()), state]
	)
