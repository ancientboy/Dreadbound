class_name PersistentDungeonState
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_HISTORY := 48
const UNIQUE_ITEMS := {
	"director_reaper": {"world": "sanatorium", "kind": "growing_boss_relic"},
	"conductor_railgun": {"world": "metro", "kind": "growing_boss_relic"},
	"linye_pass": {"world": "metro", "kind": "story_unique"},
}

var dungeons := {}
var unique_registry := {}


func _init() -> void:
	reset()


func reset() -> void:
	dungeons = {
		"sanatorium": _default_dungeon(),
		"metro": _default_dungeon(),
	}
	unique_registry = {}


func _default_dungeon() -> Dictionary:
	return {
		"visits": 0,
		"completed_runs": 0,
		"active_run_id": "",
		"chapter": "first_arrival",
		"first_ending": "",
		"next_variant": "first_arrival",
		"opened_areas": [],
		"completed_events": [],
		"boss_state": {"defeats": 0, "phase": "unseen"},
		"history": [],
	}


func begin_visit(world_id: String, run_id: String, world_state: WorldStateStore) -> Dictionary:
	var dungeon := _ensure_dungeon(world_id)
	if not run_id.is_empty() and str(dungeon.get("active_run_id", "")) != run_id:
		dungeon.visits = int(dungeon.get("visits", 0)) + 1
		dungeon.active_run_id = run_id
	dungeon.chapter = _select_chapter(world_id, dungeon, world_state)
	dungeon.next_variant = str(dungeon.chapter)
	dungeons[world_id] = dungeon
	if world_id == "metro":
		_ensure_linye(world_state)
	return chapter_snapshot(world_id, world_state)


func chapter_snapshot(world_id: String, world_state: WorldStateStore) -> Dictionary:
	var dungeon := _ensure_dungeon(world_id)
	var chapter := str(dungeon.get("chapter", "first_arrival"))
	if world_id != "metro":
		return {
			"world_id": world_id,
			"chapter": chapter,
			"visit": int(dungeon.get("visits", 0)),
			"title": "疗养院残留记录",
			"briefing": "这座副本已经开始保存你的行动痕迹。",
			"hidden_open": has_opened_area(world_id, "lost_passenger_level"),
		}
	var npc: Dictionary = _ensure_linye(world_state)
	var presentation := _metro_presentation(chapter, npc)
	presentation.world_id = world_id
	presentation.chapter = chapter
	presentation.visit = int(dungeon.get("visits", 0))
	presentation.hidden_open = has_opened_area(world_id, "lost_passenger_level")
	presentation.npc = npc.duplicate(true)
	presentation.cause = _latest_cause(dungeon)
	return presentation


