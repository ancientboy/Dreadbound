class_name MapRoomObstacle
extends StaticBody2D

enum PropKind {
	HOSPITAL_BED,
	GURNEY,
	SUPPLY_CRATE,
	BARRICADE,
	MEDICAL_LOCKER,
	WALL_CONSOLE,
	MEDICINE_TROLLEY,
	IV_STAND,
}

@export var prop_kind := PropKind.SUPPLY_CRATE
@export var prop_texture: Texture2D
@export var footprint_size := Vector2(120.0, 64.0)
@export var footprint_offset := Vector2.ZERO
@export var visual_scale := 1.0
@export var placement_role := "combat"
@export var wall_side := ""
@export var blocks_projectiles := true


func _ready() -> void:
	add_to_group(&"map_room_obstacles")
	var sprite := Sprite2D.new()
	sprite.name = "PropSprite"
	sprite.texture = prop_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * visual_scale
	if prop_texture != null:
		sprite.position.y = -float(prop_texture.get_height()) * visual_scale * 0.5
	add_child(sprite)

	var collision := CollisionPolygon2D.new()
	collision.name = "FootprintCollision"
	collision.polygon = _footprint_polygon()
	add_child(collision)


func _footprint_polygon() -> PackedVector2Array:
	var half_width := footprint_size.x * 0.5
	var depth := footprint_size.y
	var skew := minf(18.0, footprint_size.x * 0.1)
	return PackedVector2Array([
		footprint_offset + Vector2(-half_width + skew, -depth),
		footprint_offset + Vector2(half_width, -depth),
		footprint_offset + Vector2(half_width - skew, 0.0),
		footprint_offset + Vector2(-half_width, 0.0),
	])
