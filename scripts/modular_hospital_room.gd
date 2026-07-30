class_name ModularHospitalRoom
extends RoomBuilder

const FLOOR_ATLAS := preload(
	"res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png"
)
const WALL_ATLAS := preload(
	"res://assets/art/worlds/map_demo/hospital_tiles_v8/wall_atlas.svg"
)


func build_from_spec(spec: Dictionary) -> void:
	build(spec, FLOOR_ATLAS, WALL_ATLAS)
	_build_floor_details()


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
	center_line.width = 5.0
	center_line.default_color = Color(0.16, 0.68, 0.64, 0.24)
	center_line.antialiased = true
	details.add_child(center_line)
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
		threshold.color = Color(0.16, 0.25, 0.27, 0.92)
		details.add_child(threshold)


func set_foreground_faded(faded: bool) -> void:
	if foreground_walls == null:
		return
	var target_alpha := 0.2 if faded else 1.0
	create_tween().tween_property(foreground_walls, "modulate:a", target_alpha, 0.18)
