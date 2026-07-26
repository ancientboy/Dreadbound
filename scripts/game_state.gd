class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 8
const UPGRADE_MAX_LEVEL := 3
const MAX_EQUIPMENT := 20
const UPGRADE_COSTS := [4, 7, 11, 16, 22, 29]
const PATHWAY_ANCHOR_COST := {"echo_shards": 8, "causality_fragments": 1}
const LOADOUTS := {
	"scavenger": {"name": "搜救配置", "weapon": "melee", "ammo": 6, "bandages": 1, "shells": 2, "sedatives": 0, "stimulants": 0, "description": "撬棍 · 6 发弹药 · 1 份绷带"},
	"marksman": {"name": "警戒配置", "weapon": "ranged", "ammo": 14, "bandages": 0, "shells": 0, "sedatives": 1, "stimulants": 0, "description": "手枪 · 14 发弹药 · 1 支镇静剂"},
	"medic": {"name": "应急配置", "weapon": "melee", "ammo": 3, "bandages": 2, "shells": 0, "sedatives": 1, "stimulants": 0, "description": "撬棍 · 2 份绷带 · 1 支镇静剂"},
	"breacher": {"name": "破门配置", "weapon": "shotgun", "ammo": 2, "bandages": 0, "shells": 6, "sedatives": 0, "stimulants": 1, "description": "霰弹枪 · 6 发霰弹 · 1 支兴奋剂"},
}
const PATH_NODES := {
	"steadfast_guard": {"path": "steadfast", "name": "坚守者：守望", "cost": 5, "description": "生命上限 +12 · 解锁耐受/恢复 Lv.4–6"},
	"steadfast_mender": {"path": "steadfast", "name": "坚守者：缝合", "cost": 8, "requires": "steadfast_guard", "description": "绷带恢复 +8"},
	"armorer_calibration": {"path": "armorer", "name": "武装师：校准", "cost": 5, "description": "全部武器伤害 +3 · 解锁武器/机动 Lv.4–6"},
	"armorer_mobility": {"path": "armorer", "name": "武装师：机动装填", "cost": 8, "requires": "armorer_calibration", "description": "移动速度 +10 · 手枪伤害 +2"},
	"resonant_sense": {"path": "resonant", "name": "共鸣者：余响感知", "cost": 5, "description": "移动速度 +8 · 生命上限 -3 · 解锁机动/武器 Lv.4–6"},
	"resonant_bargain": {"path": "resonant", "name": "共鸣者：代价交换", "cost": 8, "requires": "resonant_sense", "description": "全部武器伤害 +5 · 生命上限 -6"},
}
const PATHWAY_NAMES := {"steadfast": "坚守者", "armorer": "武装师", "resonant": "共鸣者"}

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
var selected_world := "sanatorium"
var player_profile := {"runs": 0, "successful_runs": 0, "metro_runs": 0, "noise_actions": 0, "events_taken": 0, "last_observation": "尚无足够行动数据。"}
var unlocked_path_nodes: Array[String] = []
var selected_pathway := ""


func _ready() -> void:
	load_progress()


func get_player_stats() -> Dictionary:
	var gear := EquipmentDatabase.get_bonuses(equipped)
	var path := get_path_bonuses()
	return {
		"max_health": 100 + int(upgrades.vitality) * 10 + int(gear.max_health) + int(path.max_health),
		"movement_speed": 210.0 + int(upgrades.mobility) * 8.0 + float(gear.movement_speed) + float(path.movement_speed),
		"melee_damage": 35 + int(upgrades.weapons) * 4 + int(gear.melee_damage) + int(path.melee_damage),
		"ranged_damage": 25 + int(upgrades.weapons) * 3 + int(gear.ranged_damage) + int(path.ranged_damage),
		"shotgun_damage": 28 + int(upgrades.weapons) * 3 + int(gear.shotgun_damage) + int(path.shotgun_damage),
		"bandage_heal": 35 + int(upgrades.recovery) * 7 + int(gear.bandage_heal) + int(path.bandage_heal),
	}


func get_path_bonuses() -> Dictionary:
	var bonuses := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0}
	for node_id in unlocked_path_nodes:
		match node_id:
			"steadfast_guard": bonuses.max_health += 12
			"steadfast_mender": bonuses.bandage_heal += 8
			"armorer_calibration":
				bonuses.melee_damage += 3
				bonuses.ranged_damage += 3
				bonuses.shotgun_damage += 3
			"armorer_mobility":
				bonuses.movement_speed += 10.0
				bonuses.ranged_damage += 2
			"resonant_sense":
				bonuses.movement_speed += 8.0
				bonuses.max_health -= 3
			"resonant_bargain":
				bonuses.max_health -= 6
				bonuses.melee_damage += 5
				bonuses.ranged_damage += 5
				bonuses.shotgun_damage += 5
	return bonuses


func unlock_path_node(node_id: String) -> bool:
	if not PATH_NODES.has(node_id) or unlocked_path_nodes.has(node_id):
		return false
	var node: Dictionary = PATH_NODES[node_id]
	var path_id := str(node.path)
	if not selected_pathway.is_empty() and selected_pathway != path_id:
		return false
	var required_node := str(node.get("requires", ""))
	if not required_node.is_empty() and not unlocked_path_nodes.has(required_node):
		return false
	var anchor_echo_cost := int(PATHWAY_ANCHOR_COST.echo_shards) if selected_pathway.is_empty() else 0
	var anchor_fragment_cost := int(PATHWAY_ANCHOR_COST.causality_fragments) if selected_pathway.is_empty() else 0
	if echo_shards < int(node.cost) + anchor_echo_cost or causality_fragments < anchor_fragment_cost:
		return false
	echo_shards -= int(node.cost) + anchor_echo_cost
	causality_fragments -= anchor_fragment_cost
	if selected_pathway.is_empty():
		selected_pathway = path_id
	unlocked_path_nodes.append(node_id)
	save_progress()
	progress_changed.emit()
	return true


