extends Control

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")

var list: VBoxContainer
var nickname: LineEdit
var feedback: Label
var email: LineEdit
var password: LineEdit
var pending_cloud_payload: Dictionary = {}


func _ready() -> void:
	var profile_theme := Theme.new()
	profile_theme.default_font = UI_FONT
	theme = profile_theme
	_build_ui()
	CloudSync.auth_completed.connect(_on_cloud_result)
	CloudSync.sync_completed.connect(_on_cloud_result)
	CloudSync.conflict_detected.connect(_on_cloud_conflict)
	_refresh_profiles()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("071311")
	add_child(background)
	var panel := VBoxContainer.new()
	panel.position = Vector2(maxf(24.0, (size.x - 680.0) * 0.5), 54)
	panel.size = Vector2(minf(680.0, size.x - 48.0), size.y - 108)
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	var title := Label.new()
	title.text = "终末回廊 // 选择行者档案"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("62dec6"))
	panel.add_child(title)
	var home := Button.new()
	home.text = "← 返回游戏首页"
	home.custom_minimum_size.y = 42
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/startup.tscn"))
	panel.add_child(home)
	var note := Label.new()
	note.text = "每个昵称拥有独立本地存档。游客档案保存在当前浏览器；登录后可选择同步到云端。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(note)
	list = VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(list)
	nickname = LineEdit.new()
	nickname.placeholder_text = "输入行者昵称（1～16 字）"
	nickname.max_length = 16
	panel.add_child(nickname)
	var create := Button.new()
	create.text = "创建本地行者"
	create.custom_minimum_size.y = 52
	create.pressed.connect(_create_profile)
	panel.add_child(create)
	var cloud_title := Label.new()
	cloud_title.text = "可选云账号"
	cloud_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cloud_title.add_theme_color_override("font_color", Color("62dec6"))
	panel.add_child(cloud_title)
	email = LineEdit.new()
	email.placeholder_text = "邮箱"
	panel.add_child(email)
	password = LineEdit.new()
	password.placeholder_text = "密码（至少 10 位）"
	password.secret = true
	panel.add_child(password)
	var cloud_actions := HBoxContainer.new()
	for spec in [["注册并绑定", _register_cloud], ["登录/保留本地", _login_cloud], ["同步/采用云端", _sync_cloud], ["退出", _logout_cloud], ["删除账号", _delete_cloud]]:
		var button := Button.new()
		button.text = spec[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(spec[1])
		cloud_actions.add_child(button)
	panel.add_child(cloud_actions)
	feedback = Label.new()
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_color_override("font_color", Color("d0bd73"))
	panel.add_child(feedback)


func _refresh_profiles() -> void:
	for child in list.get_children():
		child.queue_free()
	for profile in ProfileManager.profiles:
		var row := HBoxContainer.new()
		var select := Button.new()
		select.text = "%s\n上次游玩 %s" % [str(profile.nickname), Time.get_datetime_string_from_unix_time(int(profile.last_played_at), true)]
		select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select.custom_minimum_size.y = 58
		select.pressed.connect(_select_profile.bind(str(profile.id)))
		row.add_child(select)
		var rename := Button.new()
		rename.text = "改名"
		rename.pressed.connect(_rename_profile.bind(str(profile.id)))
		row.add_child(rename)
		var remove := Button.new()
		remove.text = "删除"
		remove.pressed.connect(_delete_profile.bind(str(profile.id)))
		row.add_child(remove)
		list.add_child(row)


func _create_profile() -> void:
	var profile := ProfileManager.create_profile(nickname.text)
	if profile.is_empty():
		feedback.text = "无法创建：昵称不能为空，且最多保留 %d 个档案。" % LocalProfileManager.MAX_PROFILES
		return
	GameState.activate_profile(ProfileManager.active_save_path())
	GameState.save_progress()
	_route_into_game()


func _select_profile(profile_id: String) -> void:
	if ProfileManager.select_profile(profile_id):
		GameState.activate_profile(ProfileManager.active_save_path())
		_route_into_game()


func _rename_profile(profile_id: String) -> void:
	if ProfileManager.rename_profile(profile_id, nickname.text):
		feedback.text = "昵称已更新。"
		_refresh_profiles()
	else:
		feedback.text = "请先输入新的昵称。"


func _delete_profile(profile_id: String) -> void:
	ProfileManager.delete_profile(profile_id)
	feedback.text = "本地档案已删除。"
	_refresh_profiles()


func _route_into_game() -> void:
	if not GameState.corridor_unlocked and GameState.active_run_seed == 0:
		GameState.begin_run()
	get_tree().change_scene_to_file("res://scenes/corridor.tscn" if GameState.corridor_unlocked else "res://scenes/main.tscn")


func _register_cloud() -> void:
	if not CloudSync.configured():
		feedback.text = "云服务尚未配置；本地多档案仍可正常使用。"
		return
	feedback.text = "正在注册……" if CloudSync.register_account(email.text, password.text, nickname.text) else "无法发起注册请求。"


func _login_cloud() -> void:
	if not pending_cloud_payload.is_empty():
		CloudSync.resolve_conflict(false, pending_cloud_payload)
		pending_cloud_payload.clear()
		return
	feedback.text = "正在登录……" if CloudSync.login(email.text, password.text) else "云服务未配置或请求正忙。"


func _sync_cloud() -> void:
	if not pending_cloud_payload.is_empty():
		CloudSync.resolve_conflict(true, pending_cloud_payload)
		pending_cloud_payload.clear()
		return
	feedback.text = "正在比较本地与云端版本……" if CloudSync.sync_active_profile() else "请先选择档案并登录。"


func _logout_cloud() -> void:
	CloudSync.logout()
	feedback.text = "已退出云账号，本地档案不受影响。"


func _delete_cloud() -> void:
	feedback.text = "正在删除账号……" if CloudSync.delete_account() else "请先登录云账号。"


func _on_cloud_result(ok: bool, message: String) -> void:
	feedback.text = ("✓ " if ok else "⚠ ") + message


func _on_cloud_conflict(_local_save: Dictionary, cloud_payload: Dictionary) -> void:
	pending_cloud_payload = cloud_payload
	feedback.text = "检测到存档冲突：点击‘登录’保留本地并上传，或点击‘同步当前档案’采用云端。"
	# The two existing actions double as explicit conflict choices, avoiding a
	# modal that would be unusable on short mobile canvases.
