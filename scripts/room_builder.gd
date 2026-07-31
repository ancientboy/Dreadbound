class_name RoomBuilder
extends Node2D

const TILE_SIZE := Vector2i(128, 128)
const FLOOR_ATLAS_SIZE := Vector2i(8, 6)
const WALL_ATLAS_SIZE := Vector2i(8, 1)
const TILE_FLIP_H := 4096
const TILE_FLIP_V := 8192
const CARDINAL_OFFSETS := {
	&"north": Vector2i.UP,
	&"south": Vector2i.DOWN,
	&"west": Vector2i.LEFT,
	&"east": Vector2i.RIGHT,
}
const WALL_ATLAS_CELLS := {
	&"north": Vector2i(0, 0),
	&"south": Vector2i(1, 0),
	&"west": Vector2i(2, 0),
	&"east": Vector2i(3, 0),
}
const CORNER_ATLAS_CELLS := {
	&"north_west": Vector2i(4, 0),
	&"north_east": Vector2i(5, 0),
	&"south_west": Vector2i(6, 0),
	&"south_east": Vector2i(7, 0),
}

var floor_tiles: TileMapLayer
var wall_base_tiles: TileMapLayer
var side_wall_tiles: TileMapLayer
var foreground_walls: TileMapLayer
var corner_tiles: TileMapLayer
var door_sockets: Node2D
var content_slots: Node2D
var room_spec: Dictionary = {}
var walkable_outline := PackedVector2Array()
var blocked_outlines: Array[PackedVector2Array] = []
var map_bounds := Rect2()
var door_anchor_points: Dictionary = {}
var room_floor_macro: Node2D
var room_wall_shell: Node2D

var _floor_texture: Texture2D
var _wall_texture: Texture2D
var _floor_atlas_size := FLOOR_ATLAS_SIZE
var _wall_atlas_size := WALL_ATLAS_SIZE
var _occupied_cells: Dictionary = {}
var _door_cells: Dictionary = {}
var _foreground_shell_sprites: Array[Sprite2D] = []


func build(
	spec: Dictionary,
	floor_texture: Texture2D,
	wall_texture: Texture2D,
	floor_atlas_size := FLOOR_ATLAS_SIZE,
	wall_atlas_size := WALL_ATLAS_SIZE,
) -> void:
	_clear_generated_nodes()
	room_spec = spec.duplicate(true)
	_floor_texture = floor_texture
	_wall_texture = wall_texture
	_floor_atlas_size = floor_atlas_size
	_wall_atlas_size = wall_atlas_size
	_occupied_cells = _cell_lookup(spec.get("grid_cells", []))
	assert(not _occupied_cells.is_empty(), "RoomBuilder requires at least one floor cell")
	_door_cells = {}
	door_anchor_points.clear()
	for door_spec in spec.get("door_sockets", []):
		var direction := StringName(door_spec["direction"])
		var cell: Vector2i = door_spec["cell"]
		assert(CARDINAL_OFFSETS.has(direction), "Unsupported room door direction")
		assert(not _occupied_cells.has(cell), "Door sockets must occupy a boundary wall cell")
		_door_cells[cell] = direction
		door_anchor_points[direction] = door_spec.get(
			"anchor",
			_door_anchor_for_cell(cell, direction),
		)
	walkable_outline = _trace_walkable_outline()
	_build_blocked_outlines()
	map_bounds = spec.get("map_bounds", _default_map_bounds())
	_build_floor_tiles()
	_build_floor_macro()
	_build_wall_tiles()
	_build_wall_shell()
	_build_door_sockets()
	_build_content_slots()


func wall_tile_count() -> int:
	var result := 0
	for layer in [wall_base_tiles, side_wall_tiles, foreground_walls, corner_tiles]:
		if layer != null:
			result += layer.get_used_cells().size()
	return result


func door_directions() -> PackedStringArray:
	var result := PackedStringArray()
	for door_spec in room_spec.get("door_sockets", []):
		result.append(String(door_spec["direction"]))
	return result


func set_foreground_faded(faded: bool) -> void:
	var target_alpha := 0.2 if faded else 1.0
	if foreground_walls != null:
		create_tween().tween_property(
			foreground_walls,
			"modulate:a",
			target_alpha,
			0.18,
		)
	for sprite in _foreground_shell_sprites:
		if is_instance_valid(sprite):
			create_tween().tween_property(
				sprite,
				"modulate:a",
				target_alpha,
				0.18,
			)


