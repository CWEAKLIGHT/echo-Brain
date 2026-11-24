class_name BattleController
extends Node

signal battle_event(event: Dictionary)
signal battle_finished(result: String)

const GridRulesScript = preload("res://scripts/battle/grid_rules.gd")
const APBudgetScript = preload("res://scripts/battle/ap_budget.gd")
const BattleActorScript = preload("res://scripts/actors/battle_actor.gd")
const BattleIntentScript = preload("res://scripts/battle/battle_intent.gd")

enum BattlePhase { PLAYER, ENEMY, FINISHED }

@export var grid_size: Vector2i = Vector2i(8, 8)
@export var player_ap: int = 3

var phase: BattlePhase = BattlePhase.FINISHED
var ap
var actors: Dictionary = {}
var blocked_cells: Dictionary = {}
var intents: Array = []
var event_sequence: int = 0
var turn_number: int = 0
var battle_result: String = ""


func _ready() -> void:
	ap = APBudgetScript.new(player_ap)


func start_encounter(
	player_cell: Vector2i,
	enemy_cells: Array[Vector2i],
	obstacles: Array[Vector2i] = []
) -> bool:
	# Validate the complete setup before mutating live encounter state.
	if not GridRulesScript.is_inside_bounds(player_cell, grid_size):
		return false
	var candidate_blockers: Dictionary = {}
	for cell in obstacles:
		if not GridRulesScript.is_inside_bounds(cell):
			return false
		candidate_blockers[cell] = true
	if candidate_blockers.has(player_cell):
		return false

	var candidate_enemy_cells: Dictionary = {}
	for cell in enemy_cells:
		if not GridRulesScript.is_inside_bounds(cell) or cell == player_cell:
			return false
		if candidate_blockers.has(cell) or candidate_enemy_cells.has(cell):
			return false
		candidate_enemy_cells[cell] = true

	actors.clear()
	blocked_cells = candidate_blockers
	intents.clear()
	event_sequence = 0
	turn_number = 0
	battle_result = ""
	actors["sevrin"] = BattleActorScript.new("sevrin", "player", player_cell, 10)
	for index in range(enemy_cells.size()):
		var cell: Vector2i = enemy_cells[index]
		var enemy_id := "vanguard_%02d" % index
		actors[enemy_id] = BattleActorScript.new(enemy_id, "enemy", cell, 6)

	phase = BattlePhase.PLAYER
	_begin_player_turn()
	return true


func get_occupied_cells(exclude_actor_id: String = "") -> Dictionary:
	var occupied := {}
	for actor_id in actors:
		var actor = actors[actor_id]
		if actor_id != exclude_actor_id and actor.is_alive():
			occupied[actor.cell] = actor_id
	return occupied


func get_actor(actor_id: String):
	return actors.get(actor_id)


func request_player_move(path: Array[Vector2i]) -> bool:
	if phase != BattlePhase.PLAYER or not actors.has("sevrin"):
		return false
	var player = actors["sevrin"]
	if not player.is_alive() or not ap.can_spend(1):
		return false
	if not GridRulesScript.is_path_legal(player.cell, path, grid_size, blocked_cells, get_occupied_cells("sevrin"), 2):
		_emit_event("action_rejected", "sevrin", "", "invalid_move")
		return false
	if not ap.spend(1):
		return false
	player.cell = path[path.size() - 1]
	_emit_event("actor_moved", "sevrin", "", str(player.cell))
	_check_battle_end()
	return true


func request_player_attack(target_actor_id: String, damage: int = 2) -> bool:
	if phase != BattlePhase.PLAYER or not actors.has("sevrin") or not actors.has(target_actor_id):
		return false
	var player = actors["sevrin"]
	var target = actors[target_actor_id]
	if not player.is_alive() or not target.is_alive() or target.team != "enemy":
		return false
	if GridRulesScript.manhattan_distance(player.cell, target.cell) != 1:
		return false
	if damage <= 0 or not ap.can_spend(1):
		return false
	if not ap.spend(1):
		return false
	_apply_damage(target_actor_id, damage, "sevrin", "player_attack")
	_emit_event("attack_resolved", "sevrin", target_actor_id, "damage=%d" % damage)
	_check_battle_end()
	return true


