extends SceneTree

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var fx := CombatFX.new()
	root.add_child(fx)
	await process_frame
	fx.melee_swing(Vector2(10, 10), Vector2.RIGHT, 76.0)
	fx.pistol_shot(Vector2.ZERO, Vector2(200, 0))
	fx.shotgun_blast(Vector2.ZERO, Vector2.RIGHT, 235.0)
	fx.impact(Vector2(80, 0), Vector2.RIGHT, true)
	fx.melee_swing_styled(Vector2.ZERO, Vector2.RIGHT, 76.0, Color("b47cff"))
	fx.movement_echo(Vector2(40, 0), Vector2.RIGHT, Color("88bc82"))
	var events_before_enemy_hit := 0
	for event in fx._events:
		if event.active:
			events_before_enemy_hit += 1
	fx.enemy_hit(Vector2(70, 0), Vector2.RIGHT, true)
	var events_after_enemy_hit := 0
	for event in fx._events:
		if event.active:
			events_after_enemy_hit += 1
	assert(events_after_enemy_hit == events_before_enemy_hit)
	fx.enemy_defeat(Vector2(100, 0), Color("d37a68"))
	fx.attack_telegraph(Vector2(130, 0), 90.0, 0.18)
	fx.loot_burst(Vector2(160, 0))
	var active := 0
	for event in fx._events:
		if event.active:
			active += 1
	assert(active >= 16) # enemy hits no longer allocate a detached spark event
	await create_timer(0.6).timeout
	for event in fx._events:
		assert(not event.active)
	print("Combat FX test passed: pooled melee, tracer, scatter and impact effects expire")
	quit()
