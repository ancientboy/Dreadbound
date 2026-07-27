class_name Player
extends CharacterBody2D

const DRIFTER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/drifter/drifter_spritesheet.png")
const HIGHRES_DRIFTER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/drifter/drifter_highres_spritesheet.png")
const STEADFAST_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/steadfast_spritesheet.png")
const ARMORER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/armorer_spritesheet.png")
const RESONANT_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/resonant_spritesheet.png")
const COMBAT_STYLE_SPRITESHEETS := {
	"barrier_counter": preload("res://assets/art/characters/professions/styles/barrier_counter_spritesheet.png"),
	"last_stand": preload("res://assets/art/characters/professions/styles/last_stand_spritesheet.png"),
	"sacrifice_medic": preload("res://assets/art/characters/professions/styles/sacrifice_medic_walk_spritesheet.png"),
	"choke_control": preload("res://assets/art/characters/professions/styles/choke_control_spritesheet.png"),
	"weakpoint_sniper": preload("res://assets/art/characters/professions/styles/weakpoint_sniper_spritesheet.png"),
	"heavy_suppression": preload("res://assets/art/characters/professions/styles/heavy_suppression_spritesheet.png"),
	"demolition_traps": preload("res://assets/art/characters/professions/styles/demolition_traps_spritesheet.png"),
	"relic_engineer": preload("res://assets/art/characters/professions/styles/relic_engineer_spritesheet.png"),
	"psychic_sense": preload("res://assets/art/characters/professions/styles/psychic_sense_spritesheet.png"),
	"anomaly_ingestion": preload("res://assets/art/characters/professions/styles/anomaly_ingestion_spritesheet.png"),
	"echo_summoner": preload("res://assets/art/characters/professions/styles/echo_summoner_spritesheet.png"),
	"aberrant_form": preload("res://assets/art/characters/professions/styles/aberrant_form_spritesheet.png"),
}
const BASIC_WEAPONS: Texture2D = preload("res://assets/art/weapons/basic_weapons.png")
const ADVANCED_WEAPONS: Texture2D = preload("res://assets/art/weapons/advanced_weapons.png")
const DIRECTOR_REAPER_GROWTH: Texture2D = preload("res://assets/art/weapons/director_reaper_growth.png")
const CONDUCTOR_RAILGUN_GROWTH: Texture2D = preload("res://assets/art/weapons/conductor_railgun_growth.png")
const BOSS_EVOLUTION_WEAPONS: Texture2D = preload("res://assets/art/weapons/boss_evolution_weapons.png")
const PLAYER_STATES_LIGHTING: Texture2D = preload("res://assets/art/vfx/player_states_lighting.png")
const METRO_FLOOD_LAYERS: Texture2D = preload("res://assets/art/vfx/metro_flood_layers.png")

signal health_changed(current: int, maximum: int)
signal died
signal inventory_changed(bandages: int, echo_shards: int)
signal weapon_changed(weapon_name: String, ammo: int)
signal utility_changed(sedatives: int, duration: float)
signal selected_item_changed(item_name: String, count: int)
signal noise_generated(amount: int)
signal equipment_trait_used(trait_id: String)
signal skill_changed(skill_name: String, remaining: float, duration: float)
signal footstep_requested(surface_hint: String, intensity: float)

enum Weapon { MELEE, RANGED, SHOTGUN }
enum Consumable { BANDAGE, SEDATIVE, STIMULANT }

@export var movement_speed := 210.0
@export var use_runtime_progress := true
@export_group("Demo Loadout")
@export var demo_weapon_slots: Array[String] = ["service_crowbar", "balanced_pistol", "breach_shotgun"]
@export var demo_offhand_item := "riot_shield"
@export var demo_charm_item := "medical_tag"
@export_group("")
@export_group("Character Feel")
@export var acceleration := 1850.0
@export var deceleration := 2450.0
@export var movement_smoothing := 18.0
@export var turn_acceleration_multiplier := 1.35
@export var stop_speed_threshold := 5.0
@export_group("")
@export var max_health := 100
@export var attack_damage := 35
@export var attack_range := 76.0
@export var attack_cooldown := 0.48
@export var max_bandages := 3
@export var bandage_heal := 35
@export var ranged_damage := 25
@export var ranged_range := 430.0
@export var ranged_cooldown := 0.34
@export var max_ammo := 24
@export var shotgun_damage := 28
@export var shotgun_range := 235.0
@export var shotgun_cooldown := 0.95
@export var max_shells := 12

var health := 100
var facing := Vector2.DOWN
var _attack_timer := 0.0
var _skill_cooldown := 0.0
var _skill_duration := 0.0
var _attack_flash := 0.0
var _invulnerability_timer := 0.0
var _hurt_flash := 0.0
var _dead := false
var bandages := 0
var echo_shards := 0
var _heal_flash := 0.0
var current_weapon := Weapon.MELEE
var ammo := 6
var shells := 0
var sedatives := 0
var sedative_duration := 0.0
var stimulants := 0
var stimulant_duration := 0.0
var environment_speed_multiplier := 1.0
var environment_water_depth := 0
var selected_item := Consumable.BANDAGE
var _shot_end := Vector2.ZERO
var _movement_echo_timer := 0.0
var pathway_effects: PathwayEffects
var combat_fx: CombatFX
var relic_profile := {}
var equipped_weapon_item := ""
var _relic_hit_counter := 0
var _walk_animation_time := 0.0
var _idle_animation_time := 0.0
var _step_phase := 0.0
var _was_moving := false
var _smoothed_move_direction := Vector2.ZERO
var _body_sprite: Sprite2D
var _body_sprite_rest_position := Vector2.ZERO
var _body_sprite_rest_scale := Vector2.ONE
var _body_frame_ground_y := PackedFloat32Array()
var _locked_ranged_target: Node2D
var _skill_pose_timer := 0.0


func _ready() -> void:
	_setup_body_sprite()
	_apply_permanent_upgrades()
	pathway_effects = PathwayEffects.new()
	pathway_effects.setup(self, get_node_or_null("/root/GameState") as GameProgress)
	add_child(pathway_effects)
	combat_fx = CombatFX.new()
	add_child(combat_fx)
	health = max_health
	health_changed.emit(health, max_health)
	inventory_changed.emit(bandages, echo_shards)
	weapon_changed.emit(get_weapon_name(), ammo)
	utility_changed.emit(sedatives, sedative_duration)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	queue_redraw()


