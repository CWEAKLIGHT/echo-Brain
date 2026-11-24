class_name BattleAreaEffect
extends RefCounted

const TARGET_ANY: StringName = &"any"
const TARGET_SAME_TEAM: StringName = &"same_team"
const TARGET_OTHER_TEAM: StringName = &"other_team"
const EFFECT_DAMAGE_REDUCTION: StringName = &"damage_reduction"

var effect_id: StringName = &""
var effect_type: StringName = EFFECT_DAMAGE_REDUCTION
var source_actor_id: String = ""
var source_team: String = ""
var center_cell: Vector2i = Vector2i.ZERO
var affected_cells: Array[Vector2i] = []
var target_relation: StringName = TARGET_ANY
var magnitude: int = 0
var expiry_boundary: StringName = &""


func _init(
	p_effect_id: StringName = &"",
	p_effect_type: StringName = EFFECT_DAMAGE_REDUCTION,
	p_source_actor_id: String = "",
	p_source_team: String = "",
	p_center_cell: Vector2i = Vector2i.ZERO,
	p_affected_cells: Array[Vector2i] = [],
	p_target_relation: StringName = TARGET_ANY,
	p_magnitude: int = 0,
	p_expiry_boundary: StringName = &""
) -> void:
	effect_id = p_effect_id
	effect_type = p_effect_type
	source_actor_id = p_source_actor_id
	source_team = p_source_team
	center_cell = p_center_cell
	affected_cells = p_affected_cells.duplicate()
	target_relation = p_target_relation
	magnitude = p_magnitude
	expiry_boundary = p_expiry_boundary


func is_valid() -> bool:
	if effect_id == &"" or effect_type == &"":
		return false
	if affected_cells.is_empty() or magnitude < 0:
		return false
	if target_relation == TARGET_SAME_TEAM or target_relation == TARGET_OTHER_TEAM:
		if source_team.is_empty():
			return false
	if expiry_boundary == &"":
		return false
	return true


func affects_actor(actor) -> bool:
	if actor == null or not actor.is_alive() or not affected_cells.has(actor.cell):
		return false
	match target_relation:
		TARGET_SAME_TEAM:
			return actor.team == source_team
		TARGET_OTHER_TEAM:
			return actor.team != source_team
		TARGET_ANY:
			return true
		_:
			return false
