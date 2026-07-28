extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")

@onready var _player := $Player as Player
@onready var _martial_artist_trial := (
	$Player/MartialArtistTrialCharacter as MartialArtistTrialCharacter
)
@onready var _humanoid_actions := (
	$Player/UniversalHumanoidActionCharacter as UniversalHumanoidActionCharacter
)
@onready var _hud_panel := $HUD/Panel as PanelContainer
@onready var _touch_test_buttons := $HUD/TouchTestButtons as HBoxContainer
@onready var _trial_button := $HUD/TouchTestButtons/Trial as Button


func _ready() -> void:
	var demo_theme := Theme.new()
	demo_theme.default_font = UI_FONT
	_hud_panel.theme = demo_theme
	_touch_test_buttons.theme = demo_theme
	$HUD/TouchTestButtons/Hit.pressed.connect(_trigger_hit)
	$HUD/TouchTestButtons/Death.pressed.connect(_trigger_death)
	$HUD/TouchTestButtons/Reset.pressed.connect(_reset_demo)
	_trial_button.pressed.connect(_toggle_character_trial)
	get_viewport().size_changed.connect(_layout_touch_ui)
	_update_trial_button()
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
		KEY_V:
			_toggle_character_trial()


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


func _toggle_character_trial() -> void:
	_humanoid_actions.set_action_library_enabled(
		not _humanoid_actions.is_action_library_enabled()
	)
	_update_trial_button()


func _update_trial_button() -> void:
	_trial_button.text = (
		"返回正式武斗师"
		if _humanoid_actions.is_action_library_enabled()
		else "查看骨骼调试"
	)


func _layout_touch_ui() -> void:
	var viewport_size := get_viewport_rect().size
	var narrow := viewport_size.x < 900.0
	var compact := viewport_size.x < 1400.0
	_hud_panel.offset_right = minf(790.0, viewport_size.x - 24.0)
	_hud_panel.offset_bottom = 524.0 if narrow else 510.0
	_touch_test_buttons.offset_left = maxf(24.0, viewport_size.x - 568.0)
	_touch_test_buttons.offset_right = viewport_size.x - 28.0
	_touch_test_buttons.offset_top = 536.0 if narrow else (522.0 if compact else 28.0)
	_touch_test_buttons.offset_bottom = _touch_test_buttons.offset_top + 60.0
