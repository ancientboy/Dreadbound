extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_knowledge_and_humanity()
	_test_factions_curator_and_scenario()
	_test_async_society()
	_test_multiplayer_authority()
	print("J1-J6 systems passed: evidence RAG, echoes, factions, scenario, async society and authoritative multiplayer")
	quit()


func _test_knowledge_and_humanity() -> void:
	var knowledge := BehaviorKnowledgeBase.new()
	assert(knowledge.entries.size() >= 8)
	var promise_sources := knowledge.retrieve(["commitment", "守诺"], 2)
	assert(not promise_sources.is_empty())
	assert(str(promise_sources[0].get("source", "")).length() > 0)

	var ledger := ActionLedger.new()
	ledger.record("run-a", "p1", "SAN-A", "sanatorium", "promise_kept", "player", "survivor")
	ledger.record("run-b", "p1", "MET-B", "metro", "promise_kept", "player", "station_survivor")
	ledger.record("run-c", "p1", "MET-C", "metro", "rescue", "player", "station_survivor")
	var profiler := HumanityProfile.new()
	var profile := profiler.analyze(ledger.events)
	var commitment: Dictionary = profile.dimensions.commitment
	assert(int(commitment.score) > 0)
	assert(float(commitment.confidence) > 0.0)
	assert(not commitment.evidence.is_empty())
	assert(not commitment.knowledge.is_empty())
	assert(str(profile.disclaimer).contains("不是"))
	var echo := profiler.generate_echo(profile)
	assert(str(echo.id) == "promise_remnant")


func _test_factions_curator_and_scenario() -> void:
	var state := WorldStateStore.new()
	var ledger := ActionLedger.new()
	var scenario := FactionScenario.new()
	var started := scenario.begin(state)
	assert(str(started.npc.last_outcome) == "waiting")
	var events := scenario.choose(state, "station_survivor", "promise_rescue", ledger, "MET-1", "p1")
	assert(events.size() == 1)
	var resolved := scenario.resolve_promise(state, true, ledger, "MET-2", "p1")
	assert(str(resolved.event_type) == "promise_kept")
	assert(str(state.npcs.station_survivor.last_outcome) == "rescued")
	ledger.record("SAN-3", "p1", "SAN-3", "sanatorium", "promise_kept", "player", "ward_survivor")

	var engine := ConsequenceEngine.new()
	for event in ledger.events:
		engine.apply_event(event, state)
	var simulator := FactionSimulator.new()
	var first := simulator.advance(state, "MET-2:0001")
	assert(int(first.cycle) == 1)
	assert(first.changes.size() >= 4)
	var clone := WorldStateStore.new()
	clone.load_dict(WorldStateStore.new().to_dict())
	var second := simulator.advance(clone, "MET-2:0001")
	assert(first.changes == second.changes)

	var curator := CuratorV2.new()
	var assessment := curator.assess(ledger.events, state)
	assert(str(assessment.echo.name) == "守诺的残影")
	assert(not str(assessment.trailer).is_empty())
	var contract := curator.offer_contract(assessment, "metro")
	assert(str(contract.id).begins_with("contradict_"))


func _test_async_society() -> void:
	var ledger := ActionLedger.new()
	ledger.record("SAN-1", "p1", "SAN-1", "sanatorium", "rescue", "player", "npc")
	var society := AsyncSociety.new()
	var package := society.build_action_package("p1", "SAN-1", "drifters", ledger.events, 17)
	assert(society.validate_package(package))
	var aggregate := society.aggregate([package, package])
	assert(int(aggregate.accepted) == 1)
	assert(int(aggregate.factions.drifters) == 1)


func _test_multiplayer_authority() -> void:
	var authority := MultiplayerAuthority.new()
	assert(int(authority.create_room("room-a", "host", 4242).seed) == 4242)
	var joined := authority.join_room("room-a", "guest")
	assert(not str(joined.reconnect_token).is_empty())
	var moved := authority.submit("room-a", "guest", "guest:1", 1, "move", {"x": 12.0, "y": -9.0})
	assert(bool(moved.accepted))
	assert(bool(authority.submit("room-a", "guest", "guest:1", 1, "move", {}).duplicate))
	var stale := authority.submit("room-a", "guest", "guest:3", 3, "move", {})
	assert(not bool(stale.accepted) and str(stale.error) == "sequence_conflict")
	var loot := authority.submit("room-a", "host", "host:1", 1, "claim_loot", {"loot_id": "core-1"})
	assert(bool(loot.accepted))
	var conflict := authority.submit("room-a", "guest", "guest:2", 2, "claim_loot", {"loot_id": "core-1"})
	assert(not bool(conflict.accepted))
	var restored := authority.reconnect("room-a", "guest", str(joined.reconnect_token))
	assert(int(restored.revision) == 3)
