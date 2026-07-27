class_name GameProgress
extends Node

signal progress_changed

const SAVE_VERSION := 23
const MAX_REFLECTION_HISTORY := 24
const UPGRADE_MAX_LEVEL := 3
const MAX_EQUIPMENT := 20
const MAX_MATERIAL_STACK := 999
const MAX_LOOT_HISTORY := 40
const EQUIPMENT_SLOTS := ["weapon_melee", "weapon_ranged", "weapon_shotgun", "charm"]
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
const DIFFICULTIES := {
	"standard": {"name": "标准行动", "description": "推荐首次探索。敌人与掉落保持基准。", "enemy_health": 1.0, "enemy_damage": 1.0, "spawn_bonus": 0, "loot_bonus": 0.0, "boss_drop": 0.18, "reward_multiplier": 1.0},
	"hazard": {"name": "危险行动", "description": "敌人更密集、更强；首领遗物掉率与结算碎片提高。", "enemy_health": 1.28, "enemy_damage": 1.18, "spawn_bonus": 2, "loot_bonus": 0.10, "boss_drop": 0.34, "reward_multiplier": 1.25},
	"nightmare": {"name": "深渊行动", "description": "为熟练玩家准备。敌人高压、精英强化，首领遗物概率最高。", "enemy_health": 1.62, "enemy_damage": 1.36, "spawn_bonus": 4, "loot_bonus": 0.20, "boss_drop": 0.55, "reward_multiplier": 1.55},
}
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
var equipped := {"weapon_melee": "", "weapon_ranged": "", "weapon_shotgun": "", "charm": ""}
var active_run_seed := 0
var last_action_code := ""
var selected_world := "sanatorium"
var selected_difficulty := "standard"
var relic_growth := {}
var player_profile := _default_player_profile()
var unlocked_path_nodes: Array[String] = []
var selected_pathway := ""
var pathway_respec_used := false
var claimed_milestones: Array[String] = []
var pathway_migration_refund := 0
var action_ledger := ActionLedger.new()
var world_state := WorldStateStore.new()
var consequence_engine := ConsequenceEngine.new()
var faction_simulator := FactionSimulator.new()
var humanity_profiler := HumanityProfile.new()
var curator_v2 := CuratorV2.new()
var last_reflection := {}
var reflection_history: Array[Dictionary] = []
var reflection_disputes := {}
var active_counter_contract := {}
var last_save_health := {"status": "new", "loaded_version": 0, "current_version": SAVE_VERSION, "migrations": []}
var persistent_dungeons := PersistentDungeonState.new()
var active_dungeon_chapter := {}
var synthesis_embers := 0
var world_materials := _default_world_materials()
var loot_history: Array[Dictionary] = []
var known_recipes: Array[String] = ["basic_weapon_fusion", "basic_charm_fusion"]
var exchange_cycle := 0
var exchange_purchases: Array[String] = []
var pending_synthesis := {}
var synthesis_counter := 0
var synthesis_pity := {"weapon": 0, "charm": 0}
var equipment_levels := {}
var equipment_affixes := {}
var equipment_evolutions := {}
var equipment_mastery := {}
var unlocked_combat_styles: Array[String] = []
var active_combat_style := ""
var heart_aspect := {}
var player_avatar := "drifter_male"


func _ready() -> void:
	var manager := get_node_or_null("/root/ProfileManager") as LocalProfileManager
	if manager and not manager.active_profile_id.is_empty():
		save_path = manager.active_save_path()
		load_progress()


func get_player_stats() -> Dictionary:
	var gear := EquipmentDatabase.get_bonuses(equipped)
	var path := get_path_bonuses()
	var equipped_items := equipped_item_ids()
	for item_id in equipped_items:
		var relic := EquipmentDatabase.get_item(item_id)
		if not relic.is_empty() and relic.has("series"):
			var level := get_relic_growth(item_id)
			gear.melee_damage += level * 2 if relic.has("melee_damage") else 0
			gear.ranged_damage += level * 2 if relic.has("ranged_damage") else 0
			gear.shotgun_damage += level if relic.has("shotgun_damage") else 0
		var upgraded := EquipmentDatabase.upgraded_bonuses(item_id, int(equipment_levels.get(item_id, 0)))
		for stat in upgraded:
			gear[stat] += upgraded[stat]
	var progression := ExchangeEvolution.combined_bonuses(
		active_combat_style,
		"",
		{},
		heart_aspect,
	)
	for item_id in equipped_items:
		var item_progression := ExchangeEvolution.combined_bonuses(
			"",
			str(equipment_affixes.get(item_id, "")),
			current_equipment_evolution(item_id),
			{},
		)
		for stat in progression:
			progression[stat] += item_progression[stat]
	var relic_profiles := {}
	for attack_type in ["melee", "ranged", "shotgun"]:
		var weapon_id := get_equipped_weapon_for_attack(attack_type)
		relic_profiles[attack_type] = EquipmentDatabase.relic_growth_profile(weapon_id, get_relic_growth(weapon_id))
	var selected_attack_type := str(get_selected_loadout().get("weapon", "melee"))
	var legacy_relic_profile: Dictionary = relic_profiles.get(selected_attack_type, {})
	if legacy_relic_profile.is_empty():
		for attack_type in ["melee", "ranged", "shotgun"]:
			if not relic_profiles[attack_type].is_empty():
				legacy_relic_profile = relic_profiles[attack_type]
				break
	return {
		"max_health": 100 + int(upgrades.vitality) * 10 + int(gear.max_health) + int(path.max_health) + int(progression.max_health),
		"movement_speed": 210.0 + int(upgrades.mobility) * 8.0 + float(gear.movement_speed) + float(path.movement_speed) + float(progression.movement_speed),
		"melee_damage": 35 + int(upgrades.weapons) * 4 + int(gear.melee_damage) + int(path.melee_damage) + int(progression.melee_damage),
		"ranged_damage": 25 + int(upgrades.weapons) * 3 + int(gear.ranged_damage) + int(path.ranged_damage) + int(progression.ranged_damage),
		"shotgun_damage": 28 + int(upgrades.weapons) * 3 + int(gear.shotgun_damage) + int(path.shotgun_damage) + int(progression.shotgun_damage),
		"bandage_heal": 35 + int(upgrades.recovery) * 7 + int(gear.bandage_heal) + int(path.bandage_heal) + int(progression.bandage_heal),
		"attack_range": 76.0 + float(relic_profiles.melee.get("melee_range", 0.0)) + float(progression.attack_range),
		"ranged_range": 430.0 + float(relic_profiles.ranged.get("ranged_range", 0.0)) + float(progression.ranged_range),
		"shotgun_range": 235.0 + float(relic_profiles.shotgun.get("shotgun_range", 0.0)) + float(progression.shotgun_range),
		"relic_profiles": relic_profiles,
		# Kept for older callers while v22 transitions runtime use to typed profiles.
		"relic_profile": legacy_relic_profile,
	}


