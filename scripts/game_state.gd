class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 14
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
	"steadfast_barrier": {"path": "steadfast", "name": "坚守者：应急屏障", "cost": 3, "fragment_cost": 1, "requires": "steadfast_mender", "description": "低生命治疗后获得 4 秒减伤"},
	"armorer_calibration": {"path": "armorer", "name": "武装师：校准", "cost": 5, "description": "全部武器伤害 +3 · 解锁武器/机动 Lv.4–6"},
	"armorer_mobility": {"path": "armorer", "name": "武装师：机动装填", "cost": 8, "requires": "armorer_calibration", "description": "移动速度 +10 · 手枪伤害 +2"},
	"armorer_alternation": {"path": "armorer", "name": "武装师：交替校准", "cost": 3, "fragment_cost": 1, "requires": "armorer_mobility", "description": "切换武器后下一击 +20%"},
	"resonant_sense": {"path": "resonant", "name": "共鸣者：余响感知", "cost": 5, "description": "移动速度 +8 · 生命上限 -3 · 解锁机动/武器 Lv.4–6"},
	"resonant_bargain": {"path": "resonant", "name": "共鸣者：代价交换", "cost": 8, "requires": "resonant_sense", "description": "全部武器伤害 +5 · 生命上限 -6"},
	"resonant_ingestion": {"path": "resonant", "name": "共鸣者：异常摄取", "cost": 3, "fragment_cost": 1, "requires": "resonant_bargain", "description": "高风险事件 +2 碎片并累积异化"},
}
const PATHWAY_NAMES := {"steadfast": "坚守者", "armorer": "武装师", "resonant": "共鸣者"}
const CURATOR_TRIALS := {
	"sanatorium_restraint": {"world": "sanatorium", "kind": "world", "title": "病区克制", "description": "在废弃疗养院清除不超过 4 个威胁并成功撤离。", "rule_text": "司仪会标记非必要交战；完成后获得因果残片。", "reward": 1, "effects": {"restraint": true}},
	"sanatorium_director": {"world": "sanatorium", "kind": "world", "title": "终止主任", "description": "击败缝合主任并从废弃疗养院成功撤离。", "rule_text": "主任被标记为裁决目标；撤离条件不改变。", "reward": 1, "effects": {"boss_mark": true}},
	"metro_quiet": {"world": "metro", "kind": "behavior", "title": "静默末班", "description": "在潮没末班线以噪音不高于 3 成功撤离。", "rule_text": "潮位第一次上升延后 15 秒；噪音超标则契约失效。", "reward": 1, "effects": {"tide_delay": 15.0}},
	"metro_recovery": {"world": "metro", "kind": "behavior", "title": "错时补救", "description": "错过首班车后仍从潮没末班线成功撤离。", "rule_text": "备用车次额外停靠 15 秒；必须承受一次错过车次的压力。", "reward": 1, "effects": {"recovery_window_bonus": 15.0}},
	"metro_reverse_tide": {"world": "metro", "kind": "risk", "title": "逆潮通行", "description": "潮位提前抵达；开启应急水闸后，在排水期间通过中央低层并撤离。", "rule_text": "潮位提前 15 秒；水闸排水延长 16 秒，形成高风险捷径。", "reward": 2, "effects": {"tide_advance": 15.0, "floodgate_bonus": 16.0, "requires_floodgate": true}},
	"metro_zero_priority": {"world": "metro", "kind": "world", "title": "零号优先级", "description": "在零号道岔行动中无错序完成校准并撤离。", "rule_text": "仅零号道岔任务可完成；正确改线后中央高架额外维持 18 秒。", "reward": 2, "effects": {"zero_route_bonus": 18.0, "requires_zero_clean": true}},
	"risk_control": {"world": "any", "kind": "behavior", "title": "可控异常", "description": "解决至少 2 个风险事件并成功撤离。", "rule_text": "风险事件会被归档为可读线索；完成后获得因果残片。", "reward": 1, "effects": {"risk_archive": true}},
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
var selected_world := "sanatorium"
var player_profile := _default_player_profile()
var unlocked_path_nodes: Array[String] = []
var selected_pathway := ""
var pathway_respec_used := false
var claimed_milestones: Array[String] = []
var pathway_migration_refund := 0


func _ready() -> void:
	var manager := get_node_or_null("/root/ProfileManager") as LocalProfileManager
	if manager and not manager.active_profile_id.is_empty():
		save_path = manager.active_save_path()
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


static func _default_player_profile() -> Dictionary:
	# Keep reward claims separate from display history: malformed legacy saves
	# must never turn a paid trial into another fragment source.
	return {"runs": 0, "successful_runs": 0, "metro_runs": 0, "quiet_successes": 0, "noise_actions": 0, "events_taken": 0, "threats_cleared": 0, "north_routes": 0, "south_routes": 0, "missed_trains": 0, "whistle_uses": 0, "pathway_stats": {}, "last_observation": "尚无足够行动数据。", "recent_runs": [], "active_trial": "", "dismissed_trials": [], "completed_trials": [], "trial_reward_claims": [], "settled_action_codes": []}


func has_equipment_trait(trait_id: String) -> bool:
	return EquipmentDatabase.has_trait(equipped, trait_id)


func has_path_node(node_id: String) -> bool:
	return unlocked_path_nodes.has(node_id)


func get_curator_trial() -> Dictionary:
	var active := str(player_profile.get("active_trial", ""))
	if not CURATOR_TRIALS.has(active):
		return {}
	var trial: Dictionary = CURATOR_TRIALS[active].duplicate(true)
	trial.id = active
	trial.reward_text = "%d 因果残片" % int(trial.reward)
	return trial


func get_curator_contract_offers(world := "") -> Array[Dictionary]:
	if not str(player_profile.get("active_trial", "")).is_empty():
		return []
	var preferred_world := selected_world if world.is_empty() else world
	var dismissed: Array = player_profile.get("dismissed_trials", [])
	var completed: Array = player_profile.get("completed_trials", [])
	var claimed: Array = player_profile.get("trial_reward_claims", [])
	var candidates: Array[String] = []
	for trial_id in CURATOR_TRIALS:
		var trial: Dictionary = CURATOR_TRIALS[trial_id]
		if str(trial.world) in [preferred_world, "any"] and not completed.has(trial_id) and not claimed.has(trial_id) and not dismissed.has(trial_id):
			candidates.append(trial_id)
	candidates.sort_custom(func(a, b): return _contract_priority(a, preferred_world) > _contract_priority(b, preferred_world))
	var offers: Array[Dictionary] = []
	# The curator always presents a readable choice set: one world rule, one
	# behavior response, and one voluntary high-risk rule whenever available.
	for kind in ["world", "behavior", "risk"]:
		for trial_id in candidates:
			if str(CURATOR_TRIALS[trial_id].get("kind", "behavior")) == kind:
				var typed_offer: Dictionary = CURATOR_TRIALS[trial_id].duplicate(true)
				typed_offer.id = trial_id
				typed_offer.reward_text = "%d 因果残片" % int(typed_offer.reward)
				offers.append(typed_offer)
				break
	for trial_id in candidates:
		if offers.size() >= 3 or offers.any(func(offer): return str(offer.id) == trial_id):
			continue
		var offer: Dictionary = CURATOR_TRIALS[trial_id].duplicate(true)
		offer.id = trial_id
		offer.reward_text = "%d 因果残片" % int(offer.reward)
		offers.append(offer)
	return offers


func choose_curator_contract(trial_id: String) -> bool:
	if not str(player_profile.get("active_trial", "")).is_empty() or not CURATOR_TRIALS.has(trial_id):
		return false
	for offer in get_curator_contract_offers():
		if str(offer.id) == trial_id:
			player_profile.active_trial = trial_id
			save_progress()
			progress_changed.emit()
			return true
	return false


func get_active_contract_effects() -> Dictionary:
	var trial := get_curator_trial()
	return trial.get("effects", {}).duplicate(true) if not trial.is_empty() else {}


func get_growth_plan() -> Array[String]:
	if selected_pathway == "steadfast":
		return ["稳固：完成一次低噪声撤离", "缝合：保留绷带完成高压行动", "屏障：在低生命状态成功撤离"]
	if selected_pathway == "armorer":
		return ["校准：完成一局远程主导行动", "机动：在站台追击中保持移动", "交替：切换武器后解决关键威胁"]
	if selected_pathway == "resonant":
		return ["感知：探索未标记区域", "代价：完成一次高风险事件", "摄取：携带异常装备完成撤离"]
	return ["生存：完成一次可控撤离", "武器：尝试不同整备配置", "异常：在可读风险中作出选择"]


func _contract_priority(trial_id: String, world: String) -> int:
	var trial: Dictionary = CURATOR_TRIALS[trial_id]
	var priority := 10 if str(trial.world) == world else 1
	if trial_id == "metro_quiet" and int(player_profile.get("noise_actions", 0)) >= 4:
		priority += 30
	if trial_id == "risk_control" and int(player_profile.get("events_taken", 0)) > 0:
		priority += 20
	if trial_id == "metro_recovery" and int(player_profile.get("missed_trains", 0)) > 0:
		priority += 20
	if trial_id == "metro_zero_priority" and int(player_profile.get("metro_runs", 0)) > 0:
		priority += 15
	return priority


func accept_curator_trial() -> bool:
	# Compatibility path for older UI/tests: choose the highest-priority offer.
	# New UI always calls choose_curator_contract with the player's explicit card.
	var offers := get_curator_contract_offers()
	if offers.is_empty():
		return false
	var chosen: Dictionary = offers[0]
	for offer in offers:
		if _contract_priority(str(offer.id), selected_world) > _contract_priority(str(chosen.id), selected_world):
			chosen = offer
	return choose_curator_contract(str(chosen.id))


func dismiss_curator_trial() -> bool:
	var active := str(player_profile.get("active_trial", ""))
	if active.is_empty():
		return false
	var dismissed: Array = player_profile.get("dismissed_trials", [])
	if not dismissed.has(active):
		dismissed.append(active)
	player_profile.dismissed_trials = dismissed
	player_profile.active_trial = ""
	save_progress()
	progress_changed.emit()
	return true


func reset_curator_profile() -> void:
	var completed: Array = player_profile.get("completed_trials", []).duplicate()
	var claimed: Array = player_profile.get("trial_reward_claims", []).duplicate()
	var settled: Array = player_profile.get("settled_action_codes", []).duplicate()
	var dismissed: Array = player_profile.get("dismissed_trials", []).duplicate()
	var active := str(player_profile.get("active_trial", ""))
	player_profile = _default_player_profile()
	player_profile.completed_trials = completed
	player_profile.trial_reward_claims = claimed
	player_profile.settled_action_codes = settled
	player_profile.dismissed_trials = dismissed
	player_profile.active_trial = active
	save_progress()
	progress_changed.emit()


func curator_evidence() -> Array[String]:
	var evidence: Array[String] = []
	var recent: Array = player_profile.get("recent_runs", [])
	var noisy := recent.filter(func(run): return int(run.get("noise", 0)) >= 4).size()
	if noisy > 0:
		evidence.append("最近 %d 局中有 %d 局属于高噪音行动" % [recent.size(), noisy])
	if int(player_profile.get("missed_trains", 0)) > 0:
		evidence.append("累计错过车次 %d 次" % int(player_profile.missed_trains))
	if int(player_profile.get("events_taken", 0)) > 0:
		evidence.append("已处理风险事件 %d 次" % int(player_profile.events_taken))
	if evidence.is_empty():
		evidence.append("行动样本不足，建议继续完成一次撤离")
	return evidence


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
	var fragment_cost := int(node.get("fragment_cost", 0)) + anchor_fragment_cost
	if echo_shards < int(node.cost) + anchor_echo_cost or causality_fragments < fragment_cost:
		return false
	echo_shards -= int(node.cost) + anchor_echo_cost
	causality_fragments -= fragment_cost
	if selected_pathway.is_empty():
		selected_pathway = path_id
	unlocked_path_nodes.append(node_id)
	save_progress()
	progress_changed.emit()
	return true


func respec_pathway() -> bool:
	if pathway_respec_used or selected_pathway.is_empty() or causality_fragments < 1:
		return false
	# A respec is intentionally limited to once per profile and still costs one
	# causality fragment. It must, however, return every resource invested in the
	# pathway: the initial anchor, each node's shards, and node fragment costs.
	# Returning only half the shard cost made changing profession permanently
	# punitive and silently destroyed the anchor/material investment.
	var shard_refund := int(PATHWAY_ANCHOR_COST.echo_shards)
	var fragment_refund := int(PATHWAY_ANCHOR_COST.causality_fragments)
	for node_id in unlocked_path_nodes:
		if not PATH_NODES.has(node_id):
			continue
		var node: Dictionary = PATH_NODES[node_id]
		shard_refund += int(node.get("cost", 0))
		fragment_refund += int(node.get("fragment_cost", 0))
	causality_fragments -= 1
	echo_shards += shard_refund
	causality_fragments += fragment_refund
	unlocked_path_nodes.clear()
	selected_pathway = ""
	pathway_respec_used = true
	save_progress()
	progress_changed.emit()
	return true


func begin_run(requested_seed := 0) -> int:
	active_run_seed = requested_seed if requested_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	last_action_code = ("MET" if selected_world == "metro" else "SAN") + "-%08X" % absi(active_run_seed)
	save_progress()
	return active_run_seed


func settle_run(success: bool, records: int, carried_shards: int, enemies_defeated: int, events_resolved := 0, equipment_rewards: Array[String] = [], run_summary: Dictionary = {}) -> int:
	var action_code := str(run_summary.get("action_code", ""))
	var settled_codes: Array = player_profile.get("settled_action_codes", [])
	if not action_code.is_empty() and settled_codes.has(action_code):
		return 0
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
	var milestone_rewards := _claim_run_milestones(success, run_summary)
	var trial_rewards := _complete_curator_trial_if_eligible(success, enemies_defeated, events_resolved, run_summary)
	last_run = {"success": success, "records": records, "carried_shards": carried_shards, "mission_reward": mission_reward if success else 0, "banked_shards": banked, "enemies_defeated": enemies_defeated, "events_resolved": events_resolved, "equipment_rewards": banked_equipment, "overflow_shards": overflow_shards, "milestone_rewards": milestone_rewards, "trial_rewards": trial_rewards, "dynamic_run": run_summary}
	player_profile.runs = int(player_profile.get("runs", 0)) + 1
	player_profile.successful_runs = int(player_profile.get("successful_runs", 0)) + (1 if success else 0)
	player_profile.metro_runs = int(player_profile.get("metro_runs", 0)) + (1 if str(run_summary.get("world", "")) == "metro" else 0)
	player_profile.noise_actions = int(player_profile.get("noise_actions", 0)) + int(run_summary.get("noise", 0))
	player_profile.events_taken = int(player_profile.get("events_taken", 0)) + events_resolved
	player_profile.threats_cleared = int(player_profile.get("threats_cleared", 0)) + enemies_defeated
	var route := str(run_summary.get("metro_route", ""))
	if route == "north": player_profile.north_routes = int(player_profile.get("north_routes", 0)) + 1
	if route == "south": player_profile.south_routes = int(player_profile.get("south_routes", 0)) + 1
	player_profile.missed_trains = int(player_profile.get("missed_trains", 0)) + (1 if bool(run_summary.get("missed_train", false)) else 0)
	player_profile.whistle_uses = int(player_profile.get("whistle_uses", 0)) + int(run_summary.get("whistle_uses", 0))
	var pathway_id := selected_pathway if not selected_pathway.is_empty() else "unbound"
	var pathway_stats: Dictionary = player_profile.get("pathway_stats", {})
	var world_id := str(run_summary.get("world", "sanatorium"))
	var key := "%s:%s" % [pathway_id, world_id]
	var stats: Dictionary = pathway_stats.get(key, {"runs": 0, "successes": 0, "duration": 0.0, "shards": 0})
	stats.runs = int(stats.runs) + 1
	stats.successes = int(stats.successes) + (1 if success else 0)
	stats.duration = float(stats.duration) + float(run_summary.get("duration", 0.0))
	stats.shards = int(stats.shards) + carried_shards
	pathway_stats[key] = stats
	player_profile.pathway_stats = pathway_stats
	if success and int(run_summary.get("noise", 0)) <= 3:
		player_profile.quiet_successes = int(player_profile.get("quiet_successes", 0)) + 1
	player_profile.last_observation = _build_observation(success, enemies_defeated, events_resolved, run_summary)
	var recent: Array = player_profile.get("recent_runs", [])
	recent.push_front({"world": str(run_summary.get("world", "sanatorium")), "success": success, "noise": int(run_summary.get("noise", 0)), "events": events_resolved, "threats": enemies_defeated, "route": route, "missed_train": bool(run_summary.get("missed_train", false)), "action_code": str(run_summary.get("action_code", ""))})
	if recent.size() > 5:
		recent.resize(5)
	player_profile.recent_runs = recent
	if success:
		echo_shards += banked
		corridor_unlocked = true
	if not action_code.is_empty():
		settled_codes.append(action_code)
		if settled_codes.size() > 32:
			settled_codes = settled_codes.slice(settled_codes.size() - 32)
		player_profile.settled_action_codes = settled_codes
	active_run_seed = 0
	save_progress()
	progress_changed.emit()
	return banked


func _claim_run_milestones(success: bool, run_summary: Dictionary) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	if not success:
		return rewards
	var world := str(run_summary.get("world", "sanatorium"))
	if world == "metro":
		_claim_milestone("first_metro_clear", "首次完成潮没末班线", 2, rewards)
		if bool(run_summary.get("boss_defeated", false)):
			_claim_milestone("first_last_train_defeat", "首次击败末班列车", 1, rewards)
	else:
		_claim_milestone("first_sanatorium_clear", "首次完成废弃疗养院", 1, rewards)
		if bool(run_summary.get("boss_defeated", false)):
			_claim_milestone("first_sanatorium_boss", "首次击败缝合主任", 1, rewards)
	return rewards


func _claim_milestone(id: String, title: String, amount: int, rewards: Array[Dictionary]) -> void:
	if claimed_milestones.has(id):
		return
	claimed_milestones.append(id)
	causality_fragments += amount
	rewards.append({"id": id, "title": title, "causality_fragments": amount})


func _complete_curator_trial_if_eligible(success: bool, enemies_defeated: int, events_resolved: int, run_summary: Dictionary) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var trial := str(player_profile.get("active_trial", ""))
	if not success or not CURATOR_TRIALS.has(trial):
		return rewards
	var world := str(run_summary.get("world", "sanatorium"))
	var completed := false
	match trial:
		"sanatorium_restraint": completed = world == "sanatorium" and enemies_defeated <= 4
		"sanatorium_director": completed = world == "sanatorium" and bool(run_summary.get("boss_defeated", false))
		"metro_quiet": completed = world == "metro" and int(run_summary.get("noise", 0)) <= 3
		"metro_recovery": completed = world == "metro" and bool(run_summary.get("missed_train", false))
		"metro_reverse_tide": completed = world == "metro" and bool(run_summary.get("curator_floodgate_used", false))
		"metro_zero_priority": completed = world == "metro" and str(run_summary.get("mission_id", "")) == "switch_zero" and int(run_summary.get("switch_failures", 0)) == 0
		"risk_control": completed = events_resolved >= 2
	if not completed:
		return rewards
	var completed_trials: Array = player_profile.get("completed_trials", [])
	var claimed: Array = player_profile.get("trial_reward_claims", [])
	if not claimed.has(trial):
		if not completed_trials.has(trial):
			completed_trials.append(trial)
		claimed.append(trial)
		var amount := int(CURATOR_TRIALS[trial].reward)
		causality_fragments += amount
		rewards.append({"id": trial, "title": str(CURATOR_TRIALS[trial].title), "causality_fragments": amount})
	player_profile.completed_trials = completed_trials
	player_profile.trial_reward_claims = claimed
	player_profile.active_trial = ""
	return rewards


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
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "upgrades": upgrades, "last_run": last_run, "selected_loadout": selected_loadout, "corridor_unlocked": corridor_unlocked, "corridor_intro_seen": corridor_intro_seen, "equipment_inventory": equipment_inventory, "equipped": equipped, "active_run_seed": active_run_seed, "last_action_code": last_action_code, "selected_world": selected_world, "player_profile": player_profile, "unlocked_path_nodes": unlocked_path_nodes, "selected_pathway": selected_pathway, "pathway_respec_used": pathway_respec_used, "claimed_milestones": claimed_milestones}))
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
	_migrate_curator_trials()
	unlocked_path_nodes.clear()
	for node_id in parsed.get("unlocked_path_nodes", []):
		if PATH_NODES.has(str(node_id)):
			unlocked_path_nodes.append(str(node_id))
	selected_pathway = str(parsed.get("selected_pathway", ""))
	pathway_respec_used = bool(parsed.get("pathway_respec_used", false))
	claimed_milestones.clear()
	for milestone_id in parsed.get("claimed_milestones", []):
		claimed_milestones.append(str(milestone_id))
	if selected_pathway not in PATHWAY_NAMES:
		selected_pathway = str(PATH_NODES[unlocked_path_nodes[0]].path) if not unlocked_path_nodes.is_empty() else ""
	_sanitize_pathway_nodes()
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
	_clear_runtime_progress()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	progress_changed.emit()


