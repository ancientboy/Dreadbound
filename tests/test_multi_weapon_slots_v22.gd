extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := GameProgress.new()
	state.save_path = "user://test_dreadbound_multi_weapon_slots_v22.json"
	state.reset_progress()
	state.equipment_inventory.append_array([
		"balanced_pistol",
		"breach_shotgun",
		"director_reaper",
		"conductor_railgun",
		"siege_core",
	])
	assert(state.equip_item("director_reaper"))
	assert(state.equip_item("conductor_railgun"))
	assert(state.equip_item("siege_core"))
	assert(str(state.equipped.weapon_1) == "director_reaper")
	assert(str(state.equipped.weapon_2) == "conductor_railgun")
	assert(str(state.equipped.weapon_3) == "siege_core")
	assert(state.get_equipped_weapon_for_attack("melee") == "director_reaper")
	assert(state.get_equipped_weapon_for_attack("ranged") == "conductor_railgun")
	assert(state.get_equipped_weapon_for_attack("shotgun") == "siege_core")
	assert(state.is_item_equipped("director_reaper"))
	assert(state.is_item_equipped("conductor_railgun"))
	assert(state.is_item_equipped("siege_core"))

	state.equipped.weapon_3 = ""
	assert(state.get_equipped_weapon_for_attack("shotgun").is_empty())

	var legacy_path := "user://test_dreadbound_multi_weapon_slots_v21.json"
	var legacy := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({
		"version": 21,
		"equipment_inventory": ["service_crowbar", "medical_tag", "conductor_railgun"],
		"equipped": {"weapon": "conductor_railgun", "charm": "medical_tag"},
	}))
	legacy = null
	var migrated := GameProgress.new()
	migrated.save_path = legacy_path
	migrated.load_progress()
	assert(str(migrated.equipped.weapon_1) == "conductor_railgun")
	assert(str(migrated.equipped.charm) == "medical_tag")
	assert(migrated.save_health().migrations.any(func(text): return str(text).contains("v24")))

	state.reset_progress()
	migrated.reset_progress()
	state.free()
	migrated.free()
	print("V24 passed: three free weapon slots with legacy migration")
	quit()