static func _default_world_materials() -> Dictionary:
	var result := {}
	for material_id in ExchangeEvolution.MATERIALS:
		result[material_id] = 0
	return result


func get_difficulty() -> Dictionary:
	return DIFFICULTIES.get(selected_difficulty, DIFFICULTIES.standard).duplicate(true)


func set_player_avatar(avatar_id: String) -> bool:
	if avatar_id != "drifter_male":
		return false
	player_avatar = avatar_id
	save_progress()
	progress_changed.emit()
	return true


func get_player_avatar_name() -> String:
	return "男性行者"


func set_difficulty(difficulty_id: String) -> bool:
	if not DIFFICULTIES.has(difficulty_id):
		return false
	selected_difficulty = difficulty_id
	save_progress()
	progress_changed.emit()
	return true


func get_relic_growth(item_id: String) -> int:
	return maxi(int(relic_growth.get(item_id, 0)), 0)


func award_boss_growth(world_id: String) -> Dictionary:
	var item_id := EquipmentDatabase.boss_growth_item(world_id)
	if not equipment_inventory.has(item_id):
		return {}
	var item := EquipmentDatabase.get_item(item_id)
	var current := get_relic_growth(item_id)
	var maximum := int(item.get("growth_max", 0))
	if current >= maximum:
		return {}
	relic_growth[item_id] = current + 1
	return {"item_id": item_id, "name": str(item.name), "level": current + 1, "maximum": maximum}


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
	if selected_pathway.is_empty() or causality_fragments < 1:
		return false
	# A respec remains paid but is no longer limited by profile. It must return
	# every resource invested in the
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
	unlocked_combat_styles.clear()
	active_combat_style = ""
	selected_pathway = ""
	# Profession reconstruction is intentionally unlimited.  The one fragment fee
	# keeps it a meaningful preparation choice without trapping a player forever.
	pathway_respec_used = false
	save_progress()
	progress_changed.emit()
	return true


func begin_run(requested_seed := 0) -> int:
	active_run_seed = requested_seed if requested_seed != 0 else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	last_action_code = ("MET" if selected_world == "metro" else "SAN") + "-%08X" % absi(active_run_seed)
	active_dungeon_chapter = persistent_dungeons.begin_visit(selected_world, last_action_code, world_state)
	record_action("run_started", "system", selected_world, "", {"seed": active_run_seed, "difficulty": selected_difficulty})
	record_action("dungeon_chapter_loaded", "system", selected_world, str(active_dungeon_chapter.get("chapter", "")), {
		"visit": int(active_dungeon_chapter.get("visit", 0)),
		"cause": str(active_dungeon_chapter.get("cause", "")),
	})
	save_progress()
	return active_run_seed


func dungeon_chapter(world_id := "") -> Dictionary:
	var target_world := selected_world if world_id.is_empty() else world_id
	if target_world == selected_world and not active_dungeon_chapter.is_empty():
		return active_dungeon_chapter.duplicate(true)
	return persistent_dungeons.chapter_snapshot(target_world, world_state)


func resolve_dungeon_narrative(world_id: String, choice: String) -> Dictionary:
	if selected_world != world_id or last_action_code.is_empty():
		return {}
	var result := persistent_dungeons.resolve_choice(world_id, choice, world_state, last_action_code)
	if not bool(result.get("accepted", false)):
		return result
	var context := {
		"chapter": str(result.get("chapter", "")),
		"hidden_opened": bool(result.get("hidden_opened", false)),
	}
	if str(result.get("event_type", "")) in HumanityProfile.EVENT_WEIGHTS or str(result.get("event_type", "")) == "promise_made":
		var content_choice := _chapter_choice_data(world_id, str(result.get("chapter", "")), choice)
		context.cost_level = int(content_choice.get("cost_level", 1))
		context.anonymous = "anonymous" in str(result.event_type)
		context.public = "public" in str(result.event_type)
		record_human_choice(str(result.event_type), "linye" if world_id == "metro" else "sanatorium_npcs", choice, context, {"summary": str(result.summary)})
	else:
		record_action(str(result.event_type), "player", "linye", choice, context, {"summary": str(result.summary)})
	active_dungeon_chapter = persistent_dungeons.chapter_snapshot(world_id, world_state)
	save_progress()
	progress_changed.emit()
	return result