func _apply_permanent_upgrades() -> void:
	# Presentation scenes use a fixed loadout with the same equipment rules as the
	# game. They must not inherit a player's save file or alter it.
	if not use_runtime_progress:
		_apply_demo_loadout()
		return
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return
	var loadout: Dictionary = state.get_selected_loadout()
	current_weapon = Weapon.MELEE # weapon enum now selects free slot 1 / 2 / 3.
	var stats: Dictionary = state.get_player_stats()
	max_health = int(stats.max_health)
	movement_speed = float(stats.movement_speed)
	attack_damage = int(stats.melee_damage)
	ranged_damage = int(stats.ranged_damage)
	shotgun_damage = int(stats.get("shotgun_damage", shotgun_damage))
	bandage_heal = int(stats.bandage_heal)
	attack_range = float(stats.get("attack_range", attack_range))
	ranged_range = float(stats.get("ranged_range", ranged_range))
	shotgun_range = float(stats.get("shotgun_range", shotgun_range))
	_sync_active_weapon_equipment()
	ammo = max_ammo # retained only for old HUD/save compatibility; weapons have no ammo inventory.
	bandages = clampi(int(loadout.bandages), 0, max_bandages)
	shells = max_shells # no shell pickups or reserve tracking.
	sedatives = clampi(int(loadout.get("sedatives", 0)), 0, 2)
	stimulants = clampi(int(loadout.get("stimulants", 0)), 0, 2)


func _apply_demo_loadout() -> void:
	current_weapon = Weapon.MELEE
	var demo_equipped := {
		"weapon_1": demo_weapon_slots[0] if demo_weapon_slots.size() > 0 else "",
		"weapon_2": demo_weapon_slots[1] if demo_weapon_slots.size() > 1 else "",
		"weapon_3": demo_weapon_slots[2] if demo_weapon_slots.size() > 2 else "",
		"offhand": demo_offhand_item,
		"charm": demo_charm_item,
	}
	var bonuses := EquipmentDatabase.get_bonuses(demo_equipped)
	max_health += int(bonuses.max_health)
	movement_speed += float(bonuses.movement_speed)
	attack_damage += int(bonuses.melee_damage)
	ranged_damage += int(bonuses.ranged_damage)
	shotgun_damage += int(bonuses.shotgun_damage)
	bandage_heal += int(bonuses.bandage_heal)
	equipped_weapon_item = str(demo_equipped.weapon_1)
	relic_profile = {}
	ammo = max_ammo # Compatibility-only display value; the demo has no ammo reserve.
	shells = max_shells


func _weapon_attack_type() -> String:
	var item := EquipmentDatabase.get_item(equipped_weapon_item)
	return str(item.get("weapon_type", "melee"))


func _apply_profession_default_weapon() -> void:
	var style := _profession_style_definition()
	var weapon_type := str(style.get("weapon_type", ""))
	current_weapon = weapon_for_attack_type(weapon_type, current_weapon)


static func weapon_for_attack_type(attack_type: String, fallback := Weapon.MELEE) -> Weapon:
	match attack_type:
		"ranged":
			return Weapon.RANGED
		"shotgun":
			return Weapon.SHOTGUN
		"melee":
			return Weapon.MELEE
	return fallback


func _sync_active_weapon_equipment() -> void:
	var state := get_node_or_null("/root/GameState") as GameProgress
	if state == null:
		equipped_weapon_item = ""
		relic_profile = {}
		return
	equipped_weapon_item = state.get_equipped_weapon_at_slot(int(current_weapon))
	relic_profile = EquipmentDatabase.relic_growth_profile(
		equipped_weapon_item,
		state.get_relic_growth(equipped_weapon_item),
	)


func _physics_process(delta: float) -> void:
	var had_visual_effect := _attack_flash > 0.0 or _hurt_flash > 0.0 or _heal_flash > 0.0
	var previous_facing := facing
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_skill_cooldown = maxf(_skill_cooldown - delta, 0.0)
	_skill_pose_timer = maxf(_skill_pose_timer - delta, 0.0)
	if not _active_combat_style().is_empty():
		skill_changed.emit(get_skill_name(), _skill_cooldown, _skill_duration)
	_attack_flash = maxf(_attack_flash - delta, 0.0)
	_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_heal_flash = maxf(_heal_flash - delta, 0.0)
	_movement_echo_timer = maxf(_movement_echo_timer - delta, 0.0)
	sedative_duration = maxf(sedative_duration - delta, 0.0)
	stimulant_duration = maxf(stimulant_duration - delta, 0.0)
	pathway_effects.tick(delta)
	if _dead:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wants_to_attack := Input.is_action_just_pressed("attack")
	var wants_to_use_item := Input.is_action_just_pressed("use_item")
	var wants_to_switch := Input.is_action_just_pressed("switch_weapon")
	var wants_to_switch_item := Input.is_action_just_pressed("switch_item")
	var wants_to_use_trait := Input.is_action_just_pressed("use_trait")
	var wants_to_use_skill := Input.is_action_just_pressed("use_skill")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls") as MobileControls
	if mobile_controls:
		if mobile_controls.movement_vector != Vector2.ZERO:
			input_direction = mobile_controls.movement_vector
		wants_to_attack = mobile_controls.consume_attack() or wants_to_attack
		wants_to_use_item = mobile_controls.consume_item() or wants_to_use_item
		wants_to_switch = mobile_controls.consume_switch_weapon() or wants_to_switch
		wants_to_switch_item = mobile_controls.consume_switch_item() or wants_to_switch_item
		wants_to_use_trait = mobile_controls.consume_trait() or wants_to_use_trait
		wants_to_use_skill = mobile_controls.consume_skill() or wants_to_use_skill

	var target_speed := movement_speed * environment_speed_multiplier * (1.22 if stimulant_duration > 0.0 else 1.0)
	_update_movement_velocity(input_direction, target_speed, delta)
	if input_direction != Vector2.ZERO:
		facing = input_direction.normalized()
		var speed_ratio := clampf(velocity.length() / maxf(target_speed, 1.0), 0.0, 1.0)
		_walk_animation_time += delta * lerpf(0.78, 1.12, speed_ratio)
		_emit_pathway_movement_echo()
	else:
		_idle_animation_time += delta
	_sync_footsteps(delta, target_speed)
	_sync_body_sprite()
	_update_body_feedback(delta, target_speed)
	_update_ranged_lock()
	if wants_to_attack:
		try_attack()
	if wants_to_use_item:
		use_selected_item()
	if wants_to_switch:
		switch_weapon()
	if wants_to_switch_item:
		switch_item()
	if wants_to_use_trait:
		use_equipment_trait()
	if wants_to_use_skill:
		use_active_skill()
	_collect_nearby_pickups()
	move_and_slide()
	if had_visual_effect or velocity.length() > 2.0 or not facing.is_equal_approx(previous_facing):
		queue_redraw()


