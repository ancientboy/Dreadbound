class_name ExchangeEvolution
extends RefCounted

const MATERIALS := {
	"tissue_sample": {"name": "组织样本", "world": "sanatorium", "rarity": "常见", "category": "生体", "source": "病患、爬行者、撤离勘探", "use": "疗养院装备合成与低阶强化"},
	"medical_record": {"name": "病历残页", "world": "sanatorium", "rarity": "稀有", "category": "档案", "source": "护理员、隐藏档案室", "use": "治疗/感知词条与定向进化"},
	"stitch_core": {"name": "缝合核心", "world": "sanatorium", "rarity": "首领", "category": "进化核心", "source": "缝合主任", "use": "缝合遗物进化与高阶配方"},
	"flooded_circuit": {"name": "浸水电路", "world": "metro", "rarity": "常见", "category": "机械", "source": "溺行者、危险个体、撤离勘探", "use": "末班线装备合成与低阶强化"},
	"ticket_stub": {"name": "失效票根", "world": "metro", "rarity": "稀有", "category": "因果凭证", "source": "检票员、隐藏维护层", "use": "路线/弱点词条与定向进化"},
	"conductor_coil": {"name": "车长线圈", "world": "metro", "rarity": "首领", "category": "进化核心", "source": "车长回声", "use": "末班遗物进化与高阶配方"},
}

const AFFIXES := {
	"guardian": {"name": "守望", "tag": "guard", "max_health": 6},
	"last_round": {"name": "最后一弹", "tag": "weakpoint", "ranged_damage": 4},
	"suppression": {"name": "压制", "tag": "heavy", "shotgun_damage": 4},
	"volatile": {"name": "失控", "tag": "anomaly", "melee_damage": 4, "max_health": -3},
	"perception": {"name": "觅隙", "tag": "sense", "movement_speed": 4.0},
	"restoration": {"name": "缝合", "tag": "healing", "bandage_heal": 5},
}

