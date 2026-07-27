class_name FogOfWar
extends Node2D

signal room_revealed(room_id: String)
signal exploration_changed

# Exploration is no longer visually gated.  The node remains as a shared map
# visibility source so the minimap and encounter director see the whole level.
const EXPLORATION_FOG_ENABLED := false

var player: Player
var reveal_progress: Dictionary = {}
var run_config: DynamicRunConfig


func configure_for_run(config: DynamicRunConfig) -> void:
	run_config = config
	_reset_exploration()


func _ready() -> void:
	z_index = 20
	_reset_exploration()


func _reset_exploration() -> void:
	reveal_progress.clear()
	for region in _exploration_regions():
		reveal_progress[region.id] = 1.0
	queue_redraw()
	exploration_changed.emit()


func _process(delta: float) -> void:
	if not EXPLORATION_FOG_ENABLED or not is_instance_valid(player):
		return
	var changed := _update_region_reveal(delta)
	if changed:
		queue_redraw()
		exploration_changed.emit()


func _update_region_reveal(delta: float) -> bool:
	return false


func get_reveal_progress(room_id: String) -> float:
	return 1.0 if not EXPLORATION_FOG_ENABLED else reveal_progress.get(room_id, 0.0)


func get_world_reveal_at(world_position: Vector2) -> float:
	if not EXPLORATION_FOG_ENABLED:
		return 1.0
	# Rooms take priority over the broad circulation rectangles below. This keeps
	# a nearby hallway from revealing the contents of a room before the player
	# crosses its threshold.
	for region in _exploration_regions():
		if bool(region.get("room", false)) and region.rect.has_point(world_position):
			return get_reveal_progress(str(region.id))
	var progress := 0.0
	for region in _exploration_regions():
		if bool(region.get("room", false)):
			continue
		if region.rect.has_point(world_position):
			progress = maxf(progress, get_reveal_progress(str(region.id)))
	return progress


func _draw() -> void:
	if not EXPLORATION_FOG_ENABLED:
		return
	# Regions, not cells, own discovery state. The tiles below only paint the
	# overlay: every visible part of a room or a corridor section receives the
	# same opacity, so there is never a pixel-by-pixel trail behind the player.
	var map_size := run_config.map_size() if run_config != null else SanatoriumLayout.MAP_SIZE
	for y in range(0, int(map_size.y), 32):
		for x in range(0, int(map_size.x), 32):
			var tile := Rect2(x, y, 32, 32)
			var progress := get_world_reveal_at(tile.get_center())
			var darkness := lerpf(0.97, 0.045, ease(progress, -1.45))
			draw_rect(tile, Color(0.008, 0.02, 0.016, darkness))


func _exploration_regions() -> Array[Dictionary]:
	if run_config != null and run_config.world_id == "metro":
		return _metro_exploration_regions()
	var regions: Array[Dictionary] = []
	for room in SanatoriumLayout.rooms():
		regions.append({"id": room.id, "rect": room.rect, "room": true})
	# Circulation is deliberately authored as continuous large areas. The earlier
	# five rectangles left narrow vertical links between rooms outside any fog
	# region; those links stayed black forever. Rooms retain priority in
	# get_world_reveal_at(), so these broad sections do not leak room contents.
	regions.append_array([
		{"id": "west_hall", "rect": Rect2(32, 96, 896, 832), "room": false},
		{"id": "central_hall", "rect": Rect2(896, 96, 608, 832), "room": false},
		{"id": "east_hall", "rect": Rect2(1376, 96, 896, 832), "room": false},
		{"id": "lower_west_hall", "rect": Rect2(32, 672, 1440, 736), "room": false},
		{"id": "maintenance_approach", "rect": Rect2(1440, 864, 800, 544), "room": false},
		{"id": "upper_service", "rect": Rect2(32, 32, 2240, 96), "room": false},
	])
	return regions


func _metro_exploration_regions() -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	for region in run_config.map_regions():
		regions.append({"id": str(region.id), "rect": region.rect, "room": true})
	regions.append_array([
		{"id": "metro_west_link", "rect": Rect2(32, 64, 896, 448), "room": false},
		{"id": "metro_central_link", "rect": Rect2(480, 128, 1024, 448), "room": false},
		{"id": "metro_north_link", "rect": Rect2(896, 96, 1376, 480), "room": false},
		{"id": "metro_lower_link", "rect": Rect2(32, 608, 1472, 736), "room": false},
		{"id": "metro_east_link", "rect": Rect2(1472, 608, 768, 736), "room": false},
	])
	return regions