func _update_movement_velocity(input_direction: Vector2, target_speed: float, delta: float) -> void:
	var desired_direction := input_direction.limit_length(1.0)
	if desired_direction == Vector2.ZERO:
		_smoothed_move_direction = Vector2.ZERO
	else:
		var direction_weight := 1.0 - exp(-movement_smoothing * delta)
		if _smoothed_move_direction == Vector2.ZERO:
			_smoothed_move_direction = desired_direction
		elif _smoothed_move_direction.dot(desired_direction) < 0.0:
			# A deliberate reversal should change intent immediately; velocity
			# still decelerates through the turn boost instead of snapping.
			_smoothed_move_direction = desired_direction
		else:
			_smoothed_move_direction = _smoothed_move_direction.lerp(desired_direction, direction_weight).normalized()
	var target_velocity := _smoothed_move_direction * target_speed
	velocity = smooth_movement_velocity(
		velocity,
		target_velocity,
		acceleration,
		deceleration,
		turn_acceleration_multiplier,
		delta,
	)
	if desired_direction == Vector2.ZERO and velocity.length() <= stop_speed_threshold:
		velocity = Vector2.ZERO


static func smooth_movement_velocity(
	current_velocity: Vector2,
	target_velocity: Vector2,
	acceleration_rate: float,
	deceleration_rate: float,
	turn_multiplier: float,
	delta: float,
) -> Vector2:
	var response_rate := deceleration_rate if target_velocity == Vector2.ZERO else acceleration_rate
	if current_velocity != Vector2.ZERO and target_velocity != Vector2.ZERO and current_velocity.dot(target_velocity) < 0.0:
		response_rate *= turn_multiplier
	return current_velocity.move_toward(target_velocity, response_rate * delta)


func _sync_footsteps(delta: float, target_speed: float) -> void:
	var speed_ratio := clampf(velocity.length() / maxf(target_speed, 1.0), 0.0, 1.0)
	var is_moving := speed_ratio > 0.16
	if is_moving and not _was_moving:
		_walk_animation_time = 0.0
		_step_phase = 0.52
	if is_moving:
		_step_phase += delta * lerpf(1.55, 2.7, speed_ratio)
		if _step_phase >= 1.0:
			_step_phase = fmod(_step_phase, 1.0)
			footstep_requested.emit(_footstep_surface_hint(), lerpf(0.45, 1.0, speed_ratio))
	else:
		_step_phase = 0.0
	_was_moving = is_moving


func _footstep_surface_hint() -> String:
	if environment_water_depth >= 2:
		return "deep_water"
	if environment_water_depth == 1:
		return "shallow_water"
	return "default"


func _setup_body_sprite() -> void:
	var body_texture := _profession_body_texture()
	if body_texture == null or not _is_valid_body_spritesheet(body_texture):
		push_warning("Drifter sprite sheet unavailable or invalid; using visible fallback silhouette.")
		return
	_body_sprite = Sprite2D.new()
	_body_sprite.name = "BodySprite"
	_body_sprite.texture = body_texture
	_body_sprite.hframes = 6
	_body_sprite.vframes = 4
	if body_texture == HIGHRES_DRIFTER_SPRITESHEET:
		# The high-detail sheet is intentionally rendered at half scale.  This keeps
		# the original collision footprint while making the coat, materials and
		# lighting readable in the actual top-down game camera.
		_body_sprite.position = Vector2(0, -57)
		_body_sprite.scale = Vector2(0.55, 0.55)
		_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		_body_sprite.position = Vector2(0, -26)
		_body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body_sprite_rest_position = _body_sprite.position
	_body_sprite_rest_scale = _body_sprite.scale
	_cache_body_frame_grounding()
	_body_sprite.z_index = 1
	add_child(_body_sprite)
	_sync_body_sprite()


func _is_valid_body_spritesheet(texture: Texture2D) -> bool:
	return texture.get_size() == Vector2(288, 256) or texture.get_size() == Vector2(1536, 1024)


func _cache_body_frame_grounding() -> void:
	_body_frame_ground_y.clear()
	var image := _body_sprite.texture.get_image()
	if image == null or image.is_empty():
		return
	var frame_width := image.get_width() / _body_sprite.hframes
	var frame_height := image.get_height() / _body_sprite.vframes
	for row in range(_body_sprite.vframes):
		for column in range(_body_sprite.hframes):
			var alpha_bottom := 0
			for pixel_y in range(frame_height - 1, -1, -1):
				var found_opaque_pixel := false
				for pixel_x in range(frame_width):
					if image.get_pixel(column * frame_width + pixel_x, row * frame_height + pixel_y).a > 0.08:
						found_opaque_pixel = true
						break
				if found_opaque_pixel:
					alpha_bottom = pixel_y + 1
					break
			_body_frame_ground_y.append(
				grounded_sprite_y(alpha_bottom, frame_height, _body_sprite.scale.y, 8.0)
			)


static func grounded_sprite_y(alpha_bottom: int, frame_height: int, scale_y: float, ground_y: float) -> float:
	if alpha_bottom <= 0 or frame_height <= 0:
		return ground_y
	return ground_y - (float(alpha_bottom) - float(frame_height) * 0.5) * scale_y


func _current_body_rest_position() -> Vector2:
	var grounded_position := _body_sprite_rest_position
	var frame_index := _body_sprite.frame_coords.y * _body_sprite.hframes + _body_sprite.frame_coords.x
	if frame_index >= 0 and frame_index < _body_frame_ground_y.size():
		grounded_position.y = _body_frame_ground_y[frame_index]
	return grounded_position


