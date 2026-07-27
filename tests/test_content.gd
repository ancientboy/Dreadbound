extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	var player: Player = mission.player
	var state := root.get_node("GameState") as GameProgress
	if not state.equipment_inventory.has("balanced_pistol"):
		state.equipment_inventory.append("balanced_pistol")
	if not state.equipment_inventory.has("breach_shotgun"):
		state.equipment_inventory.append("breach_shotgun")
	state.equip_item("balanced_pistol")
	state.equip_item("breach_shotgun")
	state.equipped.weapon_1 = "service_crowbar"
	state.equipped.weapon_2 = "balanced_pistol"
	state.equipped.weapon_3 = "breach_shotgun"
	player._sync_active_weapon_equipment()
	player.ranged_damage = 25
	var crawlers = get_nodes_in_group("crawlers")
	assert(crawlers.size() == 3)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.global_position = Vector2(-1000, -1000)
	var crawler: Crawler = crawlers[0]
	crawler.global_position = player.global_position + Vector2(200, 0)
	player.facing = Vector2.RIGHT
	player.switch_weapon()
	assert(player.get_weapon_name() == "平衡手枪")
	var starting_ammo := player.ammo
	assert(player.try_attack())
	assert(player.ammo == starting_ammo)
	assert(crawler.health == 10)
	player._attack_timer = 0.0
	assert(player.try_attack())
	assert(crawler.health == 0)
	player._attack_timer = 0.0
	assert(player.try_attack())
	var ammo_pickup: ResourcePickup
	for pickup in get_nodes_in_group("pickups"):
		if pickup.kind == ResourcePickup.Kind.AMMO:
			ammo_pickup = pickup
			break
	assert(ammo_pickup == null)
	player.switch_weapon()
	assert(player.get_weapon_name() == "破门霰弹枪")
	player.switch_weapon()
	assert(player.get_weapon_name() == "制式撬棍")
	print("Content test passed: Crawler roster, free weapon slots, no-ammo ranged fire and switching")
	quit()
