extends Control

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const HOME_KEYART: Texture2D = preload("res://assets/art/brand/home_keyart.png")
const DREADBOUND_LOGO: Texture2D = preload("res://assets/art/brand/dreadbound_logo.png")

var content: VBoxContainer
var feature_grid: GridContainer
var world_grid: GridContainer
var primary_button: Button
var profile_button: Button
var settings_button: Button
var audio_settings: PanelContainer


func _ready() -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world("home")
	var home_theme := Theme.new()
	home_theme.default_font = UI_FONT
	theme = home_theme
	get_viewport().size_changed.connect(_apply_responsive_ui)
	_build_home()
	_apply_responsive_ui()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("030a0d"))
	draw_texture_rect(HOME_KEYART, Rect2(Vector2.ZERO, size), false, Color(0.82, 0.88, 0.87, 0.72))
	draw_rect(Rect2(0, 0, size.x * 0.58, size.y), Color(0.008, 0.022, 0.026, 0.72))
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.01, 0.03, 0.035, 0.16))
	var horizon := size.y * 0.48
	for index in range(9):
		var radius := 60.0 + index * 54.0
		var alpha := 0.045 * (1.0 - float(index) / 11.0)
		draw_circle(Vector2(size.x * 0.72, horizon), radius, Color(0.18, 0.92, 0.78, alpha))
	for x in range(0, int(size.x) + 80, 80):
		draw_line(Vector2(x, horizon), Vector2(size.x * 0.5 + (x - size.x * 0.5) * 2.4, size.y), Color(0.18, 0.55, 0.5, 0.08), 1.0)
	for y in range(int(horizon), int(size.y) + 44, 44):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.18, 0.55, 0.5, 0.06), 1.0)
	draw_string(UI_FONT, Vector2(28, size.y - 24), "THE CORRIDOR REMEMBERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("3d756e"))


func _build_home() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "HomeScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.name = "HomeMargin"
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 32)
	scroll.add_child(margin)
	content = VBoxContainer.new()
	content.name = "HomeContent"
	content.custom_minimum_size = Vector2(1176, 0)
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	content.add_child(nav)
	var brand := TextureRect.new()
	brand.name = "BrandLogo"
	brand.texture = DREADBOUND_LOGO
	brand.custom_minimum_size = Vector2(205, 52)
	brand.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	brand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nav.add_child(brand)
	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)
	var build := Label.new()
	build.text = "PLAYABLE ALPHA · O1 VISUAL SLICE"
	build.add_theme_font_size_override("font_size", 13)
	build.add_theme_color_override("font_color", Color("7d9993"))
	nav.add_child(build)
	settings_button = Button.new()
	settings_button.name = "OpenAudioSettings"
	settings_button.text = "设置"
	settings_button.tooltip_text = "音乐与音效设置"
	settings_button.custom_minimum_size = Vector2(92, 38)
	settings_button.add_theme_font_size_override("font_size", 16)
	settings_button.add_theme_color_override("font_color", Color("b9d9d2"))
	settings_button.add_theme_stylebox_override("normal", _button_style(Color("0b1d1c"), Color("37645e")))
	settings_button.add_theme_stylebox_override("hover", _button_style(Color("12312e"), Color("68b5a8")))
	settings_button.pressed.connect(_open_audio_settings)
	nav.add_child(settings_button)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1
	divider.color = Color("23443f")
	content.add_child(divider)

	var eyebrow := Label.new()
	eyebrow.text = "ORIGINAL HORROR EXTRACTION ROGUELITE"
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color("d0ad62"))
	content.add_child(eyebrow)
	var title := Label.new()
	title.name = "HeroTitle"
	title.text = "恐惧会记住\n你的每一次选择"
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color("e8f7f2"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "HeroSubtitle"
	subtitle.text = "进入由文明恐惧、记忆与未来可能性凝成的灾难世界。\n副本不会重置你的后果，装备会随行为进化，而你最终会成为自己选择留下的心相。"
	subtitle.custom_minimum_size.y = 76
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color("a9c3bc"))
	content.add_child(subtitle)

	var actions := BoxContainer.new()
	actions.name = "HomeActions"
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	primary_button = Button.new()
	primary_button.name = "EnterGame"
	primary_button.text = "进入终末回廊  →" if not ProfileManager.active_profile_id.is_empty() else "建立行者档案，进入终末回廊  →"
	primary_button.custom_minimum_size = Vector2(360, 64)
	primary_button.add_theme_font_size_override("font_size", 18)
	primary_button.add_theme_color_override("font_color", Color("03110f"))
	primary_button.add_theme_color_override("font_hover_color", Color("03110f"))
	primary_button.add_theme_color_override("font_pressed_color", Color("dffff8"))
	primary_button.add_theme_stylebox_override("normal", _button_style(Color("62e5cd"), Color("8af5e1")))
	primary_button.add_theme_stylebox_override("hover", _button_style(Color("87f0dc"), Color("c0fff2")))
	primary_button.add_theme_stylebox_override("pressed", _button_style(Color("17695f"), Color("79e7d2")))
	primary_button.add_theme_stylebox_override("focus", _button_style(Color("62e5cd"), Color("e3fff9"), 3))
	primary_button.pressed.connect(_enter_game)
	actions.add_child(primary_button)
	profile_button = Button.new()
	profile_button.name = "OpenProfiles"
	profile_button.text = "选择 / 管理行者档案"
	profile_button.custom_minimum_size = Vector2(260, 64)
	profile_button.add_theme_font_size_override("font_size", 17)
	profile_button.add_theme_color_override("font_color", Color("b9d9d2"))
	profile_button.add_theme_color_override("font_hover_color", Color("e9fff9"))
	profile_button.add_theme_stylebox_override("normal", _button_style(Color("0b1d1c"), Color("37645e")))
	profile_button.add_theme_stylebox_override("hover", _button_style(Color("12312e"), Color("68b5a8")))
	profile_button.add_theme_stylebox_override("pressed", _button_style(Color("081514"), Color("4c8e83")))
	profile_button.pressed.connect(_open_profiles)
	actions.add_child(profile_button)

	var loop := Label.new()
	loop.text = "选择整备  →  投送副本  →  探索与抉择  →  撤离结算  →  装备进化与世界变化"
	loop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loop.add_theme_color_override("font_color", Color("6fc5b4"))
	content.add_child(loop)

	feature_grid = GridContainer.new()
	feature_grid.name = "FeatureGrid"
	feature_grid.columns = 3
	feature_grid.add_theme_constant_override("h_separation", 14)
	feature_grid.add_theme_constant_override("v_separation", 14)
	content.add_child(feature_grid)
	_add_feature("01  持续灾难世界", "NPC 记得你的承诺、背叛与救援；再次进入时加载的是下一章，不是同一张重置地图。")
	_add_feature("02  行为塑造力量", "三职业、十二流派、五级强化和多分支进化。心相来自长期行为，无法从商店购买。")
	_add_feature("03  有代价的撤离", "材料必须成功撤离才会入库；唯一物品只存在一件，失联、归属和重复首领都有明确规则。")

	var worlds_title := Label.new()
	worlds_title.text = "CURRENT DISASTER WORLDS  //  当前可进入"
	worlds_title.add_theme_font_size_override("font_size", 18)
	worlds_title.add_theme_color_override("font_color", Color("d0ad62"))
	content.add_child(worlds_title)
	world_grid = GridContainer.new()
	world_grid.name = "WorldGrid"
	world_grid.columns = 2
	world_grid.add_theme_constant_override("h_separation", 14)
	world_grid.add_theme_constant_override("v_separation", 14)
	content.add_child(world_grid)
	var catalog := ContentCatalog.new()
	for world_id in ["sanatorium", "metro"]:
		var world := catalog.dungeon(world_id)
		_add_world_card(str(world.get("world_code", "")), str(world.get("name", "")), str(world.get("english_name", "")), str(world.get("short_intro", "")), str(world.get("core_fear", "")))

	var footer := Label.new()
	footer.text = "单人优先 · Web 直接游玩 · 2–4 人协作底层已预留\n所有世界、角色与装备均为原创内容。"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_color_override("font_color", Color("607b75"))
	content.add_child(footer)
	_build_audio_settings()


