extends SceneTree

const ControllerScript = preload("res://scripts/battle/battle_controller.gd")
const IntentScript = preload("res://scripts/battle/battle_intent.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func _run() -> void:
	var charge_battle = ControllerScript.new()
	root.add_child(charge_battle)
	_check(charge_battle.start_encounter(Vector2i(1, 1), [Vector2i(3, 1)]), "encounter starts with valid positions")
	_check(charge_battle.intents.size() == 1, "one eligible enemy produces one intent")
	var charge_intent = charge_battle.intents[0]
	_check(charge_intent.action_id == "charged_strike", "distance-two aligned enemy selects charged strike")
	_check(charge_intent.target_mode == IntentScript.TargetMode.TILE_LOCKED, "charged strike captures tile lock")
	_check(charge_intent.target_cell == Vector2i(1, 1), "charged strike captures original player cell")
	var evade_path: Array[Vector2i] = [Vector2i(1, 2)]
	_check(charge_battle.request_player_move(evade_path), "player can move away from marked cell")
	_check(charge_battle.end_player_turn(), "player can end turn")
	_check(charge_battle.get_actor("sevrin").health == 10, "tile-locked strike does not follow a moved actor")
	_check(charge_intent.state == IntentScript.IntentState.CANCELED, "empty marked cell cancels tile-locked strike")
	charge_battle.queue_free()

	var pursuit_battle = ControllerScript.new()
	root.add_child(pursuit_battle)
	_check(pursuit_battle.start_encounter(Vector2i(1, 1), [Vector2i(4, 1)]), "second encounter starts")
	var pursuit_intent = pursuit_battle.intents[0]
	_check(pursuit_intent.action_id == "pursuit", "distant enemy selects pursuit")
	_check(pursuit_intent.affected_cells.size() == 2, "pursuit captures a path of up to two cells")
	_check(pursuit_battle.end_player_turn(), "pursuit enemy phase resolves")
	_check(pursuit_battle.get_actor("vanguard_00").cell == Vector2i(2, 1), "pursuit moves two cells toward target")
	pursuit_battle.queue_free()


	var actor_lock_battle = ControllerScript.new()
	root.add_child(actor_lock_battle)
	_check(actor_lock_battle.start_encounter(Vector2i(1, 1), [Vector2i(2, 1)]), "actor-lock encounter starts")
	var actor_intent = actor_lock_battle.intents[0]
	_check(actor_intent.target_mode == IntentScript.TargetMode.ACTOR_LOCKED, "adjacent basic attack captures actor lock")
	var retreat_path: Array[Vector2i] = [Vector2i(1, 2), Vector2i(1, 3)]
	_check(actor_lock_battle.request_player_move(retreat_path), "player can retreat two cells after telegraph")
	_check(actor_lock_battle.end_player_turn(), "actor-lock enemy phase resolves")
	_check(actor_lock_battle.get_actor("sevrin").health == 9, "actor-locked attack tracks target after it moves")
	actor_lock_battle.queue_free()

	var terminal_battle = ControllerScript.new()
	root.add_child(terminal_battle)
	_check(terminal_battle.start_encounter(Vector2i(2, 2), [Vector2i(2, 1), Vector2i(1, 2)]), "terminal-order encounter starts")
	terminal_battle.get_actor("sevrin").health = 1
	_check(terminal_battle.end_player_turn(), "terminal encounter enters enemy phase")
	_check(terminal_battle.phase == ControllerScript.BattlePhase.FINISHED, "player defeat ends battle immediately")
	_check(terminal_battle.battle_result == "defeat", "terminal result is defeat")
	_check(terminal_battle.intents[1].state == IntentScript.IntentState.CANCELED, "remaining enemy intent is canceled after terminal result")
	terminal_battle.queue_free()

	print("Battle controller test run complete. Failures: ", failures)
	quit(1 if failures > 0 else 0)