func resolve_metro_choice(choice: String, world_state: WorldStateStore, run_id: String) -> Dictionary:
	var dungeon := _ensure_dungeon("metro")
	var chapter := str(dungeon.get("chapter", "first_arrival"))
	var npc := _ensure_linye(world_state)
	var result := {
		"accepted": false,
		"choice": choice,
		"chapter": chapter,
		"event_type": "",
		"summary": "",
		"hidden_opened": false,
		"unique_offer": "",
	}
	match chapter:
		"first_arrival":
			if choice == "promise_return":
				npc.promise = "return_for_linye"
				npc.last_outcome = "waiting_for_return"
				npc.trust = int(npc.get("trust", 0)) + 6
				dungeon.next_variant = "promise_due"
				result.event_type = "promise_made"
				result.summary = "你答应林雾会再次进入末班线，打开失踪乘客维护层。"
			elif choice == "sell_location":
				npc.promise = ""
				npc.last_outcome = "location_sold"
				npc.trust = int(npc.get("trust", 0)) - 24
				dungeon.next_variant = "authority_occupation"
				result.event_type = "faction_betrayal"
				result.summary = "你把林雾的位置交给秩序署；下一次列车会先找到她。"
			else:
				return result
		"promise_due":
			if choice == "keep_promise":
				npc.promise = ""
				npc.last_outcome = "rescued_guide"
				npc.location = "lost_passenger_level"
				npc.trust = int(npc.get("trust", 0)) + 30
				dungeon.next_variant = "guided_aftermath"
				result.event_type = "promise_kept"
				result.summary = "你兑现了承诺。林雾打开维护层，并记住你回来过。"
			elif choice == "take_relic_alone":
				npc.promise = ""
				npc.last_outcome = "abandoned_echo"
				npc.alive = false
				npc.trust = int(npc.get("trust", 0)) - 35
				dungeon.next_variant = "broken_promise_echo"
				result.event_type = "promise_broken"
				result.summary = "你打开维护层后独自离开；林雾的声音留在下一班列车里。"
			else:
				return result
			_open_area(dungeon, "lost_passenger_level")
			result.hidden_opened = true
		"authority_occupation":
			if choice == "free_linye":
				npc.last_outcome = "rescued_from_authority"
				npc.location = "lost_passenger_level"
				npc.trust = int(npc.get("trust", 0)) + 12
				dungeon.next_variant = "resistance_aftermath"
				result.event_type = "rescue"
				result.summary = "你反悔并破坏秩序署封锁。林雾不会原谅，但接受了这次救援。"
			elif choice == "accept_requisition":
				npc.last_outcome = "taken_by_authority"
				npc.alive = false
				dungeon.next_variant = "authority_aftermath"
				result.event_type = "faction_help"
				result.summary = "你接受秩序署征用；维护层开放，但失踪乘客被带走。"
			else:
				return result
			_open_area(dungeon, "lost_passenger_level")
			result.hidden_opened = true
		"guided_aftermath", "resistance_aftermath":
			if choice == "preserve_manifest":
				npc.last_outcome = "manifest_guardian"
				npc.trust = int(npc.get("trust", 0)) + 10
				result.event_type = "faction_help"
				result.summary = "你保留了失踪者名单；林雾会在以后帮助辨认回声。"
				result.unique_offer = "linye_pass"
			elif choice == "erase_manifest":
				npc.last_outcome = "manifest_erased"
				npc.trust = int(npc.get("trust", 0)) - 12
				result.event_type = "independent_choice"
				result.summary = "你抹去了名单，阻止阵营利用死者，也让他们永久失去姓名。"
			else:
				return result
		"broken_promise_echo", "authority_aftermath":
			if choice == "face_echo":
				npc.last_outcome = "echo_acknowledged"
				result.event_type = "sacrifice"
				result.summary = "你承认了自己造成的结局，维护层不再替你掩盖那次选择。"
			elif choice == "silence_echo":
				npc.last_outcome = "echo_silenced"
				result.event_type = "attack_neutral"
				result.summary = "你切断了回声；名单安静下来，但世界记住了这种处理方式。"
			else:
				return result
		_:
			return result
	result.accepted = true
	if str(npc.get("first_met_run", "")).is_empty():
		npc.first_met_run = run_id
	npc.last_met_run = run_id
	var memories: Array = npc.get("memories", [])
	memories.push_front({
		"run_id": run_id,
		"visit": int(dungeon.get("visits", 0)),
		"chapter": chapter,
		"choice": choice,
		"summary": str(result.summary),
	})
	if memories.size() > 12:
		memories.resize(12)
	npc.memories = memories
	_complete_event(dungeon, "%s:%s" % [chapter, choice])
	_append_history(dungeon, {
		"run_id": run_id,
		"visit": int(dungeon.get("visits", 0)),
		"chapter": chapter,
		"choice": choice,
		"summary": str(result.summary),
	})
	world_state.npcs.linye = npc
	dungeon.chapter = str(dungeon.get("next_variant", chapter))
	dungeons.metro = dungeon
	return result


func settle_visit(world_id: String, success: bool, run_id: String, boss_defeated: bool) -> Dictionary:
	var dungeon := _ensure_dungeon(world_id)
	if success:
		dungeon.completed_runs = int(dungeon.get("completed_runs", 0)) + 1
		if str(dungeon.get("first_ending", "")).is_empty():
			dungeon.first_ending = str(dungeon.get("next_variant", dungeon.get("chapter", "first_arrival")))
	if boss_defeated:
		var boss: Dictionary = dungeon.get("boss_state", {"defeats": 0, "phase": "unseen"})
		boss.defeats = int(boss.get("defeats", 0)) + 1
		boss.phase = "memory_exposed" if int(boss.defeats) == 1 else "evolved_echo"
		dungeon.boss_state = boss
	_append_history(dungeon, {
		"run_id": run_id,
		"visit": int(dungeon.get("visits", 0)),
		"chapter": str(dungeon.get("chapter", "")),
		"choice": "extracted" if success else "lost",
		"summary": "本次行动已撤离。" if success else "本次行动失联，副本仍保留未完成状态。",
	})
	dungeon.active_run_id = ""
	dungeons[world_id] = dungeon
	return {
		"world_id": world_id,
		"visits": int(dungeon.visits),
		"completed_runs": int(dungeon.completed_runs),
		"chapter": str(dungeon.chapter),
		"next_variant": str(dungeon.next_variant),
		"boss_state": dungeon.boss_state.duplicate(true),
	}


