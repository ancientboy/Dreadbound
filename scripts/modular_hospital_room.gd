class_name ModularHospitalRoom
extends Node2D

const TILE_SIZE := Vector2i(128, 128)
const FLOOR_ATLAS := preload(
	"res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png"
)
const WALL_ATLAS := preload(
	"res://assets/art/worlds/map_demo/hospital_tiles_v8/wall_atlas.svg"
)
const ROOM_MIN_CELL := Vector2i(2, 2)
const ROOM_SIZE_CELLS := Vector2i(8, 5)
const ROOM_MAX_CELL := ROOM_MIN_CELL + ROOM_SIZE_CELLS - Vector2i.ONE
const WEST_WALL_X := ROOM_MIN_CELL.x - 1
const EAST_WALL_X := ROOM_MAX_CELL.x + 1
const NORTH_WALL_Y := ROOM_MIN_CELL.y - 1
const SOUTH_WALL_Y := ROOM_MAX_CELL.y + 1
const DOOR_CELL_Y := 4

var floor_tiles: TileMapLayer
var wall_base_tiles: TileMapLayer
var foreground_walls: TileMapLayer
var door_sockets: Node2D


func _ready() -> void:
	_build_floor_tiles()
	_build_wall_tiles()
	_build_door_sockets()
	_build_floor_details()


func _build_floor_tiles() -> void:
	floor_tiles = TileMapLayer.new()
	floor_tiles.name = "FloorTiles"
	floor_tiles.z_index = -30
	floor_tiles.tile_set = _make_atlas_tileset(FLOOR_ATLAS, Vector2i(8, 6))
	add_child(floor_tiles)
	for y_index in ROOM_SIZE_CELLS.y:
		for x_index in ROOM_SIZE_CELLS.x:
			floor_tiles.set_cell(
				ROOM_MIN_CELL + Vector2i(x_index, y_index),
				0,
				Vector2i(x_index, y_index),
				0,
			)


func _build_wall_tiles() -> void:
	var wall_tileset := _make_atlas_tileset(WALL_ATLAS, Vector2i(8, 1))
	wall_base_tiles = TileMapLayer.new()
	wall_base_tiles.name = "WallBaseTiles"
	wall_base_tiles.z_index = -8
	wall_base_tiles.tile_set = wall_tileset
	add_child(wall_base_tiles)
	for x_index in range(ROOM_MIN_CELL.x, ROOM_MAX_CELL.x + 1):
		wall_base_tiles.set_cell(Vector2i(x_index, NORTH_WALL_Y), 0, Vector2i(0, 0), 0)
	for y_index in range(ROOM_MIN_CELL.y, ROOM_MAX_CELL.y + 1):
		if y_index == DOOR_CELL_Y:
			continue
		wall_base_tiles.set_cell(Vector2i(WEST_WALL_X, y_index), 0, Vector2i(2, 0), 0)
		wall_base_tiles.set_cell(Vector2i(EAST_WALL_X, y_index), 0, Vector2i(3, 0), 0)
	wall_base_tiles.set_cell(Vector2i(WEST_WALL_X, NORTH_WALL_Y), 0, Vector2i(4, 0), 0)
	wall_base_tiles.set_cell(Vector2i(EAST_WALL_X, NORTH_WALL_Y), 0, Vector2i(5, 0), 0)

	foreground_walls = TileMapLayer.new()
	foreground_walls.name = "ForegroundWalls"
	foreground_walls.z_index = 38
	foreground_walls.tile_set = wall_tileset
	add_child(foreground_walls)
	for x_index in range(ROOM_MIN_CELL.x, ROOM_MAX_CELL.x + 1):
		foreground_walls.set_cell(Vector2i(x_index, SOUTH_WALL_Y), 0, Vector2i(1, 0), 0)
	foreground_walls.set_cell(Vector2i(WEST_WALL_X, SOUTH_WALL_Y), 0, Vector2i(6, 0), 0)
	foreground_walls.set_cell(Vector2i(EAST_WALL_X, SOUTH_WALL_Y), 0, Vector2i(7, 0), 0)


func _build_door_sockets() -> void:
	door_sockets = Node2D.new()
	door_sockets.name = "DoorSockets"
	door_sockets.z_index = 2
	add_child(door_sockets)
	for entry in [
		{"name": "West", "cell": Vector2i(WEST_WALL_X, DOOR_CELL_Y)},
		{"name": "East", "cell": Vector2i(EAST_WALL_X, DOOR_CELL_Y)},
	]:
		var socket := Marker2D.new()
		socket.name = "%sSocket" % entry["name"]
		socket.position = floor_tiles.map_to_local(entry["cell"])
		socket.set_meta(&"tile_cell", entry["cell"])
		door_sockets.add_child(socket)


func _build_floor_details() -> void:
	var details := Node2D.new()
	details.name = "FloorDetails"
	details.z_index = -18
	add_child(details)
	var center_line := Line2D.new()
	center_line.name = "MedicalGuideLine"
	center_line.points = PackedVector2Array([Vector2(274, 576), Vector2(1262, 576)])
	center_line.width = 5.0
	center_line.default_color = Color(0.16, 0.68, 0.64, 0.24)
	center_line.antialiased = true
	details.add_child(center_line)
	for entry in [
		{"name": "WestThreshold", "position": Vector2(256, 576)},
		{"name": "EastThreshold", "position": Vector2(1280, 576)},
	]:
		var threshold := Polygon2D.new()
		threshold.name = entry["name"]
		threshold.position = entry["position"]
		threshold.polygon = PackedVector2Array([
			Vector2(-18, -58), Vector2(18, -58), Vector2(18, 58), Vector2(-18, 58),
		])
		threshold.color = Color(0.16, 0.25, 0.27, 0.92)
		details.add_child(threshold)


func _make_atlas_tileset(texture: Texture2D, atlas_size: Vector2i) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = TILE_SIZE
	for y_index in atlas_size.y:
		for x_index in atlas_size.x:
			source.create_tile(Vector2i(x_index, y_index))
	tile_set.add_source(source, 0)
	return tile_set


func set_foreground_faded(faded: bool) -> void:
	if foreground_walls == null:
		return
	var target_alpha := 0.2 if faded else 1.0
	create_tween().tween_property(foreground_walls, "modulate:a", target_alpha, 0.18)
