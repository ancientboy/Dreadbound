class_name HumanityProfile
extends RefCounted

const DIMENSIONS := {
	"responsibility": {"negative": "利己", "positive": "担当"},
	"loyalty": {"negative": "机会主义", "positive": "忠诚"},
	"restraint": {"negative": "暴力", "positive": "克制"},
	"risk": {"negative": "保守", "positive": "冒险"},
	"commitment": {"negative": "背弃", "positive": "守诺"},
	"belonging": {"negative": "个体性", "positive": "群体依赖"},
}
const EVENT_WEIGHTS := {
	"rescue": {"responsibility": 2},
	"sacrifice": {"responsibility": 3},
	"abandon": {"responsibility": -2},
	"share_loot": {"responsibility": 1, "belonging": 1},
	"faction_help": {"loyalty": 1, "belonging": 1},
	"faction_betrayal": {"loyalty": -3, "commitment": -2},
	"promise_kept": {"commitment": 3, "loyalty": 1},
	"promise_broken": {"commitment": -3, "loyalty": -1},
	"spare_neutral": {"restraint": 2},
	"attack_neutral": {"restraint": -3},
	"risk_choice": {"risk": 1},
	"safe_choice": {"risk": -1},
	"independent_choice": {"belonging": -1},
	"follow_group": {"belonging": 1},
	"costly_rescue": {"responsibility": 3, "risk": 1},
	"self_preservation": {"responsibility": -1, "risk": -1},
	"anonymous_restraint": {"restraint": 2, "responsibility": 1},
	"anonymous_exploitation": {"restraint": -2, "loyalty": -1},
	"authority_obedience": {"belonging": 1, "responsibility": -1},
	"share_burden": {"responsibility": 2, "loyalty": 1},
	"forgive_rescue": {"responsibility": 2, "restraint": 2},
	"retaliation": {"restraint": -2, "loyalty": -1},
	"outgroup_help": {"responsibility": 3, "belonging": -1},
	"ingroup_help": {"loyalty": 2, "belonging": 2},
	"public_help": {"responsibility": 1, "belonging": 1},
	"anonymous_help": {"responsibility": 3, "restraint": 1},
	"responsibility_acceptance": {"responsibility": 3, "commitment": 1},
}

var knowledge := BehaviorKnowledgeBase.new()


func analyze(events: Array[Dictionary]) -> Dictionary:
	var scores := {}
	var evidence := {}
	var counter_evidence := {}
	var worlds := {}
	for dimension in DIMENSIONS:
		scores[dimension] = 0
		evidence[dimension] = []
		counter_evidence[dimension] = []
	for event in events:
		var event_type := str(event.get("event_type", ""))
		var weights: Dictionary = EVENT_WEIGHTS.get(event_type, {})
		if event_type == "risk_choice" and not bool(event.get("context", {}).get("took_risk", false)):
			weights = {"risk": -1}
			event_type = "safe_choice"
		if weights.is_empty():
			continue
		var context: Dictionary = event.get("context", {})
		var cost_level := clampi(int(context.get("cost_level", 1)), 1, 3)
		var cost_multiplier := 0.75 + float(cost_level) * 0.25
		var anonymous_multiplier := 1.2 if bool(context.get("anonymous", false)) else 1.0
		var observed_multiplier := 0.85 if bool(context.get("public", false)) else 1.0
		worlds[str(event.get("world_id", "unknown"))] = true
		for dimension in weights:
			var raw_weight := int(weights[dimension])
			var weight := int(round(float(raw_weight) * cost_multiplier * anonymous_multiplier * observed_multiplier))
			if weight == 0:
				weight = signi(raw_weight)
			scores[dimension] = int(scores[dimension]) + weight
			var item := {
				"event_id": str(event.get("event_id", "")),
				"event_type": event_type,
				"world_id": str(event.get("world_id", "")),
				"weight": weight,
				"choice": str(event.get("choice", "")),
				"cost_level": cost_level,
				"anonymous": bool(context.get("anonymous", false)),
				"public": bool(context.get("public", false)),
			}
			if weight >= 0:
				evidence[dimension].append(item)
			else:
				counter_evidence[dimension].append(item)
	var results := {}
	for dimension in DIMENSIONS:
		var positive: Array = evidence[dimension]
		var negative: Array = counter_evidence[dimension]
		var sample_size := positive.size() + negative.size()
		var confidence := _confidence(sample_size, worlds.size(), positive.size(), negative.size())
		var score := clampi(int(scores[dimension]), -10, 10)
		var pole := str(DIMENSIONS[dimension].positive) if score > 0 else str(DIMENSIONS[dimension].negative) if score < 0 else "尚未形成"
		var sources := knowledge.retrieve([dimension, _knowledge_tag(dimension, score)], 2)
		var citations: Array[Dictionary] = []
		for source in sources:
			citations.append(knowledge.citation(source))
		results[dimension] = {
			"score": score,
			"pole": pole,
			"confidence": confidence,
			"sample_size": sample_size,
			"evidence": positive.slice(maxi(positive.size() - 5, 0)),
			"counter_evidence": negative.slice(maxi(negative.size() - 5, 0)),
			"knowledge": citations,
			"interpretation": _interpretation(dimension, pole, confidence, sample_size),
			"method": "行为代价、是否公开、跨副本一致性与相反证据共同决定权重",
		}
	return {
		"scope": "gameplay_tendency_only",
		"dimensions": results,
		"evidence_events": events.size(),
		"worlds_observed": worlds.size(),
		"guardrails": knowledge.guardrails.duplicate(),
		"disclaimer": "这是对游戏情境中选择模式的反思，不是对现实人格或心理健康的诊断。",
	}


