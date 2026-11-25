extends "res://tests/framework/test_case.gd"

const CatalogScript = preload("res://scripts/battle/oathkeeper_skill_catalog.gd")
const SkillDefinitionScript = preload("res://scripts/battle/skill_definition.gd")


func _run() -> void:
	var skills: Array[SkillDefinition] = CatalogScript.create_prototype_skills()
	_check(skills.size() == 5, "five active Oathkeeper skills are defined")
	var expected_ids: Array[StringName] = [
		&"oathguard_stance",
		&"watchwall",
		&"judgment_mark",
		&"echo_counter",
		&"oath_severance"
	]
	for index in range(mini(skills.size(), expected_ids.size())):
		_check(skills[index].skill_id == expected_ids[index], "skill catalog order and stable ID are deterministic")
	for skill in skills:
		_check(skill.is_valid(), "skill definition validates: " + String(skill.skill_id))
		_check(not skill.display_name_zh.is_empty(), "skill has Chinese display name: " + String(skill.skill_id))
	_check(skills[0].ap_cost == 1 and skills[4].ap_cost == 2, "skill AP costs match the design baseline")
	_check(skills[2].target_mode == SkillDefinitionScript.TARGET_ACTOR and skills[2].max_range == 4, "Judgment Mark declares actor targeting and range")
	_check(skills[4].requires_judgment_mark and skills[4].damage_multiplier == 1.4, "Oath Severance declares its mark requirement and multiplier")

	var invalid_skill: SkillDefinition = SkillDefinitionScript.new()
	invalid_skill.skill_id = &"invalid"
	invalid_skill.display_name_zh = "无效技能"
	invalid_skill.ap_cost = 0
	invalid_skill.effect_id = &"test"
	_check(not invalid_skill.is_valid(), "zero-AP skill definition is rejected")

	_report()

