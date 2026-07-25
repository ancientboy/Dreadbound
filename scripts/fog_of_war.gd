class_name FogOfWar
extends Node2D

signal room_revealed(room_id: String)

@export var reveal_duration := 1.35

var player: Player
var reveal_progress: Dictionary = {}


func _ready() -> void:
	z_index = 20
	for room in SanatoriumLayout.rooms():
		reveal_progress[room.id] = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var changed := false
	for room in SanatoriumLayout.rooms():
		if not room.rect.grow(12.0).has_point(player.global_position):
			continue
		var previous: float = reveal_progress[room.id]
		var current := minf(previous + delta / reveal_duration, 1.0)
		reveal_progress[room.id] = current
		changed = changed or not is_equal_approx(previous, current)
		if previous < 1.0 and current >= 1.0:
			room_revealed.emit(room.id)
	if changed:
		queue_redraw()


func get_reveal_progress(room_id: String) -> float:
	return reveal_progress.get(room_id, 0.0)


func _draw() -> void:
	for room in SanatoriumLayout.rooms():
		var progress := get_reveal_progress(room.id)
		var eased := ease(progress, -1.8)
		var darkness := lerpf(0.94, 0.08, eased)
		draw_rect(room.rect, Color(0.005, 0.012, 0.011, darkness))
		if progress < 1.0:
			draw_rect(room.rect, Color(0.08, 0.14, 0.12, 0.38 * (1.0 - progress)), false, 3.0)
