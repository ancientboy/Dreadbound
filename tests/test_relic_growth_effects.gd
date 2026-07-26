extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_relic_growth_effects.json"
	state.reset_progress()
	state.equipment_inventory.append("director_reaper")
	assert(state.equip_item("director_reaper"))
	for level in range(5):
		assert(int(state.award_boss_growth("sanatorium").level) == level + 1)
	var reaper_stats := state.get_player_stats()
	var reaper: Dictionary = reaper_stats.relic_profile
	assert(reaper_stats.attack_range == 116.0)
	assert(reaper.knockback > 0.0)
	assert(reaper.status == "freeze")
	assert(reaper.status_every == 2)
	assert(EquipmentDatabase.relic_growth_description("director_reaper", 5).contains("寒霜定身"))
	var visual := EquipmentDatabase.weapon_visual("director_reaper", 5)
	assert(visual.scale > 1.4)

	state.reset_progress()
	state.equipment_inventory.append("conductor_railgun")
	assert(state.equip_item("conductor_railgun"))
	for level in range(5):
		assert(int(state.award_boss_growth("metro").level) == level + 1)
	var rail_stats := state.get_player_stats()
	var rail: Dictionary = rail_stats.relic_profile
	assert(rail_stats.ranged_range == 655.0)
	assert(rail_stats.shotgun_range == 310.0)
	assert(rail.pierce_targets == 3)
	assert(rail.status == "paralyze")
	assert(rail.status_every == 2)
	assert(EquipmentDatabase.relic_growth_description("conductor_railgun", 5).contains("电磁麻痹"))

	var player := Player.new()
	root.add_child(player)
	await process_frame
	player.current_weapon = Player.Weapon.RANGED
	player.equipped_weapon_item = "conductor_railgun"
	player.relic_profile = EquipmentDatabase.relic_growth_profile("conductor_railgun", 5)
	player.ranged_range = 655.0
	player.ranged_damage = 25
	player.ammo = 4
	player.facing = Vector2.RIGHT
	var rail_targets: Array[Patient] = []
	for x in [100.0, 170.0, 240.0, 310.0]:
		var rail_target := Patient.new()
		root.add_child(rail_target)
		rail_target.target = player
		rail_target.global_position = Vector2(x, 0)
		rail_targets.append(rail_target)
	await process_frame
	assert(player.try_attack())
	assert(rail_targets[0].health == 45)
	assert(rail_targets[1].health == 45)
	assert(rail_targets[2].health == 45)
	assert(rail_targets[3].health == 70)
	assert(rail_targets[1].get_meta("dreadbound_control_status") == "paralyze")
	for rail_target in rail_targets:
		rail_target.queue_free()

	var target := Patient.new()
	root.add_child(target)
	target.target = player
	await process_frame
	target.global_position = Vector2(40, 0)
	player.global_position = Vector2.ZERO
	player.equipped_weapon_item = "director_reaper"
	player.relic_profile = EquipmentDatabase.relic_growth_profile("director_reaper", 5)
	player._relic_hit_counter = 1
	var before := target.global_position
	player._apply_relic_hit_effect(target, "melee", Vector2.RIGHT * 40.0)
	assert(target.global_position.x > before.x)
	assert(not target.is_physics_processing())
	assert(target.get_meta("dreadbound_control_status") == "freeze")
	target.queue_free()
	player.queue_free()
	await create_timer(1.2).timeout
	await process_frame
	state.reset_progress()
	state.free()
	print("Relic growth effects test passed: reach, piercing, knockback, control and evolving visuals")
	quit()