func is_unique(item_id: String) -> bool:
	return UNIQUE_ITEMS.has(item_id)


func is_claimed(item_id: String) -> bool:
	return unique_registry.has(item_id)


func claim_unique(item_id: String, run_id: String, world_id: String) -> bool:
	if not is_unique(item_id) or is_claimed(item_id):
		return false
	unique_registry[item_id] = {
		"claimed_run": run_id,
		"source_dungeon": world_id,
		"claimed_cycle": int(_ensure_dungeon(world_id).get("visits", 0)),
		"current_owner": "player",
		"destroyed": false,
		"transformed_into": "",
	}
	return true


func reconcile_inventory(items: Array[String]) -> void:
	for item_id in items:
		if is_unique(item_id) and not is_claimed(item_id):
			claim_unique(item_id, "legacy_inventory", str(UNIQUE_ITEMS[item_id].world))


func filter_reward_pool(pool: Array[String]) -> Array[String]:
	var filtered: Array[String] = []
	for item_id in pool:
		if not is_unique(item_id) or not is_claimed(item_id):
			filtered.append(item_id)
	return filtered


func has_opened_area(world_id: String, area_id: String) -> bool:
	var areas: Array = _ensure_dungeon(world_id).get("opened_areas", [])
	return areas.has(area_id)


func history_for(world_id: String) -> Array[Dictionary]:
	var history: Array[Dictionary] = []
	history.assign(_ensure_dungeon(world_id).get("history", []).duplicate(true))
	return history


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"dungeons": dungeons.duplicate(true),
		"unique_registry": unique_registry.duplicate(true),
	}


func load_dict(value: Variant) -> void:
	reset()
	if not value is Dictionary:
		return
	var saved_dungeons: Variant = value.get("dungeons", {})
	if saved_dungeons is Dictionary:
		for world_id in saved_dungeons:
			if saved_dungeons[world_id] is Dictionary:
				var merged := _default_dungeon()
				for key in saved_dungeons[world_id]:
					merged[str(key)] = saved_dungeons[world_id][key].duplicate(true) if saved_dungeons[world_id][key] is Array or saved_dungeons[world_id][key] is Dictionary else saved_dungeons[world_id][key]
				dungeons[str(world_id)] = merged
	var saved_unique: Variant = value.get("unique_registry", {})
	unique_registry = saved_unique.duplicate(true) if saved_unique is Dictionary else {}


func _ensure_dungeon(world_id: String) -> Dictionary:
	if not dungeons.has(world_id) or not dungeons[world_id] is Dictionary:
		dungeons[world_id] = _default_dungeon()
	return dungeons[world_id]


func _ensure_linye(world_state: WorldStateStore) -> Dictionary:
	if not world_state.npcs.has("linye"):
		world_state.npcs.linye = {
			"name": "林雾",
			"alive": true,
			"trust": 0,
			"injury": 1,
			"location": "metro_transfer",
			"promise": "",
			"last_outcome": "unmet",
			"first_met_run": "",
			"last_met_run": "",
			"memories": [],
		}
	return world_state.npcs.linye


func _select_chapter(world_id: String, dungeon: Dictionary, world_state: WorldStateStore) -> String:
	if world_id != "metro":
		return str(dungeon.get("next_variant", "first_arrival"))
	var visits := int(dungeon.get("visits", 0))
	if visits <= 1:
		return "first_arrival"
	var npc: Dictionary = _ensure_linye(world_state)
	var outcome := str(npc.get("last_outcome", "unmet"))
	if outcome == "waiting_for_return":
		return "promise_due"
	if outcome == "location_sold":
		return "authority_occupation"
	if outcome in ["rescued_guide", "manifest_guardian"]:
		return "guided_aftermath"
	if outcome in ["rescued_from_authority"]:
		return "resistance_aftermath"
	if outcome in ["abandoned_echo", "echo_acknowledged", "echo_silenced"]:
		return "broken_promise_echo"
	if outcome in ["taken_by_authority"]:
		return "authority_aftermath"
	return str(dungeon.get("next_variant", "first_arrival"))


