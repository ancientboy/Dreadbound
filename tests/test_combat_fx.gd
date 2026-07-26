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
	var active := 0
	for event in fx._events:
		if event.active:
			active += 1
	assert(active >= 11) # swing + pistol/muzzle + shotgun/muzzle/seven pellets + impact
	await create_timer(0.25).timeout
	for event in fx._events:
		assert(not event.active)
	print("Combat FX test passed: pooled melee, tracer, scatter and impact effects expire")
	quit()