func resolve_metro_narrative(choice: String) -> Dictionary:
	return resolve_dungeon_narrative("metro", choice)


func dungeon_boss_variant(world_id: String) -> Dictionary:
	return persistent_dungeons.boss_variant(world_id, world_state)


func _chapter_choice_data(world_id: String, chapter_id: String, choice_id: String) -> Dictionary:
	var chapter := ContentCatalog.new().chapter(world_id, chapter_id)
	for choice in chapter.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			return choice.duplicate(true)
	return {}


func dungeon_hidden_open(world_id: String, area_id: String) -> bool:
	return persistent_dungeons.has_opened_area(world_id, area_id)


func dungeon_reward_pool(pool: Array[String]) -> Array[String]:
	return persistent_dungeons.filter_reward_pool(pool)


func record_action(event_type: String, actor := "player", target := "", choice := "", context := {}, result := {}) -> Dictionary:
	if last_action_code.is_empty():
		return {}
	var manager: LocalProfileManager
	if is_inside_tree():
		manager = get_node_or_null("/root/ProfileManager") as LocalProfileManager
	var profile_id := manager.active_profile_id if manager else ""
	var event := action_ledger.record(last_action_code, profile_id, last_action_code, selected_world, event_type, actor, target, choice, context, result)
	if not event.is_empty():
		event.consequences = consequence_engine.apply_event(event, world_state)
	return event


func humanity_reflection() -> Dictionary:
	last_reflection = curator_v2.assess(action_ledger.events, world_state)
	last_reflection.disputes = reflection_disputes.duplicate(true)
	last_reflection.counter_contract = active_counter_contract.duplicate(true)
	return last_reflection.duplicate(true)


func record_human_choice(event_type: String, target := "", choice := "", context := {}, result := {}) -> Dictionary:
	if not HumanityProfile.EVENT_WEIGHTS.has(event_type) and event_type not in ["promise_made", "run_settled"]:
		return {}
	var event := record_action(event_type, "player", target, choice, context, result)
	if not event.is_empty():
		var weapon_id := get_equipped_weapon_for_attack(str(get_selected_loadout().get("weapon", "melee")))
		if event_type in ["costly_rescue", "forgive_rescue", "promise_kept"]:
			record_equipment_use(weapon_id, "rescues", 1)
		if event_type in ["risk_choice", "anonymous_exploitation", "accept_memory"]:
			record_equipment_use(weapon_id, "anomaly_events", 1)
		last_reflection = curator_v2.assess(action_ledger.events, world_state)
	return event


func next_curator_contract() -> Dictionary:
	var assessment := humanity_reflection()
	return curator_v2.offer_contract(assessment, selected_world)


func dispute_reflection(dimension: String) -> Dictionary:
	if not HumanityProfile.DIMENSIONS.has(dimension):
		return {}
	var assessment := humanity_reflection()
	var result: Dictionary = assessment.get("profile", {}).get("dimensions", {}).get(dimension, {})
	if int(result.get("sample_size", 0)) <= 0:
		return {}
	reflection_disputes[dimension] = {
		"at_run": last_action_code,
		"reason": "玩家不同意当前解释",
		"score_at_dispute": int(result.get("score", 0)),
		"confidence_at_dispute": float(result.get("confidence", 0.0)),
	}
	active_counter_contract = curator_v2.offer_counter_contract(assessment, selected_world, dimension)
	last_reflection.disputes = reflection_disputes.duplicate(true)
	last_reflection.counter_contract = active_counter_contract.duplicate(true)
	save_progress()
	progress_changed.emit()
	return active_counter_contract.duplicate(true)


func reflection_timeline() -> Array[Dictionary]:
	return reflection_history.duplicate(true)


func save_health() -> Dictionary:
	return last_save_health.duplicate(true)


func world_briefing() -> Array[String]:
	return faction_simulator.build_briefing(world_state)