func generate_echo(profile: Dictionary) -> Dictionary:
	var dimensions: Dictionary = profile.get("dimensions", {})
	var selected := ""
	var strongest := -1.0
	for dimension in dimensions:
		var result: Dictionary = dimensions[dimension]
		var strength := absf(float(result.get("score", 0))) * float(result.get("confidence", 0.0))
		if int(result.get("sample_size", 0)) >= 2 and strength > strongest:
			strongest = strength
			selected = str(dimension)
	if selected.is_empty():
		return {"id": "unformed_echo", "name": "未成形的回声", "dimension": "", "reason": "有效行为样本不足"}
	var result: Dictionary = dimensions[selected]
	var positive := int(result.score) > 0
	var echo_ids := {
		"responsibility": ["abandoned_one", "burden_bearer"],
		"loyalty": ["turncoat_shadow", "faction_witness"],
		"restraint": ["armed_double", "quiet_witness"],
		"risk": ["door_watcher", "last_step_walker"],
		"commitment": ["broken_promise", "promise_remnant"],
		"belonging": ["lone_signal", "chorus_companion"],
	}
	var names := {
		"abandoned_one": "被遗弃者", "burden_bearer": "负重者",
		"turncoat_shadow": "转旗之影", "faction_witness": "阵营见证者",
		"armed_double": "过度武装的另一个你", "quiet_witness": "沉默见证者",
		"door_watcher": "门前守望者", "last_step_walker": "最后一步行者",
		"broken_promise": "失约残响", "promise_remnant": "守诺的残影",
		"lone_signal": "孤立信号", "chorus_companion": "合唱同伴",
	}
	var ids: Array = echo_ids[selected]
	var echo_id := str(ids[1] if positive else ids[0])
	return {
		"id": echo_id,
		"name": str(names[echo_id]),
		"dimension": selected,
		"pole": str(result.pole),
		"confidence": float(result.confidence),
		"evidence": result.evidence if positive else result.counter_evidence,
		"knowledge": result.knowledge,
		"reason": str(result.interpretation),
	}


func _confidence(sample_size: int, world_count: int, positive: int, negative: int) -> float:
	if sample_size < 2:
		return 0.0
	var sample_factor := minf(float(sample_size) / 8.0, 1.0)
	var context_factor := minf(float(world_count) / 2.0, 1.0)
	var consistency := absf(float(positive - negative)) / float(sample_size)
	return snappedf(clampf(sample_factor * 0.5 + context_factor * 0.2 + consistency * 0.3, 0.0, 0.92), 0.01)


func _knowledge_tag(dimension: String, score: int) -> String:
	var pair: Dictionary = DIMENSIONS[dimension]
	return str(pair.positive if score > 0 else pair.negative)


func _interpretation(dimension: String, pole: String, confidence: float, sample_size: int) -> String:
	if sample_size < 2:
		return "样本不足，暂不判断。"
	if confidence < 0.45:
		return "目前略偏向%s，但不同情境中的证据仍不一致。" % pole
	return "在已观察的游戏情境中，你反复表现出%s倾向。" % pole