func _sync_body_sprite() -> void:
	if not is_instance_valid(_body_sprite) or _body_sprite.texture == null:
		return
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2 if facing.x > 0.0 else 1
	elif facing.y < 0.0:
		row = 3
	var frame := int(_step_phase * 6.0) % 6 if velocity.length() > 2.0 else 0
	_body_sprite.frame_coords = Vector2i(frame, row)
	_body_sprite.modulate = Color("ffb5ad") if _hurt_flash > 0.0 else (Color("c8ffdc") if _heal_flash > 0.0 else Color.WHITE)


func _update_body_feedback(delta: float, target_speed: float) -> void:
	if not is_instance_valid(_body_sprite):
		return
	var speed_ratio := clampf(velocity.length() / maxf(target_speed, 1.0), 0.0, 1.0)
	var moving := speed_ratio > 0.04
	var position_target := _current_body_rest_position()
	var scale_target := _body_sprite_rest_scale
	var rotation_target := 0.0
	if moving:
		var stride := sin(_step_phase * TAU)
		var foot_contact := pow(absf(cos(_step_phase * TAU)), 4.0)
		# Keep the feet on the ground. Weight shifts sideways and compresses on
		# contact instead of lifting the entire character above its shadow.
		position_target.x += stride * 1.35 * speed_ratio
		position_target.y += foot_contact * 0.75 * speed_ratio
		scale_target *= Vector2(
			1.0 + foot_contact * 0.012 * speed_ratio,
			1.0 - foot_contact * 0.014 * speed_ratio
		)
		rotation_target = stride * 0.012 * speed_ratio
	else:
		var breath := sin(_idle_animation_time * 2.2)
		position_target.y += maxf(breath, 0.0) * 0.25
		scale_target *= Vector2(1.0 - breath * 0.004, 1.0 + breath * 0.007)
	if _skill_pose_timer > 0.0:
		var pose_strength := clampf(_skill_pose_timer / 0.24, 0.0, 1.0)
		position_target -= facing * 2.8 * pose_strength
		scale_target *= Vector2(1.0 + 0.025 * pose_strength, 1.0 - 0.018 * pose_strength)
		rotation_target += facing.x * 0.035 * pose_strength
	var feedback_weight := 1.0 - exp(-14.0 * delta)
	_body_sprite.position = _body_sprite.position.lerp(position_target, feedback_weight)
	_body_sprite.scale = _body_sprite.scale.lerp(scale_target, feedback_weight)
	_body_sprite.rotation = lerp_angle(_body_sprite.rotation, rotation_target, feedback_weight)


func try_attack() -> bool:
	if _dead or _attack_timer > 0.0:
		return false
	if equipped_weapon_item.is_empty():
		return false
	match _weapon_attack_type():
		"ranged":
			return _try_ranged_attack()
		"shotgun":
			return _try_shotgun_attack()
		"arcane":
			return _try_ranged_attack()
		_:
			pass
	var state := get_node_or_null("/root/GameState")
	var pathway_multiplier := pathway_effects.consume_attack_multiplier()
	_play_attack_style_vfx("melee")
	var insulated: bool = state != null and state.has_equipment_trait("signal_anchor_damage")
	_attack_timer = attack_cooldown + (0.12 if insulated else 0.0)
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_melee", 0.035)
	noise_generated.emit(1)
	_attack_flash = 0.14
	if not _has_profession_combat_presentation():
		combat_fx.melee_swing_styled(global_position, facing, attack_range, _pathway_visual().accent)
	var hit_count := 0
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() <= attack_range and facing.dot(offset.normalized()) >= 0.25:
			var damage := int(attack_damage * pathway_multiplier * (1.35 if insulated and (target is Conductor or target is LastTrainBoss or target is SignalAnchor) else 1.0))
			target.take_damage(damage, global_position)
			hit_count += 1
			_apply_relic_hit_effect(target, "melee", offset)
			combat_fx.impact(target.global_position, offset, true)
	_record_equipment_mastery("melee_hits", hit_count)
	queue_redraw()
	return true


func use_equipment_trait() -> bool:
	var state := get_node_or_null("/root/GameState")
	if state == null or not state.has_equipment_trait("noise_lure"):
		return false
	equipment_trait_used.emit("noise_lure")
	return true


func _try_ranged_attack() -> bool:
	_attack_timer = ranged_cooldown
	_attack_flash = 0.11
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_pistol", 0.025)
	noise_generated.emit(3)
	_update_ranged_lock()
	var candidates: Array[Dictionary] = []
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var offset: Vector2 = target.global_position - global_position
		var distance := offset.length()
		var alignment := facing.dot(offset.normalized())
		if distance <= ranged_range and alignment >= 0.35:
			var priority := 0.0 if target == _locked_ranged_target else 1.0
			candidates.append({"target": target, "distance": distance, "offset": offset, "priority": priority, "aim_score": distance + (1.0 - alignment) * 120.0})
	_shot_end = facing * ranged_range
	candidates.sort_custom(func(a: Dictionary, b: Dictionary):
		if float(a.priority) != float(b.priority):
			return float(a.priority) < float(b.priority)
		return float(a.aim_score) < float(b.aim_score)
	)
	if not candidates.is_empty():
		var multiplier := pathway_effects.consume_attack_multiplier()
		var target_limit := maxi(1, int(relic_profile.get("pierce_targets", 1)) if equipped_weapon_item == "conductor_railgun" else 1)
		for index in range(mini(target_limit, candidates.size())):
			var hit: Dictionary = candidates[index]
			var hit_target: Node2D = hit.target
			var hit_offset: Vector2 = hit.offset
			_shot_end = hit_offset
			hit_target.take_damage(int(ranged_damage * multiplier), global_position)
			_apply_relic_hit_effect(hit_target, "ranged", hit_offset)
			combat_fx.impact(hit_target.global_position, hit_offset, index > 0)
		_record_equipment_mastery("ranged_hits", mini(target_limit, candidates.size()))
		if mini(target_limit, candidates.size()) > 1:
			_record_equipment_mastery("multi_hits", 1)
	else:
		pathway_effects.consume_attack_multiplier()
	var visual := _pathway_visual()
	_play_attack_style_vfx("ranged", _shot_end.length())
	if not _has_profession_combat_presentation():
		combat_fx.pistol_shot_styled(global_position + facing * 18.0, global_position + _shot_end, visual.tracer, visual.muzzle)
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()
	return true