func _add_feature(title: String, body: String) -> void:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(0, 132)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	feature_grid.add_child(panel)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("72ddc7"))
	panel.add_child(heading)
	var description := Label.new()
	description.text = body
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 15)
	description.add_theme_color_override("font_color", Color("91aaa4"))
	panel.add_child(description)


func _button_style(background: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _add_world_card(code: String, title: String, english: String, intro: String, fear: String) -> void:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(0, 184)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	world_grid.add_child(panel)
	var code_label := Label.new()
	code_label.text = "%s  //  %s" % [code, english.to_upper()]
	code_label.add_theme_color_override("font_color", Color("668d85"))
	panel.add_child(code_label)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color("dceee9"))
	panel.add_child(heading)
	var description := Label.new()
	description.text = intro
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color("9db6af"))
	panel.add_child(description)
	var fear_label := Label.new()
	fear_label.text = "核心恐惧：%s" % fear
	fear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fear_label.add_theme_color_override("font_color", Color("bb9562"))
	panel.add_child(fear_label)


func _apply_responsive_ui() -> void:
	if content == null:
		return
	var viewport_width := get_viewport_rect().size.x
	var compact := viewport_width < 760.0
	content.custom_minimum_size.x = maxf(viewport_width - (28.0 if compact else 104.0), 320.0)
	var margin := get_node("HomeScroll/HomeMargin") as MarginContainer
	margin.add_theme_constant_override("margin_left", 14 if compact else 52)
	margin.add_theme_constant_override("margin_right", 14 if compact else 52)
	feature_grid.columns = 1 if compact else 3
	world_grid.columns = 1 if compact else 2
	var title := content.get_node("HeroTitle") as Label
	title.add_theme_font_size_override("font_size", 38 if compact else 58)
	var actions := content.get_node("HomeActions") as BoxContainer
	actions.vertical = compact
	primary_button.custom_minimum_size.x = 0 if compact else 360
	profile_button.custom_minimum_size.x = 0 if compact else 260
	primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.custom_minimum_size.x = 0
	queue_redraw()


