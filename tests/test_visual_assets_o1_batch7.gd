extends SceneTree

const REVIEW_ASSETS := {
	"art_player_drifter_highres": ["res://assets/art/characters/drifter/drifter_highres_spritesheet.png", Vector2i(1536, 1024)],
	"art_player_profession_steadfast": ["res://assets/art/characters/professions/steadfast_spritesheet.png", Vector2i(288, 256)],
	"art_player_profession_armorer": ["res://assets/art/characters/professions/armorer_spritesheet.png", Vector2i(288, 256)],
	"art_player_profession_resonant": ["res://assets/art/characters/professions/resonant_spritesheet.png", Vector2i(288, 256)],
	"art_vfx_profession_skills": ["res://assets/art/vfx/profession_skills.png", Vector2i(512, 384)],
	"art_npc_story_cast": ["res://assets/art/characters/npcs/story_npcs_idle.png", Vector2i(384, 480)],
}

const STYLE_ORDER := [
	"barrier_counter", "last_stand", "sacrifice_medic", "choke_control",
	"weakpoint_sniper", "heavy_suppression", "demolition_traps", "relic_engineer",
	"psychic_sense", "anomaly_ingestion", "echo_summoner", "aberrant_form",
]

const STYLE_SPRITESHEETS := {
	"barrier_counter": "barrier_counter_spritesheet.png", "last_stand": "last_stand_spritesheet.png",
	"sacrifice_medic": "sacrifice_medic_walk_spritesheet.png", "choke_control": "choke_control_spritesheet.png",
	"weakpoint_sniper": "weakpoint_sniper_spritesheet.png", "heavy_suppression": "heavy_suppression_spritesheet.png",
	"demolition_traps": "demolition_traps_spritesheet.png", "relic_engineer": "relic_engineer_spritesheet.png",
	"psychic_sense": "psychic_sense_spritesheet.png", "anomaly_ingestion": "anomaly_ingestion_spritesheet.png",
	"echo_summoner": "echo_summoner_spritesheet.png", "aberrant_form": "aberrant_form_spritesheet.png",
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
	for asset_id in REVIEW_ASSETS:
		var spec: Array = REVIEW_ASSETS[asset_id]
		assert(entries.has(asset_id), "profession/NPC manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		_check_texture(str(spec[0]), spec[1])

	var state := root.get_node_or_null("GameState") as GameProgress
	assert(state != null)
	var original_pathway := state.selected_pathway
	var original_style := state.active_combat_style
	state.selected_pathway = ""
	state.active_combat_style = ""
	var male_player := load("res://scenes/entities/player.tscn").instantiate() as Player
	root.add_child(male_player)
	await process_frame
	var male_sprite := male_player.get_node_or_null("BodySprite") as Sprite2D
	assert(male_sprite != null and male_sprite.texture != null)
	assert(male_sprite.texture.resource_path.ends_with("drifter_spritesheet.png"))
	male_player.queue_free()
	await process_frame
	var profession_paths := {
		"steadfast": "steadfast_spritesheet.png",
		"armorer": "armorer_spritesheet.png",
		"resonant": "resonant_spritesheet.png",
	}
	for pathway in profession_paths:
		state.selected_pathway = pathway
		var player := load("res://scenes/entities/player.tscn").instantiate() as Player
		root.add_child(player)
		await process_frame
		var sprite := player.get_node_or_null("BodySprite") as Sprite2D
		assert(sprite != null and sprite.texture != null)
		assert(sprite.hframes == 6 and sprite.vframes == 4)
		assert(sprite.texture.resource_path.ends_with(profession_paths[pathway]))
		player.queue_free()
		await process_frame
	for style_id in STYLE_ORDER:
		state.active_combat_style = style_id
		var style_player := load("res://scenes/entities/player.tscn").instantiate() as Player
		root.add_child(style_player)
		await process_frame
		var style_sprite := style_player.get_node_or_null("BodySprite") as Sprite2D
		assert(style_sprite != null and style_sprite.texture != null)
		assert(style_sprite.texture.resource_path.ends_with("styles/%s" % STYLE_SPRITESHEETS[style_id]))
		assert(style_sprite.hframes == 6 and style_sprite.vframes == 4)
		style_player.queue_free()
		await process_frame

	var fx := CombatFX.new()
	root.add_child(fx)
	await process_frame
	for style_id in STYLE_ORDER:
		fx.profession_skill(style_id, Vector2.ZERO)
	var active_events := 0
	for event in fx._events:
		if event.active:
			active_events += 1
	assert(active_events == 12)

	var npc_specs := [
		["sanatorium_memory", "失忆病人 · 沈岚", 0],
		["sanatorium_memory", "最后的护理员 · 周衡", 1],
		["linye_story", "失踪乘客 · 林雾", 2],
		["xuzhao_memory", "修表匠 · 许照", 3],
		["ticket_echo_memory", "无票者七号", 4],
		["metro_hidden_archive", "失踪乘客名单", -1],
	]
	for spec in npc_specs:
		var npc := ObjectiveInteractable.new()
		npc.kind = ObjectiveInteractable.Kind.NPC
		npc.objective_id = str(spec[0])
		npc.display_name = str(spec[1])
		assert(npc._story_npc_row() == int(spec[2]))
		npc.free()

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var npc_source := FileAccess.get_file_as_string("res://scripts/objective_interactable.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(player_source.contains("_profession_body_texture"))
	assert(not player_source.contains("FemaleDrifterRig"))
	assert(player_source.contains("COMBAT_STYLE_SPRITESHEETS"))
	assert(not player_source.contains("_draw_combat_style_form"))
	assert(player_source.contains("_play_weapon_attack_vfx"))
	assert(not player_source.contains("_play_attack_style_vfx"))
	assert(npc_source.contains("STORY_NPCS_IDLE"))
	assert(npc_source.contains("_story_npc_row"))
	assert(main_source.contains("play_profession_skill(\"anomaly_ingestion\")"))

	state.selected_pathway = original_pathway
	state.active_combat_style = original_style
	fx.queue_free()
	print("O1 batch 7 passed: three profession bodies, twelve forms/skills and five authored story NPCs")
	quit()


func _check_texture(path: String, expected_size: Vector2i) -> void:
	var texture := load(path) as Texture2D
	assert(texture != null, "texture cannot load: %s" % path)
	var image := texture.get_image()
	assert(not image.is_empty())
	assert(image.get_size() == expected_size, "wrong texture size: %s" % path)
	assert(image.detect_alpha() != Image.ALPHA_NONE, "texture has no alpha: %s" % path)
	assert(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			assert(not (color.r > 0.72 and color.b > 0.72 and color.g < 0.3), "chroma key remains: %s" % path)
