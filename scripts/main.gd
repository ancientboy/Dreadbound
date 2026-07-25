extends Node2D

const MAP_SIZE := Vector2(1600.0, 960.0)
const TERMINAL_POSITION := Vector2(1248.0, 416.0)
const INTERACTION_DISTANCE := 78.0

@onready var player: CharacterBody2D = $Player
@onready var objective: Label = $Interface/TopBar/Objective
@onready var prompt_panel: ColorRect = $Interface/PromptPanel

var record_collected := false


func _ready() -> void:
	_create_collision_walls()
	queue_redraw()


func _process(_delta: float) -> void:
	var can_interact := not record_collected and player.global_position.distance_to(TERMINAL_POSITION) <= INTERACTION_DISTANCE
	prompt_panel.visible = can_interact
	if can_interact and Input.is_action_just_pressed("interact"):
		record_collected = true
		prompt_panel.visible = false
		objective.text = "RECORD RETRIEVED (1/3) // INTERACTION TEST COMPLETE"
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("111716"))
	_draw_grid()
	_draw_rooms()
	_draw_terminal()


func _draw_grid() -> void:
	for x in range(0, int(MAP_SIZE.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), Color(0.13, 0.17, 0.16, 0.32), 1.0)
	for y in range(0, int(MAP_SIZE.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), Color(0.13, 0.17, 0.16, 0.32), 1.0)


func _draw_rooms() -> void:
	var wall_color := Color("39423d")
	var edge_color := Color("59635c")
	for wall in _wall_rectangles():
		draw_rect(wall, wall_color)
		draw_rect(wall, edge_color, false, 2.0)

	# Temporary landmarks make navigation and camera motion easy to evaluate.
	draw_rect(Rect2(128, 256, 192, 224), Color("202a26"))
	draw_string(ThemeDB.fallback_font, Vector2(160, 300), "ENTRY WARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("66756c"))
	draw_rect(Rect2(1056, 288, 352, 256), Color("182521"))
	draw_string(ThemeDB.fallback_font, Vector2(1104, 332), "RECORDS STORAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("527269"))


func _draw_terminal() -> void:
	var glow := Color("37d6bd") if not record_collected else Color("47645e")
	draw_circle(TERMINAL_POSITION, 42.0, Color(glow, 0.09))
	draw_rect(Rect2(TERMINAL_POSITION - Vector2(18, 26), Vector2(36, 52)), Color("172b28"))
	draw_rect(Rect2(TERMINAL_POSITION - Vector2(13, 20), Vector2(26, 18)), glow)
	draw_string(ThemeDB.fallback_font, TERMINAL_POSITION + Vector2(-62, 54), "RECORD 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, glow)


func _create_collision_walls() -> void:
	for wall_rect in _wall_rectangles():
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = wall_rect.size
		collision.shape = shape
		body.position = wall_rect.get_center()
		body.add_child(collision)
		add_child(body)


func _wall_rectangles() -> Array[Rect2]:
	return [
		Rect2(0, 0, MAP_SIZE.x, 32), Rect2(0, MAP_SIZE.y - 32, MAP_SIZE.x, 32),
		Rect2(0, 0, 32, MAP_SIZE.y), Rect2(MAP_SIZE.x - 32, 0, 32, MAP_SIZE.y),
		Rect2(416, 32, 32, 256), Rect2(416, 416, 32, 256), Rect2(416, 800, 32, 128),
		Rect2(800, 160, 32, 288), Rect2(800, 576, 32, 256),
		Rect2(1056, 256, 384, 32), Rect2(1056, 544, 384, 32),
		Rect2(1056, 256, 32, 96), Rect2(1056, 480, 32, 96),
		Rect2(1408, 256, 32, 320), Rect2(448, 672, 224, 32), Rect2(768, 672, 32, 32),
	]
