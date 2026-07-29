extends SceneTree

const MANIFEST_PATH := "res://content/alpha_asset_manifest.json"

const REQUIRED_IMAGES := {
	"art_home_keyart": {
		"path": "res://assets/art/brand/home_keyart.png",
		"size": Vector2i(1280, 720),
	},
	"art_corridor_tileset": {
		"path": "res://assets/art/worlds/corridor/corridor_tileset.png",
		"size": Vector2i(256, 256),
	},
	"art_enemy_patient": {
		"path": "res://assets/art/characters/sanatorium/patient_spritesheet.png",
		"size": Vector2i(288, 256),
	},
	"art_sanatorium_room_benchmark": {
		"path": "res://assets/art/worlds/sanatorium/sanatorium_room_benchmark.png",
		"size": Vector2i(1280, 720),
	},
}


func _init() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	assert(file != null)
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	assert(str(manifest.get("production_stage", "")) in ["O1", "O2"])
	assert(str(manifest.get("production_status", "")) in ["visual_slice_review", "audio_system_integration"])

	var entries := {}
	for entry_value in manifest.get("assets", []):
		var entry: Dictionary = entry_value
		entries[str(entry.get("id", ""))] = entry

	for asset_id in REQUIRED_IMAGES:
		var spec: Dictionary = REQUIRED_IMAGES[asset_id]
		assert(entries.has(asset_id), "O1 manifest missing %s" % asset_id)
		assert(str(entries[asset_id].get("status", "")) == "review")
		assert(str(entries[asset_id].get("target", "")) == str(spec.path).trim_prefix("res://"))
		assert(FileAccess.file_exists(str(spec.path)), "O1 image missing %s" % spec.path)
		var texture := load(str(spec.path)) as Texture2D
		assert(texture != null, "O1 texture cannot load: %s" % spec.path)
		var image := texture.get_image()
		assert(not image.is_empty(), "O1 image cannot load: %s" % spec.path)
		assert(image.get_size() == spec.size, "O1 image has wrong size: %s" % spec.path)

	var patient := (load(str(REQUIRED_IMAGES.art_enemy_patient.path)) as Texture2D).get_image()
	assert(patient.detect_alpha() != Image.ALPHA_NONE)

	var startup_source := FileAccess.get_file_as_string("res://scripts/startup.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var patient_source := FileAccess.get_file_as_string("res://scripts/patient.gd")
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	assert(startup_source.contains("home_keyart.png"))
	assert(player_source.contains("_setup_runtime_weapon_vfx"))
	assert(not player_source.contains("drifter_spritesheet.png"))
	assert(patient_source.contains("patient_spritesheet.png"))
	assert(corridor_source.contains("corridor_floor_tile.png"))

	print("O1 visual slice passed: review assets have exact dimensions, alpha where required, and live game references")
	quit()
