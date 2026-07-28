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
	var humanoid := player.get_node("UniversalHumanoidActionCharacter") as UniversalHumanoidActionCharacter
	assert(player.equipped_weapon_item.is_empty())
	assert(humanoid.isolated_demo_mode)
	assert((humanoid.get_node("MainHandEquipment") as Sprite2D).texture == null)
	assert((humanoid.get_node("OffHandEquipment") as Sprite2D).texture == null)
	print("Equipment separation passed: game assets are not used by the character demo")
	quit()
