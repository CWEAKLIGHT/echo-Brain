class_name SkillDefinition
extends Resource

## Data-only skill specification. Runtime execution is handled by BattleController.

const TARGET_SELF: StringName = &"self"
const TARGET_SELF_AND_ALLY: StringName = &"self_and_ally"
const TARGET_ACTOR: StringName = &"actor"
const TARGET_CELL: StringName = &"cell"
const TARGET_AREA: StringName = &"area"

const DAMAGE_NONE: StringName = &"none"
const DAMAGE_PHYSICAL: StringName = &"physical"
const DAMAGE_MAGICAL: StringName = &"magical"

@export var skill_id: StringName = &""
@export var display_name_zh: String = ""
@export_multiline var description_zh: String = ""
@export var ap_cost: int = 1
@export var target_mode: StringName = TARGET_SELF
@export var min_range: int = 0
@export var max_range: int = 0
@export var damage_type: StringName = DAMAGE_NONE
@export var damage_multiplier: float = 0.0
@export var effect_id: StringName = &""
@export var duration_player_phases: int = 0
@export var requires_judgment_mark: bool = false
@export var is_passive: bool = false


func is_valid() -> bool:
	if skill_id == &"" or display_name_zh.strip_edges().is_empty():
		return false
	if ap_cost < 0 or (ap_cost == 0 and not is_passive) or (is_passive and ap_cost != 0) or min_range < 0 or max_range < min_range:
		return false
	if target_mode != TARGET_SELF and target_mode != TARGET_SELF_AND_ALLY and target_mode != TARGET_ACTOR and target_mode != TARGET_CELL and target_mode != TARGET_AREA:
		return false
	if damage_multiplier < 0.0 or duration_player_phases < 0:
		return false
	if damage_multiplier > 0.0:
		if damage_type != DAMAGE_PHYSICAL and damage_type != DAMAGE_MAGICAL:
			return false
	elif damage_type != DAMAGE_NONE:
		return false
	if effect_id == &"":
		return false
	return true
