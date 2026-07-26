class_name ActionLedger
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_EVENTS := 512

var events: Array[Dictionary] = []
var _run_sequences := {}


func record(run_id: String, profile_id: String, action_code: String, world_id: String, event_type: String, actor := "player", target := "", choice := "", context := {}, result := {}) -> Dictionary:
	if run_id.is_empty() or event_type.is_empty():
		return {}
	var sequence := int(_run_sequences.get(run_id, 0)) + 1
	_run_sequences[run_id] = sequence
	var event := {
		"event_id": "%s:%04d" % [run_id, sequence],
		"run_id": run_id,
		"profile_id": profile_id,
		"action_code": action_code,
		"world_id": world_id,
		"content_version": GameProgress.SAVE_VERSION,
		"sequence": sequence,
		"event_type": event_type,
		"actor": actor,
		"target": target,
		"choice": choice,
		"context": context.duplicate(true) if context is Dictionary else {},
		"result": result.duplicate(true) if result is Dictionary else {},
	}
	events.append(event)
	if events.size() > MAX_EVENTS:
		var recent_events: Array[Dictionary] = []
		recent_events.assign(events.slice(events.size() - MAX_EVENTS))
		events.assign(recent_events)
		_rebuild_sequences()
	return event.duplicate(true)


func events_for_run(run_id: String) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for event in events:
		if str(event.get("run_id", "")) == run_id:
			selected.append(event.duplicate(true))
	return selected


func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "events": events.duplicate(true)}


func load_dict(value: Variant) -> void:
	events.clear()
	if value is Dictionary:
		var saved_events: Variant = value.get("events", [])
		if saved_events is Array:
			for raw_event in saved_events:
				if raw_event is Dictionary and _valid_event(raw_event):
					events.append(raw_event.duplicate(true))
	if events.size() > MAX_EVENTS:
		var recent_events: Array[Dictionary] = []
		recent_events.assign(events.slice(events.size() - MAX_EVENTS))
		events.assign(recent_events)
	_rebuild_sequences()


func clear() -> void:
	events.clear()
	_run_sequences.clear()


func _valid_event(event: Dictionary) -> bool:
	return not str(event.get("event_id", "")).is_empty() \
		and not str(event.get("run_id", "")).is_empty() \
		and not str(event.get("event_type", "")).is_empty() \
		and int(event.get("sequence", 0)) > 0


func _rebuild_sequences() -> void:
	_run_sequences.clear()
	for event in events:
		var run_id := str(event.get("run_id", ""))
		_run_sequences[run_id] = maxi(int(_run_sequences.get(run_id, 0)), int(event.get("sequence", 0)))
