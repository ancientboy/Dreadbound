class_name BehaviorKnowledgeBase
extends RefCounted

const DEFAULT_PATH := "res://knowledge/behavior_science_zh.json"

var entries: Array[Dictionary] = []
var guardrails: Array[String] = []


func _init(path := DEFAULT_PATH) -> void:
	load_path(path)


func load_path(path: String) -> bool:
	entries.clear()
	guardrails.clear()
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
	return not entries.is_empty()


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