func _build_audio_settings() -> void:
	audio_settings = PanelContainer.new()
	audio_settings.name = "AudioSettings"
	audio_settings.visible = false
	audio_settings.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	audio_settings.custom_minimum_size = Vector2(330, 0)
	audio_settings.add_theme_stylebox_override("panel", _button_style(Color("071817"), Color("5bbdab"), 2))
	add_child(audio_settings)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	audio_settings.add_child(box)
	var heading := Label.new()
	heading.text = "声音设置"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("dffff8"))
	box.add_child(heading)
	var note := Label.new()
	note.text = "设置会自动保存在此设备"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Color("7d9993"))
	box.add_child(note)
	var director := get_node("/root/AudioDirector") as DreadboundAudioDirector
	var music_toggle := CheckButton.new()
	music_toggle.name = "MusicToggle"
	music_toggle.text = "音乐（含环境音）"
	music_toggle.button_pressed = director.is_music_enabled()
	music_toggle.add_theme_font_size_override("font_size", 18)
	music_toggle.toggled.connect(func(enabled: bool): director.set_music_enabled(enabled))
	box.add_child(music_toggle)
	var sfx_toggle := CheckButton.new()
	sfx_toggle.name = "SfxToggle"
	sfx_toggle.text = "音效"
	sfx_toggle.button_pressed = director.is_sfx_enabled()
	sfx_toggle.add_theme_font_size_override("font_size", 18)
	sfx_toggle.toggled.connect(func(enabled: bool): director.set_sfx_enabled(enabled))
	box.add_child(sfx_toggle)
	var test_sfx_button := Button.new()
	test_sfx_button.name = "TestSfx"
	test_sfx_button.text = "测试战斗音效"
	test_sfx_button.custom_minimum_size.y = 40
	test_sfx_button.add_theme_font_size_override("font_size", 16)
	test_sfx_button.add_theme_color_override("font_color", Color("dffff8"))
	test_sfx_button.add_theme_stylebox_override("normal", _button_style(Color("163a34"), Color("3e8275")))
	test_sfx_button.pressed.connect(func(): director.play_sfx_preview())
	box.add_child(test_sfx_button)
	var close_button := Button.new()
	close_button.name = "CloseAudioSettings"
	close_button.text = "完成"
	close_button.custom_minimum_size.y = 44
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color("03110f"))
	close_button.add_theme_stylebox_override("normal", _button_style(Color("62e5cd"), Color("8af5e1")))
	close_button.pressed.connect(func(): audio_settings.hide())
	box.add_child(close_button)


func _open_audio_settings() -> void:
	audio_settings.visible = true


func _enter_game() -> void:
	if ProfileManager.active_profile_id.is_empty():
		_open_profiles()
		return
	if not GameState.corridor_unlocked and GameState.active_run_seed == 0:
		GameState.begin_run()
	var destination := "res://scenes/corridor.tscn" if GameState.corridor_unlocked else "res://scenes/main.tscn"
	get_tree().change_scene_to_file(destination)


func _open_profiles() -> void:
	get_tree().change_scene_to_file("res://scenes/profile_gate.tscn")
