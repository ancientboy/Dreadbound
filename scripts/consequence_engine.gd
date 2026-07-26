class_name ConsequenceEngine
extends RefCounted


func apply_event(event: Dictionary, world_state: WorldStateStore) -> Array[Dictionary]:
	var event_id := str(event.get("event_id", ""))
	if event_id.is_empty() or world_state.has_processed(event_id):
		return []
	var consequences: Array[Dictionary] = []
	var world_id := str(event.get("world_id", "sanatorium"))
	match str(event.get("event_type", "")):
		"risk_choice":
			var took_risk := bool(event.get("context", {}).get("took_risk", false))
			world_state.change_region(world_id, "corruption", 2 if took_risk else -1)
			world_state.change_faction("resonance", "player_trust", 1 if took_risk else -1)
			consequences.append({"kind": "region", "world_id": world_id, "field": "corruption", "amount": 2 if took_risk else -1})
		"promise_kept":
			world_state.change_faction("drifters", "player_trust", 5)
			world_state.change_region(world_id, "safety", 2)
			consequences.append({"kind": "faction", "faction_id": "drifters", "field": "player_trust", "amount": 5})
		"promise_broken":
			world_state.change_faction("drifters", "player_trust", -8)
			world_state.change_region(world_id, "safety", -3)
			consequences.append({"kind": "faction", "faction_id": "drifters", "field": "player_trust", "amount": -8})
		"rescue", "sacrifice":
			world_state.change_faction("drifters", "player_trust", 4)
			world_state.change_region(world_id, "safety", 2)
			consequences.append({"kind": "relationship", "target": str(event.get("target", "")), "amount": 4})
		"abandon":
			world_state.change_faction("drifters", "player_trust", -4)
			world_state.change_region(world_id, "safety", -2)
			consequences.append({"kind": "relationship", "target": str(event.get("target", "")), "amount": -4})
		"faction_help":
			var helped := str(event.get("context", {}).get("faction_id", "drifters"))
			world_state.change_faction(helped, "player_trust", 3)
			consequences.append({"kind": "faction", "faction_id": helped, "field": "player_trust", "amount": 3})
		"faction_betrayal":
			var betrayed := str(event.get("context", {}).get("faction_id", "drifters"))
			world_state.change_faction(betrayed, "player_trust", -6)
			consequences.append({"kind": "faction", "faction_id": betrayed, "field": "player_trust", "amount": -6})
		"attack_neutral":
			world_state.change_region(world_id, "safety", -2)
			consequences.append({"kind": "region", "world_id": world_id, "field": "safety", "amount": -2})
		"spare_neutral":
			world_state.change_region(world_id, "safety", 1)
			consequences.append({"kind": "region", "world_id": world_id, "field": "safety", "amount": 1})
		"run_settled":
			var success := bool(event.get("result", {}).get("success", false))
			world_state.change_region(world_id, "safety", 2 if success else -2)
			world_state.change_region(world_id, "resources", -1)
			world_state.advance_cycle({
				"world_id": world_id,
				"event_type": "successful_extraction" if success else "lost_connection",
				"title": "撤离改变了区域态势" if success else "失联加剧了区域压力",
				"source_event_id": event_id,
			})
			consequences.append({"kind": "cycle", "cycle": world_state.cycle, "success": success})
	world_state.mark_processed(event_id)
	return consequences
