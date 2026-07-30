class_name ModularHospitalRoom
extends RoomBuilder

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
	_build_floor_details()
	_build_theme_props()
	_build_light_accents()


func _build_floor_details() -> void:
	var details := Node2D.new()
	details.name = "FloorDetails"
	details.z_index = -18
	add_child(details)
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
	if foreground_walls == null:
		return
	var target_alpha := 0.2 if faded else 1.0
	create_tween().tween_property(foreground_walls, "modulate:a", target_alpha, 0.18)
