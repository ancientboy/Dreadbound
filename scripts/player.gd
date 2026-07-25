class_name Player
extends CharacterBody2D

@export var movement_speed := 210.0

var facing := Vector2.DOWN


func _ready() -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls and mobile_controls.movement_vector != Vector2.ZERO:
		input_direction = mobile_controls.movement_vector
	velocity = input_direction * movement_speed
	if input_direction != Vector2.ZERO:
		facing = input_direction.normalized()
	move_and_slide()
	queue_redraw()


func _draw() -> void:
	# Layered graybox silhouette: backpack, coat, head, flashlight and anomaly mark.
	draw_rect(Rect2(-15, -8, 30, 30), Color("35443d"), true)
	draw_rect(Rect2(-18, -5, 7, 25), Color("514a38"), true)
	draw_rect(Rect2(-13, -19, 26, 34), Color("56665b"), true)
	draw_circle(Vector2(0, -24), 9.0, Color("292d2b"))
	draw_line(facing * 8.0, facing * 29.0, Color("d5d0a3"), 5.0)
	draw_circle(Vector2(-12, 3), 3.5, Color("36dbc0"))
	draw_circle(Vector2(-12, 3), 7.0, Color(0.21, 0.86, 0.75, 0.13))
