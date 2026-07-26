extends SceneTree

const REVIEW_ASSETS := {
	"art_boss_conductor_echo": ["res://assets/art/characters/metro/last_train_conductor_spritesheet.png", Vector2i(576, 384)],
	"art_weapon_conductor_railgun_growth": ["res://assets/art/weapons/conductor_railgun_growth.png", Vector2i(384, 64)],
	"art_vfx_metro_enemy_skills": ["res://assets/art/vfx/metro_enemy_skills.png", Vector2i(512, 256)],
	"art_vfx_metro_flood_layers": ["res://assets/art/vfx/metro_flood_layers.png", Vector2i(512, 256)],
	"art_vfx_player_states_lighting": ["res://assets/art/vfx/player_states_lighting.png", Vector2i(512, 256)],
	"art_brand_logo": ["res://assets/art/brand/dreadbound_logo.png", Vector2i(512, 128)],
	"art_ui_mobile_controls": ["res://assets/art/ui/mobile_controls.png", Vector2i(256, 128)],
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
		assert(entries.has(asset_id), "metro finish manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec[0]).trim_prefix("res://"))
		_check_texture(str(spec[0]), spec[1])

	var boss := load("res://scenes/entities/last_train_boss.tscn").instantiate() as LastTrainBoss
	root.add_child(boss)
	await process_frame
	var sprite := boss.get_node_or_null("BodySprite") as Sprite2D
	assert(sprite != null and sprite.texture != null)
	assert(sprite.hframes == 6 and sprite.vframes == 4)
	assert(sprite.texture.get_size() == Vector2(576, 384))
	assert(sprite.texture.resource_path.contains("last_train_conductor_spritesheet.png"))
	assert(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)

	var fx := CombatFX.new()
	root.add_child(fx)
	await process_frame
	fx.metro_enemy_skill("drowned_splash", Vector2.ZERO)
	fx.metro_enemy_skill("inspector_charge", Vector2.ZERO, Vector2.RIGHT)
	fx.metro_enemy_skill("anchor_discharge", Vector2.ZERO)
	fx.metro_enemy_skill("conductor_train", Vector2.ZERO, Vector2.LEFT)
	var active := 0
	for event in fx._events:
		if event.active:
			active += 1
	assert(active == 4)

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var conductor_source := FileAccess.get_file_as_string("res://scripts/conductor.gd")
	var startup_source := FileAccess.get_file_as_string("res://scripts/startup.gd")
	var mobile_source := FileAccess.get_file_as_string("res://scripts/mobile_controls.gd")
	assert(main_source.contains("METRO_FLOOD_LAYERS"))
	assert(main_source.contains("_draw_metro_flood_cell"))
	assert(main_source.find("_draw_zones()") < main_source.find("if metro and metro_tide_level > 0"))
	assert(player_source.contains("_draw_deep_water_occlusion()"))
	assert(player_source.contains("environment_water_depth < 2"))
	assert(player_source.contains("_draw_conductor_railgun"))
	assert(player_source.contains("PLAYER_STATES_LIGHTING"))
	assert(player_source.contains("The lamp is body-mounted"))
	assert(not player_source.contains("draw_circle(Vector2.ZERO, 28.0"))
	assert(conductor_source.contains("metro_enemy_skill(\"inspector_charge\""))
	assert(not conductor_source.contains("draw_line(Vector2.ZERO, _charge_direction * 330.0"))
	assert(startup_source.contains("DREADBOUND_LOGO"))
	assert(startup_source.contains("BrandLogo"))
	assert(mobile_source.contains("MOBILE_CONTROL_ICONS"))
	assert(mobile_source.contains("_draw_control_icon(6"))

	boss.queue_free()
	fx.queue_free()
	print("O1 batch 6 passed: deep flood volume, metro skills, conductor boss/railgun, state VFX and body-mounted light")
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
