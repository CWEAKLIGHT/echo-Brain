extends "res://tests/framework/test_case.gd"

const CatalogScript = preload("res://scripts/battle/oathkeeper_v2_skill_catalog.gd")
const SkillDefinitionScript = preload("res://scripts/battle/skill_definition.gd")


func _run() -> void:
	var skills: Array[SkillDefinition] = CatalogScript.create_prototype_skills()
	_check(skills.size() == 3, "V2 catalog contains exactly three active Oathkeeper skills")
	var ids: Array[StringName] = [&"oathkeeper_judgment_mark", &"oath_shield", &"absolute_guard"]
	for index in range(mini(skills.size(), ids.size())):
		_check(skills[index].skill_id == ids[index], "V2 active skill IDs and order are stable")
		_check(skills[index].is_valid(), "V2 active skill definition is valid: " + String(ids[index]))
	var passive: SkillDefinition = CatalogScript.create_passive_skill()
	_check(passive.is_passive and passive.ap_cost == 0, "Oath Vow is represented as a zero-AP passive")
	_check(passive.is_valid(), "Oath Vow passive definition validates")
	_check(skills[0].ap_cost == 1 and skills[0].damage_multiplier == 0.8 and skills[0].max_range == 4, "Judgment Mark data matches the V2 baseline")
	_check(skills[1].ap_cost == 1 and skills[2].ap_cost == 2, "Oath Shield and Absolute Guard AP costs match the V2 baseline")
	_check(skills[1].target_mode == SkillDefinitionScript.TARGET_SELF_AND_ALLY and skills[1].min_range == 0 and skills[1].max_range == 2, "Oath Shield metadata represents Sevrin plus one ally within two cells")
	_report()

