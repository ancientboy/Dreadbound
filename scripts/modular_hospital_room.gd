class_name ModularHospitalRoom
extends Node2D

const NORTH_WALL_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/north_wall.png"
)
const SOUTH_WALL_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/south_wall.png"
)
const WEST_WALL_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/west_wall.png"
)
const EAST_WALL_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/east_wall.png"
)

# Every structural module is aligned from these world-space connection lines.
# Sprites are never positioned from their arbitrary transparent-canvas centers.
const FLOOR_LEFT := 190.0
const FLOOR_RIGHT := 1346.0
const FLOOR_TOP := 280.0
const FLOOR_BOTTOM := 820.0
const SIDE_OUTER_LEFT := 106.0
const SIDE_OUTER_RIGHT := 1430.0
const SIDE_TOP := 350.0
const SIDE_BOTTOM := 730.0
const DOOR_CENTER_Y := 540.0
const DOOR_GAP_HALF_HEIGHT := 78.0
const HORIZONTAL_MODULE_COUNT := 5
const MODULE_JOIN_OVERLAP := 5.0

const FLOOR_OUTLINE := [
	Vector2(FLOOR_LEFT, FLOOR_TOP),
	Vector2(FLOOR_RIGHT, FLOOR_TOP),
	Vector2(SIDE_OUTER_RIGHT, SIDE_TOP),
	Vector2(SIDE_OUTER_RIGHT, SIDE_BOTTOM),
	Vector2(FLOOR_RIGHT, FLOOR_BOTTOM),
	Vector2(FLOOR_LEFT, FLOOR_BOTTOM),
	Vector2(SIDE_OUTER_LEFT, SIDE_BOTTOM),
	Vector2(SIDE_OUTER_LEFT, SIDE_TOP),
]


func _ready() -> void:
	_build_floor()
	_build_back_wall()
	_build_side_walls()
	_build_foreground_wall()
	_build_corner_caps()
	_build_light_wash()


func _build_floor() -> void:
	var floor_outline := PackedVector2Array(FLOOR_OUTLINE)

	var floor_underlay := Polygon2D.new()
	floor_underlay.name = "FloorUnderlay"
	floor_underlay.polygon = floor_outline
	floor_underlay.color = Color(0.205, 0.34, 0.38, 1.0)
	floor_underlay.z_index = -36
	add_child(floor_underlay)

	# The first version repeated a non-seamless 384 px image with world coordinates
	# as UVs. A single continuous surface avoids the four giant visible seams.
	var floor_surface := Polygon2D.new()
	floor_surface.name = "FloorSurface"
	floor_surface.polygon = floor_outline
	floor_surface.color = Color(0.49, 0.66, 0.69, 1.0)
	floor_surface.z_index = -35
	add_child(floor_surface)

	var panels := Node2D.new()
	panels.name = "FloorPanels"
	panels.z_index = -34
	add_child(panels)

	for x_position in range(318, 1346, 128):
		_add_floor_line(
			panels,
			"Vertical_%d" % x_position,
			PackedVector2Array([
				Vector2(x_position, FLOOR_TOP + 8.0),
				Vector2(x_position, FLOOR_BOTTOM - 8.0),
			]),
			Color(0.19, 0.35, 0.39, 0.26),
			2.0,
		)
	for y_position in range(400, 820, 120):
		_add_floor_line(
			panels,
			"Horizontal_%d" % y_position,
			PackedVector2Array([
				Vector2(FLOOR_LEFT + 8.0, y_position),
				Vector2(FLOOR_RIGHT - 8.0, y_position),
			]),
			Color(0.19, 0.35, 0.39, 0.22),
			2.0,
		)

	var perimeter := Line2D.new()
	perimeter.name = "FloorPerimeter"
	perimeter.points = floor_outline
	perimeter.closed = true
	perimeter.width = 3.0
	perimeter.default_color = Color(0.08, 0.2, 0.23, 0.72)
	perimeter.antialiased = true
	perimeter.z_index = -33
	add_child(perimeter)


func _build_back_wall() -> void:
	var container := Node2D.new()
	container.name = "BackWalls"
	container.z_index = -12
	add_child(container)
	_add_horizontal_wall_run(
		container,
		NORTH_WALL_TEXTURE,
		FLOOR_LEFT,
		FLOOR_RIGHT,
		240.0,
	)