const COMBAT_STYLES := {
	"barrier_counter": {"path": "steadfast", "name": "屏障反击", "requires": "steadfast_barrier", "description": "应急屏障持续更久，并提高近战反击。", "weapon_type": "melee", "skill": {"name": "壁垒震返", "shape": "self", "range": 118.0, "radius": 118.0, "damage_multiplier": 1.45, "cooldown": 7.0}, "bonuses": {"max_health": 6, "melee_damage": 3}},
	"last_stand": {"path": "steadfast", "name": "濒死不灭", "requires": "steadfast_barrier", "description": "低生命时获得额外减伤。", "weapon_type": "shotgun", "skill": {"name": "余命轰鸣", "shape": "cone", "range": 255.0, "radius": 0.0, "damage_multiplier": 1.55, "cooldown": 9.0}, "bonuses": {"max_health": 10}},
	"sacrifice_medic": {"path": "steadfast", "name": "牺牲治疗", "requires": "steadfast_barrier", "description": "强化治疗与救援，但降低个人火力。", "weapon_type": "ranged", "skill": {"name": "血灯缝合", "shape": "target", "range": 330.0, "radius": 92.0, "damage_multiplier": 1.10, "cooldown": 8.0, "self_heal": 14}, "bonuses": {"bandage_heal": 12, "ranged_damage": -2}},
	"choke_control": {"path": "steadfast", "name": "通道控制", "requires": "steadfast_barrier", "description": "扩大近战封锁范围。", "weapon_type": "melee", "skill": {"name": "封锁横扫", "shape": "cone", "range": 176.0, "radius": 0.0, "damage_multiplier": 1.75, "cooldown": 6.0}, "bonuses": {"attack_range": 22.0, "melee_damage": 2}},
	"weakpoint_sniper": {"path": "armorer", "name": "弱点狙击", "requires": "armorer_alternation", "description": "提高远程射程与单点伤害。", "weapon_type": "ranged", "skill": {"name": "贯芯标记", "shape": "line", "range": 610.0, "radius": 24.0, "damage_multiplier": 2.30, "cooldown": 8.0}, "bonuses": {"ranged_damage": 6, "ranged_range": 80.0}},
	"heavy_suppression": {"path": "armorer", "name": "重火力压制", "requires": "armorer_alternation", "description": "强化霰弹与群体压制。", "weapon_type": "shotgun", "skill": {"name": "镇压齐射", "shape": "cone", "range": 330.0, "radius": 0.0, "damage_multiplier": 1.65, "cooldown": 7.5}, "bonuses": {"shotgun_damage": 7, "shotgun_range": 28.0}},
	"demolition_traps": {"path": "armorer", "name": "爆破陷阱", "requires": "armorer_alternation", "description": "以准备换取全武器爆发。", "weapon_type": "shotgun", "skill": {"name": "定点爆破", "shape": "target", "range": 390.0, "radius": 112.0, "damage_multiplier": 1.85, "cooldown": 10.0}, "bonuses": {"melee_damage": 3, "ranged_damage": 3, "shotgun_damage": 3}},
	"relic_engineer": {"path": "armorer", "name": "遗物改造", "requires": "armorer_alternation", "description": "提高装备升级与进化形态的收益。", "weapon_type": "ranged", "skill": {"name": "遗物过载", "shape": "line", "range": 460.0, "radius": 42.0, "damage_multiplier": 1.70, "cooldown": 9.0}, "bonuses": {"movement_speed": 5.0}},
	"psychic_sense": {"path": "resonant", "name": "精神感知", "requires": "resonant_ingestion", "description": "扩大感知并提高机动。", "weapon_type": "ranged", "skill": {"name": "灵视穿刺", "shape": "line", "range": 520.0, "radius": 34.0, "damage_multiplier": 1.65, "cooldown": 7.0}, "bonuses": {"movement_speed": 10.0, "ranged_range": 35.0}},
	"anomaly_ingestion": {"path": "resonant", "name": "异常摄取", "requires": "resonant_ingestion", "description": "高风险选择产生更多资源，治疗代价加深。", "weapon_type": "melee", "skill": {"name": "吞噬脉冲", "shape": "self", "range": 142.0, "radius": 142.0, "damage_multiplier": 1.80, "cooldown": 8.5}, "bonuses": {"melee_damage": 4, "shotgun_damage": 4}},
	"echo_summoner": {"path": "resonant", "name": "回响召唤", "requires": "resonant_ingestion", "description": "以回响维持持续战斗能力。", "weapon_type": "ranged", "skill": {"name": "回响降临", "shape": "target", "range": 440.0, "radius": 126.0, "damage_multiplier": 1.55, "cooldown": 9.5}, "bonuses": {"max_health": 5, "bandage_heal": 5}},
	"aberrant_form": {"path": "resonant", "name": "异化形态", "requires": "resonant_ingestion", "description": "牺牲生命上限换取高额伤害与速度。", "weapon_type": "melee", "skill": {"name": "畸变突袭", "shape": "line", "range": 245.0, "radius": 52.0, "damage_multiplier": 2.10, "cooldown": 6.5, "dash": 54.0}, "bonuses": {"max_health": -10, "movement_speed": 12.0, "melee_damage": 7, "ranged_damage": 5, "shotgun_damage": 5}},
}

const EVOLUTIONS := {
	"director_reaper": {
		"watcher_form": {"name": "守望形态", "mastery": "rescues", "required": 3, "description": "击中后强化屏障。", "bonuses": {"max_health": 10, "melee_damage": 4, "attack_range": 18.0}},
		"execution_form": {"name": "处决形态", "mastery": "melee_hits", "required": 30, "description": "扩大近战处决范围。", "bonuses": {"melee_damage": 9, "attack_range": 26.0}},
		"abyss_form": {"name": "容渊形态", "mastery": "anomaly_events", "required": 4, "description": "用异化代价换取更高伤害。", "bonuses": {"max_health": -8, "melee_damage": 13}},
	},
	"conductor_railgun": {
		"hunter_form": {"name": "猎轨形态", "mastery": "ranged_hits", "required": 35, "description": "弱点标记与远距处决。", "bonuses": {"ranged_damage": 11, "ranged_range": 110.0}},
		"storm_form": {"name": "雷暴形态", "mastery": "multi_hits", "required": 12, "description": "强化贯穿与群体麻痹。", "bonuses": {"ranged_damage": 5, "shotgun_damage": 8, "shotgun_range": 45.0}},
		"runaway_form": {"name": "失控形态", "mastery": "low_health_hits", "required": 15, "description": "低生命与异化状态下追求极限输出。", "bonuses": {"max_health": -10, "ranged_damage": 14, "shotgun_damage": 10}},
	},
}