func _try_shotgun_attack() -> bool:
	_attack_timer = shotgun_cooldown
	_attack_flash = 0.16
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_shotgun", 0.02)
	noise_generated.emit(4)
	var visual := _pathway_visual()
	_play_attack_style_vfx("shotgun", shotgun_range)
	if not _has_profession_combat_presentation():
		combat_fx.shotgun_blast_styled(global_position + facing * 18.0, facing, shotgun_range, visual.tracer, visual.muzzle)
	var pathway_multiplier := pathway_effects.consume_attack_multiplier()
	var hit_count := 0
	for target in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() <= shotgun_range and facing.dot(offset.normalized()) >= 0.72:
			var falloff := clampf(1.25 - offset.length() / shotgun_range * 0.55, 0.7, 1.0)
			target.take_damage(int(shotgun_damage * falloff * pathway_multiplier), global_position)
			hit_count += 1
			_apply_relic_hit_effect(target, "shotgun", offset)
			combat_fx.impact(target.global_position, offset, true)
	_record_equipment_mastery("multi_hits" if hit_count > 1 else "ranged_hits", maxi(hit_count, 0))
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()
	return true


func _record_equipment_mastery(use_type: String, amount: int) -> void:
	var state := get_node_or_null("/root/GameState") as GameProgress
	if state == null or equipped_weapon_item.is_empty() or amount <= 0:
		return
	state.record_equipment_use(equipped_weapon_item, use_type, amount)
	if health <= int(max_health * 0.35):
		state.record_equipment_use(equipped_weapon_item, "low_health_hits", amount)


func take_damage(amount: int, source_position: Vector2) -> bool:
	if _dead or _invulnerability_timer > 0.0:
		return false
	amount = maxi(1, int(amount * pathway_effects.incoming_damage_multiplier()))
	health = maxi(health - amount, 0)
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_hit", 0.04)
	_invulnerability_timer = 0.65
	_hurt_flash = 0.18
	var knockback := source_position.direction_to(global_position)
	global_position += knockback * 12.0
	health_changed.emit(health, max_health)
	if _active_combat_style() == "last_stand" and health > 0 and health <= int(max_health * 0.3):
		combat_fx.profession_skill("last_stand", global_position, facing, 104.0, 0.48)
	if health == 0:
		_dead = true
		velocity = Vector2.ZERO
		(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_death")
		died.emit()
	queue_redraw()
	return true


func add_bandages(amount: int) -> bool:
	if bandages >= max_bandages:
		return false
	bandages = mini(bandages + amount, max_bandages)
	inventory_changed.emit(bandages, echo_shards)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	return true


func add_echo_shards(amount: int) -> void:
	echo_shards += amount
	inventory_changed.emit(bandages, echo_shards)


func add_ammo(amount: int) -> bool:
	if ammo >= max_ammo:
		return false
	ammo = mini(ammo + amount, max_ammo)
	weapon_changed.emit(get_weapon_name(), ammo)
	return true


func switch_weapon() -> void:
	current_weapon = (int(current_weapon) + 1) % 3 as Weapon
	_sync_active_weapon_equipment()
	pathway_effects.on_weapon_switched()
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_switch", 0.025)
	weapon_changed.emit(get_weapon_name(), ammo)
	queue_redraw()


func get_weapon_name() -> String:
	var relic_level := int(relic_profile.get("level", 0))
	if not equipped_weapon_item.is_empty():
		var equipped_name := str(EquipmentDatabase.get_item(equipped_weapon_item).get("name", ""))
		if not equipped_name.is_empty():
			return "%s · Lv.%d" % [equipped_name, relic_level] if EquipmentDatabase.get_item(equipped_weapon_item).has("series") else equipped_name
	match current_weapon:
		Weapon.RANGED: return "手枪"
		Weapon.SHOTGUN: return "霰弹枪"
	return "撬棍"


func _apply_relic_hit_effect(target: Node, attack_kind: String, hit_offset: Vector2) -> void:
	if relic_profile.is_empty():
		return
	var compatible := equipped_weapon_item == "director_reaper" and attack_kind == "melee"
	compatible = compatible or (equipped_weapon_item == "conductor_railgun" and attack_kind in ["ranged", "shotgun"])
	if not compatible or not is_instance_valid(target):
		return
	_relic_hit_counter += 1
	var knockback := float(relic_profile.get("knockback", 0.0))
	if knockback > 0.0 and target is Node2D:
		var resistance := 0.35 if target.is_in_group("bosses") else 1.0
		(target as Node2D).global_position += hit_offset.normalized() * knockback * resistance
	var status := str(relic_profile.get("status", ""))
	var every := int(relic_profile.get("status_every", 0))
	if status.is_empty() or every <= 0 or _relic_hit_counter % every != 0:
		return
	var duration := float(relic_profile.get("status_duration", 0.0))
	if target.is_in_group("bosses"):
		duration *= 0.45
	_apply_control_status(target, status, duration)


func _apply_control_status(target: Node, status: String, duration: float) -> void:
	if duration <= 0.0 or not is_instance_valid(target):
		return
	var token := "%s:%d:%d" % [status, Time.get_ticks_msec(), _relic_hit_counter]
	if not target.has_meta("dreadbound_original_physics_processing"):
		target.set_meta("dreadbound_original_physics_processing", target.is_physics_processing())
	target.set_meta("dreadbound_control_token", token)
	target.set_meta("dreadbound_control_status", status)
	target.set_physics_process(false)
	if target is Node2D:
		combat_fx.status_burst((target as Node2D).global_position, status)
	var target_id := target.get_instance_id()
	get_tree().create_timer(duration).timeout.connect(func():
		var controlled := instance_from_id(target_id)
		if controlled == null or str(controlled.get_meta("dreadbound_control_token", "")) != token:
			return
		var resume_physics := bool(controlled.get_meta("dreadbound_original_physics_processing", true))
		controlled.remove_meta("dreadbound_control_token")
		controlled.remove_meta("dreadbound_control_status")
		controlled.remove_meta("dreadbound_original_physics_processing")
		controlled.set_physics_process(resume_physics)
	)


func add_shells(amount: int) -> bool:
	if shells >= max_shells:
		return false
	shells = mini(shells + amount, max_shells)
	weapon_changed.emit(get_weapon_name(), ammo)
	return true


func add_sedatives(amount: int) -> bool:
	if sedatives >= 2:
		return false
	sedatives = mini(sedatives + amount, 2)
	utility_changed.emit(sedatives, sedative_duration)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	return true


func use_sedative() -> bool:
	if _dead or sedatives <= 0 or sedative_duration > 0.0:
		return false
	sedatives -= 1
	sedative_duration = 12.0
	utility_changed.emit(sedatives, sedative_duration)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_heal", 0.02)
	return true


func get_detection_multiplier() -> float:
	return 0.38 if sedative_duration > 0.0 else 1.0


func add_stimulants(amount: int) -> bool:
	if stimulants >= 2:
		return false
	stimulants = mini(stimulants + amount, 2)
	utility_changed.emit(sedatives, sedative_duration)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	return true


func use_stimulant() -> bool:
	if _dead or stimulants <= 0 or stimulant_duration > 0.0:
		return false
	stimulants -= 1
	stimulant_duration = 10.0
	utility_changed.emit(sedatives, sedative_duration)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_heal", 0.025)
	return true


func use_bandage() -> bool:
	if _dead or bandages <= 0 or health >= max_health:
		return false
	var health_before := health
	bandages -= 1
	health = mini(health + int(bandage_heal * pathway_effects.healing_multiplier()), max_health)
	pathway_effects.on_bandage_used(health_before, max_health)
	var style := _active_combat_style()
	if style in ["barrier_counter", "sacrifice_medic", "echo_summoner"]:
		combat_fx.profession_skill(style, global_position, facing, 104.0, 0.52)
	_heal_flash = 0.3
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("player_heal", 0.02)
	health_changed.emit(health, max_health)
	inventory_changed.emit(bandages, echo_shards)
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())
	queue_redraw()
	return true