func settle_run(success: bool, records: int, carried_shards: int, enemies_defeated: int, events_resolved := 0, equipment_rewards: Array[String] = [], run_summary: Dictionary = {}) -> int:
	var action_code := str(run_summary.get("action_code", last_action_code))
	var settled_codes: Array = player_profile.get("settled_action_codes", [])
	if not action_code.is_empty() and settled_codes.has(action_code):
		return 0
	var difficulty := str(run_summary.get("difficulty", selected_difficulty))
	var difficulty_data: Dictionary = DIFFICULTIES.get(difficulty, DIFFICULTIES.standard)
	var mission_reward := int(round((records * 2 + (3 if success else 0)) * float(difficulty_data.reward_multiplier)))
	var banked := carried_shards + mission_reward if success else 0
	var banked_equipment: Array[String] = []
	var overflow_shards := 0
	if success:
		for item_id in equipment_rewards:
			if EquipmentDatabase.ITEMS.has(item_id):
				if persistent_dungeons.is_unique(item_id) and persistent_dungeons.is_claimed(item_id):
					overflow_shards += 3 + int(EquipmentDatabase.get_item(item_id).quality_rank) * 2
					continue
				if equipment_inventory.size() < MAX_EQUIPMENT:
					equipment_inventory.append(item_id)
					banked_equipment.append(item_id)
					if persistent_dungeons.is_unique(item_id):
						persistent_dungeons.claim_unique(item_id, action_code, str(run_summary.get("world", selected_world)))
				else:
					overflow_shards += 1 + int(EquipmentDatabase.get_item(item_id).quality_rank) * 2
	banked += overflow_shards
	var milestone_rewards := _claim_run_milestones(success, run_summary)
	var trial_rewards := _complete_curator_trial_if_eligible(success, enemies_defeated, events_resolved, run_summary)
	var relic_reward := award_boss_growth(str(run_summary.get("world", ""))) if success and bool(run_summary.get("boss_defeated", false)) else {}
	last_run = {"success": success, "records": records, "carried_shards": carried_shards, "mission_reward": mission_reward if success else 0, "banked_shards": banked, "enemies_defeated": enemies_defeated, "events_resolved": events_resolved, "equipment_rewards": banked_equipment, "overflow_shards": overflow_shards, "milestone_rewards": milestone_rewards, "trial_rewards": trial_rewards, "relic_growth": relic_reward, "difficulty": difficulty, "dynamic_run": run_summary}
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
	if not action_code.is_empty():
		last_action_code = action_code
	var settlement_event := record_action("run_settled", "system", str(run_summary.get("world", selected_world)), "extract" if success else "lost", {"records": records, "events_resolved": events_resolved, "enemies_defeated": enemies_defeated}, {"success": success, "banked_shards": banked})
	last_run.faction_turn = faction_simulator.advance(world_state, str(settlement_event.get("event_id", "")), false)
	last_reflection = curator_v2.assess(action_ledger.events, world_state)
	last_reflection.disputes = reflection_disputes.duplicate(true)
	var counter_resolution := _resolve_counter_contract(action_ledger.events_for_run(action_code))
	if not counter_resolution.is_empty():
		last_run.counter_contract_result = counter_resolution
		active_counter_contract = {}
	last_reflection.counter_contract = active_counter_contract.duplicate(true)
	refresh_heart_aspect()
	last_run.humanity_reflection = last_reflection
	last_run.action_events = action_ledger.events_for_run(action_code)
	last_run.world_consequences = settlement_event.get("consequences", [])
	last_run.dungeon_memory = persistent_dungeons.settle_visit(
		world_id,
		success,
		action_code,
		bool(run_summary.get("boss_defeated", false)),
	)
	last_run.dungeon_history = persistent_dungeons.history_for(world_id).slice(0, 4)
	if success:
		var material_rewards := {}
		var carried_materials: Variant = run_summary.get("material_rewards", {})
		if carried_materials is Dictionary:
			for material_id in carried_materials:
				if ExchangeEvolution.MATERIALS.has(str(material_id)):
					material_rewards[str(material_id)] = maxi(int(carried_materials[material_id]), 0)
		# Every successful extraction includes one common exploration sample.
		# Boss cores are guaranteed, but are added here only for legacy callers
		# that do not yet pass the run's material manifest.
		var extraction := LootDatabase.source_reward(world_id, "extraction")
		for material_id in extraction:
			material_rewards[material_id] = int(material_rewards.get(material_id, 0)) + int(extraction[material_id])
		if bool(run_summary.get("boss_defeated", false)):
			var boss_loot := LootDatabase.boss_reward(world_id)
			var core_id := str(boss_loot.get("material", ""))
			if not core_id.is_empty() and int(material_rewards.get(core_id, 0)) <= 0:
				material_rewards[core_id] = int(boss_loot.get("amount", 1))
		for material_id in material_rewards:
			world_materials[material_id] = mini(int(world_materials.get(material_id, 0)) + int(material_rewards[material_id]), MAX_MATERIAL_STACK)
		last_run.world_materials = material_rewards
		var run_loot: Variant = run_summary.get("loot_log", [])
		if run_loot is Array:
			for entry in run_loot:
				if entry is Dictionary:
					var archived: Dictionary = entry.duplicate(true)
					archived.action_code = action_code
					archived.world = world_id
					loot_history.push_front(archived)
		if loot_history.size() > MAX_LOOT_HISTORY:
			loot_history.resize(MAX_LOOT_HISTORY)
		exchange_cycle += 1
	_append_reflection_snapshot(action_code, world_id, success)
	active_run_seed = 0
	active_dungeon_chapter = {}
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
	var equipment_slot := EquipmentDatabase.equipment_slot(item_id)
	if equipment_slot not in EQUIPMENT_SLOTS:
		return false
	equipped[equipment_slot] = item_id
	save_progress()
	progress_changed.emit()
	return true


func equipped_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in equipped.values():
		var equipped_id := str(item_id)
		if not equipped_id.is_empty() and not result.has(equipped_id):
			result.append(equipped_id)
	return result


func is_item_equipped(item_id: String) -> bool:
	return equipped_item_ids().has(item_id)


