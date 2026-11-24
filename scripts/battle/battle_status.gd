class_name BattleStatus
extends RefCounted

const STACK_REPLACE: StringName = &"replace"
const STACK_REFRESH: StringName = &"refresh"
const STACK_ADD: StringName = &"add"

var status_id: StringName = &""
var source_actor_id: String = ""
var target_actor_id: String = ""
var stacks: int = 1
var max_stacks: int = 1
## -1 means unlimited triggers; 0 means consumed/invalid.
var remaining_triggers: int = -1
## Empty means no automatic phase-boundary expiry.
var expiry_boundary: StringName = &""


func _init(
	p_status_id: StringName = &"",
	p_source_actor_id: String = "",
	p_target_actor_id: String = "",
	p_stacks: int = 1,
	p_max_stacks: int = 1,
	p_remaining_triggers: int = -1,
	p_expiry_boundary: StringName = &""
) -> void:
	status_id = p_status_id
	source_actor_id = p_source_actor_id
	target_actor_id = p_target_actor_id
	max_stacks = maxi(1, p_max_stacks)
	stacks = clampi(p_stacks, 1, max_stacks)
	remaining_triggers = p_remaining_triggers
	expiry_boundary = p_expiry_boundary


func is_valid() -> bool:
	if status_id == &"" or target_actor_id.is_empty():
		return false
	if stacks <= 0 or max_stacks <= 0 or stacks > max_stacks:
		return false
	if remaining_triggers < -1:
		return false
	return true
