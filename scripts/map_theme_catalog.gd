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
const SANATORIUM_DOOR_MODULES := (
	SANATORIUM_V2_ROOT + "sanatorium_door_modules_v1.webp"
)
const SANATORIUM_LONG_WARD_FLOOR := (
	SANATORIUM_V2_ROOT + "long_ward_floor_v1.webp"
)
const SANATORIUM_LONG_WARD_WALL_SHELL := (
	SANATORIUM_V2_ROOT + "long_ward_wall_shell_v1.webp"
)
const SANATORIUM_LONG_WARD_FOREGROUND := (
	SANATORIUM_V2_ROOT + "long_ward_foreground_v1.webp"
)
const SANATORIUM_LONG_WARD_PROPS := (
	SANATORIUM_V2_ROOT + "long_ward_props_v1.webp"
)
const SANATORIUM_LONG_WARD_DOORS := (
	SANATORIUM_V2_ROOT + "long_ward_doors_v1.webp"
)
const SANATORIUM_L_ELITE_FLOOR := (
	SANATORIUM_V2_ROOT + "l_elite_floor_v1.webp"
)
const SANATORIUM_L_ELITE_WALL_SHELL := (
	SANATORIUM_V2_ROOT + "l_elite_wall_shell_v1.webp"
)
const SANATORIUM_L_ELITE_FOREGROUND := (
	SANATORIUM_V2_ROOT + "l_elite_foreground_v1.webp"
)
const SANATORIUM_L_ELITE_PROPS := (
	SANATORIUM_V2_ROOT + "l_elite_props_v1.webp"
)
const SANATORIUM_L_ELITE_DOORS := (
	SANATORIUM_V2_ROOT + "l_elite_doors_v1.webp"
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
		"camera_zoom": Vector2(0.96, 0.96),
		"camera_overscan": 1.08,
		"camera_view_bounds": Rect2(64, 64, 1408, 896),
		"map_bounds": Rect2(0, 0, 1536, 1024),
		"spawn": Vector2(384, 544),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(8, 5)),
		"camera_guide_outline": PackedVector2Array([
			Vector2(640, 480), Vector2(896, 480),
			Vector2(896, 672), Vector2(640, 672),
		]),
		# Collision follows each fixture's floor-contact silhouette. Keep visual
		# overhangs, curtains, and the gaps between bed frames and cabinets walkable.
		"blocked_outlines": [
			# North-west bed frame and bedside cabinet.
			PackedVector2Array([
				Vector2(340, 326), Vector2(354, 312),
				Vector2(474, 312), Vector2(490, 328),
				Vector2(482, 382), Vector2(350, 382),
			]),
			_chamfered_rect_outline(Rect2(504, 338, 34, 46), 7.0),
			# North-center bed frame and bedside cabinet.
			PackedVector2Array([
				Vector2(636, 326), Vector2(650, 312),
				Vector2(770, 312), Vector2(786, 328),
				Vector2(778, 382), Vector2(646, 382),
			]),
			_chamfered_rect_outline(Rect2(800, 338, 34, 46), 7.0),
			# North-east bed frame and medical trolley.
			PackedVector2Array([
				Vector2(932, 326), Vector2(946, 312),
				Vector2(1066, 312), Vector2(1082, 328),
				Vector2(1074, 382), Vector2(942, 382),
			]),
			_chamfered_rect_outline(Rect2(1096, 336, 36, 48), 7.0),
			# South-west and south-east foreground equipment: only the bases block.
			PackedVector2Array([
				Vector2(344, 820), Vector2(360, 804),
				Vector2(468, 804), Vector2(484, 820),
				Vector2(476, 874), Vector2(352, 874),
			]),
			_chamfered_rect_outline(Rect2(504, 830, 44, 46), 8.0),
			PackedVector2Array([
				Vector2(984, 820), Vector2(1000, 804),
				Vector2(1108, 804), Vector2(1124, 820),
				Vector2(1116, 874), Vector2(992, 874),
			]),
			_chamfered_rect_outline(Rect2(1144, 830, 44, 46), 8.0),
		],
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
					Rect2(256, 192, 1024, 400),
					-2,
				),
				_layer_region(
					"front_props",
					SANATORIUM_V2_PROPS,
					Rect2(0, 620, 1586, 372),
					Rect2(256, 752, 1024, 240),
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
		"title": "长条病区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"camera_zoom": Vector2(0.92, 0.92),
		"camera_overscan": 1.04,
		"camera_view_bounds": Rect2(64, 64, 1920, 896),
		"map_bounds": Rect2(0, 0, 2048, 1024),
		"spawn": Vector2(320, 520),
		"grid_cells": _rect_cells(Vector2i(2, 2), Vector2i(12, 5)),
		"camera_guide_outline": PackedVector2Array([
			Vector2(448, 448), Vector2(1600, 448),
			Vector2(1600, 672), Vector2(448, 672),
		]),
		# Every blocker follows an independent prop's floor contact.  The full
		# west/east door corridor (y=420..640) is intentionally unobstructed.
		"blocked_outlines": [
			_chamfered_rect_outline(Rect2(360, 292, 112, 42), 8.0),
			_chamfered_rect_outline(Rect2(580, 292, 112, 42), 8.0),
			_chamfered_rect_outline(Rect2(800, 292, 108, 42), 8.0),
			_chamfered_rect_outline(Rect2(378, 398, 100, 24), 6.0),
			_chamfered_rect_outline(Rect2(608, 398, 106, 24), 6.0),
			_chamfered_rect_outline(Rect2(824, 400, 112, 24), 6.0),
			_chamfered_rect_outline(Rect2(1006, 296, 270, 64), 12.0),
			_chamfered_rect_outline(Rect2(1518, 306, 118, 50), 10.0),
			_chamfered_rect_outline(Rect2(1748, 306, 126, 50), 10.0),
			_chamfered_rect_outline(Rect2(1422, 812, 108, 44), 8.0),
			_chamfered_rect_outline(Rect2(1660, 828, 74, 34), 8.0),
		],
		"door_sockets": [
			_door_at("west", Vector2i(1, 4), Vector2(256, 512)),
			_door_at("east", Vector2i(14, 4), Vector2(1792, 512)),
		],
		"door_profile": _sanatorium_long_ward_door_profile(),
		"hide_theme_props": true,
		"floor_macro": {
			"node_name": "LongWardFloorMacro",
			"texture_path": SANATORIUM_LONG_WARD_FLOOR,
			"world_rect": Rect2(0, 0, 2048, 1024),
			"z_index": -24,
		},
		"wall_shell": {
			"node_name": "LongWardWallShell",
			"texture_path": SANATORIUM_LONG_WARD_WALL_SHELL,
			"hide_generated_walls": true,
			"regions": [
				_layer_region(
					"architecture",
					SANATORIUM_LONG_WARD_WALL_SHELL,
					Rect2(0, 0, 2048, 1024),
					Rect2(0, 0, 2048, 1024),
					-7,
				),
				_layer_region(
					"back_props",
					SANATORIUM_LONG_WARD_PROPS,
					Rect2(0, 0, 2048, 650),
					Rect2(0, 0, 2048, 650),
					-2,
				),
				_layer_region(
					"front_props",
					SANATORIUM_LONG_WARD_PROPS,
					Rect2(0, 650, 2048, 374),
					Rect2(0, 650, 2048, 374),
					37,
					true,
				),
				_layer_region(
					"foreground_wall",
					SANATORIUM_LONG_WARD_FOREGROUND,
					Rect2(0, 0, 2048, 1024),
					Rect2(0, 0, 2048, 1024),
					38,
					true,
				),
			],
		},
		"guide_line": PackedVector2Array([
			Vector2(222, 484), Vector2(826, 484),
			Vector2(826, 640), Vector2(1222, 640),
			Vector2(1222, 484), Vector2(1826, 484),
		]),
		"content_slots": [
			_slot("west_spawn_a", "enemy", Vector2i(5, 3), "enemy"),
			_slot("west_spawn_b", "enemy", Vector2i(6, 5), "enemy"),
			_slot("nurse_checkpoint", "objective", Vector2i(8, 4), "objective"),
			_slot("east_spawn_a", "enemy", Vector2i(10, 3), "enemy"),
			_slot("east_spawn_b", "enemy", Vector2i(12, 5), "enemy"),
		],
		"zones": [
			_zone("ward_wave", Rect2(192, 240, 768, 672), true, [
				Vector2(668, 406), Vector2(746, 716),
			], ["游荡病患", "破损护理体"]),
			_zone("isolation_wave", Rect2(1088, 240, 768, 672), false, [
				Vector2(1340, 432), Vector2(1568, 690),
			], ["值守残影", "精英医护残响"]),
		],
	},
	{
		"room_id": &"hospital_l_elite",
		"theme_id": HOSPITAL_THEME,
		"theme_resource": HOSPITAL_THEME_RESOURCE,
		"title": "L 形精英收容区",
		"room_kind": "elite",
		"size_class": MapRoomModule.RoomSizeClass.LARGE,
		"camera_zoom": Vector2(0.90, 0.90),
		"camera_overscan": 1.04,
		"camera_view_bounds": Rect2(64, 64, 1920, 1408),
		"map_bounds": Rect2(0, 0, 2048, 1536),
		"spawn": Vector2(320, 384),
		"grid_cells": (
			_rect_cells(Vector2i(1, 2), Vector2i(12, 2))
			+ _rect_cells(Vector2i(7, 4), Vector2i(6, 7))
		),
		"camera_guide_outline": PackedVector2Array([
			Vector2(384, 384), Vector2(1120, 384),
			Vector2(1120, 576), Vector2(1472, 576),
			Vector2(1472, 1120), Vector2(1120, 1120),
			Vector2(1120, 512), Vector2(384, 512),
		]),
		# Observation equipment and the two containment pods are standalone
		# props.  The west entry, elbow and south exit remain fully connected.
		"blocked_outlines": [
			_chamfered_rect_outline(Rect2(1050, 438, 112, 44), 8.0),
			_chamfered_rect_outline(Rect2(1220, 448, 116, 24), 6.0),
			_chamfered_rect_outline(Rect2(1098, 908, 126, 54), 10.0),
			_chamfered_rect_outline(Rect2(1528, 908, 132, 54), 10.0),
			_chamfered_rect_outline(Rect2(1022, 1180, 76, 34), 8.0),
			_chamfered_rect_outline(Rect2(1730, 1180, 76, 34), 8.0),
			_chamfered_rect_outline(Rect2(1324, 806, 34, 30), 6.0),
		],
		"door_sockets": [
			_door_at("west", Vector2i(0, 2), Vector2(176, 350)),
			_door_at("south", Vector2i(10, 11), Vector2(1341, 1320)),
		],
		"door_profile": _sanatorium_l_elite_door_profile(),
		"hide_theme_props": true,
		"floor_macro": {
			"node_name": "LEliteFloorMacro",
			"texture_path": SANATORIUM_L_ELITE_FLOOR,
			"world_rect": Rect2(0, 0, 2048, 1536),
			"z_index": -24,
		},
		"wall_shell": {
			"node_name": "LEliteWallShell",
			"texture_path": SANATORIUM_L_ELITE_WALL_SHELL,
			"hide_generated_walls": true,
			"regions": [
				_layer_region(
					"architecture",
					SANATORIUM_L_ELITE_WALL_SHELL,
					Rect2(0, 0, 2048, 1536),
					Rect2(0, 0, 2048, 1536),
					-7,
				),
				_layer_region(
					"back_props",
					SANATORIUM_L_ELITE_PROPS,
					Rect2(0, 0, 2048, 900),
					Rect2(0, 0, 2048, 900),
					-2,
				),
				_layer_region(
					"front_props",
					SANATORIUM_L_ELITE_PROPS,
					Rect2(0, 900, 2048, 636),
					Rect2(0, 900, 2048, 636),
					37,
					true,
				),
				_layer_region(
					"foreground_wall",
					SANATORIUM_L_ELITE_FOREGROUND,
					Rect2(0, 0, 2048, 1536),
					Rect2(0, 0, 2048, 1536),
					38,
					true,
				),
			],
		},
		"guide_line": PackedVector2Array([
			Vector2(214, 350), Vector2(1018, 350),
			Vector2(1120, 482), Vector2(1360, 650),
			Vector2(1360, 1342),
		]),
		"content_slots": [
			_slot("corner_ambush_a", "enemy", Vector2i(7, 3), "enemy"),
			_slot("corner_ambush_b", "enemy", Vector2i(9, 4), "enemy"),
			_slot("observation_console", "objective", Vector2i(10, 3), "objective"),
			_slot("elite_spawn", "enemy", Vector2i(10, 6), "enemy"),
			_slot("pod_guard_west", "enemy", Vector2i(8, 8), "enemy"),
			_slot("pod_guard_east", "enemy", Vector2i(12, 8), "enemy"),
		],
		"zones": [
			_zone("blind_corner_ambush", Rect2(768, 256, 704, 448), true, [
				Vector2(1000, 380), Vector2(1260, 560),
			], ["巡诊残响", "观察室伏击体"]),
			_zone("containment_elite", Rect2(896, 576, 896, 704), false, [
				Vector2(1210, 690), Vector2(1600, 690), Vector2(1370, 1170),
			], ["双舱守卫", "精英隔离体", "失控护理长"]),
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


static func _rect_outline(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


static func _chamfered_rect_outline(rect: Rect2, corner: float) -> PackedVector2Array:
	var inset := minf(corner, minf(rect.size.x, rect.size.y) * 0.5)
	return PackedVector2Array([
		rect.position + Vector2(inset, 0.0),
		Vector2(rect.end.x - inset, rect.position.y),
		Vector2(rect.end.x, rect.position.y + inset),
		Vector2(rect.end.x, rect.end.y - inset),
		Vector2(rect.end.x - inset, rect.end.y),
		Vector2(rect.position.x + inset, rect.end.y),
		Vector2(rect.position.x, rect.end.y - inset),
		Vector2(rect.position.x, rect.position.y + inset),
	])


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


static func _sanatorium_long_ward_door_profile() -> Dictionary:
	return {
		"theme_mark": &"medical_cross",
		"mark_color": Color(0.32, 0.78, 0.7, 0.52),
		"art_texture_path": SANATORIUM_DOOR_MODULES,
		"west_source_region": Rect2(16, 16, 78, 154),
		"east_source_region": Rect2(112, 16, 78, 154),
		"visual_scale": 1.5,
		"side_visual_recess": 0.0,
		"travel_distance": 58.0,
	}


static func _sanatorium_l_elite_door_profile() -> Dictionary:
	return {
		"theme_mark": &"medical_cross",
		"mark_color": Color(0.32, 0.78, 0.7, 0.52),
		"art_texture_path": SANATORIUM_DOOR_MODULES,
		"west_source_region": Rect2(16, 16, 78, 154),
		"south_source_region": Rect2(224, 112, 154, 78),
		"west_visual_scale": 0.95,
		"south_visual_scale": 0.82,
		"south_split_axis": &"vertical",
		"side_visual_recess": 0.0,
		"west_travel_distance": 38.0,
		"south_travel_distance": 31.0,
		"preserve_authored_orientation": true,
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
