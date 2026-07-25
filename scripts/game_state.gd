class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 1
const UPGRADE_MAX_LEVEL := 3
const UPGRADE_COSTS := [4, 7, 11]
const LOADOUTS := {
	"scavenger": {"name": "搜救配置", "weapon": "melee", "ammo": 6, "bandages": 1, "description": "撬棍 · 6 发弹药 · 1 份绷带"},
	"marksman": {"name": "警戒配置", "weapon": "ranged", "ammo": 14, "bandages": 0, "description": "手枪出战 · 14 发弹药 · 无绷带"},
	"medic": {"name": "应急配置", "weapon": "melee", "ammo": 3, "bandages": 2, "description": "撬棍 · 3 发弹药 · 2 份绷带"},
}

var save_path := "user://dreadbound_progress.json"
var echo_shards := 0
var causality_fragments := 0
var upgrades := {"vitality": 0, "mobility": 0, "weapons": 0, "recovery": 0}
var last_run := {}
var selected_loadout := "scavenger"
var corridor_unlocked := false


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


func settle_run(success: bool, records: int, carried_shards: int, enemies_defeated: int, events_resolved := 0) -> int:
	var mission_reward := records * 2 + (3 if success else 0)
	var banked := carried_shards + mission_reward if success else 0
	last_run = {"success": success, "records": records, "carried_shards": carried_shards, "mission_reward": mission_reward if success else 0, "banked_shards": banked, "enemies_defeated": enemies_defeated, "events_resolved": events_resolved}
	if success:
		echo_shards += banked
		corridor_unlocked = true
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


func select_loadout(loadout_id: String) -> bool:
	if not LOADOUTS.has(loadout_id):
		return false
	selected_loadout = loadout_id
	save_progress()
	progress_changed.emit()
	return true


func get_selected_loadout() -> Dictionary:
	return LOADOUTS.get(selected_loadout, LOADOUTS.scavenger).duplicate()


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "upgrades": upgrades, "last_run": last_run, "selected_loadout": selected_loadout, "corridor_unlocked": corridor_unlocked}))
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
	var saved_loadout := str(parsed.get("selected_loadout", "scavenger"))
	selected_loadout = saved_loadout if LOADOUTS.has(saved_loadout) else "scavenger"
	corridor_unlocked = bool(parsed.get("corridor_unlocked", not last_run.is_empty() and bool(last_run.get("success", false))))


func reset_progress() -> void:
	echo_shards = 0
	causality_fragments = 0
	for upgrade_id in upgrades:
		upgrades[upgrade_id] = 0
	last_run = {}
	selected_loadout = "scavenger"
	corridor_unlocked = false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	progress_changed.emit()
