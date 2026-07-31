class_name MapThemeCatalog
extends RefCounted

const HOSPITAL_THEME := &"abandoned_hospital"
const HOSPITAL_THEME_RESOURCE := "res://resources/map_themes/dungeon1_hospital.tres"
const HOSPITAL_FLOOR_MACRO := (
	"res://assets/art/worlds/map_demo/dungeon1_hospital/"
	+ "standard_floor_macro_v1.webp"
)
const HOSPITAL_WALL_SHELL := (
	"res://assets/art/worlds/map_demo/dungeon1_hospital/"
	+ "standard_wall_shell_v1.webp"
)
const SANATORIUM_V2_ROOT := (
	"res://assets/art/worlds/map_demo/dungeon1_sanatorium_v2/"
)
const SANATORIUM_V2_FLOOR := (
	SANATORIUM_V2_ROOT + "standard_combat_floor_v1.png"
)
const SANATORIUM_V2_WALL_SHELL := (
	SANATORIUM_V2_ROOT + "standard_combat_wall_shell_v1.png"
)
const SANATORIUM_V2_FOREGROUND := (
	SANATORIUM_V2_ROOT + "standard_combat_foreground_v1.png"
)
const SANATORIUM_V2_PROPS := (
	SANATORIUM_V2_ROOT + "standard_combat_props_v1.png"
)
const SANATORIUM_V2_DOORS := (
	SANATORIUM_V2_ROOT + "standard_combat_doors_v1.png"
)
const HOSPITAL_BOSS_FLOOR_MACRO := (
	"res://assets/art/worlds/map_demo/dungeon1_hospital/"
	+ "boss_floor_macro_v1.webp"
)
const HOSPITAL_BOSS_WALL_SHELL := (
	"res://assets/art/worlds/map_demo/dungeon1_hospital/"
	+ "boss_wall_shell_v1.webp"
)

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
		"spawn": Vector2(384, 544),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(8, 5)),
		"camera_guide_outline": PackedVector2Array([
			Vector2(704, 512), Vector2(832, 512),
			Vector2(832, 640), Vector2(704, 640),
		]),
		"door_sockets": [
			_door_at("west", Vector2i(1, 4), Vector2(256, 494)),
			_door_at("east", Vector2i(10, 4), Vector2(1280, 494)),
		],
		"door_profile": _sanatorium_v2_door_profile(),
		"hide_theme_props": true,
		"floor_macro": {
			"node_name": "StandardFloorMacro",
			"texture_path": SANATORIUM_V2_FLOOR,
			"world_rect": Rect2(0, 32, 1536, 960),
			"z_index": -24,
		},
		"wall_shell": {
			"node_name": "StandardWallShell",
			"texture_path": SANATORIUM_V2_WALL_SHELL,
			"hide_generated_walls": true,
			"regions": [
				_layer_region(
					"architecture",
					SANATORIUM_V2_WALL_SHELL,
					Rect2(0, 0, 1586, 992),
					Rect2(0, 32, 1536, 960),
					-7,
				),
				_layer_region(
					"back_props",
					SANATORIUM_V2_PROPS,
					Rect2(0, 0, 1586, 620),
					Rect2(0, 32, 1536, 600),
					-2,
				),
				_layer_region(
					"front_props",
					SANATORIUM_V2_PROPS,
					Rect2(0, 620, 1586, 372),
					Rect2(0, 632, 1536, 360),
					37,
					true,
				),
				_layer_region(
					"foreground_wall",
					SANATORIUM_V2_FOREGROUND,
					Rect2(0, 0, 1586, 992),
					Rect2(0, 32, 1536, 960),
					38,
					true,
				),
			],
		},
		"guide_line": PackedVector2Array([Vector2(274, 494), Vector2(1262, 494)]),
		"content_slots": [
			_slot("west_cover", "cover", Vector2i(4, 3), "cover_a"),
			_slot("objective", "objective", Vector2i(6, 4), "objective"),
			_slot("east_cover", "cover", Vector2i(8, 5), "cover_b"),
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
		"door_profile": _hospital_door_profile(),
		"guide_line": PackedVector2Array([Vector2(274, 576), Vector2(1774, 576)]),
		"content_slots": [
			_slot("west_cover", "cover", Vector2i(4, 3), "cover_a"),
			_slot("west_spawn", "enemy", Vector2i(6, 5), "enemy"),
			_slot("east_spawn", "enemy", Vector2i(10, 3), "enemy"),
			_slot("east_cover", "cover", Vector2i(12, 5), "cover_b"),
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
		"door_profile": _hospital_door_profile(),
		"guide_line": PackedVector2Array([
			Vector2(274, 448), Vector2(960, 448),
			Vector2(960, 832), Vector2(1774, 832),
		]),
		"content_slots": [
			_slot("upper_cover", "cover", Vector2i(5, 3), "cover_a"),
			_slot("junction", "objective", Vector2i(7, 4), "objective"),
			_slot("lower_spawn", "enemy", Vector2i(9, 6), "enemy"),
			_slot("east_cover", "cover", Vector2i(12, 6), "cover_b"),
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
		"room_id": &"hospital_boss_containment_arena",
		"theme_id": HOSPITAL_THEME,
		"theme_resource": HOSPITAL_THEME_RESOURCE,
		"title": "深层收容手术厅",
		"room_kind": "boss",
		"size_class": MapRoomModule.RoomSizeClass.BOSS,
		"camera_zoom": Vector2(0.84, 0.84),
		"camera_overscan": 1.28,
		"map_bounds": Rect2(0, 0, 2560, 1792),
		"spawn": Vector2(1280, 1408),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(16, 10)),
		"obstacle_cells": [
			Vector2i(5, 5),
			Vector2i(14, 5),
			Vector2i(5, 9),
			Vector2i(14, 9),
		],
		"camera_guide_outline": PackedVector2Array([
			Vector2(640, 512), Vector2(1920, 512),
			Vector2(1920, 1280), Vector2(640, 1280),
		]),
		"door_sockets": [
			_door_at("north", Vector2i(9, 1), Vector2(1280, 256)),
			_door_at("south", Vector2i(10, 12), Vector2(1280, 1536)),
		],
		"door_profile": {
			"style": &"containment",
			"theme_mark": &"containment_warning",
			"mark_color": Color(0.98, 0.28, 0.16, 0.68),
		},
		"floor_macro": {
			"node_name": "BossFloorMacro",
			"texture_path": HOSPITAL_BOSS_FLOOR_MACRO,
			"world_rect": Rect2(152, 192, 2256, 1408),
			"z_index": -24,
		},
		"wall_shell": {
			"node_name": "BossWallShell",
			"texture_path": HOSPITAL_BOSS_WALL_SHELL,
			"hide_generated_walls": true,
			"regions": [
				_shell_region("back_wall", Rect2(0, 0, 2560, 384), -7),
				_shell_region("west_wall", Rect2(0, 384, 384, 1024), 4),
				_shell_region("east_wall", Rect2(2176, 384, 384, 1024), 4),
				_shell_region(
					"foreground_wall",
					Rect2(0, 1408, 2560, 384),
					38,
					true,
				),
			],
		},
		"guide_line": PackedVector2Array([
			Vector2(1280, 1536),
			Vector2(1280, 896),
			Vector2(1216, 832),
		]),
		"content_slots": [
			_slot("boss_spawn", "boss", Vector2i(9, 6)),
			_slot("summon_north_west", "enemy", Vector2i(6, 4)),
			_slot("summon_north_east", "enemy", Vector2i(13, 4)),
			_slot("summon_south_west", "enemy", Vector2i(6, 10)),
			_slot("summon_south_east", "enemy", Vector2i(13, 10)),
			_slot("pillar_north_west", "cover", Vector2i(5, 5), "cover_a"),
			_slot("pillar_north_east", "cover", Vector2i(14, 5), "cover_b"),
			_slot("pillar_south_west", "cover", Vector2i(5, 9), "cover_b"),
			_slot("pillar_south_east", "cover", Vector2i(14, 9), "cover_a"),
			_slot("reward", "reward", Vector2i(9, 8)),
		],
		"zones": [
			_zone(
				"boss_arena",
				Rect2(256, 256, 2048, 1280),
				true,
				[],
				[],
			),
		],
		"boss": {
			"scene": "res://scenes/entities/boss.tscn",
			"spawn_slot": &"boss_spawn",
			"summon_slots": PackedStringArray([
				"summon_north_west",
				"summon_north_east",
				"summon_south_west",
				"summon_south_east",
			]),
			"phase_thresholds": PackedFloat32Array([0.5]),
			"reward_slot": &"reward",
			"lock_on_enter": true,
		},
		"art_contract": {
			"canvas_size": Vector2i(2560, 1792),
			"combat_rect": Rect2i(256, 256, 2048, 1280),
			"floor_asset": "boss_floor_macro_v1.webp",
			"floor_world_rect": Rect2i(152, 192, 2256, 1408),
			"wall_asset": "boss_wall_shell_v1.webp",
		},
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


static func _hospital_door_profile() -> Dictionary:
	return {
		"theme_mark": &"medical_cross",
		"mark_color": Color(0.32, 0.78, 0.7, 0.52),
	}


static func _sanatorium_v2_door_profile() -> Dictionary:
	return {
		"theme_mark": &"medical_cross",
		"mark_color": Color(0.32, 0.78, 0.7, 0.52),
		"art_texture_path": SANATORIUM_V2_DOORS,
		"west_source_region": Rect2(154, 401, 78, 154),
		"east_source_region": Rect2(1354, 401, 78, 154),
		"visual_scale": 1536.0 / 1586.0,
		"side_visual_recess": 69.5,
		"travel_distance": 47.0,
	}


static func _door(direction: String, cell: Vector2i) -> Dictionary:
	return {
		"direction": StringName(direction),
		"cell": cell,
	}


static func _door_at(direction: String, cell: Vector2i, anchor: Vector2) -> Dictionary:
	var result := _door(direction, cell)
	result["anchor"] = anchor
	return result


static func _slot(
	id: String,
	type: String,
	cell: Vector2i,
	visual_id := "",
) -> Dictionary:
	var result := {
		"id": StringName(id),
		"type": StringName(type),
		"cell": cell,
	}
	if not visual_id.is_empty():
		result["visual_id"] = StringName(visual_id)
	return result


static func _shell_region(
	id: String,
	rect: Rect2,
	z_index: int,
	foreground := false,
) -> Dictionary:
	return {
		"id": StringName(id),
		"source_region": rect,
		"world_rect": rect,
		"z_index": z_index,
		"foreground": foreground,
	}


static func _layer_region(
	id: String,
	texture_path: String,
	source_region: Rect2,
	world_rect: Rect2,
	z_index: int,
	foreground := false,
) -> Dictionary:
	return {
		"id": StringName(id),
		"texture_path": texture_path,
		"source_region": source_region,
		"world_rect": world_rect,
		"z_index": z_index,
		"foreground": foreground,
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
