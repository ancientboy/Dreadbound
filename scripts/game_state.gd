class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 1
const UPGRADE_MAX_LEVEL := 3
const UPGRADE_COSTS := [4, 7, 11]

var save_path := "user://dreadbound_progress.json"
var echo_shards := 0
var causality_fragments := 0
var upgrades := {"vitality": 0, "mobility": 0, "weapons": 0, "recovery": 0}
var last_run := {}


func _ready() -> void:
	load_progress()


func get_player_stats() -> Dictionary:
	return {
		"max_health": 100 + int(upgrades.vitality) * 10,
		"movement_speed": 210.0 + int(upgrades.mobility) * 8.0,
		"melee_damage": 35 + int(upgrades.weapons) * 4,
		"ranged_damage": 25 + int(upgrades.weapons) * 3,
		"bandage_heal": 35 + int(upgrades.recovery) * 7,
	}


func settle_run(success: bool, records: int, carried_shards: int, enemies_defeated: int) -> int:
	var mission_reward := records * 2 + (3 if success else 0)
	var banked := carried_shards + mission_reward if success else 0
	last_run = {"success": success, "records": records, "carried_shards": carried_shards, "mission_reward": mission_reward if success else 0, "banked_shards": banked, "enemies_defeated": enemies_defeated}
	if success:
		echo_shards += banked
	save_progress()
	progress_changed.emit()
	return banked


func get_upgrade_cost(upgrade_id: String) -> int:
	var level := int(upgrades.get(upgrade_id, 0))
	return 0 if level >= UPGRADE_MAX_LEVEL else UPGRADE_COSTS[level]


func purchase_upgrade(upgrade_id: String) -> bool:
	if not upgrades.has(upgrade_id):
		return false
	var cost := get_upgrade_cost(upgrade_id)
	if cost <= 0 or echo_shards < cost:
		return false
	echo_shards -= cost
	upgrades[upgrade_id] = int(upgrades[upgrade_id]) + 1
	save_progress()
	progress_changed.emit()
	return true


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "upgrades": upgrades, "last_run": last_run}))
	return true


func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	echo_shards = maxi(int(parsed.get("echo_shards", 0)), 0)
	causality_fragments = maxi(int(parsed.get("causality_fragments", 0)), 0)
	var saved_upgrades = parsed.get("upgrades", {})
	if saved_upgrades is Dictionary:
		for upgrade_id in upgrades:
			upgrades[upgrade_id] = clampi(int(saved_upgrades.get(upgrade_id, 0)), 0, UPGRADE_MAX_LEVEL)
	var saved_run = parsed.get("last_run", {})
	last_run = saved_run if saved_run is Dictionary else {}


func reset_progress() -> void:
	echo_shards = 0
	causality_fragments = 0
	for upgrade_id in upgrades:
		upgrades[upgrade_id] = 0
	last_run = {}
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	progress_changed.emit()
