class_name Drowned
extends Patient

var water_depth_provider: Callable
var water_depth := 0


func _ready() -> void:
	enemy_label = "溺行者"
	movement_speed = 88.0
	max_health = 62
	super._ready()
	add_to_group("metro_enemies")


func _physics_process(delta: float) -> void:
	water_depth = int(water_depth_provider.call(global_position)) if water_depth_provider.is_valid() else 0
	var dry_speed := 88.0
	movement_speed = dry_speed * (1.42 if water_depth > 0 else 1.0)
	super._physics_process(delta)


func _draw() -> void:
	super._draw()
	if water_depth > 0:
		draw_arc(Vector2(0, 18), 24.0, 0.0, TAU, 24, Color(0.25, 0.65, 0.82, 0.72), 3.0)
		draw_arc(Vector2(0, 18), 34.0, 0.25, PI - 0.25, 18, Color(0.2, 0.5, 0.7, 0.48), 2.0)

