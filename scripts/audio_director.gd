class_name AudioDirector
extends Node

## Central audio routing for Dreadbound. Gameplay only talks in named cues; this
## node owns buses, voice pooling, browser unlock and persisted volume settings.

const BUS_NAMES := ["Music", "Ambience", "Combat", "Creature", "World", "UI", "Voice"]
const MAX_VOICES := 24

const CUES := {
	"ui_hover": ["res://assets/audio/sfx/ui/ui_hover_01.wav", "UI"],
	"ui_confirm": ["res://assets/audio/sfx/ui/ui_confirm_01.wav", "UI"],
	"ui_cancel": ["res://assets/audio/sfx/ui/ui_cancel_01.wav", "UI"],
	"ui_error": ["res://assets/audio/sfx/ui/ui_error_01.wav", "UI"],
	"ui_tab": ["res://assets/audio/sfx/ui/ui_tab_01.wav", "UI"],
	"player_step": ["res://assets/audio/sfx/player/footsteps/player_step_concrete_01.wav", "World"],
	"player_step_water": ["res://assets/audio/sfx/player/footsteps/player_step_water_01.wav", "World"],
	"player_melee": ["res://assets/audio/sfx/player/combat/player_melee_swing_01.wav", "Combat"],
	"player_pistol": ["res://assets/audio/sfx/player/combat/player_pistol_fire_01.wav", "Combat"],
	"player_shotgun": ["res://assets/audio/sfx/player/combat/player_shotgun_fire_01.wav", "Combat"],
	"player_hit": ["res://assets/audio/sfx/player/combat/player_hit_01.wav", "Combat"],
	"player_death": ["res://assets/audio/sfx/player/combat/player_death_01.wav", "Combat"],
	"player_heal": ["res://assets/audio/sfx/player/combat/player_heal_01.wav", "World"],
	"player_switch": ["res://assets/audio/sfx/player/combat/player_switch_01.wav", "Combat"],
	"pickup": ["res://assets/audio/sfx/world/pickup/world_pickup_01.wav", "World"],
	"pickup_rare": ["res://assets/audio/sfx/world/pickup/world_pickup_rare_01.wav", "World"],
	"interact": ["res://assets/audio/sfx/world/objective/world_interact_01.wav", "World"],
	"objective": ["res://assets/audio/sfx/world/objective/world_objective_01.wav", "World"],
	"warning": ["res://assets/audio/sfx/world/objective/world_warning_01.wav", "World"],
	"success": ["res://assets/audio/sfx/world/objective/world_success_01.wav", "World"],
	"extract": ["res://assets/audio/sfx/world/objective/world_extract_01.wav", "World"],
	"patient_windup": ["res://assets/audio/sfx/creatures/sanatorium/patient_windup_01.wav", "Creature"],
	"patient_attack": ["res://assets/audio/sfx/creatures/sanatorium/patient_attack_01.wav", "Creature"],
	"crawler_windup": ["res://assets/audio/sfx/creatures/sanatorium/crawler_windup_01.wav", "Creature"],
	"crawler_attack": ["res://assets/audio/sfx/creatures/sanatorium/crawler_attack_01.wav", "Creature"],
	"orderly_attack": ["res://assets/audio/sfx/creatures/sanatorium/orderly_attack_01.wav", "Creature"],
	"director_windup": ["res://assets/audio/sfx/creatures/sanatorium/director_windup_01.wav", "Creature"],
	"director_attack": ["res://assets/audio/sfx/creatures/sanatorium/director_attack_01.wav", "Creature"],
	"drowned_attack": ["res://assets/audio/sfx/creatures/metro/drowned_attack_01.wav", "Creature"],
	"conductor_windup": ["res://assets/audio/sfx/creatures/metro/conductor_windup_01.wav", "Creature"],
	"conductor_attack": ["res://assets/audio/sfx/creatures/metro/conductor_attack_01.wav", "Creature"],
}

const MUSIC := {
	"home": "res://assets/audio/music/music_home_threshold_loop.ogg",
	"corridor": "res://assets/audio/music/music_corridor_idle_loop.ogg",
	"sanatorium": "res://assets/audio/music/music_sanatorium_explore_loop.ogg",
	"sanatorium_boss": "res://assets/audio/music/music_sanatorium_boss_loop.ogg",
	"metro": "res://assets/audio/music/music_metro_explore_loop.ogg",
	"metro_boss": "res://assets/audio/music/music_metro_boss_loop.ogg",
}

