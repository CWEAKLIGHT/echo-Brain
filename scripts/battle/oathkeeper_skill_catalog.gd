class_name OathkeeperSkillCatalog
extends RefCounted

const SkillDefinitionScript = preload("res://scripts/battle/skill_definition.gd")


static func create_prototype_skills() -> Array[SkillDefinition]:
	var skills: Array[SkillDefinition] = []
	skills.append(_make_skill(&"oathguard_stance", "誓盾架势", "进入防御姿态，抵御下一次攻击并为反制蓄势。", 1, SkillDefinitionScript.TARGET_SELF, 0, 0, SkillDefinitionScript.DAMAGE_NONE, 0.0, &"oathguard", 1, false))
	skills.append(_make_skill(&"watchwall", "守望壁垒", "在当前位置周围建立十字形守护区域。", 1, SkillDefinitionScript.TARGET_SELF, 0, 1, SkillDefinitionScript.DAMAGE_NONE, 0.0, &"watchwall", 1, false))
	skills.append(_make_skill(&"judgment_mark", "裁决印记", "标记一名敌人，干预其下一次攻击并制造破绽。", 1, SkillDefinitionScript.TARGET_ACTOR, 1, 4, SkillDefinitionScript.DAMAGE_NONE, 0.0, &"judgment_mark", 1, false))
	skills.append(_make_skill(&"echo_counter", "回响反击", "预备反击；敌方攻击命中瑟弗林时进行回应。", 1, SkillDefinitionScript.TARGET_SELF, 0, 0, SkillDefinitionScript.DAMAGE_PHYSICAL, 0.8, &"echo_counter", 1, false))
	skills.append(_make_skill(&"oath_severance", "誓约裁断", "消耗目标身上的裁决印记，打断其尚未执行的意图。", 2, SkillDefinitionScript.TARGET_ACTOR, 1, 2, SkillDefinitionScript.DAMAGE_PHYSICAL, 1.4, &"oath_severance", 0, true))
	return skills


static func _make_skill(
	p_skill_id: StringName,
	p_name_zh: String,
	p_description_zh: String,
	p_ap_cost: int,
	p_target_mode: StringName,
	p_min_range: int,
	p_max_range: int,
	p_damage_type: StringName,
	p_damage_multiplier: float,
	p_effect_id: StringName,
	p_duration: int,
	p_requires_mark: bool
) -> SkillDefinition:
	var skill: SkillDefinition = SkillDefinitionScript.new()
	skill.skill_id = p_skill_id
	skill.display_name_zh = p_name_zh
	skill.description_zh = p_description_zh
	skill.ap_cost = p_ap_cost
	skill.target_mode = p_target_mode
	skill.min_range = p_min_range
	skill.max_range = p_max_range
	skill.damage_type = p_damage_type
	skill.damage_multiplier = p_damage_multiplier
	skill.effect_id = p_effect_id
	skill.duration_player_phases = p_duration
	skill.requires_judgment_mark = p_requires_mark
	return skill
