class_name EquipmentDatabase
extends RefCounted

const ITEMS := {
	"service_crowbar": {"name": "制式撬棍", "quality": "制式", "quality_rank": 0, "slot": "weapon", "weapon_type": "melee", "rating": 92, "description": "近战伤害 +3", "melee_damage": 3},
	"balanced_pistol": {"name": "平衡手枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "weapon_type": "ranged", "rating": 118, "description": "手枪伤害 +5", "ranged_damage": 5},
	"breach_shotgun": {"name": "破门霰弹枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "weapon_type": "shotgun", "rating": 126, "description": "霰弹伤害 +6", "shotgun_damage": 6},
	"echo_edge": {"name": "回响切割器", "quality": "回响", "quality_rank": 2, "slot": "weapon", "weapon_type": "melee", "rating": 154, "description": "近战伤害 +8 · 移速 +4", "melee_damage": 8, "movement_speed": 4.0},
	"medical_tag": {"name": "旧医疗铭牌", "quality": "制式", "quality_rank": 0, "slot": "charm", "rating": 88, "description": "生命上限 +5", "max_health": 5},
	"calming_coil": {"name": "镇静线圈", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 116, "description": "生命上限 +8 · 绷带恢复 +3", "max_health": 8, "bandage_heal": 3},
	"ward_echo": {"name": "病房回响体", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 148, "description": "生命上限 +12 · 移速 +3", "max_health": 12, "movement_speed": 3.0},
	"cyan_mark": {"name": "异常青印", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 176, "description": "全武器伤害 +5 · 生命上限 -8", "max_health": -8, "melee_damage": 5, "ranged_damage": 5, "shotgun_damage": 5},
	"waterproof_pulse": {"name": "防水脉冲腕带", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 124, "trait": "reduce_water_penalty", "description": "浸水减速降低 35% · 生命上限 -3", "max_health": -3},
	"station_whistle": {"name": "站务员哨", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 151, "trait": "noise_lure", "description": "T / 吹哨主动诱引附近敌人 · 冷却 12 秒 · 武器伤害 +3", "melee_damage": 3, "ranged_damage": 3, "shotgun_damage": 3},
	"insulated_crowbar": {"name": "绝缘撬棍", "quality": "回响", "quality_rank": 2, "slot": "weapon", "weapon_type": "melee", "rating": 158, "trait": "signal_anchor_damage", "description": "对检票员/车长近战伤害 +35% · 冷却 +0.12 秒 · 生命上限 -4", "melee_damage": 11, "max_health": -4},
	"last_ticket": {"name": "末班票根", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 182, "trait": "missed_train_recovery", "description": "首次错过车次时补救窗口延长 15 秒 · 生命上限 +6", "max_health": 6},
	"nullpoint_sidearm": {"name": "零点标记枪", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "ranged", "rating": 186, "trait": "weakpoint_mark", "tags": ["weakpoint", "precision"], "description": "远距命中积累弱点标记 · 手枪伤害 +10 · 生命上限 -4", "ranged_damage": 10, "max_health": -4},
	"siege_core": {"name": "围城火力核心", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "shotgun", "rating": 190, "trait": "heavy_suppression", "tags": ["heavy", "suppression"], "description": "霰弹压制范围扩大 · 霰弹伤害 +11 · 移速 -5", "shotgun_damage": 11, "movement_speed": -5.0},
	"volatile_edge": {"name": "失控回响刃", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "melee", "rating": 188, "trait": "anomaly_edge", "tags": ["anomaly", "melee"], "description": "近战伤害 +13 · 生命上限 -9", "melee_damage": 13, "max_health": -9},
	"archive_lens": {"name": "活档案透镜", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 180, "trait": "hidden_sense", "tags": ["sense", "archive"], "description": "更容易感知隐藏区域 · 移速 +7 · 生命上限 +3", "movement_speed": 7.0, "max_health": 3},
	"linye_pass": {"name": "林雾的失踪乘客通行牌", "quality": "剧情唯一", "quality_rank": 4, "slot": "charm", "rating": 205, "trait": "lost_passenger_guide", "unique": true, "max_health": 8, "movement_speed": 5.0, "description": "世界唯一 · 维护层向导留下的通行牌；生命上限 +8、移动速度 +5。再次进入末班线时会唤起林雾的记忆。"},
	"director_reaper": {"name": "主任的缝合镰", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "weapon_type": "melee", "rating": 218, "series": "缝合遗物", "unique": true, "growth_max": 5, "melee_damage": 14, "description": "成长武器 · 世界唯一 · 近战伤害 +14；再次击败疗养院首领只提供成长层数。"},
	"conductor_railgun": {"name": "末班导轨枪", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "weapon_type": "ranged", "attack_types": ["ranged", "shotgun"], "rating": 224, "series": "末班遗物", "unique": true, "growth_max": 5, "ranged_damage": 11, "shotgun_damage": 5, "description": "成长武器 · 世界唯一 · 手枪伤害 +11、霰弹伤害 +5；再次击败车长回声只提供成长层数。"},
}

const QUALITY_COLORS := [Color("aab3ad"), Color("79b889"), Color("58c7b5"), Color("bc6ac9")]


static func weapon_visual(item_id: String, growth_level := 0) -> Dictionary:
	var item := get_item(item_id)
	var growth := relic_growth_profile(item_id, growth_level)
	var scale := float(growth.get("visual_scale", 1.0))
	match item_id:
		"director_reaper": return {"shape": "reaper", "color": Color("c9786a").lerp(Color("9fe6ff"), float(growth_level) * 0.055), "name": "缝合镰", "scale": scale, "growth": growth_level}
		"conductor_railgun": return {"shape": "railgun", "color": Color("79d8e8").lerp(Color("d7b1ff"), float(growth_level) * 0.06), "name": "导轨枪", "scale": scale, "growth": growth_level}
		"echo_edge": return {"shape": "advanced", "atlas_index": 0, "color": Color("66d9c6"), "name": "回响切割器"}
		"insulated_crowbar": return {"shape": "advanced", "atlas_index": 1, "color": Color("8dc5d4"), "name": "绝缘撬棍"}
		"nullpoint_sidearm": return {"shape": "advanced", "atlas_index": 2, "color": Color("79d8e8"), "name": "零点标记枪"}
		"siege_core": return {"shape": "advanced", "atlas_index": 3, "color": Color("e58a54"), "name": "围城火力核心"}
		"volatile_edge": return {"shape": "advanced", "atlas_index": 4, "color": Color("b47cff"), "name": "失控回响刃"}
	return {"shape": "standard", "color": QUALITY_COLORS[clampi(int(item.get("quality_rank", 0)), 0, QUALITY_COLORS.size() - 1)], "name": str(item.get("name", "制式武器"))}


static func relic_growth_profile(item_id: String, level: int) -> Dictionary:
	level = clampi(level, 0, int(get_item(item_id).get("growth_max", 0)))
	if item_id == "director_reaper":
		return {
			"item_id": item_id,
			"level": level,
			"melee_range": level * 8.0,
			"knockback": 0.0 if level < 2 else 14.0 + level * 5.0,
			"status": "" if level < 3 else "freeze",
			"status_every": 0 if level < 3 else (2 if level >= 5 else 3),
			"status_duration": 0.0 if level < 3 else 0.55 + float(level - 3) * 0.18,
			"visual_scale": 1.0 + float(level) * 0.09,
		}
	if item_id == "conductor_railgun":
		return {
			"item_id": item_id,
			"level": level,
			"ranged_range": level * 45.0,
			"shotgun_range": level * 15.0,
			"pierce_targets": 1 + int(level / 2),
			"knockback": 0.0 if level < 3 else 12.0 + level * 5.0,
			"status": "" if level < 4 else "paralyze",
			"status_every": 0 if level < 4 else (2 if level >= 5 else 3),
			"status_duration": 0.0 if level < 4 else 0.62 + float(level - 4) * 0.22,
			"visual_scale": 1.0 + float(level) * 0.08,
		}
	return {}


static func relic_growth_description(item_id: String, level: int) -> String:
	var profile := relic_growth_profile(item_id, level)
	if profile.is_empty() or level <= 0:
		return "尚未觉醒：再次击败对应首领可解锁范围、控制与外形变化。"
	var effects: Array[String] = []
	if item_id == "director_reaper":
		effects.append("近战范围 +%d" % int(profile.melee_range))
		if float(profile.knockback) > 0.0:
			effects.append("命中击退 %d" % int(profile.knockback))
		if not str(profile.status).is_empty():
			effects.append("每 %d 次命中寒霜定身 %.2f 秒" % [int(profile.status_every), float(profile.status_duration)])
	elif item_id == "conductor_railgun":
		effects.append("手枪射程 +%d" % int(profile.ranged_range))
		effects.append("霰弹射程 +%d" % int(profile.shotgun_range))
		if int(profile.pierce_targets) > 1:
			effects.append("贯穿 %d 个目标" % int(profile.pierce_targets))
		if float(profile.knockback) > 0.0:
			effects.append("命中击退 %d" % int(profile.knockback))
		if not str(profile.status).is_empty():
			effects.append("每 %d 次命中电磁麻痹 %.2f 秒" % [int(profile.status_every), float(profile.status_duration)])
	return " · ".join(effects)


static func boss_growth_item(world_id: String) -> String:
	return "conductor_railgun" if world_id == "metro" else "director_reaper"


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).duplicate(true)


static func equipment_slot(item_id: String) -> String:
	var item := get_item(item_id)
	if str(item.get("slot", "")) != "weapon":
		return str(item.get("slot", ""))
	return "weapon_%s" % str(item.get("weapon_type", "melee"))


static func slot_label(item_id: String) -> String:
	match equipment_slot(item_id):
		"weapon_melee": return "近战武器"
		"weapon_ranged": return "精确武器"
		"weapon_shotgun": return "重型武器"
		"charm": return "护符"
	return "未知"


static func supports_attack(item_id: String, attack_type: String) -> bool:
	var item := get_item(item_id)
	if str(item.get("slot", "")) != "weapon":
		return false
	var attack_types: Array = item.get("attack_types", [str(item.get("weapon_type", "melee"))])
	return attack_types.has(attack_type)


static func reward_pool() -> Array[String]:
	return ["balanced_pistol", "breach_shotgun", "echo_edge", "calming_coil", "ward_echo", "cyan_mark"]


static func metro_reward_pool() -> Array[String]:
	return ["waterproof_pulse", "station_whistle", "insulated_crowbar", "last_ticket", "echo_edge", "cyan_mark"]


static func get_bonuses(equipped: Dictionary) -> Dictionary:
	var bonuses := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0}
	var seen: Array[String] = []
	for item_id in equipped.values():
		var equipped_id := str(item_id)
		if equipped_id.is_empty() or seen.has(equipped_id):
			continue
		seen.append(equipped_id)
		var item := get_item(equipped_id)
		for stat in bonuses:
			bonuses[stat] += item.get(stat, 0)
	return bonuses


static func upgraded_bonuses(item_id: String, level: int) -> Dictionary:
	var item := get_item(item_id)
	level = clampi(level, 0, 5)
	var result := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0}
	if item.is_empty() or level <= 0:
		return result
	for stat in result:
		var base := float(item.get(stat, 0))
		if base > 0.0:
			result[stat] = int(ceil(absf(base) * level * 0.08)) if stat != "movement_speed" else absf(base) * level * 0.08
	return result


static func has_trait(equipped: Dictionary, trait_id: String) -> bool:
	for item_id in equipped.values():
		if str(get_item(str(item_id)).get("trait", "")) == trait_id:
			return true
	return false