func switch_item() -> void:
	selected_item = (int(selected_item) + 1) % 3 as Consumable
	selected_item_changed.emit(get_selected_item_name(), get_selected_item_count())


func use_selected_item() -> bool:
	match selected_item:
		Consumable.SEDATIVE:
			return use_sedative()
		Consumable.STIMULANT:
			return use_stimulant()
	return use_bandage()


func get_selected_item_name() -> String:
	match selected_item:
		Consumable.SEDATIVE:
			return "镇静剂"
		Consumable.STIMULANT:
			return "兴奋剂"
	return "绷带"


func get_selected_item_count() -> int:
	match selected_item:
		Consumable.SEDATIVE:
			return sedatives
		Consumable.STIMULANT:
			return stimulants
	return bandages


func _collect_nearby_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and global_position.distance_to(pickup.global_position) <= 32.0:
			pickup.collect(self)


func _pathway_visual() -> Dictionary:
	var state := get_node_or_null("/root/GameState")
	var pathway := str(state.selected_pathway) if state != null else ""
	match pathway:
		"steadfast":
			return {"id": pathway, "accent": Color("88bc82"), "tracer": Color("b4d6a7"), "muzzle": Color("d9e7ad")}
		"armorer":
			return {"id": pathway, "accent": Color("f0a44d"), "tracer": Color("ffbd61"), "muzzle": Color("fff0b5")}
		"resonant":
			return {"id": pathway, "accent": Color("b47cff"), "tracer": Color("9ee8ff"), "muzzle": Color("ddbcff")}
	return {"id": "", "accent": Color("36dbc0"), "tracer": Color("6fe8c8"), "muzzle": Color("f5e6b2")}


func _profession_body_texture() -> Texture2D:
	var state := get_node_or_null("/root/GameState")
	var style := str(state.active_combat_style) if state != null else ""
	var style_texture: Texture2D = COMBAT_STYLE_SPRITESHEETS.get(style)
	if style_texture != null:
		return style_texture
	var pathway := str(state.selected_pathway) if state != null else ""
	match pathway:
		"steadfast":
			return STEADFAST_SPRITESHEET
		"armorer":
			return ARMORER_SPRITESHEET
		"resonant":
			return RESONANT_SPRITESHEET
	return DRIFTER_SPRITESHEET


func _active_combat_style() -> String:
	var state := get_node_or_null("/root/GameState")
	return str(state.active_combat_style) if state != null else ""


func get_skill_name() -> String:
	var state := get_node_or_null("/root/GameState") as GameProgress
	if state == null:
		return "未装备护符"
	return str(EquipmentDatabase.active_charm_skill(str(state.equipped.get("charm", ""))).get("name", "未装备护符"))


func get_skill_cooldown() -> float:
	return _skill_cooldown


func use_active_skill() -> bool:
	if _dead or _skill_cooldown > 0.0:
		return false
	var state := get_node_or_null("/root/GameState") as GameProgress
	if state == null:
		return false
	var charm_id := str(state.equipped.get("charm", ""))
	var skill := EquipmentDatabase.active_charm_skill(charm_id)
	if skill.is_empty():
		return false
	var kind := str(skill.get("kind", ""))
	if kind in ["heal", "cleanse"]:
		health = mini(max_health, health + int(skill.get("amount", 0)))
		health_changed.emit(health, max_health)
		combat_fx.status_burst(global_position, "heal")
	elif kind == "lure":
		equipment_trait_used.emit("noise_lure")
		combat_fx.profession_skill("echo_summoner", global_position, facing, 104.0, 0.4)
	_skill_cooldown = float(skill.get("cooldown", 1.0))
	_skill_duration = _skill_cooldown
	_skill_pose_timer = 0.24
	skill_changed.emit(get_skill_name(), _skill_cooldown, _skill_duration)
	queue_redraw()
	return true


func _profession_style_definition() -> Dictionary:
	return ExchangeEvolution.COMBAT_STYLES.get(_active_combat_style(), {})


func _profession_skill_definition() -> Dictionary:
	return _profession_style_definition().get("skill", {})


func _damage_for_attack_type(attack_type: String) -> int:
	match attack_type:
		"ranged":
			return ranged_damage
		"shotgun":
			return shotgun_damage
	return attack_damage


func _skill_hits_offset(offset: Vector2, shape: String, skill_range: float, radius: float) -> bool:
	var distance := offset.length()
	if distance <= 0.001:
		return shape == "self"
	match shape:
		"self":
			return distance <= radius
		"cone":
			return distance <= skill_range and facing.dot(offset.normalized()) >= 0.62
		"line":
			if distance > skill_range or facing.dot(offset.normalized()) <= 0.0:
				return false
			return absf(offset.cross(facing)) <= radius
		"target":
			return offset.distance_to(facing * skill_range) <= radius
	return false


