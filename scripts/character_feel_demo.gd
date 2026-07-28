extends Node2D

@onready var _player := $Player as Player
@onready var _hud_panel := $HUD/Panel as PanelContainer
@onready var _touch_test_buttons := $HUD/TouchTestButtons as HBoxContainer


func _ready() -> void:
	$HUD/TouchTestButtons/Hit.pressed.connect(_trigger_hit)
	$HUD/TouchTestButtons/Death.pressed.connect(_trigger_death)
	$HUD/TouchTestButtons/Reset.pressed.connect(_reset_demo)
	get_viewport().size_changed.connect(_layout_touch_ui)
	_layout_touch_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if _player == null or _player._dead:
		return
	match key_event.physical_keycode:
		KEY_H:
			_trigger_hit()
		KEY_K:
			_trigger_death()


func _trigger_hit() -> void:
	if _player == null or _player._dead:
		return
	_player.take_damage(1, _player.global_position + Vector2.RIGHT * 40.0)


func _trigger_death() -> void:
	if _player == null or _player._dead:
		return
	_player.take_damage(_player.health, _player.global_position + Vector2.RIGHT * 40.0)


func _reset_demo() -> void:
	get_tree().reload_current_scene()


func _layout_touch_ui() -> void:
	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 900.0
	_hud_panel.offset_right = minf(790.0, viewport_size.x - 24.0)
	_hud_panel.offset_bottom = 314.0 if narrow else 332.0
	_touch_test_buttons.offset_left = maxf(24.0, viewport_size.x - 424.0)
	_touch_test_buttons.offset_right = viewport_size.x - 28.0
	_touch_test_buttons.offset_top = 28.0 if not narrow else 326.0
	_touch_test_buttons.offset_bottom = _touch_test_buttons.offset_top + 60.0
