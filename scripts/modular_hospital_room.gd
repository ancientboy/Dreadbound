class_name ModularHospitalRoom
extends RoomBuilder

const STANDARD_FLOOR_WALL_OVERLAP := Vector2(104.0, 64.0)
const STANDARD_FLOOR_CORNER_CUT := Vector2(44.0, 44.0)
const DEFAULT_THEME: RoomTheme = preload(
	"res://resources/map_themes/dungeon1_hospital.tres"
)
var theme: RoomTheme = DEFAULT_THEME


func build_from_spec(spec: Dictionary) -> void:
	var theme_path := String(spec.get(
		"theme_resource",
		"res://resources/map_themes/dungeon1_hospital.tres",
	))
	var loaded_theme := load(theme_path) as RoomTheme
	assert(loaded_theme != null, "Hospital room requires a valid RoomTheme")
	theme = loaded_theme
	build(
		spec,
		theme.floor_atlas,
		theme.wall_atlas,
		theme.floor_atlas_size,
		theme.wall_atlas_size,
	)
	_build_standard_floor_macro()
	_build_standard_wall_shell()
	_build_floor_details()
	_build_theme_props()
	_build_light_accents()


func _build_standard_floor_macro() -> void:
	if not _uses_standard_floor_macro():
		return
	var grid_cells: Array = room_spec.get("grid_cells", [])
	var min_cell := Vector2i(1 << 20, 1 << 20)
	var max_cell := Vector2i(-(1 << 20), -(1 << 20))
	for cell_value in grid_cells:
		var cell: Vector2i = cell_value
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	var target_size := (
		Vector2((max_cell - min_cell + Vector2i.ONE) * TILE_SIZE)
		+ STANDARD_FLOOR_WALL_OVERLAP * 2.0
	)
	var floor_macro := Polygon2D.new()
	floor_macro.name = "StandardFloorMacro"
	floor_macro.texture = theme.standard_floor_macro
	floor_macro.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor_macro.position = (
		Vector2(min_cell * TILE_SIZE) - STANDARD_FLOOR_WALL_OVERLAP
	)
	floor_macro.polygon = _standard_floor_outline(target_size)
	var texture_size := Vector2(theme.standard_floor_macro.get_size())
	var texture_uv := PackedVector2Array()
	for point in floor_macro.polygon:
		texture_uv.append(point / target_size * texture_size)
	floor_macro.uv = texture_uv
	floor_macro.z_index = -24
	add_child(floor_macro)


func _standard_floor_outline(size: Vector2) -> PackedVector2Array:
	var cut := STANDARD_FLOOR_CORNER_CUT
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


func _uses_standard_floor_macro() -> bool:
	return (
		theme.standard_floor_macro != null
		and StringName(room_spec.get("room_id", &"")) == &"hospital_standard_combat"
	)


func _build_standard_wall_shell() -> void:
	if not _uses_standard_floor_macro() or theme.standard_wall_shell == null:
		return
	var shell := Node2D.new()
	shell.name = "StandardWallShell"
	add_child(shell)
	_add_wall_shell_region(
		shell,
		"BackWall",
		Rect2(0, 0, 1536, 256),
		Vector2.ZERO,
		-7,
	)
	_add_wall_shell_region(
		shell,
		"WestWall",
		Rect2(0, 256, 256, 640),
		Vector2(0, 256),
		4,
	)
	_add_wall_shell_region(
		shell,
		"EastWall",
		Rect2(1280, 256, 256, 640),
		Vector2(1280, 256),
		4,
	)
	_add_wall_shell_region(
		shell,
		"ForegroundWall",
		Rect2(0, 896, 1536, 128),
		Vector2(0, 896),
		38,
	)
	# Keep generated wall cells available for collision/layout inspection, while the
	# standard room uses a continuous shell instead of visible 128 px repetition.
	for tile_layer in [wall_base_tiles, side_wall_tiles, foreground_walls, corner_tiles]:
		tile_layer.visible = false


func _add_wall_shell_region(
	parent: Node2D,
	node_name: String,
	region_rect: Rect2,
	world_position: Vector2,
	layer: int,
) -> void:
	var region := AtlasTexture.new()
	region.atlas = theme.standard_wall_shell
	region.region = region_rect
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = region
	sprite.centered = false
	sprite.position = world_position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = layer
	parent.add_child(sprite)


