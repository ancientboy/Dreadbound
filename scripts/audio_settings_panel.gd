class_name DreadboundAudioSettingsPanel
extends PanelContainer

## Reusable audio panel for the corridor and live missions, not only the title.

var _director: DreadboundAudioDirector


func configure(font: Font) -> void:
	_director = get_node("/root/AudioDirector") as DreadboundAudioDirector
	name = "InGameAudioSettings"
	visible = false
	z_index = 1000
	custom_minimum_size = Vector2(320, 0)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("071817")
	panel_style.border_color = Color("5bbdab")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(22)
	add_theme_stylebox_override("panel", panel_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var heading := Label.new()
	heading.text = "声音设置"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", font)
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("dffff8"))
	box.add_child(heading)
	var note := Label.new()
	note.text = "音乐与音效会保存在此设备"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_override("font", font)
	note.add_theme_color_override("font_color", Color("7d9993"))
	box.add_child(note)
	var music_toggle := CheckButton.new()
	music_toggle.name = "InGameMusicToggle"
	music_toggle.text = "音乐（含环境音）"
	music_toggle.button_pressed = _director.is_music_enabled()
	music_toggle.add_theme_font_override("font", font)
	music_toggle.add_theme_font_size_override("font_size", 18)
	music_toggle.toggled.connect(func(enabled: bool): _director.set_music_enabled(enabled))
	box.add_child(music_toggle)
	var sfx_toggle := CheckButton.new()
	sfx_toggle.name = "InGameSfxToggle"
	sfx_toggle.text = "音效"
	sfx_toggle.button_pressed = _director.is_sfx_enabled()
	sfx_toggle.add_theme_font_override("font", font)
	sfx_toggle.add_theme_font_size_override("font_size", 18)
	sfx_toggle.toggled.connect(func(enabled: bool): _director.set_sfx_enabled(enabled))
	box.add_child(sfx_toggle)
	var close := Button.new()
	close.name = "CloseInGameAudioSettings"
	close.text = "完成"
	close.custom_minimum_size.y = 44
	close.add_theme_font_override("font", font)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(hide)
	box.add_child(close)


func toggle() -> void:
	visible = not visible
