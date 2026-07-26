class_name ContentCatalog
extends RefCounted

const DEFAULT_PATH := "res://content/dreadbound_content_zh.json"

var data := {}
var errors: Array[String] = []


func _init(path := DEFAULT_PATH) -> void:
	load_path(path)


func load_path(path: String) -> bool:
	data = {}
	errors.clear()
	if not FileAccess.file_exists(path):
		errors.append("内容文件不存在：%s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("内容文件无法读取：%s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		errors.append("内容文件不是 JSON 对象")
		return false
	data = parsed.duplicate(true)
	_validate()
	return errors.is_empty()


func chapter(world_id: String, chapter_id: String) -> Dictionary:
	var world: Dictionary = data.get("dungeons", {}).get(world_id, {})
	return world.get("chapters", {}).get(chapter_id, {}).duplicate(true)


func identity() -> Dictionary:
	return data.get("identity", {}).duplicate(true)


func world_rule(rule_id: String) -> Dictionary:
	return data.get("world_rules", {}).get(rule_id, {}).duplicate(true)


func faction(faction_id: String) -> Dictionary:
	return data.get("factions", {}).get(faction_id, {}).duplicate(true)


func squad() -> Dictionary:
	return data.get("squad", {}).duplicate(true)


func dungeon(world_id: String) -> Dictionary:
	return data.get("dungeons", {}).get(world_id, {}).duplicate(true)


func unique_item(item_id: String) -> Dictionary:
	return data.get("unique_items", {}).get(item_id, {}).duplicate(true)


func material(material_id: String) -> Dictionary:
	return data.get("materials", {}).get(material_id, {}).duplicate(true)


func main_story() -> Dictionary:
	return data.get("main_story", {}).duplicate(true)


func generation_rules() -> Dictionary:
	return data.get("narrative_generation", {}).duplicate(true)


func npc(npc_id: String) -> Dictionary:
	return data.get("npcs", {}).get(npc_id, {}).duplicate(true)


func behavior_event(event_id: String) -> Dictionary:
	return data.get("behavior_events", {}).get(event_id, {}).duplicate(true)


func behavior_events_for(world_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id in data.get("behavior_events", {}):
		var event: Dictionary = behavior_event(str(event_id))
		if str(event.get("world", "any")) in [world_id, "any"]:
			event.id = str(event_id)
			result.append(event)
	result.sort_custom(func(a, b): return str(a.id) < str(b.id))
	return result


func affix(affix_id: String) -> Dictionary:
	return data.get("enemy_affixes", {}).get(affix_id, {}).duplicate(true)


func affix_ids_for(difficulty_id: String) -> Array[String]:
	var ids: Array[String] = []
	for affix_id in data.get("enemy_affixes", {}):
		var affix: Dictionary = data.enemy_affixes[affix_id]
		var difficulties: Array = affix.get("difficulties", [])
		if difficulties.has(difficulty_id):
			ids.append(str(affix_id))
	ids.sort()
	return ids


func _validate() -> void:
	for root_key in ["identity", "world_rules", "factions", "squad", "main_story", "dungeons", "npcs", "unique_items", "materials", "narrative_generation", "behavior_events", "enemy_affixes"]:
		if not data.get(root_key, null) is Dictionary:
			errors.append("缺少内容根节点：%s" % root_key)
	for key in ["title", "genre", "positioning", "themes", "originality_boundary"]:
		if data.get("identity", {}).get(key, null) == null:
			errors.append("游戏定位缺少 %s" % key)
	if data.get("world_rules", {}).size() < 7:
		errors.append("世界法则至少需要七条")
	if data.get("factions", {}).size() != 4:
		errors.append("正式阵营必须恰好四个")
	var squad_data: Dictionary = data.get("squad", {})
	if squad_data.get("roles", {}).size() != 4:
		errors.append("行者编组必须提供四种职责")
	for key in ["formation", "resource_rules", "loss_rules", "betrayal_rules"]:
		if not squad_data.get(key, null) is Dictionary and not squad_data.get(key, null) is Array:
			errors.append("行者编组缺少 %s" % key)
	var ids := {}
	for world_id in data.get("dungeons", {}):
		var world: Dictionary = data.dungeons[world_id]
		for key in ["name", "english_name", "short_intro", "full_story", "core_fear", "anomaly_law", "boss_truth", "unique_items", "materials", "truth_records"]:
			if world.get(key, null) == null or (world.get(key) is String and str(world.get(key, "")).is_empty()):
				errors.append("副本 %s 缺少 %s" % [world_id, key])
		for item_id in world.get("unique_items", []):
			if not data.get("unique_items", {}).has(str(item_id)):
				errors.append("副本 %s 引用了未知唯一物品 %s" % [world_id, item_id])
		for material_id in world.get("materials", []):
			if not data.get("materials", {}).has(str(material_id)):
				errors.append("副本 %s 引用了未知材料 %s" % [world_id, material_id])
		for record in world.get("truth_records", []):
			for key in ["id", "title", "perspective", "text", "unlock"]:
				if record.get(key, null) == null:
					errors.append("副本 %s 的真相档案缺少 %s" % [world_id, key])
		for chapter_id in world.get("chapters", {}):
			var chapter: Dictionary = world.chapters[chapter_id]
			_validate_id("chapter:%s:%s" % [world_id, chapter_id], ids)
			for key in ["title", "briefing"]:
				if str(chapter.get(key, "")).is_empty():
					errors.append("章节 %s/%s 缺少 %s" % [world_id, chapter_id, key])
			var choices: Array = chapter.get("choices", [])
			if not choices.is_empty() and choices.size() < 2:
				errors.append("章节 %s/%s 必须提供至少两个选择" % [world_id, chapter_id])
	for npc_id in data.get("npcs", {}):
		_validate_id("npc:%s" % npc_id, ids)
		var npc_data: Dictionary = data.npcs[npc_id]
		if str(npc_data.get("name", "")).is_empty() or str(npc_data.get("world", "")).is_empty():
			errors.append("NPC %s 缺少 name/world" % npc_id)
	for item_id in data.get("unique_items", {}):
		_validate_id("unique:%s" % item_id, ids)
		var item: Dictionary = data.unique_items[item_id]
		for key in ["name", "serial", "world", "origin", "uniqueness", "acquisition", "cost", "growth", "evolutions", "repeat_defeat"]:
			if item.get(key, null) == null:
				errors.append("唯一物品 %s 缺少 %s" % [item_id, key])
		if not EquipmentDatabase.ITEMS.has(str(item_id)):
			errors.append("唯一物品 %s 未在装备数据库注册" % item_id)
	for material_id in data.get("materials", {}):
		_validate_id("material:%s" % material_id, ids)
		var material_data: Dictionary = data.materials[material_id]
		for key in ["name", "world", "rarity", "origin", "meaning"]:
			if str(material_data.get(key, "")).is_empty():
				errors.append("材料 %s 缺少 %s" % [material_id, key])
		if not ExchangeEvolution.MATERIALS.has(str(material_id)):
			errors.append("材料 %s 未在经济数据库注册" % material_id)
	var generation: Dictionary = data.get("narrative_generation", {})
	for key in ["authored_facts", "generated_variants", "forbidden_mutations", "dungeon_template"]:
		if not generation.get(key, null) is Array:
			errors.append("叙事生成规则缺少 %s" % key)
	for event_id in data.get("behavior_events", {}):
		_validate_id("event:%s" % event_id, ids)
		var event: Dictionary = data.behavior_events[event_id]
		for key in ["title", "description", "event_type"]:
			if str(event.get(key, "")).is_empty():
				errors.append("行为事件 %s 缺少 %s" % [event_id, key])
		if not event.get("choices", null) is Array or event.choices.size() != 2:
			errors.append("行为事件 %s 必须恰好有两个选择" % event_id)
	for affix_id in data.get("enemy_affixes", {}):
		_validate_id("affix:%s" % affix_id, ids)
		var affix_data: Dictionary = data.enemy_affixes[affix_id]
		if str(affix_data.get("prefix", "")).is_empty():
			errors.append("怪物词缀 %s 缺少 prefix" % affix_id)


func _validate_id(id: String, ids: Dictionary) -> void:
	if ids.has(id):
		errors.append("重复内容 ID：%s" % id)
	ids[id] = true
