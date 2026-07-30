class_name ModularHospitalRoom
extends Node2D

const FLOOR_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/floor_tile_384.png"
)
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
const INNER_CORNER_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/inner_corner.png"
)
const OUTER_CORNER_TEXTURE := preload(
	"res://assets/art/worlds/map_demo/modular_hospital/walls/outer_corner.png"
)

const FLOOR_OUTLINE := PackedVector2Array([
	Vector2(190.0, 280.0),
	Vector2(1346.0, 280.0),
	Vector2(1430.0, 350.0),
	Vector2(1430.0, 730.0),
	Vector2(1346.0, 820.0),
	Vector2(190.0, 820.0),
	Vector2(106.0, 730.0),
	Vector2(106.0, 350.0),
])


func _ready() -> void:
	_build_floor()
	_build_back_wall()
	_build_side_walls()
	_build_foreground_wall()
	_build_corners()
	_build_light_wash()


func _build_floor() -> void:
	var floor_surface := Polygon2D.new()
	floor_surface.name = "FloorSurface"
	floor_surface.polygon = FLOOR_OUTLINE
	floor_surface.uv = FLOOR_OUTLINE
	floor_surface.texture = FLOOR_TEXTURE
	floor_surface.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor_surface.z_index = -35
	add_child(floor_surface)

	var floor_base := Polygon2D.new()
	floor_base.name = "FloorUnderlay"
	floor_base.polygon = FLOOR_OUTLINE
	floor_base.color = Color(0.14, 0.24, 0.27, 1.0)
	floor_base.z_index = -36
	add_child(floor_base)


func _build_back_wall() -> void:
	var container := Node2D.new()
	container.name = "BackWalls"
	container.z_index = -12
	add_child(container)
	for x_position in [284.0, 526.0, 768.0, 1010.0, 1252.0]:
		_add_wall_sprite(
			container,
			NORTH_WALL_TEXTURE,
			Vector2(x_position, 250.0),
			Vector2.ONE * 0.55,
		)


func _build_side_walls() -> void:
	var west_container := Node2D.new()
	west_container.name = "WestWalls"
	west_container.z_index = 4
	add_child(west_container)
	for y_position in [368.0, 714.0]:
		_add_wall_sprite(
			west_container,
			WEST_WALL_TEXTURE,
			Vector2(112.0, y_position),
			Vector2.ONE * 0.43,
		)

	var east_container := Node2D.new()
	east_container.name = "EastWalls"
	east_container.z_index = 4
	add_child(east_container)
	for y_position in [368.0, 714.0]:
		_add_wall_sprite(
			east_container,
			EAST_WALL_TEXTURE,
			Vector2(1424.0, y_position),
			Vector2.ONE * 0.43,
		)


func _build_foreground_wall() -> void:
	var container := Node2D.new()
	container.name = "ForegroundWalls"
	container.z_index = 42
	add_child(container)
	for x_position in [284.0, 526.0, 768.0, 1010.0, 1252.0]:
		_add_wall_sprite(
			container,
			SOUTH_WALL_TEXTURE,
			Vector2(x_position, 835.0),
			Vector2.ONE * 0.55,
		)
	container.modulate.a = 0.92


func _build_corners() -> void:
	var corners := Node2D.new()
	corners.name = "Corners"
	corners.z_index = 44
	add_child(corners)
	_add_wall_sprite(
		corners,
		INNER_CORNER_TEXTURE,
		Vector2(154.0, 300.0),
		Vector2.ONE * 0.46,
	)
	_add_wall_sprite(
		corners,
		OUTER_CORNER_TEXTURE,
		Vector2(1380.0, 815.0),
		Vector2.ONE * 0.46,
	)


func _build_light_wash() -> void:
	var wash := Polygon2D.new()
	wash.name = "CenterLightWash"
	wash.polygon = PackedVector2Array([
		Vector2(320.0, 350.0),
		Vector2(1216.0, 350.0),
		Vector2(1320.0, 720.0),
		Vector2(216.0, 720.0),
	])
	wash.color = Color(0.16, 0.55, 0.58, 0.045)
	wash.z_index = -18
	add_child(wash)


func set_foreground_faded(faded: bool) -> void:
	var foreground := get_node_or_null("ForegroundWalls") as Node2D
	if foreground == null:
		return
	var target_alpha := 0.24 if faded else 0.92
	create_tween().tween_property(foreground, "modulate:a", target_alpha, 0.18)


func _add_wall_sprite(
	parent_node: Node2D,
	texture: Texture2D,
	world_position: Vector2,
	sprite_scale: Vector2,
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = world_position
	sprite.scale = sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent_node.add_child(sprite)
	return sprite
