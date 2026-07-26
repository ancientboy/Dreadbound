class_name CloudSaveService
extends Node

signal auth_completed(ok: bool, message: String)
signal sync_completed(ok: bool, message: String)
signal conflict_detected(local_save: Dictionary, cloud_save: Dictionary)

const SESSION_PATH := "user://dreadbound_cloud_session.json"

var api_url := ""
var access_token := ""
var user_id := ""
var revision := 0
var _request: HTTPRequest
var _operation := ""
var _pending_local: Dictionary = {}


func _ready() -> void:
	api_url = str(ProjectSettings.get_setting("cloud/api_url", "")).trim_suffix("/")
	_request = HTTPRequest.new()
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	_load_session()


func configured() -> bool:
	return api_url.begins_with("https://") or api_url.begins_with("http://127.0.0.1")


func register_account(email: String, password: String, nickname: String) -> bool:
	return _send("register", "/auth/register", HTTPClient.METHOD_POST, {"email": email, "password": password, "nickname": nickname})


func login(email: String, password: String) -> bool:
	return _send("login", "/auth/login", HTTPClient.METHOD_POST, {"email": email, "password": password})


func sync_active_profile() -> bool:
	if access_token.is_empty() or ProfileManager.active_profile_id.is_empty():
		return false
	_pending_local = _read_local_save()
	return _send("download_for_sync", "/save", HTTPClient.METHOD_GET, {})


func upload_active_profile(expected_revision := -1) -> bool:
	var local := _read_local_save()
	var expected := revision if expected_revision < 0 else expected_revision
	return _send("upload", "/save", HTTPClient.METHOD_PUT, {"save_version": GameProgress.SAVE_VERSION, "revision": expected, "save": local})


func resolve_conflict(use_cloud: bool, cloud_payload: Dictionary = {}) -> bool:
	if use_cloud:
		return _write_cloud_save(cloud_payload)
	return upload_active_profile(revision)


func delete_account() -> bool:
	return _send("delete", "/account", HTTPClient.METHOD_DELETE, {})


func logout() -> void:
	access_token = ""
	user_id = ""
	revision = 0
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)


func _send(operation: String, path: String, method: HTTPClient.Method, body: Dictionary) -> bool:
	if not configured() or _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return false
	_operation = operation
	var headers := ["Content-Type: application/json"]
	if not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)
	return _request.request(api_url + path, headers, method, JSON.stringify(body) if method != HTTPClient.METHOD_GET else "") == OK


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	var payload: Dictionary = parsed if parsed is Dictionary else {}
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		if response_code == 409 and _operation == "upload" and payload.has("save"):
			revision = int(payload.get("revision", revision))
			conflict_detected.emit(_pending_local, payload)
			return
		var message := str(payload.get("error", "网络不可用，已保留本地存档。"))
		if _operation in ["register", "login"]: auth_completed.emit(false, message)
		else: sync_completed.emit(false, message)
		return
	match _operation:
		"register", "login":
			access_token = str(payload.get("access_token", ""))
			user_id = str(payload.get("user_id", ""))
			revision = int(payload.get("revision", 0))
			_save_session()
			auth_completed.emit(true, "账号已连接，可以同步当前行者。")
		"download_for_sync":
			revision = int(payload.get("revision", 0))
			var cloud_save: Dictionary = payload.get("save", {})
			if cloud_save.is_empty():
				upload_active_profile(0)
			elif str(ProfileManager.active_profile().get("cloud_user_id", "")) == user_id and int(ProfileManager.active_profile().get("cloud_revision", 0)) == revision:
				_write_cloud_save(payload)
			else:
				conflict_detected.emit(_pending_local, payload)
		"upload":
			revision = int(payload.get("revision", revision + 1))
			ProfileManager.update_cloud_link(user_id, revision)
			_save_session()
			sync_completed.emit(true, "云存档已更新至版本 %d。" % revision)
		"delete":
			logout()
			sync_completed.emit(true, "账号及云存档已删除。")


func _read_local_save() -> Dictionary:
	GameState.save_progress()
	var file := FileAccess.open(ProfileManager.active_save_path(), FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	return parsed if parsed is Dictionary else {}


func _write_cloud_save(payload: Dictionary) -> bool:
	var cloud_save: Dictionary = payload.get("save", {})
	if cloud_save.is_empty():
		return false
	var file := FileAccess.open(ProfileManager.active_save_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(cloud_save))
	revision = int(payload.get("revision", revision))
	ProfileManager.update_cloud_link(user_id, revision)
	GameState.activate_profile(ProfileManager.active_save_path())
	sync_completed.emit(true, "已恢复云端行者档案。")
	return true


func _save_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"access_token": access_token, "user_id": user_id, "revision": revision}))


func _load_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if parsed is Dictionary:
		access_token = str(parsed.get("access_token", ""))
		user_id = str(parsed.get("user_id", ""))
		revision = int(parsed.get("revision", 0))
