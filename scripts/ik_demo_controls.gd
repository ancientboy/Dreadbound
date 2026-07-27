extends VBoxContainer

@onready var _rig := get_node("../../../../Player/LayeredSkeletonRig") as LayeredSkeletonCharacter
@onready var _mode_label := $ModeLabel as Label


func _ready() -> void:
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
	_update_mode_label()


func _process(_delta: float) -> void:
	_update_mode_label()


func _select_mode(mode) -> void:
	_rig.set_ik_demo_mode(mode)
	_update_mode_label()


func _update_mode_label() -> void:
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