func _build_side_walls() -> void:
	var west_container := Node2D.new()
	west_container.name = "WestWalls"
	west_container.z_index = 4
	add_child(west_container)
	_add_vertical_wall_span(
		west_container,
		WEST_WALL_TEXTURE,
		Vector2((SIDE_OUTER_LEFT + FLOOR_LEFT) * 0.5, SIDE_TOP),
		Vector2((SIDE_OUTER_LEFT + FLOOR_LEFT) * 0.5, DOOR_CENTER_Y - DOOR_GAP_HALF_HEIGHT),
	)
	_add_vertical_wall_span(
		west_container,
		WEST_WALL_TEXTURE,
		Vector2((SIDE_OUTER_LEFT + FLOOR_LEFT) * 0.5, DOOR_CENTER_Y + DOOR_GAP_HALF_HEIGHT),
		Vector2((SIDE_OUTER_LEFT + FLOOR_LEFT) * 0.5, SIDE_BOTTOM),
	)

	var east_container := Node2D.new()
	east_container.name = "EastWalls"
	east_container.z_index = 4
	add_child(east_container)
	_add_vertical_wall_span(
		east_container,
		EAST_WALL_TEXTURE,
		Vector2((SIDE_OUTER_RIGHT + FLOOR_RIGHT) * 0.5, SIDE_TOP),
		Vector2((SIDE_OUTER_RIGHT + FLOOR_RIGHT) * 0.5, DOOR_CENTER_Y - DOOR_GAP_HALF_HEIGHT),
	)
	_add_vertical_wall_span(
		east_container,
		EAST_WALL_TEXTURE,
		Vector2((SIDE_OUTER_RIGHT + FLOOR_RIGHT) * 0.5, DOOR_CENTER_Y + DOOR_GAP_HALF_HEIGHT),
		Vector2((SIDE_OUTER_RIGHT + FLOOR_RIGHT) * 0.5, SIDE_BOTTOM),
	)


func _build_foreground_wall() -> void:
	var container := Node2D.new()
	container.name = "ForegroundWalls"
	container.z_index = 42
	add_child(container)
	_add_horizontal_wall_run(
		container,
		SOUTH_WALL_TEXTURE,
		FLOOR_LEFT,
		FLOOR_RIGHT,
		820.0,
	)
	container.modulate.a = 0.88


func _build_corner_caps() -> void:
	var corners := Node2D.new()
	corners.name = "CornerCaps"
	corners.z_index = 44
	add_child(corners)
	var cap_points := [
		Vector2(-42.0, -35.0),
		Vector2(42.0, -35.0),
		Vector2(42.0, 35.0),
		Vector2(-42.0, 35.0),
	]
	for entry in [
		{"name": "NorthWest", "position": Vector2(148.0, 315.0)},
		{"name": "NorthEast", "position": Vector2(1388.0, 315.0)},
		{"name": "SouthWest", "position": Vector2(148.0, 775.0)},
		{"name": "SouthEast", "position": Vector2(1388.0, 775.0)},
	]:
		var cap := Polygon2D.new()
		cap.name = entry["name"]
		cap.position = entry["position"]
		cap.polygon = PackedVector2Array(cap_points)
		cap.color = Color(0.24, 0.38, 0.42, 0.96)
		corners.add_child(cap)


func _build_light_wash() -> void:
	var wash := Polygon2D.new()
	wash.name = "CenterLightWash"
	wash.polygon = PackedVector2Array([
		Vector2(320.0, 350.0),
		Vector2(1216.0, 350.0),
		Vector2(1320.0, 720.0),
		Vector2(216.0, 720.0),
	])
	wash.color = Color(0.22, 0.82, 0.78, 0.055)
	wash.z_index = -18
	add_child(wash)


func set_foreground_faded(faded: bool) -> void:
	var foreground := get_node_or_null("ForegroundWalls") as Node2D
	if foreground == null:
		return
	var target_alpha := 0.2 if faded else 0.88
	create_tween().tween_property(foreground, "modulate:a", target_alpha, 0.18)


func _add_horizontal_wall_run(
	parent_node: Node2D,
	texture: Texture2D,
	start_x: float,
	end_x: float,
	baseline_y: float,
) -> void:
	var span := end_x - start_x
	var module_width := (
		span + MODULE_JOIN_OVERLAP * float(HORIZONTAL_MODULE_COUNT - 1)
	) / float(HORIZONTAL_MODULE_COUNT)
	var module_step := module_width - MODULE_JOIN_OVERLAP
	var scale_factor := module_width / float(texture.get_width())
	for index in HORIZONTAL_MODULE_COUNT:
		var sprite := _make_wall_sprite(parent_node, texture)
		sprite.name = "Module_%02d" % index
		sprite.scale = Vector2.ONE * scale_factor
		sprite.position = Vector2(
			start_x + module_width * 0.5 + module_step * float(index),
			baseline_y,
		)


func _add_vertical_wall_span(
	parent_node: Node2D,
	texture: Texture2D,
	start: Vector2,
	finish: Vector2,
) -> void:
	var span := finish.y - start.y
	var scale_factor := span / float(texture.get_height())
	var sprite := _make_wall_sprite(parent_node, texture)
	sprite.name = "Module_%02d" % parent_node.get_child_count()
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = (start + finish) * 0.5


func _make_wall_sprite(parent_node: Node2D, texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent_node.add_child(sprite)
	return sprite


func _add_floor_line(
	parent_node: Node2D,
	line_name: String,
	line_points: PackedVector2Array,
	color: Color,
	line_width: float,
) -> void:
	var line := Line2D.new()
	line.name = line_name
	line.points = line_points
	line.width = line_width
	line.default_color = color
	line.antialiased = true
	parent_node.add_child(line)