const AMBIENCE := {
	"corridor": "res://assets/audio/ambience/amb_corridor_structure_loop.ogg",
	"sanatorium": "res://assets/audio/ambience/amb_sanatorium_ward_loop.ogg",
	"sanatorium_basement": "res://assets/audio/ambience/amb_sanatorium_basement_loop.ogg",
	"metro": "res://assets/audio/ambience/amb_metro_platform_loop.ogg",
	"metro_flood": "res://assets/audio/ambience/amb_metro_flood_loop.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _settings_path := "user://dreadbound_audio.cfg"
var _unlocked := false


func _ready() -> void:
	_setup_buses()
	_create_players()
	_load_settings()
	get_tree().node_added.connect(_on_node_added)


func unlock() -> void:
	# Browsers require a direct input before audible playback. Calling this from
	# the first click/tap is harmless on desktop and keeps Web exports silent-safe.
	_unlocked = true


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		unlock()


func _on_node_added(node: Node) -> void:
	if not node is BaseButton or node.has_meta("dreadbound_audio_bound"):
		return
	node.set_meta("dreadbound_audio_bound", true)
	node.pressed.connect(func(): play("ui_confirm", 0.02))
	node.mouse_entered.connect(func(): play("ui_hover", 0.01))


func play(cue_id: String, pitch_jitter := 0.0) -> void:
	if not _unlocked or not CUES.has(cue_id):
		return
	var spec: Array = CUES[cue_id]
	var path := _variant_path(str(spec[0]))
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := _available_player()
	player.bus = str(spec[1])
	player.stream = stream
	player.pitch_scale = clampf(1.0 + randf_range(-pitch_jitter, pitch_jitter), 0.82, 1.18)
	player.play()


func play_at(cue_id: String, _world_position: Vector2, pitch_jitter := 0.0) -> void:
	# Current top-down scenes have no Camera2D listener routing for AudioStreamPlayer2D.
	# The named API deliberately preserves that upgrade path without changing callers.
	play(cue_id, pitch_jitter)


func play_style(style_id: String) -> void:
	if not _unlocked:
		return
	var stream := load("res://assets/audio/sfx/skills/skill_%s_01.wav" % style_id) as AudioStream
	if stream == null:
		return
	var player := _available_player()
	player.bus = "Combat"
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()


func play_status(status_id: String) -> void:
	play("warning" if status_id == "freeze" else "objective", 0.025)


func set_world(world_id: String, boss_active := false, flooded := false) -> void:
	var music_id := world_id
	if boss_active and world_id in ["sanatorium", "metro"]:
		music_id = "%s_boss" % world_id
	var ambience_id := "%s_flood" % world_id if flooded and world_id == "metro" else world_id
	_play_loop(_music, MUSIC.get(music_id, MUSIC.home), "Music")
	_play_loop(_ambience, AMBIENCE.get(ambience_id, AMBIENCE.get(world_id, "")), "Ambience")


func set_volume(bus: String, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear, 0.0, 1.0)))
	_save_settings()


func get_volume(bus: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index)) if bus_index >= 0 else 1.0


func _setup_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _create_players() -> void:
	_music = _new_player("Music")
	_ambience = _new_player("Ambience")
	for _index in MAX_VOICES:
		_players.append(_new_player("World"))


func _new_player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]


func _variant_path(base_path: String) -> String:
	if not base_path.ends_with("_01.wav"):
		return base_path
	var candidate := base_path.replace("_01.wav", "_%02d.wav" % randi_range(1, 4))
	return candidate if ResourceLoader.exists(candidate) else base_path


func _play_loop(player: AudioStreamPlayer, path: String, bus: String) -> void:
	if path.is_empty():
		player.stop()
		return
	var stream := load(path) as AudioStream
	if stream == null or player.stream == stream:
		return
	player.stop()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	player.bus = bus
	player.play()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_settings_path) != OK:
		return
	for bus_name in BUS_NAMES:
		set_volume(bus_name, float(config.get_value("audio", bus_name, 1.0)))


func _save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name in BUS_NAMES:
		config.set_value("audio", bus_name, get_volume(bus_name))
	config.save(_settings_path)
