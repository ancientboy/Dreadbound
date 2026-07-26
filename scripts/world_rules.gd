class_name WorldRules
extends RefCounted

var world_id := "sanatorium"


func _init(requested_world := "sanatorium") -> void:
	world_id = requested_world


func reward_pool() -> Array[String]:
	return EquipmentDatabase.metro_reward_pool() if world_id == "metro" else EquipmentDatabase.reward_pool()


func event_ids() -> Array[String]:
	if world_id == "metro":
		return ["floating_locker", "wrong_announcement", "help_carriage", "breaker_bypass"]
	return ["medicine_cabinet", "echo_ward", "archive_whisper", "power_surge"]


func water_speed_multiplier(depth: int, has_waterproof_trait: bool) -> float:
	if depth <= 0:
		return 1.0
	var base := 0.68 if depth == 1 else 0.46
	return lerpf(base, 1.0, 0.35) if has_waterproof_trait else base


func train_window(route: String, has_ticket_trait: bool, recovery := false) -> float:
	if recovery:
		return 50.0 if has_ticket_trait else 35.0
	return 115.0 if route == "north" else 70.0

