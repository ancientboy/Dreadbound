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
	assert(player.get_node("CollisionShape2D") != null)
	assert(get_nodes_in_group("enemies")[0].get_node("CollisionShape2D") != null)
	var pickups = get_nodes_in_group("pickups")
	assert(pickups.size() == 6)
	var bandage: ResourcePickup
	var shard: ResourcePickup
	for pickup in pickups:
		if pickup.kind == ResourcePickup.Kind.BANDAGE and bandage == null:
			bandage = pickup
		elif pickup.kind == ResourcePickup.Kind.ECHO_SHARD and shard == null:
			shard = pickup
	assert(bandage.collect(player))
	assert(player.bandages == 1)
	player._invulnerability_timer = 0.0
	player.take_damage(50, player.global_position - Vector2.RIGHT)
	assert(player.health == 50)
	assert(player.use_bandage())
	assert(player.health == 85)
	assert(player.bandages == 0)
	assert(not player.use_bandage())
	var shard_amount := shard.amount
	assert(shard.collect(player))
	assert(player.echo_shards == shard_amount)
	print("Resource test passed: reusable scenes, pickups, bandage healing, shard inventory")
	quit()
