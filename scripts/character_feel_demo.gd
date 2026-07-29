extends Node2D

const PANEL_MAX_WIDTH := 540.0
const PANEL_HEIGHT := 530.0
const PANEL_MARGIN := 18.0

@onready var _player := $Player as Player
@onready var _hud_panel := $HUD/Panel as PanelContainer


func _ready() -> void:
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
	_hud_panel.offset_left = PANEL_MARGIN
	_hud_panel.offset_top = PANEL_MARGIN
	_hud_panel.offset_right = minf(
		PANEL_MARGIN + PANEL_MAX_WIDTH,
		viewport_size.x - PANEL_MARGIN,
	)
	_hud_panel.offset_bottom = minf(
		PANEL_MARGIN + PANEL_HEIGHT,
		viewport_size.y - PANEL_MARGIN,
	)
