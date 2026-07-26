class_name AsyncSociety
extends RefCounted

const SCHEMA_VERSION := 1
const ALLOWED_EVENTS := ["faction_help", "faction_betrayal", "promise_kept", "promise_broken", "rescue", "abandon", "run_settled"]


func build_action_package(profile_id: String, action_code: String, faction_id: String, events: Array[Dictionary], content_version: int) -> Dictionary:
	var safe_events: Array[Dictionary] = []
	for event in events:
		if ALLOWED_EVENTS.has(str(event.get("event_type", ""))):
			safe_events.append({
				"event_id": str(event.get("event_id", "")),
				"event_type": str(event.get("event_type", "")),
				"world_id": str(event.get("world_id", "")),
				"choice": str(event.get("choice", "")),
			})
	return {
		"schema_version": SCHEMA_VERSION,
		"package_id": "%s:%s" % [profile_id, action_code],
		"profile_id": profile_id,
		"action_code": action_code,
		"faction_id": faction_id,
		"content_version": content_version,
		"events": safe_events,
	}


func validate_package(package: Dictionary) -> bool:
	if int(package.get("schema_version", 0)) != SCHEMA_VERSION:
		return false
	if str(package.get("package_id", "")).is_empty() or str(package.get("action_code", "")).is_empty():
		return false
	var events: Variant = package.get("events", [])
	if not events is Array or events.size() > 32:
		return false
	for event in events:
		if not event is Dictionary or not ALLOWED_EVENTS.has(str(event.get("event_type", ""))):
			return false
	return true


func aggregate(packages: Array[Dictionary]) -> Dictionary:
	var accepted := {}
	var factions := {}
	var echoes: Array[Dictionary] = []
	for package in packages:
		if not validate_package(package):
			continue
		var package_id := str(package.package_id)
		if accepted.has(package_id):
			continue
		accepted[package_id] = true
		var faction_id := str(package.get("faction_id", "drifters"))
		factions[faction_id] = int(factions.get(faction_id, 0)) + 1
		echoes.append({
			"package_id": package_id,
			"action_code": str(package.action_code),
			"faction_id": faction_id,
			"event_count": package.events.size(),
		})
	echoes.sort_custom(func(a, b): return str(a.package_id) < str(b.package_id))
	return {"accepted": accepted.size(), "factions": factions, "echoes": echoes}
