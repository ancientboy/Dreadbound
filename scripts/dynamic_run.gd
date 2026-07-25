class_name DynamicRunConfig
extends RefCounted

const ROOM_MODULES := ["入口大厅", "病房甲区", "护理站", "隔离病房", "实验档案室", "地下维护区", "药品库", "撤离通道"]
const METRO_ROOM_MODULES := ["检票大厅", "废弃商街", "北站台", "南站台", "淹水隧道", "信号机房", "维修走廊", "售票档案室", "换乘天桥", "零号换乘层"]
const CONTENT_SLOTS := [
	Vector2(352, 416), Vector2(672, 256), Vector2(800, 480), Vector2(1088, 608),
	Vector2(1184, 480), Vector2(1344, 608), Vector2(1760, 704), Vector2(1952, 288),
	Vector2(2048, 384), Vector2(1600, 1088), Vector2(1840, 1200), Vector2(224, 1184),
]
const SIDE_CONTRACTS := ["medicine_cabinet", "echo_ward", "archive_whisper", "power_surge"]
const CAUSAL_CHAINS := ["spore_bloom", "quiet_signal", "hungry_corridor"]

var seed: int
var world_id := "sanatorium"
var action_code: String
var room_order: Array[String] = []
var edges: Array[Vector2i] = []
var mission_id := "archive_recovery"
var mission_title := "档案回收"
var objective_noun := "实验记录"
var objective_count := 3
var objective_positions: Array[Vector2] = []
var power_position := Vector2.ZERO
var boss_position := Vector2.ZERO
var exit_position := Vector2.ZERO
var patient_spawns: Array[Vector2] = []
var crawler_spawns: Array[Vector2] = []
var orderly_spawns: Array[Vector2] = []
var side_contracts: Array[String] = []
var causal_chain := ""


func _init(run_seed: int, requested_world := "sanatorium") -> void:
	seed = absi(run_seed) if run_seed != 0 else 1
	world_id = requested_world if requested_world in ["sanatorium", "metro"] else "sanatorium"
	action_code = ("MET" if world_id == "metro" else "SAN") + "-%08X" % seed
	_generate()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var modules: Array[String] = []
	modules.assign(METRO_ROOM_MODULES if world_id == "metro" else ROOM_MODULES)
	room_order.assign(modules)
	# Keep entrance first and extraction last while changing every interior route role.
	var middle: Array[String] = room_order.slice(1, room_order.size() - 1)
	_shuffle_with_rng(middle, rng)
	room_order = [modules[0]]
	room_order.append_array(middle)
	room_order.append(modules[-1])
	for index in range(room_order.size() - 1):
		edges.append(Vector2i(index, index + 1))
	edges.append(Vector2i(1 + rng.randi_range(0, 2), 4 + rng.randi_range(0, 2)))
	if world_id == "metro":
		mission_id = "lost_service" if rng.randi() % 2 == 0 else "switch_zero"
		mission_title = "失联车次" if mission_id == "lost_service" else "零号道岔"
		objective_noun = "车次信标" if mission_id == "lost_service" else "道岔锁"
	else:
		mission_id = "archive_recovery" if rng.randi() % 2 == 0 else "anomaly_severance"
		mission_title = "档案回收" if mission_id == "archive_recovery" else "异常切除"
		objective_noun = "实验记录" if mission_id == "archive_recovery" else "异常节点"
	objective_count = rng.randi_range(2, 4)
	var slots: Array[Vector2] = []
	slots.assign(CONTENT_SLOTS)
	_shuffle_with_rng(slots, rng)
	for index in range(objective_count):
		objective_positions.append(slots.pop_back())
	power_position = slots.pop_back()
	boss_position = slots.pop_back()
	exit_position = slots.pop_back()
	var enemy_slots: Array[Vector2] = []
	for slot in CONTENT_SLOTS:
		if slot.distance_to(Vector2(224, 360)) > 430.0:
			enemy_slots.append(slot)
	_shuffle_with_rng(enemy_slots, rng)
	for index in range(4):
		patient_spawns.append(_jitter(enemy_slots[index % enemy_slots.size()], rng, 54.0))
	for index in range(3):
		crawler_spawns.append(_jitter(enemy_slots[(index + 4) % enemy_slots.size()], rng, 68.0))
	for index in range(2):
		orderly_spawns.append(_jitter(enemy_slots[(index + 7) % enemy_slots.size()], rng, 42.0))
	var contracts: Array[String] = []
	contracts.assign(SIDE_CONTRACTS)
	_shuffle_with_rng(contracts, rng)
	side_contracts.assign(contracts.slice(0, 2))
	causal_chain = CAUSAL_CHAINS[rng.randi_range(0, CAUSAL_CHAINS.size() - 1)]


func validate() -> bool:
	var modules: Array[String] = []
	modules.assign(METRO_ROOM_MODULES if world_id == "metro" else ROOM_MODULES)
	if room_order.size() != modules.size() or room_order[0] != modules[0] or room_order[-1] != modules[-1]:
		return false
	if objective_positions.size() != objective_count or objective_count < 2 or objective_count > 4:
		return false
	var reached := {0: true}
	for _pass in range(room_order.size()):
		for edge in edges:
			if reached.has(edge.x): reached[edge.y] = true
			if reached.has(edge.y): reached[edge.x] = true
	return reached.size() == room_order.size() and power_position != exit_position and boss_position != exit_position


func room_role(index: int) -> String:
	return room_order[index % room_order.size()]


func _shuffle_with_rng(array: Array, rng: RandomNumberGenerator) -> void:
	for index in range(array.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var value = array[index]
		array[index] = array[other]
		array[other] = value


func _jitter(origin: Vector2, rng: RandomNumberGenerator, radius: float) -> Vector2:
	return origin + Vector2(rng.randf_range(-radius, radius), rng.randf_range(-radius, radius))
