extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"
const REVIEW_ASSETS := {
	"art_corridor_props": ["res://assets/art/worlds/corridor/corridor_props.png", Vector2i(384, 256)],
	"art_icon_service_crowbar": ["res://assets/art/icons/equipment/service_crowbar.png", Vector2i(32, 32)],
	"art_icon_balanced_pistol": ["res://assets/art/icons/equipment/balanced_pistol.png", Vector2i(32, 32)],
	"art_icon_breach_shotgun": ["res://assets/art/icons/equipment/breach_shotgun.png", Vector2i(32, 32)],
	"art_vfx_combat_core": ["res://assets/art/vfx/combat_core.png", Vector2i(256, 128)],
}


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null)
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	var entries := {}
	for entry_value in manifest.get("assets", []):
		var entry: Dictionary = entry_value
		entries[str(entry.get("id", ""))] = entry

	for asset_id in REVIEW_ASSETS:
		var spec: Array = REVIEW_ASSETS[asset_id]
		assert(entries.has(asset_id), "O1 batch 2 manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		var texture := load(str(spec[0])) as Texture2D
		assert(texture != null, "O1 batch 2 texture cannot load: %s" % spec[0])
		var image := texture.get_image()
		assert(not image.is_empty())
		assert(image.get_size() == spec[1], "O1 batch 2 image has wrong size: %s" % spec[0])
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0)

	var player := load("res://scenes/entities/player.tscn").instantiate() as Player
	var patient := load("res://scenes/entities/patient.tscn").instantiate() as Patient
	root.add_child(player)
	root.add_child(patient)
	await process_frame

	var player_character := player.get_node_or_null("RenderedAtlasCharacter") as RenderedAtlasCharacter
	var patient_sprite := patient.get_node_or_null("BodySprite") as Sprite2D
	assert(player_character != null)
	assert(player.get_node_or_null("BodySprite") == null)
	assert(player_character.get_node_or_null("AnimatedSprite2D") != null)
	assert(patient_sprite != null and patient_sprite.texture != null)
	assert(patient_sprite.hframes == 6 and patient_sprite.vframes == 4)
	assert(patient_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(patient_sprite.position == Vector2(0, -26))

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var patient_source := FileAccess.get_file_as_string("res://scripts/patient.gd")
	var combat_source := FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	assert(not player_source.contains("_setup_body_sprite"))
	assert(player_source.contains("_setup_runtime_weapon_vfx"))
	assert(patient_source.contains("using visible fallback silhouette"))
	assert(combat_source.contains("combat_core.png"))
	assert(corridor_source.contains("corridor_props.png"))
	assert(corridor_source.contains("_draw_walker_fallback"))

	player.queue_free()
	patient.queue_free()
	print("O1 batch 2 passed: rendered player, enemy fallback, corridor props and combat atlas")
	quit()
