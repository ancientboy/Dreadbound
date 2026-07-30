class_name MapThemeCatalog
extends RefCounted

const HOSPITAL_THEME := &"abandoned_hospital"

static func _hospital_rooms() -> Array[Dictionary]:
	return [
	{
		"room_id": &"hospital_standard_combat",
		"theme_id": HOSPITAL_THEME,
		"title": "标准战斗房",
		"room_kind": "combat",
		"size_class": MapRoomModule.RoomSizeClass.STANDARD,
		"texture_path": "res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png",
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
		"title": "长条住院区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"texture_path": "res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png",
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
		"title": "L 形精英病区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"texture_path": "res://assets/art/worlds/map_demo/hospital_tiles_v8/floor_atlas.png",
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
	{
		"room_id": &"hospital_cross_ambush",
		"theme_id": HOSPITAL_THEME,
		"title": "十字伏击病区",
		"room_kind": "ambush",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"texture_path": "res://assets/art/worlds/map_demo/themes/hospital/cross_ambush.jpg",
		"camera_zoom": Vector2(1.6, 1.6),
		"spawn": Vector2(760, 800),
		"walkable_outline": PackedVector2Array([
			Vector2(570, 90), Vector2(970, 90), Vector2(970, 310),
			Vector2(1450, 310), Vector2(1450, 710), Vector2(970, 710),
			Vector2(970, 940), Vector2(570, 940), Vector2(570, 710),
			Vector2(90, 710), Vector2(90, 310), Vector2(570, 310),
		]),
		"camera_guide_outline": PackedVector2Array([
			Vector2(650, 300), Vector2(890, 300), Vector2(890, 410),
			Vector2(1220, 410), Vector2(1220, 610), Vector2(890, 610),
			Vector2(890, 740), Vector2(650, 740), Vector2(650, 610),
			Vector2(320, 610), Vector2(320, 410), Vector2(650, 410),
		]),
		"door_directions": PackedStringArray(["north", "south", "west", "east"]),
		"zones": [
			_zone("center", Rect2(560, 300, 420, 420), true, [
				Vector2(680, 440), Vector2(860, 590),
			], ["诱导残响", "伏击护理体"]),
			_zone("west_arm", Rect2(90, 310, 470, 400), false, [
				Vector2(250, 450), Vector2(430, 600),
			], ["西翼病患", "西翼病患"]),
			_zone("east_arm", Rect2(980, 310, 470, 400), false, [
				Vector2(1110, 440), Vector2(1320, 600),
			], ["东翼病患", "精英医护残响"]),
		],
	},
	{
		"room_id": &"hospital_ring_quarantine",
		"theme_id": HOSPITAL_THEME,
		"title": "环形隔离病区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"texture_path": "res://assets/art/worlds/map_demo/themes/hospital/ring_quarantine.jpg",
		"camera_zoom": Vector2(1.55, 1.55),
		"spawn": Vector2(770, 850),
		"walkable_outline": PackedVector2Array([
			Vector2(190, 120), Vector2(1346, 120), Vector2(1470, 260),
			Vector2(1470, 780), Vector2(1346, 910), Vector2(190, 910),
			Vector2(66, 780), Vector2(66, 260),
		]),
		"camera_guide_outline": PackedVector2Array([
			Vector2(370, 300), Vector2(1166, 300), Vector2(1260, 400),
			Vector2(1260, 630), Vector2(1166, 730), Vector2(370, 730),
			Vector2(276, 630), Vector2(276, 400),
		]),
		"blocked_outlines": [
			PackedVector2Array([
				Vector2(515, 285), Vector2(1025, 285), Vector2(1070, 360),
				Vector2(1070, 675), Vector2(1025, 745), Vector2(515, 745),
				Vector2(470, 675), Vector2(470, 360),
			]),
		],
		"door_directions": PackedStringArray(["north", "south", "west", "east"]),
		"zones": [
			_zone("west_loop", Rect2(70, 200, 530, 650), true, [
				Vector2(260, 350), Vector2(340, 690),
			], ["隔离巡游体", "回声病患"]),
			_zone("east_loop", Rect2(936, 200, 530, 650), false, [
				Vector2(1190, 350), Vector2(1270, 690),
			], ["隔离巡游体", "精英隔离体"]),
			_zone("north_loop", Rect2(520, 120, 500, 280), false, [
				Vector2(680, 260), Vector2(870, 260),
			], ["监护残响", "值守残影"]),
		],
	},
	{
		"room_id": &"hospital_asymmetric_boss",
		"theme_id": HOSPITAL_THEME,
		"title": "不对称手术 Boss 房",
		"room_kind": "boss",
		"size_class": MapRoomModule.RoomSizeClass.BOSS,
		"texture_path": "res://assets/art/worlds/map_demo/themes/hospital/asymmetric_boss.jpg",
		"camera_zoom": Vector2(1.48, 1.48),
		"spawn": Vector2(760, 820),
		"walkable_outline": PackedVector2Array([
			Vector2(120, 160), Vector2(450, 160), Vector2(520, 90),
			Vector2(1260, 90), Vector2(1260, 180), Vector2(1470, 240),
			Vector2(1470, 800), Vector2(1280, 900), Vector2(1030, 900),
			Vector2(960, 960), Vector2(580, 960), Vector2(520, 900),
			Vector2(120, 840),
		]),
		"camera_guide_outline": PackedVector2Array([
			Vector2(350, 320), Vector2(520, 260), Vector2(1120, 260),
			Vector2(1250, 390), Vector2(1250, 690), Vector2(1080, 760),
			Vector2(450, 760), Vector2(300, 650),
		]),
		"door_directions": PackedStringArray(["north", "south", "west"]),
		"zones": [
			_zone("preparation", Rect2(100, 160, 430, 680), true, [
				Vector2(250, 360), Vector2(360, 650),
			], ["手术前置体", "失序护理体"]),
			_zone("boss_arena", Rect2(500, 100, 760, 800), false, [
				Vector2(780, 420), Vector2(960, 620),
			], ["阈值手术体", "手术护卫"]),
			_zone("quarantine_bays", Rect2(1240, 220, 230, 600), false, [
				Vector2(1340, 380), Vector2(1340, 680),
			], ["隔离增援体", "隔离增援体"]),
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
