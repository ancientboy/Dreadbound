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
}

const QUALITY_COLORS := [Color("aab3ad"), Color("79b889"), Color("58c7b5"), Color("bc6ac9")]


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).duplicate(true)


static func reward_pool() -> Array[String]:
	return ["balanced_pistol", "breach_shotgun", "echo_edge", "calming_coil", "ward_echo", "cyan_mark"]


static func get_bonuses(equipped: Dictionary) -> Dictionary:
	var bonuses := {"max_health": 0, "movement_speed": 0.0, "melee_damage": 0, "ranged_damage": 0, "shotgun_damage": 0, "bandage_heal": 0}
	for slot in ["weapon", "charm"]:
		var item := get_item(str(equipped.get(slot, "")))
		for stat in bonuses:
			bonuses[stat] += item.get(stat, 0)
	return bonuses
