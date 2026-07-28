extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_weapon_profiles_v25.json"
	state.reset_progress()
	state.equipment_inventory.append_array(["mourning_bow", "echo_staff", "riot_shield", "field_codex"])
	assert(state.equip_item("mourning_bow"))
	assert(state.equip_item("echo_staff"))
	assert(state.equip_item("riot_shield"))
	assert(str(state.equipped.offhand) == "riot_shield")
	assert(state.get_equipped_weapon_for_attack("bow") == "mourning_bow")
	assert(state.get_equipped_weapon_for_attack("arcane") == "echo_staff")

	var bow := EquipmentDatabase.attack_profile("mourning_bow")
	assert(str(bow.id) == "bow")
	assert(str(bow.kind) == "ranged")
	assert(float(bow.range) > 500.0)
	assert(EquipmentDatabase.weapon_tags("mourning_bow").has("echo"))
	var staff := EquipmentDatabase.attack_profile("echo_staff")
	assert(str(staff.id) == "arcane")
	assert(str(staff.kind) == "arcane")
	assert(int(staff.chain_targets) == 2)
	assert(str(staff.cast) == "rift_channel")
	assert(str(staff.vfx) == "arcane_chain")
	assert(float(staff.range) == 365.0)
	var crowbar := EquipmentDatabase.attack_profile("service_crowbar")
	assert(str(crowbar.cast) == "sweep")
	assert(str(crowbar.vfx) == "melee_sweep")
	assert(float(crowbar.range) == 76.0)
	var railgun := EquipmentDatabase.attack_profile("conductor_railgun")
	assert(str(railgun.cast) == "piercing_beam")
	assert(str(railgun.vfx) == "rail_beam")
	assert(EquipmentDatabase.active_charm_skill("medical_tag").has("kind"))
	assert(not ExchangeEvolution.COMBAT_STYLES["weakpoint_sniper"].has("skill"))
	assert(ExchangeEvolution.COMBAT_STYLES["weakpoint_sniper"].preferred_tags.has("bow"))
	assert(ExchangeEvolution.combat_style_tag_multiplier("weakpoint_sniper", "mourning_bow") > 1.0)
	assert(is_equal_approx(ExchangeEvolution.combat_style_tag_multiplier("weakpoint_sniper", "service_crowbar"), 1.0))
	assert(ExchangeEvolution.validate_catalog().is_empty())
	state.reset_progress()
	state.free()
	print("V25 passed: attack profiles, offhands, charm active, and passive styles")
	quit()
