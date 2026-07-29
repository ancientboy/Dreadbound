extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var state := root.get_node("GameState") as GameProgress
	var original_pathway := state.selected_pathway
	var original_style := state.active_combat_style
	var original_equipped := state.equipped.duplicate(true)
	state.selected_pathway = ""
	state.active_combat_style = ""
	state.equipped.weapon_1 = "echo_edge"
	state.equipped.weapon_2 = "mourning_bow"
	state.equipped.weapon_3 = "echo_staff"

	var player_scene := load("res://scenes/entities/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	await process_frame
	await process_frame

	var rendered := player.get_node("RenderedAtlasCharacter") as RenderedAtlasCharacter
	assert(rendered != null)
	assert(rendered.runtime_sync_enabled)
	assert(rendered.selected_skin() == &"base_drifter")
	assert(rendered.runtime_weapon_family() == &"echo_edge")
	assert(rendered.owns_equipment_visuals())
	assert(player.weapon_vfx != null)

	rendered._process(1.0 / 60.0)
	assert(rendered.runtime_weapon_layer_visible())
	assert(rendered.selected_preview_attack() == &"attack_melee")
	assert(player.try_attack())
	assert(player.weapon_vfx.last_effect() == &"melee")
	assert(player.weapon_vfx.last_family() == &"echo_edge")

	player._attack_timer = 0.0
	player.equipped_weapon_item = "mourning_bow"
	rendered._process(1.0 / 60.0)
	assert(rendered.runtime_weapon_family() == &"mourning_bow")
	assert(rendered.selected_preview_attack() == &"bow_release")
	assert(player.try_attack())
	assert(player.weapon_vfx.last_effect() == &"bow")
	assert(player.weapon_vfx.last_family() == &"mourning_bow")

	state.selected_pathway = "armorer"
	rendered._process(1.0 / 60.0)
	assert(rendered.selected_skin() == &"armorer_demo_v1")
	assert(not rendered.runtime_weapon_layer_visible())
	assert(rendered.selected_preview_attack() == &"bow_release")

	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	var demo_instance := demo.instantiate()
	root.add_child(demo_instance)
	await process_frame
	await process_frame
	var demo_rendered := (
		demo_instance.get_node("Player/RenderedAtlasCharacter")
		as RenderedAtlasCharacter
	)
	assert(not demo_rendered.runtime_sync_enabled)
	assert(demo_instance.get_node("DemoWeaponVFX") is DemoWeaponVFX)

	demo_instance.queue_free()
	player.queue_free()
	state.selected_pathway = original_pathway
	state.active_combat_style = original_style
	state.equipped = original_equipped
	print(
		"Main character presentation passed: demo retained, runtime actions, "
		+ "main-hand layers, profession skins and shared VFX integrated"
	)
	quit()