func get_equipped_weapon_for_attack(attack_type: String) -> String:
	var exact := str(equipped.get("weapon_%s" % attack_type, ""))
	if not exact.is_empty():
		return exact
	for slot in ["weapon_melee", "weapon_ranged", "weapon_shotgun"]:
		var item_id := str(equipped.get(slot, ""))
		if not item_id.is_empty() and EquipmentDatabase.supports_attack(item_id, attack_type):
			return item_id
	return ""


func disassemble_item(item_id: String) -> bool:
	var index := equipment_inventory.rfind(item_id)
	if index < 0 or (equipped.values().has(item_id) and equipment_inventory.count(item_id) <= 1):
		return false
	var item := EquipmentDatabase.get_item(item_id)
	equipment_inventory.remove_at(index)
	var rewards := get_disassembly_rewards(item)
	echo_shards += int(rewards.echo_shards)
	causality_fragments += int(rewards.causality_fragments)
	synthesis_embers += int(rewards.synthesis_embers)
	save_progress()
	progress_changed.emit()
	return true


func get_disassembly_rewards(item: Dictionary) -> Dictionary:
	var rank := int(item.get("quality_rank", 0))
	return {"echo_shards": 2 + rank * 3, "causality_fragments": maxi(rank - 1, 0), "synthesis_embers": 1 + rank}


func get_exchange_offers() -> Array[Dictionary]:
	return ExchangeEvolution.exchange_offers(exchange_cycle, selected_world)


func purchase_exchange_offer(offer_id: String) -> bool:
	var purchase_key := "%d:%s" % [exchange_cycle, offer_id]
	if exchange_purchases.has(purchase_key):
		return false
	for offer in get_exchange_offers():
		if str(offer.id) != offer_id:
			continue
		var cost := int(offer.echo_cost)
		if echo_shards < cost:
			return false
		if str(offer.kind) == "item" and equipment_inventory.size() >= MAX_EQUIPMENT:
			return false
		echo_shards -= cost
		if str(offer.kind) == "item":
			equipment_inventory.append(str(offer.item_id))
		else:
			var material_id := str(offer.material_id)
			world_materials[material_id] = int(world_materials.get(material_id, 0)) + 1
		exchange_purchases.append(purchase_key)
		save_progress()
		progress_changed.emit()
		return true
	return false


func begin_synthesis(item_ids: Array[String], catalyst_id := "", locked_affix := "") -> Dictionary:
	if not pending_synthesis.is_empty() or item_ids.size() != 3:
		return {}
	var first := EquipmentDatabase.get_item(item_ids[0])
	if first.is_empty() or bool(first.get("unique", false)):
		return {}
	var slot := str(first.get("slot", ""))
	var rank := int(first.get("quality_rank", -1))
	if rank < 0 or rank >= 3:
		return {}
	var required_counts := {}
	for item_id in item_ids:
		var item := EquipmentDatabase.get_item(item_id)
		if item.is_empty() or bool(item.get("unique", false)) or str(item.get("slot", "")) != slot or int(item.get("quality_rank", -1)) != rank:
			return {}
		required_counts[item_id] = int(required_counts.get(item_id, 0)) + 1
	for item_id in required_counts:
		var protected := 1 if equipped.values().has(item_id) else 0
		if equipment_inventory.count(item_id) - protected < int(required_counts[item_id]):
			return {}
	if not catalyst_id.is_empty():
		if not ExchangeEvolution.MATERIALS.has(catalyst_id) or int(world_materials.get(catalyst_id, 0)) <= 0:
			return {}
	if not locked_affix.is_empty():
		if not ExchangeEvolution.AFFIXES.has(locked_affix) or causality_fragments < 1:
			return {}
		causality_fragments -= 1
	for item_id in item_ids:
		equipment_inventory.remove_at(equipment_inventory.rfind(item_id))
	if not catalyst_id.is_empty():
		world_materials[catalyst_id] = int(world_materials[catalyst_id]) - 1
	synthesis_counter += 1
	var seed := active_run_seed + synthesis_counter * 7919 + exchange_cycle * 101
	var candidates := ExchangeEvolution.synthesis_candidates(slot, rank + 1, catalyst_id, seed, int(synthesis_pity.get(slot, 0)))
	if not locked_affix.is_empty():
		for candidate in candidates:
			candidate.affix_id = locked_affix
	pending_synthesis = {"slot": slot, "source_rank": rank, "catalyst": catalyst_id, "candidates": candidates, "seed": seed}
	save_progress()
	progress_changed.emit()
	return pending_synthesis.duplicate(true)


func complete_synthesis(choice_index: int) -> Dictionary:
	var candidates: Array = pending_synthesis.get("candidates", [])
	if choice_index < 0 or choice_index >= candidates.size() or equipment_inventory.size() >= MAX_EQUIPMENT:
		return {}
	var result: Dictionary = candidates[choice_index].duplicate(true)
	var item_id := str(result.item_id)
	equipment_inventory.append(item_id)
	equipment_affixes[item_id] = str(result.affix_id)
	synthesis_pity[str(pending_synthesis.slot)] = 0
	pending_synthesis = {}
	save_progress()
	progress_changed.emit()
	return result


func reject_synthesis() -> int:
	if pending_synthesis.is_empty():
		return 0
	var slot := str(pending_synthesis.slot)
	var gained := 2 + int(pending_synthesis.source_rank)
	synthesis_embers += gained
	synthesis_pity[slot] = mini(int(synthesis_pity.get(slot, 0)) + 1, 3)
	pending_synthesis = {}
	save_progress()
	progress_changed.emit()
	return gained


