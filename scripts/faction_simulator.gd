class_name FactionSimulator
extends RefCounted

const GOALS := {
	"order_authority": {"target": "safety", "rival": "sunken_cult"},
	"sunken_cult": {"target": "corruption", "rival": "order_authority"},
	"resonance": {"target": "resources", "rival": "drifters"},
	"drifters": {"target": "safety", "rival": "resonance"},
}


func advance(world_state: WorldStateStore, source_event_id := "", advance_cycle := true) -> Dictionary:
	var changes: Array[Dictionary] = []
	var faction_ids: Array = world_state.factions.keys()
	faction_ids.sort()
	var region_ids: Array = world_state.regions.keys()
	region_ids.sort()
	for faction_id in faction_ids:
		var faction: Dictionary = world_state.factions[faction_id]
		var goal: Dictionary = GOALS.get(faction_id, {})
		if goal.is_empty() or region_ids.is_empty():
			continue
		var index := (world_state.cycle + faction_ids.find(faction_id)) % region_ids.size()
		var region_id := str(region_ids[index])
		var strength := 1 + int(faction.get("supplies", 0)) / 35
		var field := str(goal.target)
		var amount := strength if faction_id != "sunken_cult" else strength
		world_state.change_region(region_id, field, amount)
		world_state.change_faction(faction_id, "supplies", -1)
		changes.append({"faction_id": faction_id, "region_id": region_id, "field": field, "amount": amount})
	_resolve_control(world_state, changes)
	if advance_cycle:
		world_state.advance_cycle({
			"world_id": "shared",
			"event_type": "faction_turn",
			"title": "四方势力完成本周期行动",
			"source_event_id": source_event_id,
		})
	return {"cycle": world_state.cycle, "changes": changes, "briefing": build_briefing(world_state)}


func build_briefing(world_state: WorldStateStore) -> Array[String]:
	var lines: Array[String] = []
	var region_ids: Array = world_state.regions.keys()
	region_ids.sort()
	for region_id in region_ids:
		var region: Dictionary = world_state.regions[region_id]
		lines.append("%s：%s 控制，安全 %d / 污染 %d / 资源 %d" % [
			region_id, str(region.get("controller", "drifters")),
			int(region.get("safety", 0)), int(region.get("corruption", 0)), int(region.get("resources", 0)),
		])
	return lines


func _resolve_control(world_state: WorldStateStore, changes: Array[Dictionary]) -> void:
	for region_id in world_state.regions:
		var region: Dictionary = world_state.regions[region_id]
		var candidates: Array[Dictionary] = []
		for faction_id in world_state.factions:
			var faction: Dictionary = world_state.factions[faction_id]
			var affinity := int(faction.get("influence", 0)) + int(faction.get("player_trust", 0))
			if faction_id == "order_authority":
				affinity += int(region.get("safety", 0)) / 3
			elif faction_id == "sunken_cult":
				affinity += int(region.get("corruption", 0)) / 3
			elif faction_id == "resonance":
				affinity += int(region.get("resources", 0)) / 3
			else:
				affinity += (100 - int(region.get("corruption", 0))) / 4
			candidates.append({"id": faction_id, "score": affinity})
		candidates.sort_custom(func(a, b):
			if int(a.score) == int(b.score):
				return str(a.id) < str(b.id)
			return int(a.score) > int(b.score)
		)
		var old_controller := str(region.get("controller", ""))
		var new_controller := str(candidates[0].id)
		if old_controller != new_controller:
			region.controller = new_controller
			world_state.regions[region_id] = region
			changes.append({"region_id": region_id, "field": "controller", "from": old_controller, "to": new_controller})