func _build_floor_details() -> void:
	var details := Node2D.new()
	details.name = "FloorDetails"
	details.z_index = -18
	add_child(details)
	if not _uses_standard_floor_macro():
		var center_line := Line2D.new()
		center_line.name = "MedicalGuideLine"
		var line_points: PackedVector2Array = room_spec.get(
			"guide_line",
			PackedVector2Array(),
		)
		center_line.points = line_points
		center_line.width = 4.0
		center_line.default_color = theme.guide_color
		center_line.antialiased = true
		details.add_child(center_line)
		var route_glow := center_line.duplicate() as Line2D
		route_glow.name = "MedicalGuideGlow"
		route_glow.width = 13.0
		route_glow.default_color = Color(
			theme.guide_color.r,
			theme.guide_color.g,
			theme.guide_color.b,
			0.07,
		)
		route_glow.z_index = -1
		details.add_child(route_glow)
	for door_spec in room_spec.get("door_sockets", []):
		var threshold := Polygon2D.new()
		var direction := StringName(door_spec["direction"])
		threshold.name = "%sThreshold" % String(direction).capitalize()
		threshold.position = door_anchor_points[direction]
		threshold.polygon = (
			PackedVector2Array([
				Vector2(-18, -58), Vector2(18, -58),
				Vector2(18, 58), Vector2(-18, 58),
			])
			if direction == &"west" or direction == &"east"
			else PackedVector2Array([
				Vector2(-58, -18), Vector2(58, -18),
				Vector2(58, 18), Vector2(-58, 18),
			])
		)
		threshold.color = Color(0.025, 0.08, 0.1, 0.94)
		details.add_child(threshold)
		_add_threshold_warning(details, threshold.position, direction)

	if not _uses_standard_floor_macro():
		for slot_spec in room_spec.get("content_slots", []):
			if StringName(slot_spec["type"]) != &"objective":
				continue
			var center := _cell_center(slot_spec["cell"])
			var objective_marker := Line2D.new()
			objective_marker.name = "ObjectiveBay"
			objective_marker.points = PackedVector2Array([
				center + Vector2(-110, -78), center + Vector2(110, -78),
				center + Vector2(110, 78), center + Vector2(-110, 78),
				center + Vector2(-110, -78),
			])
			objective_marker.width = 3.0
			objective_marker.default_color = Color(0.3, 0.78, 0.73, 0.18)
			objective_marker.antialiased = true
			details.add_child(objective_marker)
			break


func _add_threshold_warning(
	parent: Node2D,
	anchor: Vector2,
	direction: StringName,
) -> void:
	for index in 5:
		var stripe := Polygon2D.new()
		stripe.name = "ThresholdWarning%d" % (index + 1)
		stripe.position = anchor
		var offset := -42.0 + index * 21.0
		if direction == &"west" or direction == &"east":
			stripe.polygon = PackedVector2Array([
				Vector2(-10, offset - 8), Vector2(10, offset + 1),
				Vector2(10, offset + 9), Vector2(-10, offset),
			])
		else:
			stripe.polygon = PackedVector2Array([
				Vector2(offset - 8, -10), Vector2(offset + 1, 10),
				Vector2(offset + 9, 10), Vector2(offset, -10),
			])
		stripe.color = Color(
			theme.warning_color.r,
			theme.warning_color.g,
			theme.warning_color.b,
			0.32,
		)
		parent.add_child(stripe)


func _build_theme_props() -> void:
	var props := Node2D.new()
	props.name = "ThemeProps"
	props.z_index = 7
	props.y_sort_enabled = true
	add_child(props)
	var slot_index := 0
	for slot_spec in room_spec.get("content_slots", []):
		var slot_type := StringName(slot_spec["type"])
		var atlas_index := 0
		if slot_type == &"objective":
			atlas_index = 2
		elif slot_type == &"enemy":
			atlas_index = 3
		elif slot_index % 2 == 1:
			atlas_index = 1
		var sprite := Sprite2D.new()
		sprite.name = "%sVisual" % String(slot_spec["id"]).to_pascal_case()
		sprite.texture = _prop_region(atlas_index)
		sprite.position = _cell_center(slot_spec["cell"])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		props.add_child(sprite)
		slot_index += 1


func _prop_region(index: int) -> AtlasTexture:
	var region := AtlasTexture.new()
	region.atlas = theme.prop_atlas
	region.region = Rect2(
		Vector2(index * theme.prop_region_size.x, 0),
		Vector2(theme.prop_region_size),
	)
	return region


func _build_light_accents() -> void:
	var accents := Node2D.new()
	accents.name = "LightAccents"
	accents.z_index = 10
	add_child(accents)
	for door_spec in room_spec.get("door_sockets", []):
		var direction := StringName(door_spec["direction"])
		var glow := Polygon2D.new()
		glow.name = "%sDoorGlow" % String(direction).capitalize()
		glow.position = door_anchor_points[direction]
		glow.polygon = (
			PackedVector2Array([
				Vector2(-30, -72), Vector2(30, -72),
				Vector2(50, 0), Vector2(30, 72), Vector2(-30, 72),
			])
			if direction == &"west" or direction == &"east"
			else PackedVector2Array([
				Vector2(-72, -30), Vector2(72, -30),
				Vector2(72, 30), Vector2(-72, 30),
			])
		)
		glow.color = Color(
			theme.warning_color.r,
			theme.warning_color.g,
			theme.warning_color.b,
			0.045,
		)
		accents.add_child(glow)


func set_foreground_faded(faded: bool) -> void:
	var target_alpha := 0.2 if faded else 1.0
	if foreground_walls != null:
		create_tween().tween_property(foreground_walls, "modulate:a", target_alpha, 0.18)
	var shell_foreground := get_node_or_null(
		"StandardWallShell/ForegroundWall"
	) as Sprite2D
	if shell_foreground != null:
		create_tween().tween_property(
			shell_foreground,
			"modulate:a",
			target_alpha,
			0.18,
		)