func end_player_turn() -> bool:
	if phase != BattlePhase.PLAYER:
		return false
	ap.clear()
	phase = BattlePhase.ENEMY
	_emit_event("turn_ended", "sevrin", "", "turn=%d" % turn_number)
	_resolve_enemy_phase()
	return true


func _begin_player_turn() -> void:
	turn_number += 1
	ap.reset()
	phase = BattlePhase.PLAYER
	intents = _generate_enemy_intents()
	_emit_event("player_turn_started", "sevrin", "", "turn=%d" % turn_number)


func _generate_enemy_intents() -> Array:
	var generated: Array = []
	var occupied := get_occupied_cells()
	for actor_id in actors:
		var enemy = actors[actor_id]
		if not enemy.is_alive() or enemy.team != "enemy":
			continue
		var target = actors["sevrin"]
		if not target.is_alive():
			continue
		var distance: int = GridRulesScript.manhattan_distance(enemy.cell, target.cell)
		var intent = null
		if distance == 2 and GridRulesScript.has_clear_orthogonal_line(enemy.cell, target.cell, blocked_cells, occupied):
			intent = BattleIntentScript.new("intent_%d_%s" % [turn_number, actor_id], actor_id, "charged_strike", BattleIntentScript.TargetMode.TILE_LOCKED, "", target.cell, [target.cell], 2, 0)
		elif distance == 1:
			intent = BattleIntentScript.new("intent_%d_%s" % [turn_number, actor_id], actor_id, "basic_melee", BattleIntentScript.TargetMode.ACTOR_LOCKED, "sevrin", target.cell, [target.cell], 1, 1)
		else:
			var pursuit_path: Array[Vector2i] = _next_pursuit_path(enemy.cell, target.cell, actor_id, 2)
			if not pursuit_path.is_empty():
				intent = BattleIntentScript.new("intent_%d_%s" % [turn_number, actor_id], actor_id, "pursuit", BattleIntentScript.TargetMode.NONE, "", pursuit_path[pursuit_path.size() - 1], pursuit_path, 0, 2)
		if intent != null:
			generated.append(intent)
	generated.sort_custom(func(a, b):
		if a.execution_priority != b.execution_priority:
			return a.execution_priority < b.execution_priority
		var source_a = actors[a.source_actor_id]
		var source_b = actors[b.source_actor_id]
		if source_a.cell.y != source_b.cell.y:
			return source_a.cell.y < source_b.cell.y
		if source_a.cell.x != source_b.cell.x:
			return source_a.cell.x < source_b.cell.x
		return a.source_actor_id < b.source_actor_id
	)
	return generated


func _next_pursuit_path(start: Vector2i, goal: Vector2i, actor_id: String, max_steps: int) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var came_from := {start: start}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var occupied := get_occupied_cells(actor_id)
	var found_cell := start
	var found := false
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if GridRulesScript.manhattan_distance(current, goal) == 1:
			found_cell = current
			found = true
			break
		for direction in directions:
			var next: Vector2i = current + direction
			if not GridRulesScript.is_inside_bounds(next, grid_size):
				continue
			if blocked_cells.has(next) or occupied.has(next) or came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)
	if not found or found_cell == start:
		return []
	var reversed_path: Array[Vector2i] = []
	var cursor: Vector2i = found_cell
	while cursor != start:
		reversed_path.push_front(cursor)
		cursor = came_from[cursor]
	var result: Array[Vector2i] = []
	for index in range(mini(max_steps, reversed_path.size())):
		result.append(reversed_path[index])
	return result


func _resolve_enemy_phase() -> void:
	for intent in intents:
		if phase == BattlePhase.FINISHED:
			break
		if intent.state != BattleIntentScript.IntentState.ACTIVE:
			continue
		if not actors.has(intent.source_actor_id) or not actors[intent.source_actor_id].is_alive():
			intent.cancel("source_defeated")
			continue
		match intent.action_id:
			"basic_melee":
				_resolve_actor_locked_attack(intent)
			"charged_strike":
				_resolve_tile_locked_attack(intent)
			"pursuit":
				_resolve_pursuit(intent)
			_:
				intent.cancel("unknown_action")
		_check_battle_end()
		if phase == BattlePhase.FINISHED:
			break
	if phase != BattlePhase.FINISHED:
		_begin_player_turn()


