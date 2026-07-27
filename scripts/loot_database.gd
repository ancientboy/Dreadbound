class_name LootDatabase
extends RefCounted

# Loot is authored by source rather than by scene.  This keeps enemy variants,
# difficulty modifiers and future worlds from duplicating probability code.
const ENEMY_POOLS := {
	"sanatorium:crawler": [
		{"kind": "bandage", "amount": 1, "weight": 18},
		{"kind": "material", "id": "tissue_sample", "amount": 1, "weight": 16},
		{"kind": "echo_shard", "amount": 1, "weight": 8},
	],
	"sanatorium:patient": [
		{"kind": "bandage", "amount": 1, "weight": 16},
		{"kind": "material", "id": "tissue_sample", "amount": 1, "weight": 18},
		{"kind": "echo_shard", "amount": 1, "weight": 10},
	],
	"sanatorium:orderly": [
		{"kind": "echo_shard", "amount": 2, "weight": 18},
		{"kind": "sedative", "amount": 1, "weight": 12},
		{"kind": "material", "id": "medical_record", "amount": 1, "weight": 10, "rare": true},
	],
	"metro:drowned": [
		{"kind": "material", "id": "flooded_circuit", "amount": 1, "weight": 20},
		{"kind": "bandage", "amount": 1, "weight": 12},
		{"kind": "echo_shard", "amount": 1, "weight": 12},
	],
	"metro:conductor": [
		{"kind": "echo_shard", "amount": 2, "weight": 16},
		{"kind": "sedative", "amount": 1, "weight": 10},
		{"kind": "material", "id": "ticket_stub", "amount": 1, "weight": 14, "rare": true},
	],
	"default": [
		{"kind": "echo_shard", "amount": 1, "weight": 38},
	],
}

const WORLD_COMMON_MATERIAL := {
	"sanatorium": "tissue_sample",
	"metro": "flooded_circuit",
}

const BOSS_REWARDS := {
	"sanatorium": {"material": "stitch_core", "amount": 1, "equipment": "director_reaper"},
	"metro": {"material": "conductor_coil", "amount": 1, "equipment": "conductor_railgun"},
}

const SOURCE_REWARDS := {
	"sanatorium:hidden": {"medical_record": 1},
	"metro:hidden": {"ticket_stub": 1},
	"sanatorium:extraction": {"tissue_sample": 1},
	"metro:extraction": {"flooded_circuit": 1},
}

const RARE_PITY_KILLS := 6


static func enemy_family(enemy: Node, world_id: String) -> String:
	if world_id == "metro":
		if enemy is Conductor:
			return "conductor"
		if enemy is Drowned:
			return "drowned"
	if enemy is Crawler:
		return "crawler"
	if enemy is Orderly:
		return "orderly"
	if enemy is Patient:
		return "patient"
	return "default"


static func pool_for(world_id: String, family: String) -> Array:
	return ENEMY_POOLS.get("%s:%s" % [world_id, family], ENEMY_POOLS.default).duplicate(true)


static func roll_enemy(
	world_id: String,
	family: String,
	roll: float,
	difficulty_bonus: float,
	affix_bonus: float,
	rare_pity: int
) -> Dictionary:
	var pool := pool_for(world_id, family)
	var base_percent := 0
	for entry in pool:
		base_percent += int(entry.weight)
	var threshold := clampf(float(base_percent) / 100.0 + difficulty_bonus + affix_bonus, 0.0, 0.92)
	if roll > threshold:
		return {}

	# The extra chance granted by difficulty/affixes becomes the world's common
	# material.  This makes harder enemies improve progression, not only supplies.
	if roll * 100.0 >= float(base_percent):
		return {
			"kind": "material",
			"id": str(WORLD_COMMON_MATERIAL.get(world_id, "")),
			"amount": 1,
			"source": "difficulty_bonus",
		}

	if rare_pity >= RARE_PITY_KILLS:
		for entry in pool:
			if bool(entry.get("rare", false)):
				var guaranteed: Dictionary = entry.duplicate(true)
				guaranteed.source = "rare_pity"
				return guaranteed

	var cursor := roll * 100.0
	for entry in pool:
		cursor -= float(entry.weight)
		if cursor <= 0.0:
			return entry.duplicate(true)
	return pool.back().duplicate(true)


static func boss_reward(world_id: String) -> Dictionary:
	return BOSS_REWARDS.get(world_id, {}).duplicate(true)


static func source_reward(world_id: String, source: String) -> Dictionary:
	return SOURCE_REWARDS.get("%s:%s" % [world_id, source], {}).duplicate(true)


static func describe_pool(world_id: String, family: String) -> Array[String]:
	var lines: Array[String] = []
	for entry in pool_for(world_id, family):
		var label := str(entry.kind)
		if label == "material":
			label = str(ExchangeEvolution.MATERIALS.get(str(entry.id), {}).get("name", entry.id))
		lines.append("%s %d%%" % [label, int(entry.weight)])
	return lines
