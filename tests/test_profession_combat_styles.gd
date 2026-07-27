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
	var skill_names: Array[String] = []
	for style_id in ExchangeEvolution.COMBAT_STYLES:
		var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
		var pathway := str(style.path)
		counts[pathway] += 1
		assert(str(style.weapon_type) in ["melee", "ranged", "shotgun"])
		var skill: Dictionary = style.skill
		assert(not str(skill.name).is_empty())
		assert(not skill_names.has(str(skill.name)))
		skill_names.append(str(skill.name))
		assert(str(skill.shape) in ["self", "cone", "line", "target"])
		assert(float(skill.range) >= 100.0)
		assert(float(skill.cooldown) >= 5.0)
		assert(float(skill.damage_multiplier) > 1.0)
	for pathway in counts:
		assert(int(counts[pathway]) == 4)

	assert(Player.weapon_for_attack_type("melee") == Player.Weapon.MELEE)
	assert(Player.weapon_for_attack_type("ranged") == Player.Weapon.RANGED)
	assert(Player.weapon_for_attack_type("shotgun") == Player.Weapon.SHOTGUN)

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
	assert(not player_source.contains("active-skill action is retired"))
	assert(not player_source.contains("combat_fx.profession_skill(style, global_position + facing * 24.0"))
	await _test_all_runtime_skills()
	print("Profession combat passed: three professions, twelve styles, mapped weapons and distinct active skills")
	quit()


func _test_all_runtime_skills() -> void:
	var state := root.get_node("GameState") as GameProgress
	for style_id in ExchangeEvolution.COMBAT_STYLES:
		var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
		var skill: Dictionary = style.skill
		state.selected_pathway = str(style.path)
		state.active_combat_style = str(style_id)
		var runtime_player := Player.new()
		runtime_player.position = Vector2.ZERO
		root.add_child(runtime_player)
		var target := SkillTarget.new()
		target.add_to_group("enemies")
		var target_offset := Vector2.RIGHT * float(skill.range)
		match str(skill.shape):
			"self":
				target_offset = Vector2.RIGHT * float(skill.radius) * 0.6
			"cone", "line":
				target_offset = Vector2.RIGHT * float(skill.range) * 0.7
		target.position = target_offset
		root.add_child(target)
		await process_frame
		runtime_player.facing = Vector2.RIGHT
		assert(runtime_player.current_weapon == Player.weapon_for_attack_type(str(style.weapon_type)))
		if str(style.weapon_type) == "ranged":
			assert(runtime_player.ammo >= 6)
		elif str(style.weapon_type) == "shotgun":
			assert(runtime_player.shells >= 2)
		assert(runtime_player.get_skill_name() == str(skill.name))
		assert(runtime_player.use_active_skill(), "skill failed to cast: %s" % style_id)
		assert(target.damage_taken > 0, "skill missed its authored target: %s" % style_id)
		assert(runtime_player.get_skill_cooldown() > 0.0)
		assert(not runtime_player.use_active_skill(), "cooldown failed: %s" % style_id)
		runtime_player.free()
		target.free()
