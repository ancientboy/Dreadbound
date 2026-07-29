extends SceneTree

const ASSETS := {
	"art_vfx_sanatorium_enemy_skills": ["res://assets/art/vfx/sanatorium_enemy_skills.png", Vector2i(512, 256), Vector2i(4, 2)],
	"art_material_world_and_enemy_affixes": ["res://assets/art/vfx/materials_enemy_affixes.png", Vector2i(320, 128), Vector2i(5, 2)],
	"art_vfx_profession_skills_steadfast_animated": ["res://assets/art/vfx/profession_skills_steadfast.png", Vector2i(512, 512), Vector2i(4, 4)],
	"art_vfx_profession_skills_armorer_animated": ["res://assets/art/vfx/profession_skills_armorer.png", Vector2i(512, 512), Vector2i(4, 4)],
	"art_vfx_profession_skills_resonant_animated": ["res://assets/art/vfx/profession_skills_resonant.png", Vector2i(512, 512), Vector2i(4, 4)],
	"art_vfx_profession_attack_modes_steadfast": ["res://assets/art/vfx/profession_attack_modes_steadfast.png", Vector2i(512, 384), Vector2i(4, 3)],
	"art_vfx_profession_attack_modes_armorer": ["res://assets/art/vfx/profession_attack_modes_armorer.png", Vector2i(512, 384), Vector2i(4, 3)],
	"art_vfx_profession_attack_modes_resonant": ["res://assets/art/vfx/profession_attack_modes_resonant.png", Vector2i(512, 384), Vector2i(4, 3)],
	"art_ui_progression_status_icons": ["res://assets/art/ui/progression_status_icons.png", Vector2i(192, 96), Vector2i(6, 3)],
	"art_npc_story_portraits": ["res://assets/art/characters/npcs/story_npc_portraits.png", Vector2i(576, 384), Vector2i(3, 2)],
	"art_metro_maintenance_level": ["res://assets/art/worlds/metro/metro_maintenance_atlas.png", Vector2i(512, 256), Vector2i(4, 2)],
	"art_narrative_archive_illustrations": ["res://assets/art/narrative/archive_illustrations.png", Vector2i(768, 288), Vector2i(3, 2)],
	"art_vfx_milestone_feedback": ["res://assets/art/vfx/milestone_feedback.png", Vector2i(768, 192), Vector2i(4, 1)],
}


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var file := FileAccess.open("res://content/alpha_asset_manifest.json", FileAccess.READ)
	assert(file != null)
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	var entries := {}
	for entry_value in manifest.get("assets", []):
		var entry: Dictionary = entry_value
		entries[str(entry.get("id", ""))] = entry
	for asset_id in ASSETS:
		var spec: Array = ASSETS[asset_id]
		assert(entries.has(asset_id), "manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		_check_texture(str(spec[0]), spec[1], spec[2])

	var advanced := ["echo_edge", "insulated_crowbar", "nullpoint_sidearm", "siege_core", "volatile_edge"]
	for index in range(advanced.size()):
		var visual := EquipmentDatabase.weapon_visual(advanced[index])
		assert(str(visual.shape) == "advanced")
		assert(int(visual.atlas_index) == index)

	var pickup := ResourcePickup.new()
	pickup.kind = ResourcePickup.Kind.MATERIAL
	for spec in [["stitch_core", 0], ["flooded_circuit", 1], ["ticket_stub", 2], ["conductor_coil", 3]]:
		pickup.material_id = str(spec[0])
		assert(pickup._material_atlas_index() == int(spec[1]))
	pickup.free()

	var affix_target := Node2D.new()
	affix_target.add_to_group("enemies")
	root.add_child(affix_target)
	var affix_system := EnemyAffixSystem.new()
	for affix_id in ["elite", "mutated", "frenzied", "frozen", "resonant", "nightmare"]:
		var previous := affix_target.get_node_or_null("AffixVisual")
		if previous:
			previous.free()
		affix_system._attach_visual(affix_target, affix_id)
		var visual := affix_target.get_node_or_null("AffixVisual") as Sprite2D
		assert(visual != null and visual.texture != null)
		assert(visual.texture is AtlasTexture)
	affix_target.queue_free()

	var fx := CombatFX.new()
	root.add_child(fx)
	await process_frame
	for skill in ["patient_claw", "crawler_lunge", "orderly_heavy", "director_sweep", "director_slam", "director_mutation", "patient_grasp", "crawler_tear"]:
		fx.sanatorium_enemy_skill(skill, Vector2.ZERO)
	for style in [
		"barrier_counter", "last_stand", "sacrifice_medic", "choke_control",
		"weakpoint_sniper", "heavy_suppression", "demolition_traps", "relic_engineer",
		"psychic_sense", "anomaly_ingestion", "echo_summoner", "aberrant_form",
	]:
		fx.profession_skill(style, Vector2.ZERO)
	for pathway in ["steadfast", "armorer", "resonant"]:
		for attack_kind in ["melee", "ranged", "shotgun"]:
			fx.profession_attack(pathway, attack_kind, Vector2.ZERO)
	assert(fx._events.filter(func(event): return bool(event.active)).size() == 29)
	fx.queue_free()

	var combat_source := FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	var patient_source := FileAccess.get_file_as_string("res://scripts/patient.gd")
	var crawler_source := FileAccess.get_file_as_string("res://scripts/crawler.gd")
	var orderly_source := FileAccess.get_file_as_string("res://scripts/orderly.gd")
	var boss_source := FileAccess.get_file_as_string("res://scripts/boss.gd")
	assert(combat_source.contains("floori(progress * 4.0)"))
	assert(combat_source.contains("profession_attack"))
	assert(patient_source.contains("patient_grasp") and patient_source.contains("patient_claw"))
	assert(crawler_source.contains("crawler_lunge") and crawler_source.contains("crawler_tear"))
	assert(orderly_source.contains("orderly_heavy"))
	assert(boss_source.contains("director_sweep") and boss_source.contains("director_slam") and boss_source.contains("director_mutation"))
	assert(not player_source.contains("COMBAT_STYLE_SPRITESHEETS"))
	assert(not player_source.contains("direction_column * 128"))
	assert(not player_source.contains("_draw_boss_evolution"))
	assert(not player_source.contains("_has_profession_combat_presentation"))
	assert(player_source.contains("_setup_runtime_weapon_vfx"))
	assert(main_source.contains("_draw_metro_maintenance_level"))
	assert(main_source.contains("_set_narrative_portrait"))
	assert(main_source.contains("_refresh_status_icons"))
	assert(corridor_source.contains("_add_archive_illustration"))
	assert(corridor_source.contains("_show_milestone"))
	assert(corridor_source.contains("_affix_icon_index"))
	print("Full visual materialization passed: P0 combat, P1 progression, P2 narrative assets and runtime hooks")
	quit()


func _check_texture(path: String, expected_size: Vector2i, grid: Vector2i) -> void:
	var texture := load(path) as Texture2D
	assert(texture != null, "texture cannot load: %s" % path)
	var image := texture.get_image()
	assert(not image.is_empty())
	assert(image.get_size() == expected_size, "wrong texture size: %s" % path)
	assert(image.detect_alpha() != Image.ALPHA_NONE, "texture has no alpha: %s" % path)
	var cell_size := Vector2i(expected_size.x / grid.x, expected_size.y / grid.y)
	for row in range(grid.y):
		for column in range(grid.x):
			var used := false
			for y in range(row * cell_size.y, (row + 1) * cell_size.y):
				for x in range(column * cell_size.x, (column + 1) * cell_size.x):
					var color := image.get_pixel(x, y)
					assert(not (color.a > 0.1 and color.r > 0.72 and color.b > 0.72 and color.g < 0.3), "magenta key remains: %s" % path)
					if color.a > 0.12:
						used = true
			assert(used, "empty atlas cell %d,%d: %s" % [column, row, path])
