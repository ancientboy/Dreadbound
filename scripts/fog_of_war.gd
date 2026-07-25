class_name FogOfWar
extends Node2D

signal room_revealed(room_id: String)
signal exploration_changed

const CELL_SIZE := 128.0
const LOCAL_REVEAL_RADIUS := 155.0

@export var reveal_duration := 1.35
@export var corridor_reveal_duration := 0.55

var player: Player
var reveal_progress: Dictionary = {}
var cell_progress: Dictionary = {}


func _ready() -> void:
	z_index = 20
	for room in SanatoriumLayout.rooms():
		reveal_progress[room.id] = 0.0
	for y in range(_row_count()):
		for x in range(_column_count()):
			cell_progress[Vector2i(x, y)] = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var changed := _update_room_reveal(delta)
	changed = _update_world_reveal(delta) or changed
	if changed:
		queue_redraw()
		exploration_changed.emit()


func _update_room_reveal(delta: float) -> bool:
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
	return changed


func _update_world_reveal(delta: float) -> bool:
	var changed := false
	for y in range(_row_count()):
		for x in range(_column_count()):
			var key := Vector2i(x, y)
			var previous: float = cell_progress[key]
			if previous >= 1.0:
				continue
			var cell_rect := _cell_rect(key)
			var target := 0.0
			if cell_rect.get_center().distance_to(player.global_position) <= LOCAL_REVEAL_RADIUS:
				target = minf(previous + delta / corridor_reveal_duration, 1.0)
			for room in SanatoriumLayout.rooms():
				if room.rect.has_point(cell_rect.get_center()):
					target = maxf(target, get_reveal_progress(room.id))
			if target > previous:
				cell_progress[key] = target
				changed = true
	return changed


func get_reveal_progress(room_id: String) -> float:
	return reveal_progress.get(room_id, 0.0)


func get_world_reveal_at(world_position: Vector2) -> float:
	var key := Vector2i(floori(world_position.x / CELL_SIZE), floori(world_position.y / CELL_SIZE))
	return cell_progress.get(key, 0.0)


func _draw() -> void:
	# Every map cell starts nearly opaque. Rooms fade as a whole while corridors
	# reveal locally around the player, producing a continuous exploration trail.
	for y in range(_row_count()):
		for x in range(_column_count()):
			var key := Vector2i(x, y)
			var progress: float = cell_progress[key]
			var darkness := lerpf(0.975, 0.07, ease(progress, -1.7))
			draw_rect(_cell_rect(key), Color(0.002, 0.008, 0.007, darkness))


func _cell_rect(key: Vector2i) -> Rect2:
	var position := Vector2(key) * CELL_SIZE
	var remaining := SanatoriumLayout.MAP_SIZE - position
	return Rect2(position, Vector2(minf(CELL_SIZE, remaining.x), minf(CELL_SIZE, remaining.y)))


func _column_count() -> int:
	return ceili(SanatoriumLayout.MAP_SIZE.x / CELL_SIZE)


func _row_count() -> int:
	return ceili(SanatoriumLayout.MAP_SIZE.y / CELL_SIZE)
