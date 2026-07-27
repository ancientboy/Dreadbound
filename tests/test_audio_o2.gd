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
		assert(ResourceLoader.exists(path), "audio stream cannot load: %s" % path)
	for index in range(1, 5):
		assert(ResourceLoader.exists("res://assets/audio/sfx/world/pickup/world_pickup_%02d.wav" % index))
	var director := root.get_node_or_null("AudioDirector")
	assert(director != null, "AudioDirector autoload must be available")
	await process_frame
	assert(director.MUSIC.size() == 6 and director.AMBIENCE.size() == 5)
	assert(AudioServer.get_bus_index("Music") >= 0)
	assert(AudioServer.get_bus_index("Ambience") >= 0)
	assert(AudioServer.get_bus_index("Combat") >= 0)
	assert(AudioServer.get_bus_index("Creature") >= 0)
	await process_frame
	assert(director.get_tree().root.get_meta("dreadbound_audio_bound", false) == false, "Only UI buttons may receive audio bindings")
	director.set_world("metro", true, true)
	assert(director._music.stream == null and director._ambience.stream == null, "Web loops must wait for the first trusted interaction")
	director.unlock()
	assert(director._music.stream != null and director._ambience.stream != null, "First interaction must start queued music and ambience")
	director.set_music_enabled(false)
	assert(not director.is_music_enabled())
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")))
	director.set_music_enabled(true)
	director.set_sfx_enabled(false)
	assert(not director.is_sfx_enabled())
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI")))
	director.set_sfx_enabled(true)
	director.play_sfx_preview()
	assert(director._last_cue == "player_pistol", "Settings preview must route a real combat cue")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var fx_source := FileAccess.get_file_as_string("res://scripts/combat_fx.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert(player_source.contains("DreadboundAudioDirector") and not player_source.contains("player_step"))
	assert(fx_source.contains("DreadboundAudioDirector"))
	assert(main_source.contains("DreadboundAudioDirector"))
	# Audio settings now live in a reusable panel rather than duplicated scene-local buttons.
	var corridor_source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	assert(corridor_source.contains("DreadboundAudioDirector"))
	var audio_panel_source := FileAccess.get_file_as_string("res://scripts/audio_settings_panel.gd")
	assert(audio_panel_source.contains("InGameMusicToggle") and audio_panel_source.contains("InGameSfxToggle"))
	var startup_source := FileAccess.get_file_as_string("res://scripts/startup.gd")
	assert(startup_source.contains("OpenAudioSettings") and startup_source.contains("MusicToggle") and startup_source.contains("SfxToggle") and startup_source.contains("TestSfx"))
	var director_source := FileAccess.get_file_as_string("res://scripts/audio_director.gd")
	assert(director_source.contains("_bind_existing_buttons") and director_source.contains("_bind_buttons_under"))
	assert(director_source.contains("DreadboundNativeAudio") and director_source.contains("JavaScriptBridge.eval"), "Web export must route audio through the native browser fallback")
	var workflow_source := FileAccess.get_file_as_string("res://.github/workflows/deploy-web.yml")
	assert(workflow_source.contains("builds/web/assets/audio") and workflow_source.contains("DreadboundNativeAudio") and workflow_source.contains("Number.isFinite(gain)"), "Pages build must publish native fallback audio assets and honor per-cue gain")
	director.queue_free()
	await process_frame
	print("O2 audio passed: routed loops, core SFX variants, combat styles and browser-safe director")
	quit()
