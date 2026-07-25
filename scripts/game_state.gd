class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 4
const UPGRADE_MAX_LEVEL := 3
const MAX_EQUIPMENT := 20
const UPGRADE_COSTS := [4, 7, 11]
const LOADOUTS := {
	"scavenger": {"name": "搜救配置", "weapon": "melee", "ammo": 6, "bandages": 1, "shells": 2, "sedatives": 0, "stimulants": 0, "description": "撬棍 · 6 发弹药 · 1 份绷带"},
	"marksman": {"name": "警戒配置", "weapon": "ranged", "ammo": 14, "bandages": 0, "shells": 0, "sedatives": 1, "stimulants": 0, "description": "手枪 · 14 发弹药 · 1 支镇静剂"},
	"medic": {"name": "应急配置", "weapon": "melee", "ammo": 3, "bandages": 2, "shells": 0, "sedatives": 1, "stimulants": 0, "description": "撬棍 · 2 份绷带 · 1 支镇静剂"},
	"breacher": {"name": "破门配置", "weapon": "shotgun", "ammo": 2, "bandages": 0, "shells": 6, "sedatives": 0, "stimulants": 1, "description": "霰弹枪 · 6 发霰弹 · 1 支兴奋剂"},
}

var save_path := "user://dreadbound_progress.json"
var echo_shards := 0
var causality_fragments := 0
var upgrades := {"vitality": 0, "mobility": 0, "weapons": 0, "recovery": 0}
var last_run := {}
var selected_loadout := "scavenger"
var corridor_unlocked := false
var corridor_intro_seen := false
var equipment_inventory: Array[String] = ["service_crowbar", "medical_tag"]
var equipped := {"weapon": "", "charm": ""}
var active_run_seed := 0
var last_action_code := ""


func _ready() -> void:
	load_progress()


func get_player_stats() -> Dictionary:
	var gear := EquipmentDatabase.get_bonuses(equipped)
	return {
		"max_health": 100 + int(upgrades.vitality) * 10 + int(gear.max_health),
		"movement_speed": 210.0 + int(upgrades.mobility) * 8.0 + float(gear.movement_speed),
		"melee_damage": 35 + int(upgrades.weapons) * 4 + int(gear.melee_damage),
		"ranged_damage": 25 + int(upgrades.weapons) * 3 + int(gear.ranged_damage),
		"shotgun_damage": 28 + int(upgrades.weapons) * 3 + int(gear.shotgun_damage),
		"bandage_heal": 35 + int(upgrades.recovery) * 7 + int(gear.bandage_heal),
	}


func begin_run(requested_seed := 0) -> int:
	active_run_seed = requested_seed if requested_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	last_action_code = "SAN-%08X" % absi(active_run_seed)
	save_progress()
	return active_run_seed


func settle_run(success: bool, records: int, carried_shards: int, enemies_defeated: int, events_resolved := 0, equipment_rewards: Array[String] = [], run_summary: Dictionary = {}) -> int:
	var mission_reward := records * 2 + (3 if success else 0)
	var banked := carried_shards + mission_reward if success else 0
	var banked_equipment: Array[String] = []
	var overflow_shards := 0
	if success:
		for item_id in equipment_rewards:
			if EquipmentDatabase.ITEMS.has(item_id):
				if equipment_inventory.size() < MAX_EQUIPMENT:
					equipment_inventory.append(item_id)
					banked_equipment.append(item_id)
				else:
					overflow_shards += 1 + int(EquipmentDatabase.get_item(item_id).quality_rank) * 2
	banked += overflow_shards
	last_run = {"success": success, "records": records, "carried_shards": carried_shards, "mission_reward": mission_reward if success else 0, "banked_shards": banked, "enemies_defeated": enemies_defeated, "events_resolved": events_resolved, "equipment_rewards": banked_equipment, "overflow_shards": overflow_shards, "dynamic_run": run_summary}
	if success:
		echo_shards += banked
		corridor_unlocked = true
	active_run_seed = 0
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


func equip_item(item_id: String) -> bool:
	if not equipment_inventory.has(item_id):
		return false
	var item := EquipmentDatabase.get_item(item_id)
	if item.is_empty():
		return false
	equipped[item.slot] = item_id
	save_progress()
	progress_changed.emit()
	return true


func disassemble_item(item_id: String) -> bool:
	var index := equipment_inventory.rfind(item_id)
	if index < 0 or (equipped.values().has(item_id) and equipment_inventory.count(item_id) <= 1):
		return false
	var item := EquipmentDatabase.get_item(item_id)
	equipment_inventory.remove_at(index)
	echo_shards += 1 + int(item.get("quality_rank", 0)) * 2
	save_progress()
	progress_changed.emit()
	return true


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "upgrades": upgrades, "last_run": last_run, "selected_loadout": selected_loadout, "corridor_unlocked": corridor_unlocked, "corridor_intro_seen": corridor_intro_seen, "equipment_inventory": equipment_inventory, "equipped": equipped, "active_run_seed": active_run_seed, "last_action_code": last_action_code}))
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
	corridor_intro_seen = bool(parsed.get("corridor_intro_seen", false))
	active_run_seed = int(parsed.get("active_run_seed", 0))
	last_action_code = str(parsed.get("last_action_code", ""))
	equipment_inventory.clear()
	for item_id in parsed.get("equipment_inventory", ["service_crowbar", "medical_tag"]):
		if EquipmentDatabase.ITEMS.has(str(item_id)):
			equipment_inventory.append(str(item_id))
	if equipment_inventory.is_empty():
		equipment_inventory.assign(["service_crowbar", "medical_tag"])
	var saved_equipped = parsed.get("equipped", {})
	if saved_equipped is Dictionary:
		for slot in ["weapon", "charm"]:
			var item_id := str(saved_equipped.get(slot, equipped[slot]))
			if equipment_inventory.has(item_id) and EquipmentDatabase.get_item(item_id).get("slot", "") == slot:
				equipped[slot] = item_id


func reset_progress() -> void:
	echo_shards = 0
	causality_fragments = 0
	for upgrade_id in upgrades:
		upgrades[upgrade_id] = 0
	last_run = {}
	selected_loadout = "scavenger"
	corridor_unlocked = false
	corridor_intro_seen = false
	equipment_inventory.assign(["service_crowbar", "medical_tag"])
	equipped = {"weapon": "", "charm": ""}
	active_run_seed = 0
	last_action_code = ""
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	progress_changed.emit()