func _update_ranged_lock() -> void:
	_locked_ranged_target = null
	if _weapon_attack_type() not in ["ranged", "arcane"] or _dead:
		if combat_fx != null:
			combat_fx.set_target_lock(null)
		return
	var best_score := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not (candidate is Node2D) or not candidate.has_method("take_damage"):
			continue
		var offset: Vector2 = candidate.global_position - global_position
		var distance := offset.length()
		if distance <= 8.0 or distance > ranged_range:
			continue
		var alignment := facing.dot(offset.normalized())
		if alignment < 0.35:
			continue
		var score := distance + (1.0 - alignment) * 120.0
		if score < best_score:
			best_score = score
			_locked_ranged_target = candidate as Node2D
	if combat_fx != null:
		combat_fx.set_target_lock(_locked_ranged_target)


func _has_profession_combat_presentation() -> bool:
	var state := get_node_or_null("/root/GameState") as GameProgress
	return state != null and not state.selected_pathway.is_empty()


func play_profession_skill(style_id: String) -> void:
	if combat_fx == null:
		return
	combat_fx.profession_skill(style_id, global_position, facing, 108.0, 0.52)


func _play_attack_style_vfx(attack_kind: String, reach := 0.0) -> void:
	if combat_fx == null or not _has_profession_combat_presentation():
		return
	var pathway: String = str(_pathway_visual().id)
	var mode_size := 128.0 if attack_kind == "shotgun" else (106.0 if attack_kind == "ranged" else 116.0)
	var visual_reach := reach if reach > 0.0 else (attack_range if attack_kind == "melee" else (ranged_range if attack_kind == "ranged" else shotgun_range))
	combat_fx.profession_attack(pathway, attack_kind, global_position + facing * 28.0, facing, mode_size, visual_reach, 0.26)


func _emit_pathway_movement_echo() -> void:
	if _movement_echo_timer > 0.0 or combat_fx == null:
		return
	var visual := _pathway_visual()
	# Residual silhouettes are a deliberate Resonant-path identity, not a
	# baseline movement effect. Other paths must keep the body visually stable.
	if visual.id != "resonant":
		return
	_movement_echo_timer = 0.14
	combat_fx.movement_echo(global_position, facing, visual.accent, true)
	if _active_combat_style() == "psychic_sense" and int(_walk_animation_time * 10.0) % 5 == 0:
		combat_fx.profession_skill("psychic_sense", global_position, facing, 84.0, 0.34)


func _draw() -> void:
	_draw_character_shadow()
	_draw_pathway_state_vfx()
	var visual := _pathway_visual()
	if not is_instance_valid(_body_sprite):
		_draw_visible_body_fallback(Color("ffb5ad") if _hurt_flash > 0.0 else Color("7d9b76"))
	if not _has_profession_combat_presentation():
		# Only the unbound starting drifter carries an actual weapon silhouette.
		# Equipment continues to govern stats, traits, mastery and evolutions for every path.
		var state := get_node_or_null("/root/GameState") as GameProgress
		var weapon_item := state.get_equipped_weapon_for_attack(_weapon_attack_type()) if state else ""
		var growth_level := state.get_relic_growth(weapon_item) if state else 0
		var weapon_visual := EquipmentDatabase.weapon_visual(weapon_item, growth_level)
		var weapon_color: Color = weapon_visual.color if not weapon_item.is_empty() else visual.tracer
		var weapon_scale := float(weapon_visual.get("scale", 1.0))
		var growth := int(weapon_visual.get("growth", 0))
		var evolution_id := str(state.current_equipment_evolution(weapon_item).get("id", "")) if state else ""
		if str(weapon_visual.shape) == "reaper":
			if evolution_id in ["watcher_form", "execution_form", "abyss_form"]:
				_draw_boss_evolution(["watcher_form", "execution_form", "abyss_form"].find(evolution_id), weapon_scale)
			else:
				_draw_director_reaper(growth, weapon_scale, weapon_color)
			if growth >= 3:
				draw_arc(Vector2.ZERO, 30.0 + growth * 3.0, facing.angle() - 0.8, facing.angle() + 0.55, 18, Color(weapon_color, 0.2), 2.0)
		elif str(weapon_visual.shape) == "railgun":
			if evolution_id in ["hunter_form", "storm_form", "runaway_form"]:
				_draw_boss_evolution(3 + ["hunter_form", "storm_form", "runaway_form"].find(evolution_id), weapon_scale)
			else:
				_draw_conductor_railgun(growth, weapon_scale, weapon_color)
		elif str(weapon_visual.shape) == "advanced":
			_draw_advanced_weapon(int(weapon_visual.get("atlas_index", 0)))
		elif current_weapon == Weapon.RANGED:
			_draw_basic_weapon(1)
		elif current_weapon == Weapon.SHOTGUN:
			_draw_basic_weapon(2)
		else:
			_draw_basic_weapon(0)
	_draw_deep_water_occlusion()
	_draw_health_bar()


func _draw_character_shadow() -> void:
	var speed_ratio := clampf(velocity.length() / maxf(movement_speed, 1.0), 0.0, 1.0)
	var foot_contact := pow(absf(cos(_step_phase * TAU)), 4.0) if speed_ratio > 0.04 else 0.0
	draw_set_transform(
		Vector2(0, 8),
		0.0,
		Vector2(1.0 + speed_ratio * 0.06, 0.32 + foot_contact * speed_ratio * 0.025),
	)
	draw_circle(Vector2.ZERO, 14.5, Color(0.0, 0.0, 0.0, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_health_bar() -> void:
	# Keep combat readability close to the character while the top HUD remains the detailed status view.
	var health_ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var bar_rect := Rect2(-23, -68, 46, 6)
	draw_rect(bar_rect.grow(2.0), Color(0.005, 0.014, 0.012, 0.9), true)
	draw_rect(bar_rect, Color("283832"), true)
	var health_color := Color("5edb9b").lerp(Color("e56e66"), 1.0 - health_ratio)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * health_ratio, bar_rect.size.y)), health_color, true)


func _draw_pathway_state_vfx() -> void:
	if pathway_effects == null:
		return
	if pathway_effects.guard_duration > 0.0:
		_draw_player_state_cell(2, Vector2(0, -6), 74.0, 0.0, Color(0.72, 0.94, 1.0, 0.72))
	if pathway_effects.calibration_ready:
		_draw_player_state_cell(3, Vector2(0, -25), 58.0, 0.0, Color(1.0, 0.85, 0.55, 0.82))
	if pathway_effects.anomaly_pressure > 0:
		var opacity := 0.32 + float(pathway_effects.anomaly_pressure) * 0.07
		_draw_player_state_cell(4, Vector2(0, -4), 82.0, 0.0, Color(0.92, 0.74, 1.0, opacity))


