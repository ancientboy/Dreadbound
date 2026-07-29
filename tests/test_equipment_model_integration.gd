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
	var combat_source := FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	assert(combat_source.contains("weapon_swing_styled"))

	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var player := instance.get_node("Player") as Player
	var rendered := player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	assert(rendered != null)
	assert(rendered.get_node("AnimatedSprite2D").visible)
	assert(player.get_node_or_null("MartialArtistTrialCharacter") == null)
	var humanoid := player.get_node_or_null(
		"UniversalHumanoidActionCharacter"
	) as UniversalHumanoidActionCharacter
	assert(humanoid == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/EquipmentButtons") == null)
	assert(instance.get_node_or_null("HUD/Panel/Margin/Text/OffhandButtons") == null)
	assert(player.equipped_weapon_item.is_empty())
	assert(player.demo_weapon_slots.is_empty())
	assert(player.demo_offhand_item.is_empty())
	assert(player.demo_charm_item.is_empty())
	print("Equipment model integration passed: game equipment remains isolated from action demo")
	quit()
