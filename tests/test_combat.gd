extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var player: Player = mission.player
	player.attack_damage = 35
	player.max_health = 100
	player.health = 100
	var enemies = get_nodes_in_group("enemies")
	assert(enemies.size() == 10)
	var patient: Patient = enemies[0]
	patient.set_physics_process(false)
	patient.global_position = player.global_position + Vector2(60, 0)
	player.facing = Vector2.RIGHT
	assert(player.try_attack())
	assert(patient.health == 35)
	assert(not player.try_attack())
	player._attack_timer = 0.0
	patient.global_position = player.global_position + Vector2(60, 0)
	assert(player.try_attack())
	assert(patient.health == 0)
	assert(player.take_damage(18, player.global_position - Vector2.RIGHT))
	assert(player.health == 82)
	assert(not player.take_damage(18, player.global_position - Vector2.RIGHT))
	player._invulnerability_timer = 0.0
	player.take_damage(100, player.global_position - Vector2.RIGHT)
	assert(player.health == 0)
	assert(mission.mission_phase == mission.MissionPhase.FAILED)
	assert(mission.complete_panel.visible)
	print("Combat test passed: attack cooldown, enemy damage/death, invulnerability, player failure")
	quit()
