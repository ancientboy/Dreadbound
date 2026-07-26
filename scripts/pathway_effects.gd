class_name PathwayEffects
extends Node

var player: Player
var state: GameProgress
var guard_duration := 0.0
var calibration_duration := 0.0
var calibration_ready := false
var anomaly_pressure := 0
var last_trigger := ""


func setup(owner_player: Player, game_state: GameProgress) -> void:
	player = owner_player
	state = game_state


func tick(delta: float) -> void:
	guard_duration = maxf(guard_duration - delta, 0.0)
	calibration_duration = maxf(calibration_duration - delta, 0.0)
	if calibration_duration <= 0.0:
		calibration_ready = false


func on_bandage_used(health_before: int, maximum: int) -> void:
	if state and state.has_path_node("steadfast_barrier") and float(health_before) / maximum <= 0.4:
		guard_duration = 4.0
		last_trigger = "应急屏障"


func on_weapon_switched() -> void:
	if state and state.has_path_node("armorer_alternation"):
		calibration_ready = true
		calibration_duration = 6.0
		last_trigger = "交替校准"


func consume_attack_multiplier() -> float:
	if not calibration_ready:
		return 1.0
	calibration_ready = false
	calibration_duration = 0.0
	return 1.2


func incoming_damage_multiplier() -> float:
	return 0.75 if guard_duration > 0.0 else 1.0


func on_risk_event(take_risk: bool) -> int:
	if not take_risk or not state or not state.has_path_node("resonant_ingestion"):
		return 0
	anomaly_pressure = mini(anomaly_pressure + 1, 5)
	last_trigger = "异常摄取"
	return 2


func healing_multiplier() -> float:
	return maxf(0.6, 1.0 - anomaly_pressure * 0.08)


func statuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if guard_duration > 0.0:
		result.append({"id": "guard", "name": "应急屏障", "remaining": guard_duration, "color": Color("66c8d7")})
	if calibration_ready:
		result.append({"id": "calibration", "name": "交替校准", "remaining": calibration_duration, "color": Color("e2b55d")})
	if anomaly_pressure > 0:
		result.append({"id": "anomaly", "name": "异化压力 %d" % anomaly_pressure, "remaining": -1.0, "color": Color("c86bd8")})
	return result
