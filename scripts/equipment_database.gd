class_name EquipmentDatabase
extends RefCounted

const ITEMS := {
	"service_crowbar": {"name": "制式撬棍", "quality": "制式", "quality_rank": 0, "slot": "weapon", "weapon_type": "melee", "tags": ["melee", "blunt", "breach"], "rating": 92, "trait": "breach_stagger", "description": "短横扫 · 破门/打断 · 近战伤害 +3", "melee_damage": 3},
	"balanced_pistol": {"name": "平衡手枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "weapon_type": "ranged", "tags": ["ranged", "precision"], "rating": 118, "trait": "steady_aim", "description": "精确弹道 · 弱点射击 · 手枪伤害 +5", "ranged_damage": 5},
	"breach_shotgun": {"name": "破门霰弹枪", "quality": "改装", "quality_rank": 1, "slot": "weapon", "weapon_type": "shotgun", "tags": ["heavy", "suppression"], "rating": 126, "trait": "door_breach", "description": "扇形压制 · 强击退 · 霰弹伤害 +6", "shotgun_damage": 6},
	"echo_edge": {"name": "回响切割器", "quality": "回响", "quality_rank": 2, "slot": "weapon", "weapon_type": "melee", "rating": 154, "description": "近战伤害 +8 · 移速 +4", "melee_damage": 8, "movement_speed": 4.0},
	"medical_tag": {"name": "旧医疗铭牌", "quality": "制式", "quality_rank": 0, "slot": "charm", "rating": 88, "active_skill": {"name": "应急缝合", "kind": "heal", "amount": 22, "cooldown": 18.0}, "description": "主动：应急缝合 · 生命上限 +5", "max_health": 5},
	"calming_coil": {"name": "镇静线圈", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 116, "active_skill": {"name": "镇静脉冲", "kind": "cleanse", "amount": 12, "cooldown": 16.0}, "description": "主动：镇静脉冲 · 生命上限 +8 · 绷带恢复 +3", "max_health": 8, "bandage_heal": 3},
	"ward_echo": {"name": "病房回响体", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 148, "description": "生命上限 +12 · 移速 +3", "max_health": 12, "movement_speed": 3.0},
	"cyan_mark": {"name": "异常青印", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 176, "description": "全武器伤害 +5 · 生命上限 -8", "max_health": -8, "melee_damage": 5, "ranged_damage": 5, "shotgun_damage": 5},
	"waterproof_pulse": {"name": "防水脉冲腕带", "quality": "改装", "quality_rank": 1, "slot": "charm", "rating": 124, "trait": "reduce_water_penalty", "description": "浸水减速降低 35% · 生命上限 -3", "max_health": -3},
	"station_whistle": {"name": "站务员哨", "quality": "回响", "quality_rank": 2, "slot": "charm", "rating": 151, "trait": "noise_lure", "active_skill": {"name": "猎犬哨", "kind": "lure", "cooldown": 12.0}, "description": "主动：猎犬哨 · 诱引附近敌人 · 全武器伤害 +3", "melee_damage": 3, "ranged_damage": 3, "shotgun_damage": 3},
	"riot_shield": {"name": "折叠防暴盾", "quality": "改装", "quality_rank": 1, "slot": "offhand", "rating": 132, "tags": ["guard", "shield"], "trait": "guard_window", "description": "副手 · 格挡后短暂减伤 · 生命上限 +8", "max_health": 8},
	"field_codex": {"name": "野战法典", "quality": "回响", "quality_rank": 2, "slot": "offhand", "rating": 146, "tags": ["echo", "arcane"], "description": "副手 · 回响武器强化 · 移速 +4", "movement_speed": 4.0},
	"insulated_crowbar": {"name": "绝缘撬棍", "quality": "回响", "quality_rank": 2, "slot": "weapon", "weapon_type": "melee", "rating": 158, "trait": "signal_anchor_damage", "description": "对检票员/车长近战伤害 +35% · 冷却 +0.12 秒 · 生命上限 -4", "melee_damage": 11, "max_health": -4},
	"last_ticket": {"name": "末班票根", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 182, "trait": "missed_train_recovery", "description": "首次错过车次时补救窗口延长 15 秒 · 生命上限 +6", "max_health": 6},
	"nullpoint_sidearm": {"name": "零点标记枪", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "ranged", "rating": 186, "trait": "weakpoint_mark", "tags": ["weakpoint", "precision"], "description": "远距命中积累弱点标记 · 手枪伤害 +10 · 生命上限 -4", "ranged_damage": 10, "max_health": -4},
	"siege_core": {"name": "围城火力核心", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "shotgun", "rating": 190, "trait": "heavy_suppression", "tags": ["heavy", "suppression"], "description": "霰弹压制范围扩大 · 霰弹伤害 +11 · 移速 -5", "shotgun_damage": 11, "movement_speed": -5.0},
	"volatile_edge": {"name": "失控回响刃", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "melee", "rating": 188, "trait": "anomaly_edge", "tags": ["anomaly", "melee"], "description": "近战伤害 +13 · 生命上限 -9", "melee_damage": 13, "max_health": -9},
	"archive_lens": {"name": "活档案透镜", "quality": "异常", "quality_rank": 3, "slot": "charm", "rating": 180, "trait": "hidden_sense", "tags": ["sense", "archive"], "description": "更容易感知隐藏区域 · 移速 +7 · 生命上限 +3", "movement_speed": 7.0, "max_health": 3},
	"linye_pass": {"name": "林雾的失踪乘客通行牌", "quality": "剧情唯一", "quality_rank": 4, "slot": "charm", "rating": 205, "trait": "lost_passenger_guide", "unique": true, "max_health": 8, "movement_speed": 5.0, "description": "世界唯一 · 维护层向导留下的通行牌；生命上限 +8、移动速度 +5。再次进入末班线时会唤起林雾的记忆。"},
	"director_reaper": {"name": "主任的缝合镰", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "weapon_type": "melee", "tags": ["melee", "anomaly", "control"], "rating": 218, "series": "缝合遗物", "unique": true, "growth_max": 5, "melee_damage": 14, "trait": "stitch_pull", "description": "成长武器 · 缝线拉扯与定身 · 近战伤害 +14。"},
	"conductor_railgun": {"name": "末班导轨枪", "quality": "首领遗物", "quality_rank": 4, "slot": "weapon", "weapon_type": "ranged", "tags": ["ranged", "precision", "heavy"], "rating": 224, "series": "末班遗物", "unique": true, "growth_max": 5, "ranged_damage": 11, "trait": "rail_pierce", "description": "成长武器 · 蓄能贯穿线与电磁麻痹 · 手枪伤害 +11。"},
	"mourning_bow": {"name": "哀鸣骨弓", "quality": "回响", "quality_rank": 2, "slot": "weapon", "weapon_type": "ranged", "attack_profile": {"id": "bow", "kind": "ranged", "range": 520.0, "cooldown": 0.74, "damage_multiplier": 0.92}, "tags": ["bow", "precision", "pierce", "echo"], "rating": 162, "trait": "echo_retrieval", "ranged_damage": 7, "description": "拉弓穿刺 · 命中回响回收 · 不消耗箭矢 · 远程伤害 +7。"},
	"echo_staff": {"name": "裂隙法杖", "quality": "异常", "quality_rank": 3, "slot": "weapon", "weapon_type": "arcane", "attack_profile": {"id": "arcane", "kind": "arcane", "range": 365.0, "cooldown": 0.62, "damage_multiplier": 0.86, "chain_targets": 2}, "tags": ["arcane", "anomaly", "echo"], "rating": 184, "trait": "anomaly_spread", "ranged_damage": 9, "description": "短束射线 · 异常扩散 · 回响充能 · 不消耗法力药水 · 远程伤害 +9。"},
}

const QUALITY_COLORS := [Color("aab3ad"), Color("79b889"), Color("58c7b5"), Color("bc6ac9")]
const WEAPON_ATTACK_PRESENTATIONS := {
	"service_crowbar": {"range": 76.0, "cooldown": 0.48, "cast": "sweep", "vfx": "melee_sweep", "effect_color": "c8b58f", "impact_color": "e5d0a4"},
	"balanced_pistol": {"range": 430.0, "cooldown": 0.34, "cast": "hitscan", "vfx": "pistol", "effect_color": "79d8e8", "impact_color": "a9eff7"},
	"breach_shotgun": {"range": 235.0, "cooldown": 0.95, "cast": "cone", "vfx": "shotgun", "effect_color": "e5a45f", "impact_color": "ffd093"},
	"echo_edge": {"range": 88.0, "cooldown": 0.42, "cast": "sweep", "vfx": "melee_sweep", "effect_color": "66d9c6", "impact_color": "9df6e5"},
	"insulated_crowbar": {"range": 82.0, "cooldown": 0.60, "cast": "heavy_sweep", "vfx": "melee_sweep", "effect_color": "8dc5d4", "impact_color": "c4eef6"},
	"nullpoint_sidearm": {"range": 480.0, "cooldown": 0.38, "cast": "marking_hitscan", "vfx": "pistol", "effect_color": "79d8e8", "impact_color": "b7f4ff"},
	"siege_core": {"range": 255.0, "cooldown": 1.05, "cast": "heavy_cone", "vfx": "shotgun", "effect_color": "e58a54", "impact_color": "ffc28c"},
	"volatile_edge": {"range": 96.0, "cooldown": 0.52, "cast": "anomaly_sweep", "vfx": "melee_sweep", "effect_color": "b47cff", "impact_color": "debaff"},
	"director_reaper": {"range": 104.0, "cooldown": 0.68, "cast": "reaping_arc", "vfx": "melee_sweep", "effect_color": "c9786a", "impact_color": "f0aaa0"},
	"conductor_railgun": {"range": 540.0, "cooldown": 0.66, "cast": "piercing_beam", "vfx": "rail_beam", "effect_color": "79d8e8", "impact_color": "d7b1ff"},
	"mourning_bow": {"cast": "draw_release", "vfx": "bone_arrow", "effect_color": "a8dce0", "impact_color": "d9f2ed"},
	"echo_staff": {"cast": "rift_channel", "vfx": "arcane_chain", "effect_color": "b47cff", "impact_color": "e0bfff"},
}


# Combat rules stay in attack_profile. This table only selects the rendered
# character action family and the future per-item appearance layer.
# Until a unique layer exists, every item deliberately uses its family's
# standard layer so no new body animation is required.
const WEAPON_PRESENTATION_PROFILES := {
	"service_crowbar": {"animation_family": "sword", "visual_asset": "service_crowbar", "layer_asset": "standard_melee_sword", "hand_mode": "one_handed"},
	"balanced_pistol": {"animation_family": "pistol", "visual_asset": "balanced_pistol", "layer_asset": "standard_service_pistol", "hand_mode": "one_handed"},
	"breach_shotgun": {"animation_family": "pistol", "visual_asset": "breach_shotgun", "layer_asset": "standard_service_pistol", "hand_mode": "one_handed"},
	"echo_edge": {"animation_family": "sword", "visual_asset": "echo_edge", "layer_asset": "standard_melee_sword", "hand_mode": "one_handed"},
	"insulated_crowbar": {"animation_family": "sword", "visual_asset": "insulated_crowbar", "layer_asset": "standard_melee_sword", "hand_mode": "one_handed"},
	"nullpoint_sidearm": {"animation_family": "pistol", "visual_asset": "nullpoint_sidearm", "layer_asset": "standard_service_pistol", "hand_mode": "one_handed"},
	"siege_core": {"animation_family": "pistol", "visual_asset": "siege_core", "layer_asset": "standard_service_pistol", "hand_mode": "one_handed"},
	"volatile_edge": {"animation_family": "sword", "visual_asset": "volatile_edge", "layer_asset": "standard_melee_sword", "hand_mode": "one_handed"},
	"director_reaper": {"animation_family": "sword", "visual_asset": "director_reaper", "layer_asset": "standard_melee_sword", "hand_mode": "one_handed"},
	"conductor_railgun": {"animation_family": "pistol", "visual_asset": "conductor_railgun", "layer_asset": "standard_service_pistol", "hand_mode": "one_handed"},
	"mourning_bow": {"animation_family": "bow", "visual_asset": "mourning_bow", "layer_asset": "standard_hunter_bow", "hand_mode": "two_handed"},
	"echo_staff": {"animation_family": "staff", "visual_asset": "echo_staff", "layer_asset": "standard_echo_staff", "hand_mode": "two_handed"},
}
const OFFHAND_PRESENTATION_PROFILES := {
	"riot_shield": {"animation_family": "shield", "visual_asset": "riot_shield", "layer_asset": "standard_guard_shield", "hand_mode": "off_hand"},
	"field_codex": {"animation_family": "", "visual_asset": "field_codex", "layer_asset": "", "hand_mode": "off_hand"},
}


static func weapon_presentation(item_id: String) -> Dictionary:
	var configured: Dictionary = WEAPON_PRESENTATION_PROFILES.get(item_id, {}).duplicate(true)
	if not configured.is_empty():
		return configured
	var item := get_item(item_id)
	if str(item.get("slot", "")) != "weapon":
		return {}
	var weapon_type := str(item.get("weapon_type", "melee"))
	var family := "sword"
	if weapon_type in ["ranged", "shotgun"]:
		family = "pistol"
	elif weapon_type == "arcane":
		family = "staff"
	return {
		"animation_family": family,
		"visual_asset": item_id,
		"layer_asset": "standard_service_pistol" if family == "pistol" else ("standard_echo_staff" if family == "staff" else "standard_melee_sword"),
		"hand_mode": "two_handed" if family == "staff" else "one_handed",
	}


static func weapon_animation_family(item_id: String) -> StringName:
	return StringName(str(weapon_presentation(item_id).get("animation_family", "")))


static func weapon_visual_asset(item_id: String) -> String:
	return str(weapon_presentation(item_id).get("visual_asset", ""))


static func weapon_hand_mode(item_id: String) -> StringName:
	return StringName(str(weapon_presentation(item_id).get("hand_mode", "")))


static func offhand_presentation(item_id: String) -> Dictionary:
	return OFFHAND_PRESENTATION_PROFILES.get(item_id, {}).duplicate(true)



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
		"mourning_bow": return {"shape": "equipment", "atlas_index": 0, "color": Color("a8dce0"), "name": "哀鸣骨弓", "rotation_offset": 0.0}
		"echo_staff": return {"shape": "equipment", "atlas_index": 1, "color": Color("b47cff"), "name": "裂隙法杖", "rotation_offset": PI}
	return {"shape": "standard", "color": QUALITY_COLORS[clampi(int(item.get("quality_rank", 0)), 0, QUALITY_COLORS.size() - 1)], "name": str(item.get("name", "制式武器"))}


static func offhand_visual(item_id: String) -> Dictionary:
	match item_id:
		"riot_shield": return {"shape": "equipment", "atlas_index": 2, "name": "折叠防暴盾", "display_size": 48.0}
		"field_codex": return {"shape": "equipment", "atlas_index": 3, "name": "野战法典", "display_size": 34.0}
	return {}


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
	return str(item.get("slot", ""))


static func slot_label(item_id: String) -> String:
	match equipment_slot(item_id):
		"weapon": return "自由武器槽"
		"offhand": return "副手"
		"charm": return "护符"
	return "未知"


static func supports_attack(item_id: String, attack_type: String) -> bool:
	var item := get_item(item_id)
	if str(item.get("slot", "")) != "weapon":
		return false
	var profile := attack_profile(item_id)
	return str(profile.get("kind", "melee")) == attack_type or str(profile.get("id", "")) == attack_type


static func attack_profile(item_id: String) -> Dictionary:
	var item := get_item(item_id)
	var fallback := str(item.get("weapon_type", "melee"))
	var profile: Dictionary = item.get("attack_profile", {}).duplicate(true)
	if profile.is_empty():
		profile = {"id": fallback, "kind": fallback}
	profile.merge(WEAPON_ATTACK_PRESENTATIONS.get(item_id, {}), false)
	profile.id = str(profile.get("id", fallback))
	profile.kind = str(profile.get("kind", fallback))
	return profile


static func weapon_tags(item_id: String) -> Array[String]:
	var tags: Array[String] = []
	for tag in get_item(item_id).get("tags", []):
		tags.append(str(tag))
	var profile := attack_profile(item_id)
	for tag in [str(profile.get("id", "")), str(profile.get("kind", ""))]:
		if not tag.is_empty() and not tags.has(tag):
			tags.append(tag)
	return tags


static func active_charm_skill(item_id: String) -> Dictionary:
	return get_item(item_id).get("active_skill", {}).duplicate(true)


static func reward_pool() -> Array[String]:
	return ["balanced_pistol", "breach_shotgun", "mourning_bow", "riot_shield", "echo_edge", "calming_coil", "ward_echo", "cyan_mark"]


static func metro_reward_pool() -> Array[String]:
	return ["waterproof_pulse", "station_whistle", "insulated_crowbar", "field_codex", "echo_staff", "last_ticket", "echo_edge", "cyan_mark"]


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