const HEART_ASPECTS := {
	"watch": {"name": "守望心相", "description": "有代价的救援会在下一次危机中留下屏障。", "bonuses": {"max_health": 8, "bandage_heal": 4}},
	"last_breath": {"name": "余命心相", "description": "持续面对危险形成濒死韧性。", "bonuses": {"max_health": 12}},
	"broken_oath": {"name": "断契心相", "description": "以关系与承诺为代价换取短时力量。", "bonuses": {"melee_damage": 5, "ranged_damage": 5, "max_health": -5}},
	"seek_gap": {"name": "觅隙心相", "description": "持续探索让隐藏路线与弱点更易显现。", "bonuses": {"movement_speed": 8.0, "ranged_range": 45.0}},
	"contain_abyss": {"name": "容渊心相", "description": "承担异常并将其转化为可控力量。", "bonuses": {"melee_damage": 4, "shotgun_damage": 4}},
	"finale": {"name": "终局心相", "description": "把环境与代价组织成连锁终局。", "bonuses": {"shotgun_damage": 6}},
}

const SYNTHESIS_POOLS := {
	"weapon:1": ["balanced_pistol", "breach_shotgun"],
	"weapon:2": ["echo_edge", "insulated_crowbar"],
	"weapon:3": ["nullpoint_sidearm", "siege_core", "volatile_edge"],
	"charm:1": ["calming_coil", "waterproof_pulse"],
	"charm:2": ["ward_echo", "station_whistle"],
	"charm:3": ["cyan_mark", "last_ticket", "archive_lens"],
}


static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	if COMBAT_STYLES.size() != 12:
		errors.append("combat styles must contain exactly twelve entries")
	for style_id in COMBAT_STYLES:
		var style: Dictionary = COMBAT_STYLES[style_id]
		if str(style.get("weapon_type", "")) not in ["melee", "ranged", "shotgun"]:
			errors.append("combat style %s has invalid weapon type" % style_id)
		var skill: Dictionary = style.get("skill", {})
		if str(skill.get("name", "")).is_empty() or float(skill.get("range", 0.0)) <= 0.0 or float(skill.get("cooldown", 0.0)) <= 0.0:
			errors.append("combat style %s has incomplete active skill" % style_id)
	for material_id in MATERIALS:
		if str(MATERIALS[material_id].get("world", "")).is_empty():
			errors.append("material %s has no world" % material_id)
	for item_id in EVOLUTIONS:
		if EVOLUTIONS[item_id].size() < 3:
			errors.append("equipment %s needs three evolution branches" % item_id)
	return errors


static func exchange_offers(cycle: int, world_id: String) -> Array[Dictionary]:
	var world_materials := ["tissue_sample", "medical_record"] if world_id == "sanatorium" else ["flooded_circuit", "ticket_stub"]
	var rotating := ["balanced_pistol", "breach_shotgun", "calming_coil", "waterproof_pulse", "echo_edge", "station_whistle"]
	var first := posmod(cycle * 2 + (0 if world_id == "sanatorium" else 1), rotating.size())
	return [
		{"id": "base_weapon", "kind": "item", "item_id": "service_crowbar", "name": "制式撬棍", "echo_cost": 4},
		{"id": "base_charm", "kind": "item", "item_id": "medical_tag", "name": "旧医疗铭牌", "echo_cost": 4},
		{"id": "world_material", "kind": "material", "material_id": world_materials[cycle % world_materials.size()], "name": MATERIALS[world_materials[cycle % world_materials.size()]].name, "echo_cost": 5},
		{"id": "rotating_a", "kind": "item", "item_id": rotating[first], "name": EquipmentDatabase.get_item(rotating[first]).name, "echo_cost": 9},
		{"id": "rotating_b", "kind": "item", "item_id": rotating[(first + 1) % rotating.size()], "name": EquipmentDatabase.get_item(rotating[(first + 1) % rotating.size()]).name, "echo_cost": 11},
	]


