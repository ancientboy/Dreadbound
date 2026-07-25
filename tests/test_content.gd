extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var player: Player = mission.player
	var crawlers = get_nodes_in_group("crawlers")
	assert(crawlers.size() == 3)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var crawler: Crawler = crawlers[0]
	crawler.global_position = player.global_position + Vector2(200, 0)
	player.facing = Vector2.RIGHT
	player.switch_weapon()
	assert(player.current_weapon == Player.Weapon.RANGED)
	var starting_ammo := player.ammo
	assert(player.try_attack())
	assert(player.ammo == starting_ammo - 1)
	assert(crawler.health == 10)
	player._attack_timer = 0.0
	assert(player.try_attack())
	assert(crawler.health == 0)
	player.ammo = 0
	player._attack_timer = 0.0
	assert(not player.try_attack())
	var ammo_pickup: ResourcePickup
	for pickup in get_nodes_in_group("pickups"):
		if pickup.kind == ResourcePickup.Kind.AMMO:
			ammo_pickup = pickup
			break
	assert(ammo_pickup != null)
	var pickup_amount := ammo_pickup.amount
	assert(ammo_pickup.collect(player))
	assert(player.ammo == pickup_amount)
	player.switch_weapon()
	assert(player.current_weapon == Player.Weapon.MELEE)
	print("Content test passed: Crawler roster, ranged hit/ammo, empty weapon, ammo pickup, switching")
	quit()
