extends SceneTree

const CatalogScript = preload("res://scripts/battle/oathkeeper_v2_skill_catalog.gd")
const SkillDefinitionScript = preload("res://scripts/battle/skill_definition.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var skills: Array[SkillDefinition] = CatalogScript.create_prototype_skills()
	_check(skills.size() == 3, "V2 catalog contains exactly three active Oathkeeper skills", failures)
	var ids: Array[StringName] = [&"oathkeeper_judgment_mark", &"oath_shield", &"absolute_guard"]
	for index in range(mini(skills.size(), ids.size())):
		_check(skills[index].skill_id == ids[index], "V2 active skill IDs and order are stable", failures)
		_check(skills[index].is_valid(), "V2 active skill definition is valid: " + String(ids[index]), failures)
	var passive: SkillDefinition = CatalogScript.create_passive_skill()
	_check(passive.is_passive and passive.ap_cost == 0, "Oath Vow is represented as a zero-AP passive", failures)
	_check(passive.is_valid(), "Oath Vow passive definition validates", failures)
	_check(skills[0].ap_cost == 1 and skills[0].damage_multiplier == 0.8 and skills[0].max_range == 4, "Judgment Mark data matches the V2 baseline", failures)
	_check(skills[1].ap_cost == 1 and skills[2].ap_cost == 2, "Oath Shield and Absolute Guard AP costs match the V2 baseline", failures)
	print("Oathkeeper v2 skill catalog test complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
