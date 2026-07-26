extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _assert_chinese_font_inherited(node: Node, expected_font: Font) -> void:
	if node is Label or node is Button or node is LineEdit:
		assert(node.get_theme_font("font") == expected_font, "%s did not inherit the Chinese UI font" % node.name)
	for child in node.get_children():
		_assert_chinese_font_inherited(child, expected_font)


func _run_test() -> void:
	var profile_gate: Control = load("res://scenes/profile_gate.tscn").instantiate()
	root.add_child(profile_gate)
	await process_frame
	assert(profile_gate.theme != null)
	assert(profile_gate.theme.default_font == profile_gate.UI_FONT)
	_assert_chinese_font_inherited(profile_gate, profile_gate.UI_FONT)
	profile_gate.queue_free()
	await process_frame
	print("Profile gate font test passed: all labels, buttons and inputs inherit the full Chinese UI font")
	quit()
