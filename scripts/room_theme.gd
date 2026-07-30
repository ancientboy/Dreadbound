class_name RoomTheme
extends Resource

@export var theme_id: StringName
@export var display_name := ""
@export var floor_atlas: Texture2D
@export var wall_atlas: Texture2D
@export var prop_atlas: Texture2D
@export var floor_atlas_size := Vector2i(8, 6)
@export var wall_atlas_size := Vector2i(8, 1)
@export var prop_region_size := Vector2i(128, 128)
@export var ambient_tint := Color(0.68, 0.84, 0.9, 1.0)
@export var guide_color := Color(0.15, 0.78, 0.74, 0.34)
@export var warning_color := Color(0.98, 0.28, 0.18, 0.82)
@export var door_frame_color := Color(0.16, 0.28, 0.34, 1.0)
@export var door_leaf_color := Color(0.08, 0.2, 0.25, 1.0)
@export var door_locked_color := Color(1.0, 0.12, 0.08, 0.92)
@export var door_open_color := Color(0.18, 1.0, 0.72, 0.92)
