class_name EquipmentDatabase
extends RefCounted

const ITEMS := {
	"service_crowbar": {"name": "制式撬棍", "quality": "制式", "quality_rank": 0, "slot": "weapon", "rating": 92, "description": "近战伤害 +3", "melee_damage": 3},
	"balanced_pistol": {"name": "平衡手枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "rating": 118, "description": "手枪伤害 +5", "ranged_damage": 5},
	"breach_shotgun": {"name": "破门霰弹枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "rating": 126, "description": "霰弹伤害 +6", "shotgun_damage": 6},
	"echo_edge": {"name": "回响切割器", "quality": "回响", "quality_rank": 2, "slot": "weapon", "rating": 154, "description": "近战伤害 +8 · 移速 +4", "melee_damage": 8, "movement_speed": 4.0},
	"medical_tag": {"name": "旧医疗铭牌", "quality": "制式", "quality_rank": 0, "slot": "charm", "rating": 88, "description": "生命上限 +5", "max_health": 5},
	"calming_coil": {"name": "镇静线圈", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 116, "description": "生命上限 +8 · 绷带恢复 +3", "max_health": 8, "bandage_heal": 3},
	"ward_echo": {"name": "病房回响体", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 148, "description": "生命上限 +12 · 移速 +3", "max_health": 12, "movement_speed": 3.0},
	"cyan_mark": {"name": "异常青印", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 176, "description": "全武器伤害 +5 · 生命上限 -8", "max_health": -8, "melee_damage": 5, "ranged_damage": 5, "shotgun_damage": 5},
	"waterproof_pulse": {"name": "防水脉冲腕带", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 124, "trait": "reduce_water_penalty", "description": "浸水减速降低 35% · 生命上限 -3", "max_health": -3},
	"station_whistle": {"name": "站务员哨", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 151, "trait": "noise_lure", "description": "T / 吹哨主动诱引附近敌人 · 冷却 12 秒 · 武器伤害 +3", "melee_damage": 3, "ranged_damage": 3, "shotgun_damage": 3},
	"insulated_crowbar": {"name": "绝缘撬棍", "quality": "回响", "quality_rank": 2, "slot": "weapon", "rating": 158, "trait": "signal_anchor_damage", "description": "对检票员/车长近战伤害 +35% · 冷却 +0.12 秒 · 生命上限 -4", "melee_damage": 11, "max_health": -4},
	"last_ticket": {"name": "末班票根", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 182, "trait": "missed_train_recovery", "description": "首次错过车次时补救窗口延长 15 秒 · 生命上限 +6", "max_health": 6},
	"linye_pass": {"name": "林雾的失踪乘客通行牌", "quality": "剧情唯一", "quality_rank": 4, "slot": "charm", "rating": 205, "trait": "lost_passenger_guide", "unique": true, "max_health": 8, "movement_speed": 5.0, "description": "世界唯一 · 维护层向导留下的通行牌；生命上限 +8、移动速度 +5。再次进入末班线时会唤起林雾的记忆。"},
	"director_reaper": {"name": "主任的缝合镰", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "rating": 218, "series": "缝合遗物", "unique": true, "growth_max": 5, "melee_damage": 14, "description": "成长武器 · 世界唯一 · 近战伤害 +14；再次击败疗养院首领只提供成长层数。"},
	"conductor_railgun": {"name": "末班导轨枪", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "rating": 224, "series": "末班遗物", "unique": true, "growth_max": 5, "ranged_damage": 11, "shotgun_damage": 5, "description": "成长武器 · 世界唯一 · 手枪伤害 +11、霰弹伤害 +5；再次击败车长回声只提供成长层数。"},
}

const QUALITY_COLORS := [Color("aab3ad"), Color("79b889"), Color("58c7b5"), Color("bc6ac9")]


static func weapon_visual(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	match item_id:
		"director_reaper": return {"shape": "reaper", "color": Color("c9786a"), "name": "缝合镰"}
		"conductor_railgun": return {"shape": "railgun", "color": Color("79d8e8"), "name": "导轨枪"}
		"insulated_crowbar": return {"shape": "crowbar", "color": Color("8dc5d4"), "name": "绝缘撬棍"}
		"echo_edge": return {"shape": "blade", "color": Color("66d9c6"), "name": "回响切割器"}
	return {"shape": "standard", "color": QUALITY_COLORS[clampi(int(item.get("quality_rank", 0)), 0, QUALITY_COLORS.size() - 1)], "name": str(item.get("name", "制式武器"))}


static func boss_growth_item(world_id: String) -> String:
	return "conductor_railgun" if world_id == "metro" else "director_reaper"


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).duplicate(true)


static func reward_pool() -> Array[String]:
	return ["balanced_pistol", "breach_shotgun", "echo_edge", "calming_coil", "ward_echo", "cyan_mark"]


static func metro_reward_pool() -> Array[String]:
	return ["waterproof_pulse", "station_whistle", "insulated_crowbar", "last_ticket", "echo_edge", "cyan_mark"]


static func get_bonuses(equipped: Dictionary) -> Dictionary:
	var bonuses := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0}
	for slot in ["weapon", "charm"]:
		var item := get_item(str(equipped.get(slot, "")))
		for stat in bonuses:
			bonuses[stat] += item.get(stat, 0)
	return bonuses


static func has_trait(equipped: Dictionary, trait_id: String) -> bool:
	for item_id in equipped.values():
		if str(get_item(str(item_id)).get("trait", "")) == trait_id:
			return true
	return false
