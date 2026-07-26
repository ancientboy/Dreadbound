class_name WorldStateStore
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_PROCESSED_EVENTS := 512
const MAX_WORLD_EVENTS := 64
const FACTION_IDS := ["order_authority", "sunken_cult", "resonance", "drifters"]

var cycle := 0
var factions := {}
var regions := {}
var npcs := {}
var world_events: Array[Dictionary] = []
var processed_event_ids: Array[String] = []


func _init() -> void:
	reset()


func reset() -> void:
	cycle = 0
	factions = {
		"order_authority": {"influence": 50, "supplies": 50, "player_trust": 0},
		"sunken_cult": {"influence": 50, "supplies": 50, "player_trust": 0},
		"resonance": {"influence": 50, "supplies": 50, "player_trust": 0},
		"drifters": {"influence": 35, "supplies": 35, "player_trust": 0},
	}
	regions = {
		"sanatorium": {"controller": "order_authority", "safety": 40, "corruption": 35, "resources": 45},
		"metro": {"controller": "drifters", "safety": 25, "corruption": 55, "resources": 40},
	}
	npcs = {}
	world_events.clear()
	processed_event_ids.clear()


func has_processed(event_id: String) -> bool:
	return processed_event_ids.has(event_id)


func mark_processed(event_id: String) -> void:
	if event_id.is_empty() or processed_event_ids.has(event_id):
		return
	processed_event_ids.append(event_id)
	if processed_event_ids.size() > MAX_PROCESSED_EVENTS:
		var recent_ids: Array[String] = []
		recent_ids.assign(processed_event_ids.slice(processed_event_ids.size() - MAX_PROCESSED_EVENTS))
		processed_event_ids.assign(recent_ids)


func change_faction(faction_id: String, field: String, amount: int) -> void:
	if not factions.has(faction_id):
		return
	var faction: Dictionary = factions[faction_id]
	faction[field] = clampi(int(faction.get(field, 0)) + amount, -100 if field == "player_trust" else 0, 100)
	factions[faction_id] = faction


func change_region(world_id: String, field: String, amount: int) -> void:
	if not regions.has(world_id):
		regions[world_id] = {"controller": "drifters", "safety": 30, "corruption": 40, "resources": 35}
	var region: Dictionary = regions[world_id]
	region[field] = clampi(int(region.get(field, 0)) + amount, 0, 100)
	regions[world_id] = region


func advance_cycle(summary: Dictionary) -> void:
	cycle += 1
	world_events.push_front({
		"cycle": cycle,
		"world_id": str(summary.get("world_id", "")),
		"event_type": str(summary.get("event_type", "world_advanced")),
		"title": str(summary.get("title", "世界状态已推进")),
		"source_event_id": str(summary.get("source_event_id", "")),
	})
	if world_events.size() > MAX_WORLD_EVENTS:
		world_events.resize(MAX_WORLD_EVENTS)


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"cycle": cycle,
		"factions": factions.duplicate(true),
		"regions": regions.duplicate(true),
		"npcs": npcs.duplicate(true),
		"world_events": world_events.duplicate(true),
		"processed_event_ids": processed_event_ids.duplicate(),
	}


func load_dict(value: Variant) -> void:
	reset()
	if not value is Dictionary:
		return
	cycle = maxi(int(value.get("cycle", 0)), 0)
	_merge_dictionary(factions, value.get("factions", {}))
	_merge_dictionary(regions, value.get("regions", {}))
	var saved_npcs: Variant = value.get("npcs", {})
	npcs = saved_npcs.duplicate(true) if saved_npcs is Dictionary else {}
	var saved_world_events: Variant = value.get("world_events", [])
	if saved_world_events is Array:
		world_events.assign(saved_world_events.slice(0, MAX_WORLD_EVENTS))
	processed_event_ids.clear()
	var saved_processed: Variant = value.get("processed_event_ids", [])
	if saved_processed is Array:
		for event_id in saved_processed.slice(maxi(saved_processed.size() - MAX_PROCESSED_EVENTS, 0)):
			if not str(event_id).is_empty():
				processed_event_ids.append(str(event_id))


func _merge_dictionary(target: Dictionary, source: Variant) -> void:
	if not source is Dictionary:
		return
	for key in source:
		if source[key] is Dictionary:
			target[str(key)] = source[key].duplicate(true)