func begin_run(requested_seed := 0) -> int:
	active_run_seed = requested_seed if requested_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	last_action_code = ("MET" if selected_world == "metro" else "SAN") + "-%08X" % absi(active_run_seed)
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
	player_profile.runs = int(player_profile.get("runs", 0)) + 1
	player_profile.successful_runs = int(player_profile.get("successful_runs", 0)) + (1 if success else 0)
	player_profile.metro_runs = int(player_profile.get("metro_runs", 0)) + (1 if str(run_summary.get("world", "")) == "metro" else 0)
	player_profile.noise_actions = int(player_profile.get("noise_actions", 0)) + int(run_summary.get("noise", 0))
	player_profile.events_taken = int(player_profile.get("events_taken", 0)) + events_resolved
	player_profile.last_observation = _build_observation(success, enemies_defeated, events_resolved, run_summary)
	if success:
		echo_shards += banked
		corridor_unlocked = true
	active_run_seed = 0
	save_progress()
	progress_changed.emit()
	return banked


func get_upgrade_cost(upgrade_id: String) -> int:
	var level := int(upgrades.get(upgrade_id, 0))
	var maximum := get_upgrade_max_level(upgrade_id)
	return 0 if level >= maximum else UPGRADE_COSTS[level]


func get_upgrade_max_level(upgrade_id: String) -> int:
	if selected_pathway == "steadfast" and upgrade_id in ["vitality", "recovery"]:
		return 6
	if selected_pathway in ["armorer", "resonant"] and upgrade_id in ["mobility", "weapons"]:
		return 6
	return UPGRADE_MAX_LEVEL


func get_pathway_name() -> String:
	return str(PATHWAY_NAMES.get(selected_pathway, "未锚定"))


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
	var rewards := get_disassembly_rewards(item)
	echo_shards += int(rewards.echo_shards)
	causality_fragments += int(rewards.causality_fragments)
	save_progress()
	progress_changed.emit()
	return true


func get_disassembly_rewards(item: Dictionary) -> Dictionary:
	var rank := int(item.get("quality_rank", 0))
	return {"echo_shards": 2 + rank * 3, "causality_fragments": maxi(rank - 1, 0)}


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "upgrades": upgrades, "last_run": last_run, "selected_loadout": selected_loadout, "corridor_unlocked": corridor_unlocked, "corridor_intro_seen": corridor_intro_seen, "equipment_inventory": equipment_inventory, "equipped": equipped, "active_run_seed": active_run_seed, "last_action_code": last_action_code, "selected_world": selected_world, "player_profile": player_profile, "unlocked_path_nodes": unlocked_path_nodes, "selected_pathway": selected_pathway}))
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
			upgrades[upgrade_id] = clampi(int(saved_upgrades.get(upgrade_id, 0)), 0, UPGRADE_COSTS.size())
	var saved_run = parsed.get("last_run", {})
	last_run = saved_run if saved_run is Dictionary else {}
	var saved_loadout := str(parsed.get("selected_loadout", "scavenger"))
	selected_loadout = saved_loadout if LOADOUTS.has(saved_loadout) else "scavenger"
	corridor_unlocked = bool(parsed.get("corridor_unlocked", not last_run.is_empty() and bool(last_run.get("success", false))))
	corridor_intro_seen = bool(parsed.get("corridor_intro_seen", false))
	active_run_seed = int(parsed.get("active_run_seed", 0))
	last_action_code = str(parsed.get("last_action_code", ""))
	selected_world = str(parsed.get("selected_world", "sanatorium"))
	if selected_world not in ["sanatorium", "metro"]:
		selected_world = "sanatorium"
	var saved_profile = parsed.get("player_profile", {})
	if saved_profile is Dictionary:
		for key in player_profile:
			player_profile[key] = saved_profile.get(key, player_profile[key])
	unlocked_path_nodes.clear()
	for node_id in parsed.get("unlocked_path_nodes", []):
		if PATH_NODES.has(str(node_id)):
			unlocked_path_nodes.append(str(node_id))
	selected_pathway = str(parsed.get("selected_pathway", ""))
	if selected_pathway not in PATHWAY_NAMES:
		selected_pathway = str(PATH_NODES[unlocked_path_nodes[0]].path) if not unlocked_path_nodes.is_empty() else ""
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
	selected_world = "sanatorium"
	player_profile = {"runs": 0, "successful_runs": 0, "metro_runs": 0, "noise_actions": 0, "events_taken": 0, "last_observation": "尚无足够行动数据。"}
	unlocked_path_nodes.clear()
	selected_pathway = ""
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	progress_changed.emit()


func _build_observation(success: bool, enemies_defeated: int, events_resolved: int, run_summary: Dictionary) -> String:
	if not success:
		return "阈值司仪：你在撤离前失去了连接。下一次先确认出口与资源。"
	if int(run_summary.get("noise", 0)) >= 4:
		return "阈值司仪：你以高噪声推进仍完成撤离；检票员已记录你的路线。"
	if events_resolved >= 2:
		return "阈值司仪：你主动触碰异常并带回了结果。风险适应倾向正在形成。"
	if enemies_defeated >= 7:
		return "阈值司仪：你倾向清除威胁再离开。可尝试一次低噪声撤离试炼。"
	return "阈值司仪：你保持了可控的撤离节奏。继续观察你的路线选择。"