func _build_floor_tiles() -> void:
	floor_tiles = _make_layer(
		"FloorTiles",
		_make_atlas_tileset(_floor_texture, _floor_atlas_size),
		-30,
	)
	for cell_value in _occupied_cells:
		var cell: Vector2i = cell_value
		var local_cell := cell - Vector2i(2, 2)
		var x_sample := _mirrored_atlas_axis(local_cell.x, _floor_atlas_size.x)
		var y_sample := _mirrored_atlas_axis(local_cell.y, _floor_atlas_size.y)
		var alternative := 0
		if x_sample.y == 1:
			alternative |= TILE_FLIP_H
		if y_sample.y == 1:
			alternative |= TILE_FLIP_V
		floor_tiles.set_cell(
			cell,
			0,
			Vector2i(x_sample.x, y_sample.x),
			alternative,
		)


func _build_floor_macro() -> void:
	var macro_spec: Dictionary = room_spec.get("floor_macro", {})
	if macro_spec.is_empty():
		return
	var texture := _load_room_texture(macro_spec)
	if texture == null:
		return
	var source_region: Rect2 = macro_spec.get(
		"source_region",
		Rect2(Vector2.ZERO, texture.get_size()),
	)
	var world_rect: Rect2 = macro_spec.get("world_rect", Rect2())
	assert(source_region.has_area(), "Room floor macro requires a source_region")
	assert(world_rect.has_area(), "Room floor macro requires a world_rect")
	var corner_cut: Vector2 = macro_spec.get("corner_cut", Vector2.ZERO)
	# Authored macro floors already own the complete visible footprint.  Keeping
	# the generated tile layer underneath makes its blue fallback tiles show
	# through transparent outer corners and L-shaped voids.
	floor_tiles.visible = false
	if corner_cut.x > 0.0 or corner_cut.y > 0.0:
		var floor_polygon := Polygon2D.new()
		floor_polygon.name = String(macro_spec.get("node_name", "RoomFloorMacro"))
		floor_polygon.texture = texture
		floor_polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		floor_polygon.position = world_rect.position
		floor_polygon.polygon = _cut_corner_outline(world_rect.size, corner_cut)
		var texture_uv := PackedVector2Array()
		for point in floor_polygon.polygon:
			texture_uv.append(
				source_region.position
				+ point / world_rect.size * source_region.size
			)
		floor_polygon.uv = texture_uv
		floor_polygon.z_index = int(macro_spec.get("z_index", -24))
		room_floor_macro = floor_polygon
		add_child(room_floor_macro)
		return
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = source_region
	var floor_sprite := Sprite2D.new()
	floor_sprite.name = String(macro_spec.get("node_name", "RoomFloorMacro"))
	floor_sprite.texture = region
	floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor_sprite.centered = false
	floor_sprite.position = world_rect.position
	floor_sprite.scale = world_rect.size / source_region.size
	floor_sprite.z_index = int(macro_spec.get("z_index", -24))
	room_floor_macro = floor_sprite
	add_child(room_floor_macro)


func _cut_corner_outline(size: Vector2, cut: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(cut.x, 0.0),
		Vector2(size.x - cut.x, 0.0),
		Vector2(size.x, cut.y),
		Vector2(size.x, size.y - cut.y),
		Vector2(size.x - cut.x, size.y),
		Vector2(cut.x, size.y),
		Vector2(0.0, size.y - cut.y),
		Vector2(0.0, cut.y),
	])


func _build_wall_tiles() -> void:
	var wall_tileset := _make_atlas_tileset(_wall_texture, _wall_atlas_size)
	wall_base_tiles = _make_layer("WallBaseTiles", wall_tileset, -8)
	side_wall_tiles = _make_layer("SideWallTiles", wall_tileset, 4)
	foreground_walls = _make_layer("ForegroundWalls", wall_tileset, 38)
	corner_tiles = _make_layer("CornerTiles", wall_tileset, 39)
	for cell_value in _occupied_cells:
		var cell: Vector2i = cell_value
		for direction_value in CARDINAL_OFFSETS:
			var direction := StringName(direction_value)
			var wall_cell: Vector2i = cell + CARDINAL_OFFSETS[direction]
			if _occupied_cells.has(wall_cell) or _door_cells.has(wall_cell):
				continue
			var layer: TileMapLayer = _wall_layer(direction)
			layer.set_cell(wall_cell, 0, WALL_ATLAS_CELLS[direction], 0)
			_add_outer_corner_if_needed(cell, direction)


