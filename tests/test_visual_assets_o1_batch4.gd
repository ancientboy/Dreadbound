extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"
const REVIEW_ASSETS := {
	"art_boss_stitch_director": ["res://assets/art/characters/sanatorium/stitch_director_spritesheet.png", Vector2i(576, 384)],
	"art_weapon_director_reaper_growth": ["res://assets/art/weapons/director_reaper_growth.png", Vector2i(384, 64)],
	"art_icon_echo_edge": ["res://assets/art/icons/equipment/echo_edge.png", Vector2i(32, 32)],
	"art_icon_medical_tag": ["res://assets/art/icons/equipment/medical_tag.png", Vector2i(32, 32)],
	"art_icon_calming_coil": ["res://assets/art/icons/equipment/calming_coil.png", Vector2i(32, 32)],
	"art_icon_ward_echo": ["res://assets/art/icons/equipment/ward_echo.png", Vector2i(32, 32)],
	"art_icon_director_reaper": ["res://assets/art/icons/unique/director_reaper.png", Vector2i(32, 32)],
	"art_material_tissue_sample": ["res://assets/art/icons/materials/tissue_sample.png", Vector2i(32, 32)],
	"art_material_medical_record": ["res://assets/art/icons/materials/medical_record.png", Vector2i(32, 32)],
	"art_material_stitch_core": ["res://assets/art/icons/materials/stitch_core.png", Vector2i(32, 32)],
	"art_vfx_world_feedback": ["res://assets/art/vfx/world_feedback.png", Vector2i(256, 128)],
	"art_vfx_sanatorium_objective_lighting": ["res://assets/art/vfx/sanatorium_objective_lighting.png", Vector2i(512, 256)],
	"art_world_reward_chest": ["res://assets/art/worlds/global/reward_chest.png", Vector2i(64, 64)],
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
		assert(entries.has(asset_id), "O1 batch 4 manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		var texture := load(str(spec[0])) as Texture2D
		assert(texture != null, "O1 batch 4 texture cannot load: %s" % spec[0])
		var image := texture.get_image()
		assert(not image.is_empty())
		assert(image.get_size() == spec[1], "O1 batch 4 image has wrong size: %s" % spec[0])
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		assert(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0)
		_assert_no_chroma_key(image, str(spec[0]))

	var boss := load("res://scenes/entities/boss.tscn").instantiate() as SanatoriumBoss
	root.add_child(boss)
	await process_frame
	var boss_sprite := boss.get_node_or_null("BodySprite") as Sprite2D
	assert(boss_sprite != null and boss_sprite.texture != null)
	assert(boss_sprite.hframes == 6 and boss_sprite.vframes == 4)
	assert(boss_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(boss_sprite.position == Vector2(0, -44))

	var record := ObjectiveInteractable.new()
	record.kind = ObjectiveInteractable.Kind.RECORD
	record.world_id = "sanatorium"
	assert(record._objective_sprite_index() == 0)
	record.mark_complete()
	assert(record._objective_sprite_index() == 1)
	var exit := ObjectiveInteractable.new()
	exit.kind = ObjectiveInteractable.Kind.EXIT
	exit.world_id = "sanatorium"
	assert(exit._objective_sprite_index() == 2)
	exit.mark_active()
	assert(exit._objective_sprite_index() == 3)

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	var pickup_source := FileAccess.get_file_as_string("res://scripts/pickup.gd")
	assert(player_source.contains("if visual.id != \"resonant\""))
	assert(not player_source.contains("_draw_flashlight()"))
	assert(player_source.contains("director_reaper_growth.png"))
	assert(main_source.contains("_draw_sanatorium_passages()"))
	assert(main_source.find("_draw_sanatorium_passages()") < main_source.find("_draw_grid()"))
	assert(main_source.contains("_draw_sanatorium_lights()"))
	assert(main_source.contains("item.mark_active()"))
	assert(pickup_source.contains("world_feedback.png"))
	for item_id in ["echo_edge", "medical_tag", "calming_coil", "ward_echo", "director_reaper"]:
		assert(corridor_source.contains("\"%s\"" % item_id), "warehouse icon not wired: %s" % item_id)
	for material_id in ["tissue_sample", "medical_record", "stitch_core"]:
		assert(corridor_source.contains("\"%s\"" % material_id), "material icon not wired: %s" % material_id)

	boss.queue_free()
	record.queue_free()
	exit.queue_free()
	print("O1 batch 4 passed: boss, relic growth, sanatorium icons, pickups, passage tiles, objective sprites, pixel lighting and echo cleanup")
	quit()


func _assert_no_chroma_key(image: Image, path: String) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			assert(not (color.r > 0.72 and color.b > 0.72 and color.g < 0.3), "chroma key pixel remains in %s" % path)