func equipment_upgrade_cost(item_id: String) -> Dictionary:
	if not equipment_inventory.has(item_id):
		return {}
	var level := clampi(int(equipment_levels.get(item_id, 0)), 0, 5)
	if level >= 5:
		return {}
	var shard_costs := [3, 5, 8, 12, 17]
	return {"echo_shards": shard_costs[level], "synthesis_embers": maxi(level - 1, 0)}


func upgrade_equipment(item_id: String) -> bool:
	var cost := equipment_upgrade_cost(item_id)
	if cost.is_empty() or echo_shards < int(cost.echo_shards) or synthesis_embers < int(cost.synthesis_embers):
		return false
	echo_shards -= int(cost.echo_shards)
	synthesis_embers -= int(cost.synthesis_embers)
	equipment_levels[item_id] = int(equipment_levels.get(item_id, 0)) + 1
	save_progress()
	progress_changed.emit()
	return true


func record_equipment_use(item_id: String, use_type: String, amount := 1) -> void:
	if item_id.is_empty() or not equipment_inventory.has(item_id):
		return
	var mastery: Dictionary = equipment_mastery.get(item_id, {})
	mastery[use_type] = int(mastery.get(use_type, 0)) + maxi(amount, 0)
	equipment_mastery[item_id] = mastery


func available_evolutions(item_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if int(equipment_levels.get(item_id, 0)) < 5 or not ExchangeEvolution.EVOLUTIONS.has(item_id):
		return result
	var mastery: Dictionary = equipment_mastery.get(item_id, {})
	for evolution_id in ExchangeEvolution.EVOLUTIONS[item_id]:
		var evolution: Dictionary = ExchangeEvolution.EVOLUTIONS[item_id][evolution_id].duplicate(true)
		evolution.id = evolution_id
		evolution.available = int(mastery.get(str(evolution.mastery), 0)) >= int(evolution.required)
		evolution.progress = int(mastery.get(str(evolution.mastery), 0))
		result.append(evolution)
	return result


func evolve_equipment(item_id: String, evolution_id: String) -> bool:
	if causality_fragments < 1 or not equipment_inventory.has(item_id):
		return false
	for evolution in available_evolutions(item_id):
		if str(evolution.id) == evolution_id and bool(evolution.available):
			causality_fragments -= 1
			equipment_evolutions[item_id] = evolution_id
			save_progress()
			progress_changed.emit()
			return true
	return false


func current_equipment_evolution(item_id: String) -> Dictionary:
	var evolution_id := str(equipment_evolutions.get(item_id, ""))
	if evolution_id.is_empty() or not ExchangeEvolution.EVOLUTIONS.get(item_id, {}).has(evolution_id):
		return {}
	var result: Dictionary = ExchangeEvolution.EVOLUTIONS[item_id][evolution_id].duplicate(true)
	result.id = evolution_id
	return result


func unlock_combat_style(style_id: String) -> bool:
	if not ExchangeEvolution.COMBAT_STYLES.has(style_id) or unlocked_combat_styles.has(style_id):
		return false
	var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
	if str(style.path) != selected_pathway or not has_path_node(str(style.requires)) or echo_shards < 5:
		return false
	echo_shards -= 5
	unlocked_combat_styles.append(style_id)
	if active_combat_style.is_empty():
		active_combat_style = style_id
	save_progress()
	progress_changed.emit()
	return true


func select_combat_style(style_id: String) -> bool:
	if not unlocked_combat_styles.has(style_id):
		return false
	active_combat_style = style_id
	save_progress()
	progress_changed.emit()
	return true


func refresh_heart_aspect() -> Dictionary:
	var formed := ExchangeEvolution.heart_aspect_for(last_reflection, action_ledger.events)
	if not formed.is_empty():
		heart_aspect = formed
	return heart_aspect.duplicate(true)


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "echo_shards": echo_shards, "causality_fragments": causality_fragments, "synthesis_embers": synthesis_embers, "world_materials": world_materials, "loot_history": loot_history, "known_recipes": known_recipes, "exchange_cycle": exchange_cycle, "exchange_purchases": exchange_purchases, "pending_synthesis": pending_synthesis, "synthesis_counter": synthesis_counter, "synthesis_pity": synthesis_pity, "equipment_levels": equipment_levels, "equipment_affixes": equipment_affixes, "equipment_evolutions": equipment_evolutions, "equipment_mastery": equipment_mastery, "unlocked_combat_styles": unlocked_combat_styles, "active_combat_style": active_combat_style, "heart_aspect": heart_aspect, "player_avatar": player_avatar, "upgrades": upgrades, "last_run": last_run, "selected_loadout": selected_loadout, "corridor_unlocked": corridor_unlocked, "corridor_intro_seen": corridor_intro_seen, "equipment_inventory": equipment_inventory, "equipped": equipped, "active_run_seed": active_run_seed, "last_action_code": last_action_code, "selected_world": selected_world, "selected_difficulty": selected_difficulty, "relic_growth": relic_growth, "player_profile": player_profile, "unlocked_path_nodes": unlocked_path_nodes, "selected_pathway": selected_pathway, "pathway_respec_used": pathway_respec_used, "claimed_milestones": claimed_milestones, "action_ledger": action_ledger.to_dict(), "world_state": world_state.to_dict(), "last_reflection": last_reflection, "reflection_history": reflection_history, "reflection_disputes": reflection_disputes, "active_counter_contract": active_counter_contract, "persistent_dungeons": persistent_dungeons.to_dict(), "active_dungeon_chapter": active_dungeon_chapter}))
	last_save_health = {"status": "saved", "loaded_version": SAVE_VERSION, "current_version": SAVE_VERSION, "migrations": []}
	return true


