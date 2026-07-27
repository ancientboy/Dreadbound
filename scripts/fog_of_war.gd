class_name FogOfWar
extends Node2D

signal room_revealed(room_id: String)
signal exploration_changed

@export var reveal_duration := 1.35
@export var corridor_reveal_duration := 0.72

var player: Player
var reveal_progress: Dictionary = {}


func _ready() -> void:
	z_index = 20
	for region in _exploration_regions():
		reveal_progress[region.id] = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var changed := _update_region_reveal(delta)
	if changed:
		queue_redraw()
		exploration_changed.emit()


func _update_region_reveal(delta: float) -> bool:
	var changed := false
	for region in _exploration_regions():
		if not region.rect.grow(12.0).has_point(player.global_position):
			continue
		var previous: float = reveal_progress[region.id]
		var duration := reveal_duration if bool(region.get("room", false)) else corridor_reveal_duration
		var current := minf(previous + delta / duration, 1.0)
		reveal_progress[region.id] = current
		changed = changed or not is_equal_approx(previous, current)
		if bool(region.get("room", false)) and previous < 1.0 and current >= 1.0:
			room_revealed.emit(str(region.id))
	return changed


func get_reveal_progress(room_id: String) -> float:
	return reveal_progress.get(room_id, 0.0)


func get_world_reveal_at(world_position: Vector2) -> float:
	var progress := 0.0
	for region in _exploration_regions():
		if region.rect.has_point(world_position):
			progress = maxf(progress, get_reveal_progress(str(region.id)))
	return progress


func _draw() -> void:
	# Regions, not cells, own discovery state.  The small 32px tiles below only
	# cover the world; every tile in a room receives the exact same opacity so a
	# doorway reveals one continuous room-sized sheet of fog.
	for y in range(0, int(SanatoriumLayout.MAP_SIZE.y), 32):
		for x in range(0, int(SanatoriumLayout.MAP_SIZE.x), 32):
			var tile := Rect2(x, y, 32, 32)
			var progress := get_world_reveal_at(tile.get_center())
			var darkness := lerpf(0.97, 0.045, ease(progress, -1.45))
			draw_rect(tile, Color(0.008, 0.02, 0.016, darkness))


func _exploration_regions() -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	for room in SanatoriumLayout.rooms():
		regions.append({"id": room.id, "rect": room.rect, "room": true})
	# Broad circulation zones make corridors emerge as a bank of fog, rather
	# than a chain of individual illuminated pixels.
	regions.append_array([
		{"id": "west_hall", "rect": Rect2(32, 480, 896, 416), "room": false},
		{"id": "central_hall", "rect": Rect2(928, 704, 576, 224), "room": false},
		{"id": "east_hall", "rect": Rect2(1440, 480, 832, 448), "room": false},
		{"id": "lower_west_hall", "rect": Rect2(32, 896, 1440, 512), "room": false},
		{"id": "upper_service", "rect": Rect2(32, 32, 2240, 96), "room": false},
	])
	return regions
