class_name BehaviorKnowledgeBase
extends RefCounted

const DEFAULT_PATH := "res://knowledge/behavior_science_zh.json"

var entries: Array[Dictionary] = []
var guardrails: Array[String] = []
var validation_errors: Array[String] = []


func _init(path := DEFAULT_PATH) -> void:
	load_path(path)


func load_path(path: String) -> bool:
	entries.clear()
	guardrails.clear()
	validation_errors.clear()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	for item in parsed.get("entries", []):
		if item is Dictionary and not str(item.get("id", "")).is_empty():
			entries.append(item.duplicate(true))
	for rule in parsed.get("guardrails", []):
		guardrails.append(str(rule))
	_validate_entries()
	return not entries.is_empty() and validation_errors.is_empty()


func retrieve(tags: Array[String], limit := 3) -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	for entry in entries:
		var score := 0
		var entry_tags: Array = entry.get("tags", [])
		var dimensions: Array = entry.get("dimensions", [])
		for tag in tags:
			if entry_tags.has(tag):
				score += 3
			if dimensions.has(tag) or dimensions.has("all"):
				score += 1
		if score > 0:
			var candidate := entry.duplicate(true)
			candidate.retrieval_score = score
			ranked.append(candidate)
	ranked.sort_custom(func(a, b):
		if int(a.retrieval_score) == int(b.retrieval_score):
			return str(a.id) < str(b.id)
		return int(a.retrieval_score) > int(b.retrieval_score)
	)
	if ranked.size() > limit:
		ranked.resize(limit)
	return ranked


func citation(entry: Dictionary) -> Dictionary:
	return {
		"id": str(entry.get("id", "")),
		"title": str(entry.get("title", "")),
		"source": str(entry.get("source", "")),
		"source_type": str(entry.get("source_type", "")),
	}


func audit_summary() -> Dictionary:
	var source_types := {}
	for entry in entries:
		var source_type := str(entry.get("source_type", "unknown"))
		source_types[source_type] = int(source_types.get(source_type, 0)) + 1
	return {
		"entries": entries.size(),
		"source_types": source_types,
		"errors": validation_errors.duplicate(),
		"auditable": not entries.is_empty() and validation_errors.is_empty(),
	}


func _validate_entries() -> void:
	var ids := {}
	for entry in entries:
		var id := str(entry.get("id", ""))
		if ids.has(id):
			validation_errors.append("重复知识条目：%s" % id)
		ids[id] = true
		for field in ["title", "summary", "source", "source_type"]:
			if str(entry.get(field, "")).is_empty():
				validation_errors.append("%s 缺少 %s" % [id, field])
		if not entry.get("dimensions", null) is Array or entry.dimensions.is_empty():
			validation_errors.append("%s 缺少适用维度" % id)
