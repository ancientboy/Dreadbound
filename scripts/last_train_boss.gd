class_name LastTrainBoss
extends SanatoriumBoss

const LAST_TRAIN_CONDUCTOR_SPRITESHEET: Texture2D = preload("res://assets/art/characters/metro/last_train_conductor_spritesheet.png")

enum TrainPhase { ARRIVAL, INSPECTION, DEPARTURE }

var train_phase := TrainPhase.ARRIVAL
var encounter_provider: Callable


func _ready() -> void:
	boss_label = "末班列车 · 车长回声"
	max_health = 360
	super._ready()
	add_to_group("metro_enemies")


func _physics_process(delta: float) -> void:
	var context: Dictionary = encounter_provider.call() if encounter_provider.is_valid() else {}
	var anchors := int(context.get("anchors", 2))
	var tide := int(context.get("tide", 0))
	var window := float(context.get("window", 999.0))
	if health <= max_health / 3 or tide >= 2 or window <= 25.0:
		train_phase = TrainPhase.DEPARTURE
	elif health <= max_health * 2 / 3 or anchors <= 1:
		train_phase = TrainPhase.INSPECTION
	else:
		train_phase = TrainPhase.ARRIVAL
	phase_two = train_phase == TrainPhase.DEPARTURE
	super._physics_process(delta)


func _execute_attack() -> void:
	if not is_instance_valid(target):
		return
	var distance := global_position.distance_to(target.global_position)
	match train_phase:
		TrainPhase.ARRIVAL:
			_get_combat_fx().metro_enemy_skill("conductor_stamp", global_position, _facing, 150.0, 0.42)
			if distance <= 135.0:
				target.take_damage(int(round(22 * history_damage_multiplier)), global_position)
		TrainPhase.INSPECTION:
			_get_combat_fx().metro_enemy_skill("anchor_discharge", target.global_position, _facing, 220.0, 0.48)
			if distance <= 280.0:
				target.take_damage(int(round(20 * history_damage_multiplier)), global_position)
		TrainPhase.DEPARTURE:
			var train_direction := global_position.direction_to(target.global_position)
			_get_combat_fx().metro_enemy_skill("conductor_train", global_position, train_direction, 260.0, 0.58)
			if distance <= 185.0:
				target.take_damage(int(round(30 * history_damage_multiplier)), global_position)
	_attack_index += 1
	_timer = 1.05 if train_phase == TrainPhase.DEPARTURE else 1.5


func _setup_body_sprite() -> void:
	if LAST_TRAIN_CONDUCTOR_SPRITESHEET == null or LAST_TRAIN_CONDUCTOR_SPRITESHEET.get_size() != Vector2(576, 384):
		push_warning("Last Train Conductor sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = LAST_TRAIN_CONDUCTOR_SPRITESHEET
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	_body_sprite.position = Vector2(0, -44)
	_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite(0.0)


func _draw() -> void:
	super._draw()
	var phase_name: String = ["进站", "验票", "离站"][train_phase]
	draw_string(UI_FONT, Vector2(-60, 96), "阶段：%s" % phase_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 15, Color("e8b45f"))
