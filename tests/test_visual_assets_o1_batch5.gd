extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"
const REVIEW_ASSETS := {
	"art_metro_tileset": ["res://assets/art/worlds/metro/metro_tileset.png", Vector2i(256, 256)],
	"art_metro_props": ["res://assets/art/worlds/metro/metro_props.png", Vector2i(512, 384)],
	"art_enemy_drowned": ["res://assets/art/characters/metro/drowned_spritesheet.png", Vector2i(288, 256)],
	"art_enemy_inspector": ["res://assets/art/characters/metro/inspector_spritesheet.png", Vector2i(288, 256)],
	"art_enemy_signal_anchor": ["res://assets/art/characters/metro/signal_anchor_spritesheet.png", Vector2i(384, 256)],
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
		assert(entries.has(asset_id), "O1 metro manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		_check_texture(str(spec[0]), spec[1])

	var drowned := load("res://scenes/entities/drowned.tscn").instantiate() as Drowned
	var inspector := load("res://scenes/entities/conductor.tscn").instantiate() as Conductor
	var anchor := load("res://scenes/entities/signal_anchor.tscn").instantiate() as SignalAnchor
	root.add_child(drowned)
	root.add_child(inspector)
	root.add_child(anchor)
	await process_frame

	for entity in [drowned, inspector, anchor]:
		var sprite := entity.get_node_or_null("BodySprite") as Sprite2D
		assert(sprite != null and sprite.texture != null)
		assert(sprite.hframes == 6 and sprite.vframes == 4)
		assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(drowned.get_node("BodySprite").texture.resource_path.contains("drowned_spritesheet.png"))
	assert(inspector.get_node("BodySprite").texture.resource_path.contains("inspector_spritesheet.png"))
	assert(anchor.get_node("BodySprite").texture.resource_path.contains("signal_anchor_spritesheet.png"))

	var record := ObjectiveInteractable.new()
	record.kind = ObjectiveInteractable.Kind.RECORD
	record.world_id = "metro"
	assert(record._metro_prop_index() == 4)
	var route_switch := ObjectiveInteractable.new()
	route_switch.kind = ObjectiveInteractable.Kind.POWER
	route_switch.world_id = "metro"
	assert(route_switch._metro_prop_index() == 5)
	var exit := ObjectiveInteractable.new()
	exit.kind = ObjectiveInteractable.Kind.EXIT
	exit.world_id = "metro"
	assert(exit._metro_prop_index() == 10)
	var floodgate := ObjectiveInteractable.new()
	floodgate.kind = ObjectiveInteractable.Kind.FLOODGATE
	floodgate.world_id = "metro"
	assert(floodgate._metro_prop_index() == 6)

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(main_source.contains("_draw_metro_floor()"))
	assert(main_source.find("_draw_metro_floor()") < main_source.find("_draw_zones()"))
	assert(main_source.contains("_draw_metro_water_zone"))
	assert(main_source.contains("_draw_metro_props()"))
	assert(main_source.contains("for region in run_config.map_regions()"))

	drowned.queue_free()
	inspector.queue_free()
	anchor.queue_free()
	record.queue_free()
	route_switch.queue_free()
	exit.queue_free()
	floodgate.queue_free()
	print("O1 batch 5 passed: metro tiles, props, flooded surfaces, objective assets and three dedicated enemy sprites")
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
