extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var tracks: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/humanoid_action_tracks.json"),
	)
	assert(tracks.skeleton_id == "humanoid_v1")
	assert(tracks.action_count == 44)
	for action_name in ["idle", "walk", "punch_jab", "hit_chest", "death"]:
		assert(tracks.actions.has(action_name))
		for direction in tracks.directions:
			assert(tracks.actions[action_name].frames[direction].size() > 0)
	print("Humanoid baseline tracks passed")
	quit()