func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		last_save_health = {"status": "invalid_json", "loaded_version": 0, "current_version": SAVE_VERSION, "migrations": []}
		return
	var loaded_version := maxi(int(parsed.get("version", 0)), 0)
	var migrations: Array[String] = []
	if loaded_version < 19:
		migrations.append("v19：人性镜鉴时间线、异议与反证契约")
	if loaded_version < 20:
		migrations.append("v20：兑换、材料、合成、十二流派、装备进化与心相")
	if loaded_version < 21:
		migrations.append("v21：怪物掉落池、材料背包、唯一藏品与掉落档案")
	if loaded_version < 22:
		migrations.append("v22：近战、精确与重型武器独立装备槽")
	if loaded_version < 23:
		migrations.append("v23：新增可选女性行者外观")
	last_save_health = {"status": "migrated" if loaded_version < SAVE_VERSION else "loaded", "loaded_version": loaded_version, "current_version": SAVE_VERSION, "migrations": migrations}
	action_ledger.load_dict(parsed.get("action_ledger", {}))
	world_state.load_dict(parsed.get("world_state", {}))
	persistent_dungeons.load_dict(parsed.get("persistent_dungeons", {}))
	var saved_reflection: Variant = parsed.get("last_reflection", {})
	last_reflection = saved_reflection.duplicate(true) if saved_reflection is Dictionary else {}
	reflection_history.clear()
	for snapshot in parsed.get("reflection_history", []):
		if snapshot is Dictionary:
			reflection_history.append(snapshot.duplicate(true))
	if reflection_history.size() > MAX_REFLECTION_HISTORY:
		reflection_history.resize(MAX_REFLECTION_HISTORY)
	var saved_disputes: Variant = parsed.get("reflection_disputes", {})
	reflection_disputes = saved_disputes.duplicate(true) if saved_disputes is Dictionary else {}
	var saved_contract: Variant = parsed.get("active_counter_contract", {})
	active_counter_contract = saved_contract.duplicate(true) if saved_contract is Dictionary else {}
	var saved_chapter: Variant = parsed.get("active_dungeon_chapter", {})
	active_dungeon_chapter = saved_chapter.duplicate(true) if saved_chapter is Dictionary else {}
	echo_shards = maxi(int(parsed.get("echo_shards", 0)), 0)
	causality_fragments = maxi(int(parsed.get("causality_fragments", 0)), 0)
	synthesis_embers = maxi(int(parsed.get("synthesis_embers", 0)), 0)
	world_materials = _default_world_materials()
	var saved_materials: Variant = parsed.get("world_materials", {})
	if saved_materials is Dictionary:
		for material_id in world_materials:
			world_materials[material_id] = clampi(int(saved_materials.get(material_id, 0)), 0, MAX_MATERIAL_STACK)
	loot_history.clear()
	for entry in parsed.get("loot_history", []):
		if entry is Dictionary:
			loot_history.append(entry.duplicate(true))
	if loot_history.size() > MAX_LOOT_HISTORY:
		loot_history.resize(MAX_LOOT_HISTORY)
	known_recipes.assign([])
	for recipe_id in parsed.get("known_recipes", ["basic_weapon_fusion", "basic_charm_fusion"]):
		known_recipes.append(str(recipe_id))
	exchange_cycle = maxi(int(parsed.get("exchange_cycle", 0)), 0)
	exchange_purchases.assign([])
	for purchase_id in parsed.get("exchange_purchases", []):
		exchange_purchases.append(str(purchase_id))
	var saved_pending: Variant = parsed.get("pending_synthesis", {})
	pending_synthesis = saved_pending.duplicate(true) if saved_pending is Dictionary else {}
	synthesis_counter = maxi(int(parsed.get("synthesis_counter", 0)), 0)
	var saved_pity: Variant = parsed.get("synthesis_pity", {})
	synthesis_pity = saved_pity.duplicate(true) if saved_pity is Dictionary else {"weapon": 0, "charm": 0}
	for field in ["equipment_levels", "equipment_affixes", "equipment_evolutions", "equipment_mastery"]:
		var source: Variant = parsed.get(field, {})
		set(field, source.duplicate(true) if source is Dictionary else {})
	unlocked_combat_styles.assign([])
	for style_id in parsed.get("unlocked_combat_styles", []):
		if ExchangeEvolution.COMBAT_STYLES.has(str(style_id)):
			unlocked_combat_styles.append(str(style_id))
	active_combat_style = str(parsed.get("active_combat_style", ""))
	if not unlocked_combat_styles.has(active_combat_style):
		active_combat_style = ""
	# The former female rig prototype used invalid perspective data. Existing saves
	# are deliberately migrated back to the stable original drifter.
	player_avatar = "drifter_male"
	var saved_heart: Variant = parsed.get("heart_aspect", {})
	heart_aspect = saved_heart.duplicate(true) if saved_heart is Dictionary else {}
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
	selected_difficulty = str(parsed.get("selected_difficulty", "standard"))
	if not DIFFICULTIES.has(selected_difficulty):
		selected_difficulty = "standard"
	var saved_relic_growth: Variant = parsed.get("relic_growth", {})
	relic_growth = saved_relic_growth.duplicate(true) if saved_relic_growth is Dictionary else {}
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
	var valid_styles: Array[String] = []
	for style_id in unlocked_combat_styles:
		if str(ExchangeEvolution.COMBAT_STYLES[style_id].path) == selected_pathway:
			valid_styles.append(style_id)
	unlocked_combat_styles.assign(valid_styles)
	if not unlocked_combat_styles.has(active_combat_style):
		active_combat_style = ""
	equipment_inventory.clear()
	for item_id in parsed.get("equipment_inventory", ["service_crowbar", "medical_tag"]):
		if EquipmentDatabase.ITEMS.has(str(item_id)):
			equipment_inventory.append(str(item_id))
	if equipment_inventory.is_empty():
		equipment_inventory.assign(["service_crowbar", "medical_tag"])
	persistent_dungeons.reconcile_inventory(equipment_inventory)
	var saved_equipped = parsed.get("equipped", {})
	equipped = {"weapon_melee": "", "weapon_ranged": "", "weapon_shotgun": "", "charm": ""}
	if saved_equipped is Dictionary:
		var legacy_weapon := str(saved_equipped.get("weapon", ""))
		if equipment_inventory.has(legacy_weapon):
			var migrated_slot := EquipmentDatabase.equipment_slot(legacy_weapon)
			if migrated_slot in EQUIPMENT_SLOTS:
				equipped[migrated_slot] = legacy_weapon
		for slot in EQUIPMENT_SLOTS:
			var item_id := str(saved_equipped.get(slot, ""))
			if equipment_inventory.has(item_id) and EquipmentDatabase.equipment_slot(item_id) == slot:
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
	equipped = {"weapon_melee": "", "weapon_ranged": "", "weapon_shotgun": "", "charm": ""}
	active_run_seed = 0
	last_action_code = ""
	selected_world = "sanatorium"
	active_dungeon_chapter = {}
	persistent_dungeons.reset()
	action_ledger.clear()
	world_state.reset()
	selected_difficulty = "standard"
	relic_growth = {}
	player_profile = _default_player_profile()
	unlocked_path_nodes.clear()
	selected_pathway = ""
	pathway_respec_used = false
	claimed_milestones.clear()
	pathway_migration_refund = 0
	last_reflection = {}
	reflection_history.clear()
	reflection_disputes = {}
	active_counter_contract = {}
	synthesis_embers = 0
	world_materials = _default_world_materials()
	loot_history.clear()
	known_recipes.assign(["basic_weapon_fusion", "basic_charm_fusion"])
	exchange_cycle = 0
	exchange_purchases.clear()
	pending_synthesis = {}
	synthesis_counter = 0
	synthesis_pity = {"weapon": 0, "charm": 0}
	equipment_levels = {}
	equipment_affixes = {}
	equipment_evolutions = {}
	equipment_mastery = {}
	unlocked_combat_styles.clear()
	active_combat_style = ""
	heart_aspect = {}
	player_avatar = "drifter_male"
	last_save_health = {"status": "new", "loaded_version": 0, "current_version": SAVE_VERSION, "migrations": []}


