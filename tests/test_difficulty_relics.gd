extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_difficulty_relics.json"
	state.reset_progress()
	assert(state.set_difficulty("nightmare"))
	assert(state.get_difficulty().name == "深渊行动")
	var standard := DynamicRunConfig.new(77, "metro", "standard")
	var nightmare := DynamicRunConfig.new(77, "metro", "nightmare")
	assert(nightmare.patient_spawns.size() > standard.patient_spawns.size())
	assert(EquipmentDatabase.boss_growth_item("sanatorium") == "director_reaper")
	assert(EquipmentDatabase.boss_growth_item("metro") == "conductor_railgun")
	state.equipment_inventory.append("director_reaper")
	assert(state.equip_item("director_reaper"))
	var before: int = int(state.get_player_stats().melee_damage)
	assert(state.award_boss_growth("sanatorium").level == 1)
	assert(state.get_relic_growth("director_reaper") == 1)
	assert(state.get_player_stats().melee_damage == before + 2)
	state.selected_pathway = "steadfast"
	state.unlocked_path_nodes.assign(["steadfast_guard"])
	state.echo_shards = 20
	state.causality_fragments = 3
	assert(state.respec_pathway())
	state.selected_pathway = "steadfast"
	state.unlocked_path_nodes.assign(["steadfast_guard"])
	state.causality_fragments = 3
	assert(state.respec_pathway())
	state.reset_progress()
	state.free()
	print("Difficulty and relic test passed: scaling, drop identity, growth, repeatable respec")
	quit()