func _resolve_actor_locked_attack(intent) -> void:
	if not actors.has(intent.target_actor_id) or not actors[intent.target_actor_id].is_alive():
		intent.cancel("actor_target_defeated")
		return
	_apply_damage(intent.target_actor_id, intent.damage, intent.source_actor_id, intent.action_id)
	intent.mark_resolved()
	_emit_event("enemy_action_resolved", intent.source_actor_id, intent.target_actor_id, intent.action_id)


func _resolve_tile_locked_attack(intent) -> void:
	var target_id := ""
	for actor_id in actors:
		var candidate = actors[actor_id]
		if candidate.is_alive() and candidate.team == "player" and candidate.cell == intent.target_cell:
			target_id = actor_id
			break
	if target_id == "":
		intent.cancel("marked_cell_empty")
		return
	var source = actors[intent.source_actor_id]
	if not GridRulesScript.has_clear_orthogonal_line(source.cell, intent.target_cell, blocked_cells, get_occupied_cells(intent.source_actor_id)):
		intent.cancel("marked_cell_line_blocked")
		return
	_apply_damage(target_id, intent.damage, intent.source_actor_id, intent.action_id)
	intent.mark_resolved()
	_emit_event("enemy_action_resolved", intent.source_actor_id, target_id, intent.action_id)


func _resolve_pursuit(intent) -> void:
	var source = actors[intent.source_actor_id]
	var path: Array = intent.affected_cells
	if path.is_empty() or path.size() > 2:
		intent.cancel("invalid_pursuit_path")
		return
	var cursor: Vector2i = source.cell
	for destination in path:
		if not GridRulesScript.is_inside_bounds(destination, grid_size):
			intent.cancel("destination_out_of_bounds")
			return
		if blocked_cells.has(destination) or get_occupied_cells(intent.source_actor_id).has(destination):
			intent.cancel("destination_blocked")
			return
		if GridRulesScript.manhattan_distance(cursor, destination) != 1:
			intent.cancel("destination_not_adjacent")
			return
		cursor = destination
	source.cell = cursor
	intent.mark_resolved()
	_emit_event("enemy_action_resolved", intent.source_actor_id, "", "pursuit")


func _apply_damage(target_actor_id: String, amount: int, source_actor_id: String, action_id: String) -> void:
	var target = actors[target_actor_id]
	var applied: int = target.apply_damage(amount)
	_emit_event("damage_applied", source_actor_id, target_actor_id, "action=%s damage=%d health=%d" % [action_id, applied, target.health])
	if target.is_defeated and target.team == "enemy":
		for intent in intents:
			if intent.source_actor_id == target_actor_id:
				intent.cancel("source_defeated")
		_emit_event("actor_defeated", target_actor_id, "", "enemy")


func _check_battle_end() -> void:
	if phase == BattlePhase.FINISHED:
		return
	if actors.has("sevrin") and not actors["sevrin"].is_alive():
		_finish_battle("defeat")
		return
	var living_enemies := 0
	for actor in actors.values():
		if actor.team == "enemy" and actor.is_alive():
			living_enemies += 1
	if living_enemies == 0:
		_finish_battle("victory")


func _finish_battle(result: String) -> void:
	if phase == BattlePhase.FINISHED:
		return
	phase = BattlePhase.FINISHED
	battle_result = result
	for intent in intents:
		if intent.state == BattleIntentScript.IntentState.ACTIVE:
			intent.cancel("battle_finished")
	battle_finished.emit(result)
	_emit_event("battle_" + result, "", "", result)


func _emit_event(event_type: String, actor_id: String, target_id: String, detail: String) -> void:
	event_sequence += 1
	battle_event.emit({
		"sequence": event_sequence,
		"turn": turn_number,
		"type": event_type,
		"actor_id": actor_id,
		"target_id": target_id,
		"detail": detail
	})
