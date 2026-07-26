extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"
const REVIEW_ASSETS := {
	"art_sanatorium_tileset": ["res://assets/art/worlds/sanatorium/sanatorium_tileset.png", Vector2i(256, 256)],
	"art_sanatorium_props": ["res://assets/art/worlds/sanatorium/sanatorium_props.png", Vector2i(512, 384)],
	"art_enemy_crawler": ["res://assets/art/characters/sanatorium/crawler_spritesheet.png", Vector2i(384, 192)],
	"art_enemy_orderly": ["res://assets/art/characters/sanatorium/orderly_spritesheet.png", Vector2i(288, 256)],
	"art_npc_threshold_curator": ["res://assets/art/characters/corridor/threshold_curator_spritesheet.png", Vector2i(576, 384)],
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
		assert(entries.has(asset_id), "O1 batch 3 manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		var texture := load(str(spec[0])) as Texture2D
		assert(texture != null, "O1 batch 3 texture cannot load: %s" % spec[0])
		var image := texture.get_image()
		assert(not image.is_empty())
		assert(image.get_size() == spec[1], "O1 batch 3 image has wrong size: %s" % spec[0])
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0)

	var crawler := load("res://scenes/entities/crawler.tscn").instantiate() as Crawler
	var orderly := load("res://scenes/entities/orderly.tscn").instantiate() as Orderly
	root.add_child(crawler)
	root.add_child(orderly)
	await process_frame

	var crawler_sprite := crawler.get_node_or_null("BodySprite") as Sprite2D
	var orderly_sprite := orderly.get_node_or_null("BodySprite") as Sprite2D
	assert(crawler_sprite != null and crawler_sprite.texture != null)
	assert(orderly_sprite != null and orderly_sprite.texture != null)
	assert(crawler_sprite.hframes == 6 and crawler_sprite.vframes == 4)
	assert(orderly_sprite.hframes == 6 and orderly_sprite.vframes == 4)
	assert(crawler_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(orderly_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)

	assert(is_equal_approx(CombatFX.melee_arc_rotation(Vector2.RIGHT), PI))
	assert(is_equal_approx(CombatFX.melee_arc_rotation(Vector2.DOWN), PI * 1.5))
	assert(is_equal_approx(CombatFX.melee_arc_rotation(Vector2.LEFT), TAU))
	assert(is_equal_approx(CombatFX.melee_arc_rotation(Vector2.UP), PI * 0.5))

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	assert(main_source.contains("sanatorium_tileset.png"))
	assert(main_source.contains("sanatorium_props.png"))
	assert(corridor_source.contains("threshold_curator_spritesheet.png"))
	assert(corridor_source.contains("Vector2(128, 128)"))

	crawler.queue_free()
	orderly.queue_free()
	print("O1 batch 3 passed: sanatorium atlas, props, enemy sprites, boss-scale Curator and corrected melee arc")
	quit()
