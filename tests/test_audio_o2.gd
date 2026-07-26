extends SceneTree

const REQUIRED := [
	"res://assets/audio/music/music_home_threshold_loop.ogg",
	"res://assets/audio/music/music_corridor_idle_loop.ogg",
	"res://assets/audio/music/music_sanatorium_explore_loop.ogg",
	"res://assets/audio/music/music_sanatorium_boss_loop.ogg",
	"res://assets/audio/music/music_metro_explore_loop.ogg",
	"res://assets/audio/music/music_metro_boss_loop.ogg",
	"res://assets/audio/ambience/amb_corridor_structure_loop.ogg",
	"res://assets/audio/ambience/amb_sanatorium_ward_loop.ogg",
	"res://assets/audio/ambience/amb_metro_platform_loop.ogg",
	"res://assets/audio/sfx/player/combat/player_melee_swing_01.wav",
	"res://assets/audio/sfx/player/combat/player_pistol_fire_01.wav",
	"res://assets/audio/sfx/player/combat/player_shotgun_fire_01.wav",
	"res://assets/audio/sfx/skills/skill_barrier_counter_01.wav",
	"res://assets/audio/sfx/skills/skill_aberrant_form_01.wav",
	"res://assets/audio/sfx/creatures/sanatorium/director_attack_01.wav",
	"res://assets/audio/sfx/creatures/metro/conductor_attack_01.wav",
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for path in REQUIRED:
		var stream := load(path) as AudioStream
		assert(stream != null, "audio stream cannot load: %s" % path)
	for index in range(1, 5):
		assert(ResourceLoader.exists("res://assets/audio/sfx/player/footsteps/player_step_concrete_%02d.wav" % index))
		assert(ResourceLoader.exists("res://assets/audio/sfx/world/pickup/world_pickup_%02d.wav" % index))
	var director := AudioDirector.new()
	root.add_child(director)
	await process_frame
	director.unlock()
	director.set_world("metro", true, true)
	assert(director._music.stream != null and director._ambience.stream != null)
	assert(AudioServer.get_bus_index("Music") >= 0)
	assert(AudioServer.get_bus_index("Ambience") >= 0)
	assert(AudioServer.get_bus_index("Combat") >= 0)
	assert(AudioServer.get_bus_index("Creature") >= 0)
	director.queue_free()
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var fx_source := FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(player_source.contains("AudioDirector.play(\"player_melee\"") and player_source.contains("player_step_water"))
	assert(fx_source.contains("AudioDirector.play_style(kind)"))
	assert(main_source.contains("AudioDirector.set_world"))
	print("O2 audio passed: routed loops, core SFX variants, combat styles and browser-safe director")
	quit()