func _metro_presentation(chapter: String, npc: Dictionary) -> Dictionary:
	match chapter:
		"first_arrival":
			return {
				"title": "第一章：无人报站",
				"briefing": "失踪乘客林雾躲在换乘层。她知道一座地图上不存在的维护层。",
				"npc_title": "失踪乘客 · 林雾",
				"npc_description": "她把一枚旧站务牌塞进门缝：『下一次潮水退去时，回来替我开门。』",
				"choice_a": "承诺回来：记录约定",
				"choice_b": "出售坐标：秩序署资源",
				"choice_a_id": "promise_return",
				"choice_b_id": "sell_location",
			}
		"promise_due":
			return {
				"title": "第二章：回来的人",
				"briefing": "林雾仍在原地。她准确说出了你上次离开的时间。",
				"npc_title": "林雾 · 等待第 %d 次潮汐" % maxi(int(npc.get("trust", 0)), 1),
				"npc_description": "维护层就在封闭墙后。开门会放出失踪乘客的回声，也会证明你的承诺是否有重量。",
				"choice_a": "兑现承诺：带她进入",
				"choice_b": "独自开门：先取遗物",
				"choice_a_id": "keep_promise",
				"choice_b_id": "take_relic_alone",
			}
		"authority_occupation":
			return {
				"title": "第二章：征用名单",
				"briefing": "你出售的坐标变成了秩序署封锁线。林雾被扣在维护层门前。",
				"npc_title": "秩序署临时收容点",
				"npc_description": "林雾看见你后停止求救。你仍能破坏封锁，或领取上次交易的报酬。",
				"choice_a": "反悔：释放林雾",
				"choice_b": "接受征用：打开维护层",
				"choice_a_id": "free_linye",
				"choice_b_id": "accept_requisition",
			}
		"guided_aftermath", "resistance_aftermath":
			return {
				"title": "第三章：失踪者有名字",
				"briefing": "维护层已经记住你。林雾把乘客名单分成了仍会回应与已经沉默的两页。",
				"npc_title": "维护层向导 · 林雾",
				"npc_description": "名单能让死者保留姓名，也能成为阵营追踪每一个回声的工具。",
				"choice_a": "保存名单：共同守护",
				"choice_b": "抹除名单：拒绝利用",
				"choice_a_id": "preserve_manifest",
				"choice_b_id": "erase_manifest",
			}
		_:
			return {
				"title": "第三章：没人替你忘记",
				"briefing": "维护层里反复播放着你第一次作出选择时的声音。",
				"npc_title": "林雾的残留回声",
				"npc_description": "它不要求道歉，只要求你决定：承认这个结果，还是再次让它闭嘴。",
				"choice_a": "面对回声：承认因果",
				"choice_b": "切断回声：永久静默",
				"choice_a_id": "face_echo",
				"choice_b_id": "silence_echo",
			}


func _open_area(dungeon: Dictionary, area_id: String) -> void:
	var areas: Array = dungeon.get("opened_areas", [])
	if not areas.has(area_id):
		areas.append(area_id)
	dungeon.opened_areas = areas


func _complete_event(dungeon: Dictionary, event_id: String) -> void:
	var events: Array = dungeon.get("completed_events", [])
	if not events.has(event_id):
		events.append(event_id)
	dungeon.completed_events = events


func _append_history(dungeon: Dictionary, entry: Dictionary) -> void:
	var history: Array = dungeon.get("history", [])
	history.push_front(entry.duplicate(true))
	if history.size() > MAX_HISTORY:
		history.resize(MAX_HISTORY)
	dungeon.history = history


func _latest_cause(dungeon: Dictionary) -> String:
	var history: Array = dungeon.get("history", [])
	for entry in history:
		if str(entry.get("choice", "")) not in ["extracted", "lost"]:
			return str(entry.get("summary", ""))
	return "这是你第一次进入这条世界线。"