func _build_wall_shell() -> void:
	var shell_spec: Dictionary = room_spec.get("wall_shell", {})
	if shell_spec.is_empty():
		return
	var default_texture := _load_room_texture(shell_spec)
	if default_texture == null:
		return
	room_wall_shell = Node2D.new()
	room_wall_shell.name = String(shell_spec.get("node_name", "RoomWallShell"))
	add_child(room_wall_shell)
	for region_spec_value in shell_spec.get("regions", []):
		var region_spec: Dictionary = region_spec_value
		var texture := default_texture
		if region_spec.has("texture") or region_spec.has("texture_path"):
			texture = _load_room_texture(region_spec)
		if texture == null:
			continue
		var source_region: Rect2 = region_spec.get("source_region", Rect2())
		var world_rect: Rect2 = region_spec.get("world_rect", Rect2())
		assert(source_region.has_area(), "Wall shell region requires a source_region")
		assert(world_rect.has_area(), "Wall shell region requires a world_rect")
		var region := AtlasTexture.new()
		region.atlas = texture
		region.region = source_region
		var sprite := Sprite2D.new()
		sprite.name = String(region_spec.get("id", "WallRegion")).to_pascal_case()
		sprite.texture = region
		sprite.centered = false
		sprite.position = world_rect.position
		sprite.scale = world_rect.size / source_region.size
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.z_index = int(region_spec.get("z_index", -7))
		room_wall_shell.add_child(sprite)
		if bool(region_spec.get("foreground", false)):
			_foreground_shell_sprites.append(sprite)
	if bool(shell_spec.get("hide_generated_walls", true)):
		for tile_layer in [
			wall_base_tiles,
			side_wall_tiles,
			foreground_walls,
			corner_tiles,
		]:
			tile_layer.visible = false


func _add_outer_corner_if_needed(cell: Vector2i, direction: StringName) -> void:
	var pairs := {
		&"north": [&"west", &"east"],
		&"south": [&"west", &"east"],
		&"west": [&"north", &"south"],
		&"east": [&"north", &"south"],
	}
	for other_value in pairs[direction]:
		var other := StringName(other_value)
		if _occupied_cells.has(cell + CARDINAL_OFFSETS[other]):
			continue
		var corner_cell: Vector2i = (
			cell + CARDINAL_OFFSETS[direction] + CARDINAL_OFFSETS[other]
		)
		if _door_cells.has(corner_cell):
			continue
		var vertical := direction if direction == &"north" or direction == &"south" else other
		var horizontal := direction if direction == &"west" or direction == &"east" else other
		var corner_key := StringName("%s_%s" % [vertical, horizontal])
		corner_tiles.set_cell(corner_cell, 0, CORNER_ATLAS_CELLS[corner_key], 0)


func _build_door_sockets() -> void:
	door_sockets = Node2D.new()
	door_sockets.name = "DoorSockets"
	door_sockets.z_index = 2
	add_child(door_sockets)
	for door_spec in room_spec.get("door_sockets", []):
		var direction := StringName(door_spec["direction"])
		var cell: Vector2i = door_spec["cell"]
		var socket := Marker2D.new()
		socket.name = "%sSocket" % String(direction).capitalize()
		socket.position = door_anchor_points[direction]
		socket.set_meta(&"tile_cell", cell)
		socket.set_meta(&"direction", direction)
		door_sockets.add_child(socket)


func _build_content_slots() -> void:
	content_slots = Node2D.new()
	content_slots.name = "ContentSlots"
	add_child(content_slots)
	for slot_spec in room_spec.get("content_slots", []):
		var marker := Marker2D.new()
		marker.name = String(slot_spec["id"]).to_pascal_case()
		marker.position = _cell_center(slot_spec["cell"])
		marker.set_meta(&"slot_type", StringName(slot_spec["type"]))
		marker.set_meta(
			&"visual_id",
			StringName(slot_spec.get("visual_id", &"")),
		)
		marker.set_meta(&"phase", int(slot_spec.get("phase", 0)))
		content_slots.add_child(marker)


func _trace_walkable_outline() -> PackedVector2Array:
	return _trace_cell_outline(_occupied_cells)


func _trace_cell_outline(cells: Dictionary) -> PackedVector2Array:
	var edges: Array[Dictionary] = []
	for cell_value in cells:
		var cell: Vector2i = cell_value
		var top_left := cell
		var top_right := cell + Vector2i.RIGHT
		var bottom_right := cell + Vector2i.ONE
		var bottom_left := cell + Vector2i.DOWN
		if not cells.has(cell + Vector2i.UP):
			edges.append({"start": top_left, "finish": top_right})
		if not cells.has(cell + Vector2i.RIGHT):
			edges.append({"start": top_right, "finish": bottom_right})
		if not cells.has(cell + Vector2i.DOWN):
			edges.append({"start": bottom_right, "finish": bottom_left})
		if not cells.has(cell + Vector2i.LEFT):
			edges.append({"start": bottom_left, "finish": top_left})
	assert(not edges.is_empty(), "RoomBuilder could not trace a room boundary")
	var ordered := PackedVector2Array()
	var first_edge: Dictionary = edges.pop_front()
	var start: Vector2i = first_edge["start"]
	var cursor: Vector2i = first_edge["finish"]
	ordered.append(_grid_vertex(start))
	while cursor != start:
		ordered.append(_grid_vertex(cursor))
		var next_index := -1
		for index in edges.size():
			if edges[index]["start"] == cursor:
				next_index = index
				break
		assert(next_index >= 0, "Room grid cells must form one connected outline")
		var next_edge := edges[next_index]
		edges.remove_at(next_index)
		cursor = next_edge["finish"]
	assert(edges.is_empty(), "Room grid cells must not contain holes or disconnected islands")
	return _simplify_outline(ordered)