func _append_reflection_snapshot(action_code: String, world_id: String, success: bool) -> void:
	var dimensions: Dictionary = last_reflection.get("profile", {}).get("dimensions", {})
	var compact := {}
	for dimension in dimensions:
		var result: Dictionary = dimensions[dimension]
		compact[dimension] = {
			"score": int(result.get("score", 0)),
			"confidence": float(result.get("confidence", 0.0)),
			"sample_size": int(result.get("sample_size", 0)),
			"pole": str(result.get("pole", "")),
		}
	reflection_history.push_front({
		"action_code": action_code,
		"world_id": world_id,
		"success": success,
		"dimensions": compact,
		"echo": last_reflection.get("echo", {}).duplicate(true),
		"prediction": last_reflection.get("prediction", {}).duplicate(true),
	})
	if reflection_history.size() > MAX_REFLECTION_HISTORY:
		reflection_history.resize(MAX_REFLECTION_HISTORY)


func _resolve_counter_contract(run_events: Array[Dictionary]) -> Dictionary:
	if active_counter_contract.is_empty():
		return {}
	var expected := str(active_counter_contract.get("success_event", ""))
	var matched := run_events.any(func(event): return str(event.get("event_type", "")) == expected)
	var result := {
		"contract_id": str(active_counter_contract.get("id", "")),
		"dimension": str(active_counter_contract.get("dimension", "")),
		"resolved": true,
		"contradicted": matched,
		"expected_event": expected,
		"summary": "你用实际行动提供了反证；司仪将降低旧解释的确定性。" if matched else "本局没有出现足以反驳旧解释的行为。",
	}
	if matched:
		causality_fragments += int(active_counter_contract.get("reward", 2))
		var dimension := str(active_counter_contract.get("dimension", ""))
		if reflection_disputes.has(dimension):
			reflection_disputes[dimension].resolved = true
			reflection_disputes[dimension].resolved_run = last_action_code
	return result


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
