class_name FactionScenario
extends RefCounted

const SCENARIOS := {
	"station_survivor": {
		"title": "无人电台",
		"region": "metro",
		"npc_id": "station_survivor",
		"choices": ["promise_rescue", "sell_location", "mediate"],
	}
}


func begin(world_state: WorldStateStore, scenario_id := "station_survivor") -> Dictionary:
	if not SCENARIOS.has(scenario_id):
		return {}
	var scenario: Dictionary = SCENARIOS[scenario_id].duplicate(true)
	var npc_id := str(scenario.npc_id)
	if not world_state.npcs.has(npc_id):
		world_state.npcs[npc_id] = {
			"alive": true, "trust": 0, "injury": 1, "location": str(scenario.region),
			"promise": "", "last_outcome": "waiting",
		}
	scenario.id = scenario_id
	scenario.npc = world_state.npcs[npc_id].duplicate(true)
	scenario.region_state = world_state.regions.get(str(scenario.region), {}).duplicate(true)
	return scenario


func choose(world_state: WorldStateStore, scenario_id: String, choice: String, ledger: ActionLedger, run_id: String, profile_id: String) -> Array[Dictionary]:
	if not SCENARIOS.has(scenario_id):
		return []
	var scenario: Dictionary = SCENARIOS[scenario_id]
	if not scenario.choices.has(choice):
		return []
	var npc_id := str(scenario.npc_id)
	var npc: Dictionary = world_state.npcs.get(npc_id, {})
	var emitted: Array[Dictionary] = []
	match choice:
		"promise_rescue":
			npc.promise = "rescue"
			npc.last_outcome = "promised"
			emitted.append(ledger.record(run_id, profile_id, run_id, str(scenario.region), "promise_made", "player", npc_id, choice))
		"sell_location":
			npc.trust = int(npc.get("trust", 0)) - 20
			npc.last_outcome = "betrayed"
			emitted.append(ledger.record(run_id, profile_id, run_id, str(scenario.region), "faction_betrayal", "player", npc_id, choice, {"faction_id": "order_authority"}))
			emitted.append(ledger.record(run_id, profile_id, run_id, str(scenario.region), "promise_broken", "player", npc_id, choice))
		"mediate":
			npc.trust = int(npc.get("trust", 0)) + 8
			npc.last_outcome = "protected"
			emitted.append(ledger.record(run_id, profile_id, run_id, str(scenario.region), "faction_help", "player", npc_id, choice, {"faction_id": "drifters"}))
			emitted.append(ledger.record(run_id, profile_id, run_id, str(scenario.region), "rescue", "player", npc_id, choice))
	world_state.npcs[npc_id] = npc
	return emitted


func resolve_promise(world_state: WorldStateStore, kept: bool, ledger: ActionLedger, run_id: String, profile_id: String) -> Dictionary:
	var npc_id := "station_survivor"
	var npc: Dictionary = world_state.npcs.get(npc_id, {})
	if str(npc.get("promise", "")) != "rescue":
		return {}
	npc.promise = ""
	npc.last_outcome = "rescued" if kept else "abandoned"
	npc.alive = kept
	npc.trust = int(npc.get("trust", 0)) + (25 if kept else -30)
	world_state.npcs[npc_id] = npc
	return ledger.record(run_id, profile_id, run_id, "metro", "promise_kept" if kept else "promise_broken", "player", npc_id, "return" if kept else "leave")
