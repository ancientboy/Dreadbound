extends VBoxContainer

@onready var _rig := get_node("../../../../Player/ProfessionSkeletonRig") as ProfessionSkeletonCharacter
@onready var _skill_demo := get_node("../../../../SkillRangeDemo") as SkillRangeDemo
@onready var _mode_label := $ModeLabel as Label
@onready var _skill_label := $SkillLabel as Label


func _ready() -> void:
	var rendered_atlas := get_node_or_null("../../../../Player/RenderedAtlasCharacter")
	if rendered_atlas != null:
		$ModeButtons.hide()
	else:
		$ModeButtons/Free.pressed.connect(
		_select_mode.bind(LayeredSkeletonCharacter.IKDemoMode.FREE),
	)
		$ModeButtons/Pistol.pressed.connect(
		_select_mode.bind(LayeredSkeletonCharacter.IKDemoMode.PISTOL),
	)
		$ModeButtons/Rifle.pressed.connect(
		_select_mode.bind(LayeredSkeletonCharacter.IKDemoMode.RIFLE),
	)
		$ModeButtons/Cast.pressed.connect(
		_select_mode.bind(LayeredSkeletonCharacter.IKDemoMode.CAST),
	)
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
	_update_mode_label()
	_update_skill_label()


func _select_mode(mode) -> void:
	_rig.set_ik_demo_mode(mode)
	_update_mode_label()


func _select_skill(mode) -> void:
	_skill_demo.set_skill_mode(mode)
	_update_skill_label()


func _release_skill() -> void:
	_skill_demo.trigger_skill()
	_update_skill_label()


func _update_mode_label() -> void:
	if get_node_or_null("../../../../Player/RenderedAtlasCharacter") != null:
		_mode_label.text = "ACTIVE: PURE 2D ATLAS · SPACE ATTACK · H HIT · K DEATH"
		return
	if not is_instance_valid(_rig):
		return
	var mode_name := "FREE"
	match _rig.current_ik_demo_mode():
		LayeredSkeletonCharacter.IKDemoMode.PISTOL:
			mode_name = "PISTOL · MAIN-HAND GRIP"
		LayeredSkeletonCharacter.IKDemoMode.RIFLE:
			mode_name = "RIFLE · DUAL-HAND GRIPS"
		LayeredSkeletonCharacter.IKDemoMode.CAST:
			mode_name = "CAST · DUAL-HAND TARGET"
	_mode_label.text = "ACTIVE: %s" % mode_name


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
