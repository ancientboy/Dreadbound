extends SceneTree


class SkillTarget:
	extends Node2D
	var damage_taken := 0

	func take_damage(amount: int, _source_position: Vector2) -> void:
		damage_taken += amount


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	assert(ExchangeEvolution.validate_catalog().is_empty())
	assert(ExchangeEvolution.COMBAT_STYLES.size() == 12)
	var counts := {"steadfast": 0, "armorer": 0, "resonant": 0}
	for style_id in ExchangeEvolution.COMBAT_STYLES:
		var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
		var pathway := str(style.path)
		counts[pathway] += 1
		assert(str(style.weapon_type) in ["melee", "ranged", "shotgun"])
		assert(style.has("bonuses"))
	for pathway in counts:
		assert(int(counts[pathway]) == 4)

	var player := Player.new()
	player.facing = Vector2.RIGHT
	assert(player._skill_hits_offset(Vector2(90, 0), "self", 120.0, 120.0))
	assert(player._skill_hits_offset(Vector2(150, 20), "cone", 180.0, 0.0))
	assert(not player._skill_hits_offset(Vector2(-40, 0), "cone", 180.0, 0.0))
	assert(player._skill_hits_offset(Vector2(300, 18), "line", 400.0, 24.0))
	assert(not player._skill_hits_offset(Vector2(300, 40), "line", 400.0, 24.0))
	assert(player._skill_hits_offset(Vector2(390, 60), "target", 390.0, 112.0))
	assert(not player._skill_hits_offset(Vector2(190, 60), "target", 390.0, 112.0))
	player.free()

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	assert(player_source.contains("EquipmentDatabase.active_charm_skill"))
	await _test_charm_skill()
	print("Profession combat passed: three professions, twelve passive styles and one charm active")
	quit()


func _test_charm_skill() -> void:
	var state := root.get_node("GameState") as GameProgress
	state.equipped.charm = "medical_tag"
	var runtime_player := Player.new()
	runtime_player.position = Vector2.ZERO
	root.add_child(runtime_player)
	await process_frame
	runtime_player.health = 40
	assert(runtime_player.get_skill_name() == "应急缝合")
	assert(runtime_player.use_active_skill())
	assert(runtime_player.health > 40)
	assert(runtime_player.get_skill_cooldown() > 0.0)
	assert(not runtime_player.use_active_skill())
	runtime_player.free()
