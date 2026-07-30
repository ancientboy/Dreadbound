class_name MapThemeCatalog
extends RefCounted

const HOSPITAL_THEME := &"abandoned_hospital"
const HOSPITAL_THEME_RESOURCE := "res://resources/map_themes/dungeon1_hospital.tres"

static func _hospital_rooms() -> Array[Dictionary]:
	return [
	{
		"room_id": &"hospital_standard_combat",
		"theme_id": HOSPITAL_THEME,
		"theme_resource": HOSPITAL_THEME_RESOURCE,
		"title": "标准战斗房",
		"room_kind": "combat",
		"size_class": MapRoomModule.RoomSizeClass.STANDARD,
		"camera_zoom": Vector2(0.72, 0.72),
		"map_bounds": Rect2(0, 0, 1536, 1024),
		"spawn": Vector2(384, 576),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(8, 5)),
		"camera_guide_outline": PackedVector2Array([
			Vector2(704, 512), Vector2(832, 512),
			Vector2(832, 640), Vector2(704, 640),
		]),
		"door_sockets": [
			_door("west", Vector2i(1, 4)),
			_door("east", Vector2i(10, 4)),
		],
		"guide_line": PackedVector2Array([Vector2(274, 576), Vector2(1262, 576)]),
		"content_slots": [
			_slot("west_cover", "cover", Vector2i(4, 3)),
			_slot("objective", "objective", Vector2i(6, 4)),
			_slot("east_cover", "cover", Vector2i(8, 5)),
		],
		"zones": [
			_zone("arena", Rect2(256, 256, 1024, 640), true, [
				Vector2(640, 448), Vector2(960, 704),
			], ["游荡病患", "破损护理体"]),
		],
	},
	{
		"room_id": &"hospital_long_ward",
		"theme_id": HOSPITAL_THEME,
		"theme_resource": HOSPITAL_THEME_RESOURCE,
		"title": "长条住院区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"camera_zoom": Vector2(0.72, 0.72),
		"map_bounds": Rect2(0, 0, 2048, 1024),
		"spawn": Vector2(384, 576),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(12, 5)),
		"camera_guide_outline": PackedVector2Array([
			Vector2(640, 512), Vector2(1408, 512),
			Vector2(1408, 640), Vector2(640, 640),
		]),
		"door_sockets": [
			_door("west", Vector2i(1, 4)),
			_door("east", Vector2i(14, 4)),
		],
		"guide_line": PackedVector2Array([Vector2(274, 576), Vector2(1774, 576)]),
		"content_slots": [
			_slot("west_cover", "cover", Vector2i(4, 3)),
			_slot("west_spawn", "enemy", Vector2i(6, 5)),
			_slot("east_spawn", "enemy", Vector2i(10, 3)),
			_slot("east_cover", "cover", Vector2i(12, 5)),
		],
		"zones": [
			_zone("west_wing", Rect2(256, 256, 768, 640), true, [
				Vector2(640, 448), Vector2(896, 704),
			], ["游荡病患", "破损护理体"]),
			_zone("east_wing", Rect2(1024, 256, 768, 640), false, [
				Vector2(1216, 448), Vector2(1536, 704),
			], ["值守残影", "精英医护残响"]),
		],
	},
	{
		"room_id": &"hospital_l_elite",
		"theme_id": HOSPITAL_THEME,
		"theme_resource": HOSPITAL_THEME_RESOURCE,
		"title": "L 形精英病区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"camera_zoom": Vector2(0.72, 0.72),
		"map_bounds": Rect2(0, 0, 2048, 1280),
		"spawn": Vector2(512, 448),
		"grid_cells": (
			_rect_cells(Vector2i(2, 2), Vector2i(7, 3))
			+ _rect_cells(Vector2i(6, 5), Vector2i(8, 3))
		),
		"camera_guide_outline": PackedVector2Array([
			Vector2(512, 448), Vector2(1024, 448),
			Vector2(1024, 704), Vector2(1536, 704),
			Vector2(1536, 896), Vector2(896, 896),
			Vector2(896, 576), Vector2(512, 576),
		]),
		"door_sockets": [
			_door("west", Vector2i(1, 3)),
			_door("east", Vector2i(14, 6)),
		],
		"guide_line": PackedVector2Array([
			Vector2(274, 448), Vector2(960, 448),
			Vector2(960, 832), Vector2(1774, 832),
		]),
		"content_slots": [
			_slot("upper_cover", "cover", Vector2i(5, 3)),
			_slot("junction", "objective", Vector2i(7, 4)),
			_slot("lower_spawn", "enemy", Vector2i(9, 6)),
			_slot("east_cover", "cover", Vector2i(12, 6)),
		],
		"zones": [
			_zone("upper_ward", Rect2(256, 256, 896, 384), true, [
				Vector2(512, 448), Vector2(896, 448),
			], ["隔离病患", "巡诊残响"]),
			_zone("lower_ward", Rect2(768, 640, 1024, 384), false, [
				Vector2(1088, 832), Vector2(1536, 832),
			], ["破损护理体", "精英隔离体"]),
		],
	},
]


static func hospital_rooms() -> Array[Dictionary]:
	return _hospital_rooms()


static func room_at(index: int) -> Dictionary:
	var rooms := _hospital_rooms()
	return rooms[posmod(index, rooms.size())]


static func rooms_for_theme(theme_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room in _hospital_rooms():
		if room["theme_id"] == theme_id:
			result.append(room.duplicate(true))
	return result


static func is_theme_locked(rooms: Array[Dictionary]) -> bool:
	if rooms.is_empty():
		return true
	var theme_id: StringName = rooms[0]["theme_id"]
	for room in rooms:
		if room["theme_id"] != theme_id:
			return false
	return true


static func _rect_cells(origin: Vector2i, size: Vector2i) -> Array:
	var result: Array = []
	for y_index in size.y:
		for x_index in size.x:
			result.append(origin + Vector2i(x_index, y_index))
	return result


static func _door(direction: String, cell: Vector2i) -> Dictionary:
	return {
		"direction": StringName(direction),
		"cell": cell,
	}


static func _slot(id: String, type: String, cell: Vector2i) -> Dictionary:
	return {
		"id": StringName(id),
		"type": StringName(type),
		"cell": cell,
	}


static func _zone(
	id: String,
	bounds: Rect2,
	starts_active: bool,
	spawns: Array,
	labels: Array,
) -> Dictionary:
	return {
		"id": StringName(id),
		"bounds": bounds,
		"starts_active": starts_active,
		"spawns": spawns,
		"labels": PackedStringArray(labels),
	}
