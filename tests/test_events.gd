extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var player: Player = mission.player
	player.bandages = 0
	player.ammo = 0
	var cabinet: RiskEvent = mission.risk_events[0]
	mission._open_risk_event(cabinet)
	assert(mission.event_panel.visible)
	mission._resolve_active_event(true)
	assert(cabinet.resolved)
	assert(player.bandages == 1)
	assert(player.ammo == 8)
	assert(player.health == player.max_health - 15)
	var ward: RiskEvent = mission.risk_events[1]
	var enemy_count := get_nodes_in_group("enemies").size()
	mission._open_risk_event(ward)
	mission._resolve_active_event(true)
	await process_frame
	assert(player.echo_shards == 5)
	assert(get_nodes_in_group("enemies").size() == enemy_count + 2)
	assert(mission.event_results.size() == 2)
	print("Risk event test passed: modal pause, supply tradeoff, shard ambush, outcomes")
	quit()