func _draw_deep_water_occlusion() -> void:
	if environment_water_depth < 2:
		return
	if METRO_FLOOD_LAYERS == null or METRO_FLOOD_LAYERS.get_size() != Vector2(512, 256):
		draw_arc(Vector2(0, 9), 29.0, 0.05, PI - 0.05, 20, Color(0.35, 0.72, 0.82, 0.72), 3.0)
		return
	draw_texture_rect_region(
		METRO_FLOOD_LAYERS,
		Rect2(-48, -4, 96, 48),
		Rect2(256, 128, 128, 128),
		Color(0.8, 0.92, 1.0, 0.78),
	)


func _draw_player_state_cell(index: int, center: Vector2, size: float, rotation: float, modulate: Color) -> void:
	if PLAYER_STATES_LIGHTING == null or PLAYER_STATES_LIGHTING.get_size() != Vector2(512, 256):
		return
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(
		PLAYER_STATES_LIGHTING,
		Rect2(Vector2(-size, -size) * 0.5, Vector2(size, size)),
		Rect2((index % 4) * 128, floori(float(index) / 4.0) * 128, 128, 128),
		modulate,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_basic_weapon(atlas_index: int) -> void:
	if BASIC_WEAPONS == null or BASIC_WEAPONS.get_size() != Vector2(96, 32):
		draw_line(facing * 7.0 + Vector2(0, -22), facing * 34.0 + Vector2(0, -22), Color("8a5147"), 6.0)
		return
	var hand_position := Vector2(0, -27) + facing * 12.0 + facing.orthogonal() * 5.0
	draw_set_transform(hand_position, facing.angle() + PI * 0.25, Vector2.ONE)
	draw_texture_rect_region(
		BASIC_WEAPONS,
		Rect2(-16, -16, 32, 32),
		Rect2(atlas_index * 32, 0, 32, 32),
		Color(1.15, 1.15, 1.15, 1.0) if _attack_flash > 0.0 else Color.WHITE
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_advanced_weapon(atlas_index: int) -> void:
	if ADVANCED_WEAPONS == null or ADVANCED_WEAPONS.get_size() != Vector2(320, 64):
		_draw_basic_weapon(int(current_weapon))
		return
	var hand_position := Vector2(0, -27) + facing * 14.0 + facing.orthogonal() * 5.0
	draw_set_transform(hand_position, facing.angle() + PI * 0.25, Vector2.ONE)
	draw_texture_rect_region(
		ADVANCED_WEAPONS,
		Rect2(-32, -32, 64, 64),
		Rect2(clampi(atlas_index, 0, 4) * 64, 0, 64, 64),
		Color(1.16, 1.14, 1.12, 1.0) if _attack_flash > 0.0 else Color.WHITE,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_boss_evolution(atlas_index: int, scale: float) -> void:
	if BOSS_EVOLUTION_WEAPONS == null or BOSS_EVOLUTION_WEAPONS.get_size() != Vector2(384, 128):
		return
	var column := atlas_index % 3
	var row := floori(float(atlas_index) / 3.0)
	var hand_position := Vector2(0, -27) + facing * 15.0 + facing.orthogonal() * 5.0
	draw_set_transform(hand_position, facing.angle() + (PI * 0.5 if row == 0 else 0.0), Vector2.ONE * scale)
	draw_texture_rect_region(
		BOSS_EVOLUTION_WEAPONS,
		Rect2(-48, -32, 96, 64),
		Rect2(column * 128, row * 64, 128, 64),
		Color(1.18, 1.12, 1.1, 1.0) if _attack_flash > 0.0 else Color.WHITE,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_director_reaper(growth: int, scale: float, fallback_color: Color) -> void:
	if DIRECTOR_REAPER_GROWTH == null or DIRECTOR_REAPER_GROWTH.get_size() != Vector2(384, 64):
		draw_line(facing * 7.0, facing * (41.0 * scale), fallback_color.darkened(0.35), 6.0 + growth * 0.5)
		draw_arc(facing * (42.0 * scale), 15.0 * scale, facing.angle() - 1.35, facing.angle() + 0.55, 10, fallback_color, 5.0 + growth * 0.45)
		return
	var frame := clampi(growth, 0, 5)
	var hand_position := Vector2(0, -27) + facing * (14.0 + growth * 0.8) + facing.orthogonal() * 5.0
	draw_set_transform(hand_position, facing.angle() + PI * 0.5, Vector2.ONE * scale)
	draw_texture_rect_region(
		DIRECTOR_REAPER_GROWTH,
		Rect2(-32, -32, 64, 64),
		Rect2(frame * 64, 0, 64, 64),
		Color(1.18, 1.1, 1.08, 1.0) if _attack_flash > 0.0 else Color.WHITE
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_conductor_railgun(growth: int, scale: float, fallback_color: Color) -> void:
	if CONDUCTOR_RAILGUN_GROWTH == null or CONDUCTOR_RAILGUN_GROWTH.get_size() != Vector2(384, 64):
		draw_line(facing * 9.0, facing * (45.0 * scale), fallback_color, 7.0)
		return
	var frame := clampi(growth, 0, 5)
	var hand_position := Vector2(0, -27) + facing * (13.0 + growth * 0.6) + facing.orthogonal() * 5.0
	draw_set_transform(hand_position, facing.angle(), Vector2.ONE * scale)
	draw_texture_rect_region(
		CONDUCTOR_RAILGUN_GROWTH,
		Rect2(-18, -38, 64, 64),
		Rect2(frame * 64, 0, 64, 64),
		Color(1.14, 1.12, 1.1, 1.0) if _attack_flash > 0.0 else Color.WHITE,
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_visible_body_fallback(color: Color) -> void:
	draw_circle(Vector2(0, -42), 9.0, Color("c9c2ae"))
	draw_rect(Rect2(-13, -34, 26, 31), color)
	draw_line(Vector2(-8, -4), Vector2(-10, 8), Color("2b343b"), 7.0)
	draw_line(Vector2(8, -4), Vector2(10, 8), Color("2b343b"), 7.0)
	draw_circle(Vector2(-12, -25), 3.0, Color("59e1e6"))
