class_name BattleStatusCollection
extends RefCounted

const BattleStatusScript = preload("res://scripts/battle/battle_status.gd")

## actor_id -> Dictionary(status_id -> BattleStatus)
var _statuses_by_actor: Dictionary = {}


func apply_status(
	status_id: StringName,
	source_actor_id: String,
	target_actor_id: String,
	stacks: int = 1,
	max_stacks: int = 1,
	remaining_triggers: int = -1,
	expiry_boundary: StringName = &"",
	stack_policy: StringName = BattleStatusScript.STACK_REFRESH
) -> bool:
	if status_id == &"" or target_actor_id.is_empty():
		return false
	if stacks <= 0 or max_stacks <= 0 or remaining_triggers < -1:
		return false
	if stack_policy != BattleStatusScript.STACK_REPLACE and stack_policy != BattleStatusScript.STACK_REFRESH and stack_policy != BattleStatusScript.STACK_ADD:
		return false

	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	var existing = actor_statuses.get(status_id)
	if existing == null:
		var created: BattleStatus = BattleStatusScript.new(
			status_id,
			source_actor_id,
			target_actor_id,
			stacks,
			max_stacks,
			remaining_triggers,
			expiry_boundary
		)
		if not created.is_valid():
			return false
		actor_statuses[status_id] = created
		_statuses_by_actor[target_actor_id] = actor_statuses
		return true

	var current: BattleStatus = existing as BattleStatus
	match stack_policy:
		BattleStatusScript.STACK_REPLACE:
			current.stacks = mini(stacks, max_stacks)
			current.max_stacks = max_stacks
			current.remaining_triggers = remaining_triggers
			current.source_actor_id = source_actor_id
			current.expiry_boundary = expiry_boundary
		BattleStatusScript.STACK_REFRESH:
			current.stacks = mini(current.stacks, max_stacks)
			current.max_stacks = max_stacks
			current.remaining_triggers = _refresh_trigger_count(current.remaining_triggers, remaining_triggers)
			current.source_actor_id = source_actor_id
			current.expiry_boundary = expiry_boundary
		BattleStatusScript.STACK_ADD:
			current.max_stacks = max_stacks
			current.stacks = mini(current.stacks + stacks, max_stacks)
			current.remaining_triggers = _refresh_trigger_count(current.remaining_triggers, remaining_triggers)
			current.source_actor_id = source_actor_id
			current.expiry_boundary = expiry_boundary
	_statuses_by_actor[target_actor_id] = actor_statuses
	return true


func has_status(target_actor_id: String, status_id: StringName) -> bool:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	return actor_statuses.has(status_id)


func get_status(target_actor_id: String, status_id: StringName) -> BattleStatus:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	var value = actor_statuses.get(status_id)
	if value == null:
		return null
	return value as BattleStatus


func consume_trigger(target_actor_id: String, status_id: StringName) -> bool:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	var value = actor_statuses.get(status_id)
	if value == null:
		return false
	var status: BattleStatus = value as BattleStatus
	if status.remaining_triggers == 0:
		return false
	if status.remaining_triggers > 0:
		status.remaining_triggers -= 1
		if status.remaining_triggers == 0:
			actor_statuses.erase(status_id)
	_statuses_by_actor[target_actor_id] = actor_statuses
	return true


func expire_boundary(target_actor_id: String, boundary: StringName) -> int:
	if boundary == &"":
		return 0
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	var expired_ids: Array[StringName] = []
	for key in actor_statuses.keys():
		var status: BattleStatus = actor_statuses[key] as BattleStatus
		if status.expiry_boundary == boundary:
			expired_ids.append(status.status_id)
	for status_id in expired_ids:
		actor_statuses.erase(status_id)
	if actor_statuses.is_empty():
		_statuses_by_actor.erase(target_actor_id)
	else:
		_statuses_by_actor[target_actor_id] = actor_statuses
	return expired_ids.size()


func remove_status(target_actor_id: String, status_id: StringName) -> bool:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	if not actor_statuses.has(status_id):
		return false
	actor_statuses.erase(status_id)
	if actor_statuses.is_empty():
		_statuses_by_actor.erase(target_actor_id)
	else:
		_statuses_by_actor[target_actor_id] = actor_statuses
	return true


func clear_actor(target_actor_id: String) -> int:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	var removed_count: int = actor_statuses.size()
	_statuses_by_actor.erase(target_actor_id)
	return removed_count


func get_status_count(target_actor_id: String) -> int:
	var actor_statuses: Dictionary = _get_actor_statuses(target_actor_id)
	return actor_statuses.size()


func _get_actor_statuses(actor_id: String) -> Dictionary:
	var value: Variant = _statuses_by_actor.get(actor_id, {})
	if value is Dictionary:
		return value
	return {}


func _refresh_trigger_count(current_count: int, new_count: int) -> int:
	if current_count < 0 or new_count < 0:
		return -1
	return maxi(current_count, new_count)
