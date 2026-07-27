extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var mission = load("res://scenes/main.tscn").instantiate()
	root.add_child(mission)
	await process_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var crawler: Crawler = get_nodes_in_group("crawlers")[0]
	var drop: ResourcePickup = mission._drop_for_enemy(crawler, 0.1)
	assert(drop != null)
	assert(drop.kind == ResourcePickup.Kind.BANDAGE)
	assert(drop.amount == 1)
	var chest: RewardChest = mission._spawn_reward_chest(mission.player.global_position)
	assert(chest.candidates.size() == 3)
	var unique := {}
	for item_id in chest.candidates:
		assert(EquipmentDatabase.ITEMS.has(item_id))
		unique[item_id] = true
	assert(unique.size() == 3)
	mission._open_reward_chest(chest)
	mission._choose_reward(0)
	assert(chest.opened)
	assert(mission.run_equipment_rewards.size() == 1)
	var reward_id: String = mission.run_equipment_rewards[0]
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_loot.json"
	state.reset_progress()
	assert(state.settle_run(false, 3, 4, 2, 0, [reward_id]) == 0)
	assert(not state.equipment_inventory.has(reward_id))
	assert(state.settle_run(true, 3, 4, 2, 0, [reward_id]) == 13)
	assert(state.equipment_inventory.has(reward_id))
	assert(state.equip_item(reward_id))
	var item := EquipmentDatabase.get_item(reward_id)
	assert(state.equipped[EquipmentDatabase.equipment_slot(reward_id)] == reward_id)
	state.equipment_inventory.append(reward_id)
	var before_echo := state.echo_shards
	var before_fragments := state.causality_fragments
	var salvage_rewards := state.get_disassembly_rewards(item)
	assert(state.disassemble_item(reward_id))
	assert(state.echo_shards == before_echo + int(salvage_rewards.echo_shards))
	assert(state.causality_fragments == before_fragments + int(salvage_rewards.causality_fragments))
	state.reset_progress()
	state.free()
	print("Loot test passed: enemy drop, fixed chest choices, extraction banking, equip, salvage")
	quit()
