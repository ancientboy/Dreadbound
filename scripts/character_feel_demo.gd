extends Node2D

func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var player := get_node_or_null("Player") as Player
	if player == null or player._dead:
		return
	match key_event.physical_keycode:
		KEY_H:
			player.take_damage(1, player.global_position + Vector2.RIGHT * 40.0)
		KEY_K:
			player.take_damage(player.health, player.global_position + Vector2.RIGHT * 40.0)
