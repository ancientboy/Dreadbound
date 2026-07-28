extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	# Equipment assets remain valid for the formal game, but are intentionally not
	# mounted in the isolated Character Feel Demo.
	assert(EquipmentDatabase.get_item("mourning_bow").get("name", "") != "")
	var demo := load("res://scenes/test/character_feel_demo.tscn") as PackedScene
	var instance := demo.instantiate()
	root.add_child(instance)
	await process_frame
	var player := instance.get_node("Player") as Player
	var trial := player.get_node("MartialArtistTrialCharacter") as MartialArtistTrialCharacter
	assert(player.equipped_weapon_item.is_empty())
	assert(trial != null and trial.is_trial_enabled())
	assert(trial.get_node_or_null("MainHandEquipment") == null)
	assert(trial.get_node_or_null("OffHandEquipment") == null)
	print("Equipment separation passed: game assets are not used by the character demo")
	quit()
