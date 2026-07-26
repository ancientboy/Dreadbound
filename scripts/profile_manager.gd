class_name LocalProfileManager
extends Node

signal profiles_changed
signal active_profile_changed(profile_id: String)

const INDEX_PATH := "user://dreadbound_profiles.json"
const LEGACY_PATH := "user://dreadbound_progress.json"
const MAX_PROFILES := 6
var index_path := INDEX_PATH
var legacy_path := LEGACY_PATH

var profiles: Array[Dictionary] = []
var active_profile_id := ""


func _ready() -> void:
	load_index()
	_migrate_legacy_save()


func load_index() -> void:
	profiles.clear()
	if not FileAccess.file_exists(index_path):
		return
	var file := FileAccess.open(index_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if not parsed is Dictionary:
		return
	for entry in parsed.get("profiles", []):
		if entry is Dictionary and _valid_id(str(entry.get("id", ""))):
			profiles.append(entry.duplicate(true))
	active_profile_id = str(parsed.get("active_profile_id", ""))
	if not profiles.any(func(profile): return str(profile.id) == active_profile_id):
		active_profile_id = ""


func save_index() -> bool:
	var file := FileAccess.open(index_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "active_profile_id": active_profile_id, "profiles": profiles}))
	return true


func create_profile(nickname: String) -> Dictionary:
	if profiles.size() >= MAX_PROFILES:
		return {}
	var clean_name := _sanitize_nickname(nickname)
	if clean_name.is_empty():
		return {}
	var profile_id := "p_%x_%04x" % [Time.get_unix_time_from_system(), randi() & 0xffff]
	var profile := {"id": profile_id, "nickname": clean_name, "created_at": Time.get_unix_time_from_system(), "last_played_at": Time.get_unix_time_from_system(), "cloud_user_id": "", "cloud_revision": 0}
	profiles.append(profile)
	active_profile_id = profile_id
	save_index()
	profiles_changed.emit()
	active_profile_changed.emit(profile_id)
	return profile.duplicate(true)


func select_profile(profile_id: String) -> bool:
	if not profiles.any(func(profile): return str(profile.id) == profile_id):
		return false
	active_profile_id = profile_id
	for profile in profiles:
		if str(profile.id) == profile_id:
			profile.last_played_at = Time.get_unix_time_from_system()
	save_index()
	active_profile_changed.emit(profile_id)
	return true


func rename_profile(profile_id: String, nickname: String) -> bool:
	var clean_name := _sanitize_nickname(nickname)
	if clean_name.is_empty():
		return false
	for profile in profiles:
		if str(profile.id) == profile_id:
			profile.nickname = clean_name
			save_index()
			profiles_changed.emit()
			return true
	return false


func delete_profile(profile_id: String) -> bool:
	for index in range(profiles.size()):
		if str(profiles[index].id) == profile_id:
			profiles.remove_at(index)
			var path := save_path_for(profile_id)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
			if active_profile_id == profile_id:
				active_profile_id = ""
			save_index()
			profiles_changed.emit()
			return true
	return false


func active_profile() -> Dictionary:
	for profile in profiles:
		if str(profile.id) == active_profile_id:
			return profile.duplicate(true)
	return {}


func save_path_for(profile_id: String) -> String:
	return "user://dreadbound_%s.json" % profile_id if _valid_id(profile_id) else ""


func active_save_path() -> String:
	return save_path_for(active_profile_id)


func update_cloud_link(user_id: String, revision: int) -> void:
	for profile in profiles:
		if str(profile.id) == active_profile_id:
			profile.cloud_user_id = user_id
			profile.cloud_revision = revision
			save_index()
			return


func _migrate_legacy_save() -> void:
	if not profiles.is_empty() or not FileAccess.file_exists(legacy_path):
		return
	var profile := create_profile("旧档行者")
	var source := FileAccess.open(legacy_path, FileAccess.READ)
	var target := FileAccess.open(save_path_for(str(profile.id)), FileAccess.WRITE)
	if source and target:
		target.store_string(source.get_as_text())


func _sanitize_nickname(value: String) -> String:
	var cleaned := value.strip_edges().substr(0, 16)
	for forbidden in ["/", "\\", "\n", "\r", "\t"]:
		cleaned = cleaned.replace(forbidden, "")
	return cleaned


func _valid_id(profile_id: String) -> bool:
	return profile_id.begins_with("p_") and profile_id.length() <= 40 and profile_id.substr(2).replace("_", "").is_valid_hex_number()
