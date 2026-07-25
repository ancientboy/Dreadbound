class_name DreadDirector
extends RefCounted

var pressure := 0.35
var pacing_debt := 0.0
var opportunity := 0.4
var elapsed := 0.0
var decision_log: Array[String] = []
var supplied_relief := false
var escalated_once := false


func update(delta: float, health_ratio: float, ammo_ratio: float, unresolved_rooms: int, recent_damage: float, aggressive: bool) -> String:
	elapsed += delta
	pressure = clampf((1.0 - health_ratio) * 0.34 + (1.0 - ammo_ratio) * 0.18 + recent_damage * 0.22 + (0.18 if aggressive else 0.05), 0.0, 1.0)
	pacing_debt = clampf(pacing_debt + delta * (0.012 if pressure < 0.42 else -0.018), -1.0, 1.0)
	opportunity = clampf((1.0 - health_ratio) * 0.55 + (1.0 - ammo_ratio) * 0.25 + unresolved_rooms * 0.025, 0.0, 1.0)
	if opportunity > 0.72 and not supplied_relief:
		supplied_relief = true
		_log("补给干预：生命/弹药短缺，安排一次可见恢复机会")
		return "relief"
	if elapsed > 75.0 and pressure < 0.38 and pacing_debt > 0.45 and not escalated_once:
		escalated_once = true
		_log("压力干预：长时间低压，安排一次可绕行追击")
		return "escalate"
	return "none"


func choose_room_content(candidates: Array[String]) -> String:
	if candidates.is_empty():
		return "empty"
	if opportunity > 0.65 and candidates.has("resource"):
		_log("房间选择：机会值较高，选择资源房")
		return "resource"
	if pacing_debt > 0.35 and candidates.has("ambush"):
		_log("房间选择：节奏债务较高，选择伏击房")
		return "ambush"
	_log("房间选择：维持探索节奏")
	return candidates[0]


func _log(message: String) -> void:
	decision_log.append("%03d秒 %s" % [int(elapsed), message])
