class_name CuratorV2
extends RefCounted

var profiler := HumanityProfile.new()


func assess(events: Array[Dictionary], world_state: WorldStateStore) -> Dictionary:
	var profile := profiler.analyze(events)
	var echo := profiler.generate_echo(profile)
	var prediction := _prediction(profile)
	return {
		"profile": profile,
		"echo": echo,
		"prediction": prediction,
		"counterplay": "你可以故意选择相反行为来反驳司仪；系统会保留相反证据，而不是隐藏它。",
		"trailer": next_episode(world_state, echo, prediction),
	}


func offer_contract(assessment: Dictionary, world_id: String) -> Dictionary:
	var prediction: Dictionary = assessment.get("prediction", {})
	var dimension := str(prediction.get("dimension", ""))
	if dimension.is_empty():
		return {
			"id": "observe_once",
			"title": "再观察一次",
			"world_id": world_id,
			"temptation": "完成一次有效选择",
			"success_event": "run_settled",
			"reward": 1,
			"risk_budget": 0,
		}
	var expected_positive := float(prediction.get("expected_score", 0.0)) > 0.0
	var opposing_events := {
		"responsibility": ["abandon", "rescue"],
		"loyalty": ["faction_betrayal", "faction_help"],
		"restraint": ["attack_neutral", "spare_neutral"],
		"risk": ["safe_choice", "risk_choice"],
		"commitment": ["promise_broken", "promise_kept"],
		"belonging": ["independent_choice", "follow_group"],
	}
	var pair: Array = opposing_events.get(dimension, ["run_settled", "run_settled"])
	var challenge_event := str(pair[0] if expected_positive else pair[1])
	return {
		"id": "contradict_%s" % dimension,
		"title": "反驳司仪：%s" % dimension,
		"world_id": world_id,
		"temptation": "作出与既有倾向相反且有代价的选择",
		"success_event": challenge_event,
		"reward": 2,
		"risk_budget": 1,
		"evidence": prediction.get("evidence", []),
	}


func evaluate_prediction(prediction: Dictionary, new_events: Array[Dictionary]) -> Dictionary:
	var dimension := str(prediction.get("dimension", ""))
	if dimension.is_empty():
		return {"resolved": false, "reason": "没有可验证预测"}
	var before := float(prediction.get("expected_score", 0.0))
	var updated := profiler.analyze(new_events)
	var result: Dictionary = updated.get("dimensions", {}).get(dimension, {})
	if int(result.get("sample_size", 0)) == 0:
		return {"resolved": false, "reason": "本局没有相关行为"}
	var after := float(result.get("score", 0.0))
	return {
		"resolved": true,
		"prediction_correct": signf(before) == signf(after),
		"expected_score": before,
		"observed_score": after,
		"dimension": dimension,
	}


func next_episode(world_state: WorldStateStore, echo: Dictionary, prediction: Dictionary) -> String:
	var region_id := "sanatorium"
	var lowest_safety := 101
	for candidate in world_state.regions:
		var safety := int(world_state.regions[candidate].get("safety", 0))
		if safety < lowest_safety:
			lowest_safety = safety
			region_id = str(candidate)
	var echo_name := str(echo.get("name", "未成形的回声"))
	var pole := str(prediction.get("pole", "未知"))
	return "下一集：%s 的安全度正在下降；%s 将用一次%s选择验证你。" % [region_id, echo_name, pole]


func _prediction(profile: Dictionary) -> Dictionary:
	var best_dimension := ""
	var best_strength := 0.0
	var best_result := {}
	for dimension in profile.get("dimensions", {}):
		var result: Dictionary = profile.dimensions[dimension]
		var strength := absf(float(result.get("score", 0))) * float(result.get("confidence", 0.0))
		if int(result.get("sample_size", 0)) >= 2 and strength > best_strength:
			best_strength = strength
			best_dimension = str(dimension)
			best_result = result
	if best_dimension.is_empty():
		return {"dimension": "", "confidence": 0.0, "explanation": "证据不足，不作预测"}
	return {
		"dimension": best_dimension,
		"pole": str(best_result.pole),
		"expected_score": float(best_result.score),
		"confidence": float(best_result.confidence),
		"evidence": best_result.evidence if float(best_result.score) > 0 else best_result.counter_evidence,
		"knowledge": best_result.knowledge,
		"explanation": "根据跨局行为证据预测下一次相关选择；这不是人格定论。",
	}
