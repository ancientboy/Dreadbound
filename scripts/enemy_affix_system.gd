class_name EnemyAffixSystem
extends RefCounted

const AFFIX_ATLAS: Texture2D = preload("res://assets/art/vfx/materials_enemy_affixes.png")

var catalog := ContentCatalog.new()


func apply(enemy: Node, difficulty_id: String, seed: int, ordinal: int, base_name: String) -> Dictionary:
	var candidates := catalog.affix_ids_for(difficulty_id)
	if candidates.is_empty():
		_set_label(enemy, base_name)
		return {"id": "", "name": base_name, "prefix": "", "drop_bonus": 0.0}
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed * 131 + ordinal * 977 + base_name.hash())
	var chance := 0.38 if difficulty_id == "hazard" else 0.72
	if rng.randf() > chance:
		_set_label(enemy, base_name)
		return {"id": "", "name": base_name, "prefix": "", "drop_bonus": 0.0}
	var affix_id: String = candidates[rng.randi_range(0, candidates.size() - 1)]
	var affix := catalog.affix(affix_id)
	var display_name := "%s%s" % [str(affix.get("prefix", "")), base_name]
	_set_label(enemy, display_name)
	_scale_property(enemy, "max_health", float(affix.get("health", 1.0)))
	if enemy.get("health") != null:
		enemy.health = enemy.max_health
	_scale_property(enemy, "attack_damage", float(affix.get("damage", 1.0)))
	_scale_property(enemy, "movement_speed", float(affix.get("speed", 1.0)))
	_scale_property(enemy, "detection_range", float(affix.get("detection", 1.0)))
	enemy.set_meta("dreadbound_affix", affix_id)
	enemy.set_meta("dreadbound_affix_name", display_name)
	enemy.set_meta("dreadbound_affix_effect", str(affix.get("effect", "")))
	enemy.set_meta("dreadbound_drop_bonus", float(affix.get("drop_bonus", 0.0)))
	if enemy is CanvasItem:
		enemy.modulate = Color(str(affix.get("tint", "ffffff")))
	_attach_visual(enemy, affix_id)
	if enemy.has_method("queue_redraw"):
		enemy.queue_redraw()
	return {
		"id": affix_id,
		"name": display_name,
		"prefix": str(affix.get("prefix", "")),
		"effect": str(affix.get("effect", "")),
		"drop_bonus": float(affix.get("drop_bonus", 0.0)),
	}


func _attach_visual(enemy: Node, affix_id: String) -> void:
	var order := ["elite", "mutated", "frenzied", "frozen", "resonant", "nightmare"]
	var index := order.find(affix_id)
	if index < 0 or AFFIX_ATLAS == null or AFFIX_ATLAS.get_size() != Vector2(320, 128) or not enemy is Node2D:
		return
	var region := AtlasTexture.new()
	region.atlas = AFFIX_ATLAS
	region.region = Rect2(((index + 4) % 5) * 64, floori(float(index + 4) / 5.0) * 64, 64, 64)
	var sprite := Sprite2D.new()
	sprite.name = "AffixVisual"
	sprite.texture = region
	sprite.position = Vector2(0, -28)
	sprite.scale = Vector2.ONE * (1.35 if enemy.is_in_group("bosses") else 0.92)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 4
	enemy.add_child(sprite)


func _set_label(enemy: Node, value: String) -> void:
	if enemy.get("enemy_label") != null:
		enemy.enemy_label = value
	elif enemy.get("boss_label") != null:
		enemy.boss_label = value
	else:
		enemy.set_meta("dreadbound_display_name", value)


func _scale_property(enemy: Node, property: String, multiplier: float) -> void:
	if enemy.get(property) == null:
		return
	var value = enemy.get(property)
	if value is int:
		enemy.set(property, int(round(float(value) * multiplier)))
	elif value is float:
		enemy.set(property, float(value) * multiplier)
