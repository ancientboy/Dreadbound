extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var player: Player = mission.player
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var orderlies := get_nodes_in_group("orderlies")
	assert(orderlies.size() == 2)
	var orderly: Orderly = orderlies[0]
	assert(orderly.max_health >= 140)
	assert(orderly.windup_duration >= 0.7)
	var bosses := get_nodes_in_group("bosses")
	assert(bosses.size() == 1)
	var boss: SanatoriumBoss = bosses[0]
	assert(not boss.active and not boss.visible)
	for item in mission.interactables:
		if item.kind == ObjectiveInteractable.Kind.RECORD:
			mission._handle_interaction(item)
	for item in mission.interactables:
		if item.kind == ObjectiveInteractable.Kind.POWER:
			mission._handle_interaction(item)
	assert(mission.power_restored)
	assert(boss.active and boss.visible)
	assert(mission.mission_phase == mission.MissionPhase.EVACUATE)
	player.current_weapon = Player.Weapon.SHOTGUN
	player.shells = 2
	player.facing = Vector2.RIGHT
	orderly.global_position = player.global_position + Vector2(120, 20)
	var other: Orderly = orderlies[1]
	other.global_position = player.global_position + Vector2(135, -25)
	var first_health := orderly.health
	var second_health := other.health
	assert(player.try_attack())
	assert(player.shells == 1)
	assert(orderly.health < first_health and other.health < second_health)
	assert(player.add_sedatives(1))
	assert(player.use_sedative())
	assert(player.get_detection_multiplier() < 0.5)
	assert(not player.use_sedative())
	assert(player.add_stimulants(1))
	assert(player.use_stimulant())
	assert(player.stimulant_duration > 0.0)
	print("Vertical slice test passed: Orderly, boss, shotgun, three consumables")
	quit()
