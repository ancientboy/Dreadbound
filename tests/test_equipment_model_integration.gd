extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var texture := load("res://assets/art/weapons/equipment_runtime.png") as Texture2D
	assert(texture != null)
	assert(texture.get_size() == Vector2(256, 64))
	var image := texture.get_image()
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	for cell in 4:
		var used := false
		for y in 64:
			for x in range(cell * 64, (cell + 1) * 64):
				if image.get_pixel(x, y).a > 0.12:
					used = true
		assert(used, "empty equipment runtime cell %d" % cell)
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/alpha_asset_manifest.json")
	)
	var runtime_entries: Array = manifest.assets.filter(
		func(entry): return str(entry.get("id", "")) == "art_weapon_equipment_runtime"
	)
	assert(runtime_entries.size() == 1)
	assert(str(runtime_entries[0].target) == "assets/art/weapons/equipment_runtime.png")

	assert(str(EquipmentDatabase.weapon_visual("mourning_bow").shape) == "equipment")
	assert(int(EquipmentDatabase.weapon_visual("mourning_bow").atlas_index) == 0)
	assert(str(EquipmentDatabase.weapon_visual("echo_staff").shape) == "equipment")
	assert(int(EquipmentDatabase.weapon_visual("echo_staff").atlas_index) == 1)
	assert(int(EquipmentDatabase.offhand_visual("riot_shield").atlas_index) == 2)
	assert(int(EquipmentDatabase.offhand_visual("field_codex").atlas_index) == 3)
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	assert(player_source.contains("_play_weapon_attack_vfx"))
	assert(not player_source.contains("_play_attack_style_vfx"))

	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var player := instance.get_node("Player") as Player
	var trial := player.get_node("MartialArtistTrialCharacter") as MartialArtistTrialCharacter
	assert(player.equipped_weapon_item == "service_crowbar")
	player.select_demo_weapon_slot(1)
	assert(player.equipped_weapon_item == "mourning_bow")
	assert(str(player._weapon_attack_profile().id) == "bow")
	player._play_weapon_attack_vfx(
		"ranged",
		player._active_attack_range(),
		player.global_position + Vector2.RIGHT * player._active_attack_range(),
	)
	assert(
		player.combat_fx._events.any(
			func(event): return bool(event.get("active", false)) and str(event.get("kind", "")) == "arrow"
		)
	)
	player.select_demo_weapon_slot(2)
	assert(player.equipped_weapon_item == "echo_staff")
	assert(str(player._weapon_attack_profile().id) == "arcane")
	player._play_weapon_attack_vfx(
		"arcane",
		player._active_attack_range(),
		player.global_position + Vector2.RIGHT * player._active_attack_range(),
	)
	assert(
		player.combat_fx._events.any(
			func(event): return bool(event.get("active", false)) and str(event.get("kind", "")) == "arcane_chain"
		)
	)
	assert(
		not player.combat_fx._events.any(
			func(event): return str(event.get("kind", "")).begins_with("profession_attack_")
		)
	)
	player.select_demo_offhand("field_codex")
	assert(player._active_offhand_item() == "field_codex")

	player.facing = Vector2.DOWN
	await process_frame
	assert(trial.equipment_anchor(&"main_hand") == Vector2(15, -28))
	assert(trial.equipment_anchor(&"off_hand") == Vector2(-15, -28))
	player.facing = Vector2.UP
	await process_frame
	assert(trial.equipment_anchor(&"main_hand") == Vector2(-14, -30))
	assert(trial.equipment_anchor(&"off_hand") == Vector2(14, -30))
	print("Equipment model integration passed: bow, staff, shield, codex and anchors")
	quit()