func _build_blocked_outlines() -> void:
	blocked_outlines.clear()
	for outline_value in room_spec.get("blocked_outlines", []):
		var outline := PackedVector2Array(outline_value)
		assert(outline.size() >= 3, "Blocked outlines require at least three points")
		blocked_outlines.append(outline)
	var obstacle_lookup := _cell_lookup(room_spec.get("obstacle_cells", []))
	for cell_value in obstacle_lookup:
		assert(
			_occupied_cells.has(cell_value),
			"Obstacle cells must be inside the walkable room grid",
		)
	for group in _connected_cell_groups(obstacle_lookup):
		blocked_outlines.append(_trace_cell_outline(group))


func _connected_cell_groups(cells: Dictionary) -> Array[Dictionary]:
	var remaining := cells.duplicate()
	var result: Array[Dictionary] = []
	while not remaining.is_empty():
		var seed: Vector2i = remaining.keys()[0]
		var pending: Array[Vector2i] = [seed]
		var group: Dictionary = {}
		remaining.erase(seed)
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			group[cell] = true
			for offset in CARDINAL_OFFSETS.values():
				var neighbor: Vector2i = cell + offset
				if remaining.has(neighbor):
					remaining.erase(neighbor)
					pending.append(neighbor)
		result.append(group)
	return result


func _simplify_outline(outline: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in outline.size():
		var previous := outline[posmod(index - 1, outline.size())]
		var current := outline[index]
		var following := outline[(index + 1) % outline.size()]
		if is_zero_approx((current - previous).cross(following - current)):
			continue
		result.append(current)
	return result


func _default_map_bounds() -> Rect2:
	var min_cell := Vector2i(1 << 20, 1 << 20)
	var max_cell := Vector2i(-(1 << 20), -(1 << 20))
	for cell_value in _occupied_cells:
		var cell: Vector2i = cell_value
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return Rect2(
		Vector2((min_cell - Vector2i(2, 2)) * TILE_SIZE),
		Vector2((max_cell - min_cell + Vector2i(5, 5)) * TILE_SIZE),
	)


func _wall_layer(direction: StringName) -> TileMapLayer:
	if direction == &"south":
		return foreground_walls
	if direction == &"west" or direction == &"east":
		return side_wall_tiles
	return wall_base_tiles


func _make_layer(node_name: String, tile_set: TileSet, layer_z_index: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = node_name
	layer.z_index = layer_z_index
	layer.tile_set = tile_set
	add_child(layer)
	return layer


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


func _load_room_texture(visual_spec: Dictionary) -> Texture2D:
	var texture := visual_spec.get("texture") as Texture2D
	if texture != null:
		return texture
	var texture_path := String(visual_spec.get("texture_path", ""))
	assert(
		not texture_path.is_empty() and ResourceLoader.exists(texture_path),
		"Configured room visual texture does not exist: %s" % texture_path,
	)
	return load(texture_path) as Texture2D


func _cell_lookup(cells: Array) -> Dictionary:
	var result := {}
	for cell in cells:
		result[cell] = true
	return result


func _mirrored_atlas_axis(value: int, atlas_length: int) -> Vector2i:
	var phase := posmod(value, atlas_length * 2)
	if phase < atlas_length:
		return Vector2i(phase, 0)
	return Vector2i(atlas_length * 2 - phase - 1, 1)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2(TILE_SIZE) * 0.5


func _door_anchor_for_cell(cell: Vector2i, direction: StringName) -> Vector2:
	var anchor := _cell_center(cell)
	var inward: Vector2i = -CARDINAL_OFFSETS[direction]
	return anchor + Vector2(inward * (TILE_SIZE / 2))


func _grid_vertex(vertex: Vector2i) -> Vector2:
	return Vector2(vertex * TILE_SIZE)


func _clear_generated_nodes() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	floor_tiles = null
	wall_base_tiles = null
	side_wall_tiles = null
	foreground_walls = null
	corner_tiles = null
	door_sockets = null
	content_slots = null
	room_floor_macro = null
	room_wall_shell = null
	blocked_outlines.clear()
	_foreground_shell_sprites.clear()
