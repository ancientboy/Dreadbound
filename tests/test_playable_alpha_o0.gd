extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"
const REQUIRED_ART_IDS := [
	"art_home_keyart",
	"art_corridor_tileset",
	"art_sanatorium_tileset",
	"art_metro_tileset",
	"art_player_drifter",
	"art_enemy_patient",
	"art_enemy_crawler",
	"art_enemy_orderly",
	"art_boss_stitch_director",
	"art_enemy_drowned",
	"art_enemy_inspector",
	"art_boss_conductor_echo",
	"art_icon_linye_pass",
	"art_icon_director_reaper",
	"art_icon_conductor_railgun",
	"art_material_tissue_sample",
	"art_material_medical_record",
	"art_material_stitch_core",
	"art_material_flooded_circuit",
	"art_material_ticket_stub",
	"art_material_conductor_coil",
	"art_ui_hub_section_icons",
]
const REQUIRED_AUDIO_IDS := [
	"audio_music_corridor",
	"audio_music_sanatorium_explore",
	"audio_music_metro_explore",
	"audio_amb_corridor",
	"audio_amb_sanatorium_ward",
	"audio_amb_metro_platform",
	"audio_sfx_player_combat",
	"audio_sfx_enemy_sanatorium",
	"audio_sfx_enemy_metro",
	"audio_sfx_objective_extraction",
	"audio_sfx_ui_core",
]


func _init() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null, "O0 asset manifest is missing")
	var parsed = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "O0 asset manifest must be valid JSON")
	var manifest: Dictionary = parsed

	assert(int(manifest.get("schema_version", 0)) == 1)
	assert(str(manifest.get("stage", "")) == "O0")
	assert(str(manifest.get("status", "")) == "locked")
	assert(str(manifest.get("source_of_truth", "")) == "docs/playable-alpha-o0.md")

	var visual: Dictionary = manifest.get("visual_spec", {})
	assert(_numeric_pair(visual.get("design_resolution", [])) == Vector2i(1280, 720))
	assert(_numeric_pair(visual.get("tile_size", [])) == Vector2i(32, 32))
	assert(_numeric_pair(visual.get("human_frame", [])) == Vector2i(48, 64))
	assert(_numeric_pair(visual.get("icon_size", [])) == Vector2i(32, 32))
	assert(_string_array(visual.get("directions", [])) == PackedStringArray(["down", "left", "right", "up"]))
	assert(bool(visual.get("direction_row_order_locked", false)))
	assert(str(visual.get("texture_filter", "")) == "nearest")

	var audio: Dictionary = manifest.get("audio_spec", {})
	assert(int(audio.get("sample_rate_hz", 0)) == 48000)
	assert(int(audio.get("source_bit_depth", 0)) == 24)
	assert(int(audio.get("max_voices_normal", 0)) <= int(audio.get("max_voices_peak", 0)))
	assert(float(audio.get("master_peak_dbtp", 0.0)) <= -1.0)

	var policy: Dictionary = manifest.get("license_policy", {})
	assert(str(policy.get("ledger", "")) == "docs/asset-license-ledger.md")
	assert(bool(policy.get("requires_source_record", false)))
	assert(policy.get("allowed", []).has("CC0"))
	assert(policy.get("forbidden", []).has("unknown"))
	assert(policy.get("forbidden", []).has("CC BY-NC"))

	var valid_statuses: Array = manifest.get("valid_statuses", [])
	var ids := {}
	var art_count := 0
	var audio_count := 0
	for entry_value in manifest.get("assets", []):
		assert(entry_value is Dictionary)
		var entry: Dictionary = entry_value
		var asset_id := str(entry.get("id", ""))
		assert(not asset_id.is_empty())
		assert(not ids.has(asset_id), "duplicate O0 asset id: %s" % asset_id)
		ids[asset_id] = true
		assert(["art", "audio"].has(str(entry.get("discipline", ""))))
		assert(["P0", "P1", "P2"].has(str(entry.get("priority", ""))))
		assert(valid_statuses.has(str(entry.get("status", ""))))
		assert(str(entry.get("target", "")).begins_with("assets/"))
		assert(not str(entry.get("deliverable", "")).is_empty())
		assert(not str(entry.get("source_plan", "")).is_empty())
		if str(entry.discipline) == "art":
			art_count += 1
		else:
			audio_count += 1

	assert(art_count >= 45, "O0 must cover the complete first-pass art inventory")
	assert(audio_count >= 20, "O0 must cover the complete first-pass audio inventory")
	for asset_id in REQUIRED_ART_IDS + REQUIRED_AUDIO_IDS:
		assert(ids.has(asset_id), "O0 is missing required asset: %s" % asset_id)

	for item_id in EquipmentDatabase.ITEMS:
		assert(ids.has("art_icon_%s" % item_id), "equipment lacks an O0 icon asset: %s" % item_id)
	for material_id in ExchangeEvolution.MATERIALS:
		assert(ids.has("art_material_%s" % material_id), "material lacks an O0 icon asset: %s" % material_id)

	print("O0 passed: locked alpha acceptance criteria, visual/audio specs, licensing policy and complete tracked asset inventory")
	quit()


func _numeric_pair(value: Variant) -> Vector2i:
	assert(value is Array and value.size() == 2)
	return Vector2i(int(value[0]), int(value[1]))


func _string_array(value: Variant) -> PackedStringArray:
	assert(value is Array)
	var result := PackedStringArray()
	for item in value:
		result.append(str(item))
	return result