func activate_profile(profile_save_path: String) -> bool:
	if profile_save_path.is_empty():
		return false
	_clear_runtime_progress()
	save_path = profile_save_path
	load_progress()
	progress_changed.emit()
	return true


func _clear_runtime_progress() -> void:
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
	player_profile = _default_player_profile()
	unlocked_path_nodes.clear()
	selected_pathway = ""
	pathway_respec_used = false
	claimed_milestones.clear()
	pathway_migration_refund = 0


func _sanitize_pathway_nodes() -> void:
	pathway_migration_refund = 0
	if selected_pathway.is_empty():
		return
	var valid_nodes: Array[String] = []
	for node_id in unlocked_path_nodes:
		if str(PATH_NODES[node_id].path) == selected_pathway:
			valid_nodes.append(node_id)
		else:
			pathway_migration_refund += int(PATH_NODES[node_id].cost)
	if pathway_migration_refund > 0:
		echo_shards += pathway_migration_refund
		unlocked_path_nodes.assign(valid_nodes)


func _migrate_curator_trials() -> void:
	if str(player_profile.get("active_trial", "")) == "quiet_extraction":
		player_profile.active_trial = "metro_quiet"
	elif not str(player_profile.get("active_trial", "")).is_empty() and not CURATOR_TRIALS.has(str(player_profile.active_trial)):
		player_profile.active_trial = ""
	var completed: Array = player_profile.get("completed_trials", [])
	if completed.has("quiet_extraction"):
		completed.erase("quiet_extraction")
		if not completed.has("metro_quiet"):
			completed.append("metro_quiet")
	player_profile.completed_trials = completed
	var claimed: Array = player_profile.get("trial_reward_claims", [])
	for trial_id in completed:
		if CURATOR_TRIALS.has(str(trial_id)) and not claimed.has(trial_id):
			claimed.append(trial_id)
	player_profile.trial_reward_claims = claimed
	var settled: Array = player_profile.get("settled_action_codes", [])
	if settled.size() > 32:
		settled = settled.slice(settled.size() - 32)
	player_profile.settled_action_codes = settled


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