static func synthesis_candidates(slot: String, next_rank: int, catalyst_id: String, seed: int, pity: int) -> Array[Dictionary]:
	var pool: Array = SYNTHESIS_POOLS.get("%s:%d" % [slot, next_rank], [])
	if pool.is_empty():
		return []
	var result: Array[Dictionary] = []
	var catalyst_world := str(MATERIALS.get(catalyst_id, {}).get("world", ""))
	for offset in range(mini(3, pool.size())):
		var item_id: String = str(pool[posmod(seed + offset, pool.size())])
		var affix_ids := AFFIXES.keys()
		var affix_index := posmod(seed * 7 + offset * 3 + pity, affix_ids.size())
		if catalyst_world == "sanatorium":
			affix_index = affix_ids.find("restoration") if offset == 0 else affix_index
		elif catalyst_world == "metro":
			affix_index = affix_ids.find("last_round") if offset == 0 else affix_index
		result.append({"item_id": item_id, "affix_id": str(affix_ids[affix_index])})
	return result


static func material_rewards(world_id: String, boss_defeated: bool, seed: int) -> Dictionary:
	if world_id == "metro":
		return {"flooded_circuit": 1 + posmod(seed, 2), "ticket_stub": 1, "conductor_coil": 1 if boss_defeated else 0}
	return {"tissue_sample": 1 + posmod(seed, 2), "medical_record": 1, "stitch_core": 1 if boss_defeated else 0}


static func combined_bonuses(style_id: String, affix_id: String, evolution: Dictionary, heart: Dictionary) -> Dictionary:
	var result := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0, "attack_range": 0.0, "ranged_range": 0.0, "shotgun_range": 0.0}
	var sources: Array = [
		COMBAT_STYLES.get(style_id, {}).get("bonuses", {}),
		AFFIXES.get(affix_id, {}),
		evolution.get("bonuses", {}),
		heart.get("bonuses", {}),
	]
	for source in sources:
		for stat in result:
			result[stat] += source.get(stat, 0)
	return result


static func heart_aspect_for(reflection: Dictionary, action_events: Array[Dictionary]) -> Dictionary:
	if action_events.size() < 3:
		return {}
	var counts := {"watch": 0, "last_breath": 0, "broken_oath": 0, "seek_gap": 0, "contain_abyss": 0, "finale": 0}
	for event in action_events:
		var event_type := str(event.get("event_type", ""))
		if event_type in ["costly_rescue", "promise_kept", "share_burden", "public_help", "anonymous_help"]:
			counts.watch += 1
		if event_type in ["risk_choice", "self_preservation"]:
			counts.last_breath += 1
		if event_type in ["promise_broken", "faction_betrayal", "anonymous_exploitation"]:
			counts.broken_oath += 1
		if event_type in ["independent_choice", "explore_hidden"]:
			counts.seek_gap += 1
		if event_type in ["anomaly_ingestion", "accept_memory", "costly_rescue"]:
			counts.contain_abyss += 1
		if event_type in ["attack_neutral", "retaliation"]:
			counts.finale += 1
	var best := "watch"
	for aspect_id in counts:
		if int(counts[aspect_id]) > int(counts[best]):
			best = aspect_id
	if int(counts[best]) <= 0:
		var echo_id := str(reflection.get("echo", {}).get("id", ""))
		best = "seek_gap" if echo_id == "unformed_echo" else "last_breath"
	var aspect: Dictionary = HEART_ASPECTS[best].duplicate(true)
	aspect.id = best
	aspect.evidence = int(counts[best])
	return aspect
