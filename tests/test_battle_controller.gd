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

	var wait_battle = ControllerScript.new()
	root.add_child(wait_battle)
	var cage: Array[Vector2i] = [Vector2i(4, 5), Vector2i(6, 5), Vector2i(5, 4), Vector2i(5, 6)]
	_check(wait_battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 5)], cage), "blocked-enemy encounter starts")
	_check(wait_battle.intents.size() == 1, "blocked enemy still receives a visible intent")
	_check(wait_battle.intents[0].action_id == "wait", "enemy with no legal pursuit captures wait intent")
	_check(wait_battle.end_player_turn(), "wait intent resolves during enemy phase")
	_check(wait_battle.intents[0].state == IntentScript.IntentState.RESOLVED, "wait intent resolves exactly once")
	_check(wait_battle.get_actor("vanguard_00").cell == Vector2i(5, 5), "waiting enemy remains in place")
	wait_battle.queue_free()


	var marksman_battle = ControllerScript.new()
	root.add_child(marksman_battle)
	var marksman_types: Array[String] = ["marksman"]
	_check(marksman_battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 1)], [], marksman_types), "marksman encounter starts with explicit archetype")
	var shot_intent = marksman_battle.intents[0]
	_check(marksman_battle.get_actor("marksman_00").archetype == "marksman", "enemy archetype is stored on actor")
	_check(marksman_battle.get_actor("marksman_00").max_health == 4, "marksman uses provisional four health")
	_check(shot_intent.action_id == "aimed_shot", "aligned target in range produces aimed shot")
	_check(shot_intent.target_mode == IntentScript.TargetMode.TILE_LOCKED, "aimed shot captures tile lock")
	_check(shot_intent.target_cell == Vector2i(1, 1) and shot_intent.damage == 2, "aimed shot captures marked cell and damage")
	_check(marksman_battle.end_player_turn(), "aimed shot resolves during enemy phase")
	_check(marksman_battle.get_actor("sevrin").health == 8, "aimed shot deals captured two damage")
	_check(shot_intent.state == IntentScript.IntentState.RESOLVED, "aimed shot intent resolves")
	marksman_battle.queue_free()

	var evaded_marksman_battle = ControllerScript.new()
	root.add_child(evaded_marksman_battle)
	_check(evaded_marksman_battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 1)], [], marksman_types), "evadable marksman encounter starts")
	var evaded_shot = evaded_marksman_battle.intents[0]
	var marksman_evade_path: Array[Vector2i] = [Vector2i(1, 2)]
	_check(evaded_marksman_battle.request_player_move(marksman_evade_path), "player can leave marksman marked cell")
	_check(evaded_marksman_battle.end_player_turn(), "evaded marksman phase resolves")
	_check(evaded_marksman_battle.get_actor("sevrin").health == 10, "tile-locked aimed shot does not track moved player")
	_check(evaded_shot.state == IntentScript.IntentState.CANCELED, "aimed shot cancels when marked cell is empty")
	evaded_marksman_battle.queue_free()

	var blocked_marksman_battle = ControllerScript.new()
	root.add_child(blocked_marksman_battle)
	_check(blocked_marksman_battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 1)], [Vector2i(3, 1)], marksman_types), "blocked marksman encounter starts")
	_check(blocked_marksman_battle.intents[0].action_id == "wait", "blocked firing lane produces wait intent")
	blocked_marksman_battle.queue_free()

	var out_of_range_marksman_battle = ControllerScript.new()
	root.add_child(out_of_range_marksman_battle)
	_check(out_of_range_marksman_battle.start_encounter(Vector2i(1, 1), [Vector2i(3, 1)], [], marksman_types), "out-of-range marksman encounter starts")
	_check(out_of_range_marksman_battle.intents[0].action_id == "wait", "target inside minimum range produces wait intent")
	out_of_range_marksman_battle.queue_free()

	var mixed_battle = ControllerScript.new()
	root.add_child(mixed_battle)
	var mixed_types: Array[String] = ["vanguard", "marksman"]
	_check(mixed_battle.start_encounter(Vector2i(1, 1), [Vector2i(2, 1), Vector2i(5, 1)], [], mixed_types), "mixed vanguard and marksman encounter starts")
	_check(mixed_battle.intents.size() == 2, "mixed encounter creates one intent per living enemy")
	_check(mixed_battle.intents[0].action_id == "basic_melee", "vanguard melee is ordered before ranged shot")
	_check(mixed_battle.intents[1].action_id == "aimed_shot", "marksman shot follows vanguard melee in visible order")
	_check(mixed_battle.intents[0].source_actor_id == "vanguard_00" and mixed_battle.intents[1].source_actor_id == "marksman_01", "mixed execution order retains explicit archetype identities")
	_check(mixed_battle.end_player_turn(), "mixed enemy phase resolves")
	_check(mixed_battle.get_actor("sevrin").health == 7, "mixed phase applies melee and ranged damage in order")
	_check(mixed_battle.intents[0].state == IntentScript.IntentState.RESOLVED and mixed_battle.intents[1].state == IntentScript.IntentState.RESOLVED, "both mixed intents resolve")
	mixed_battle.queue_free()

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


	var validation_battle = ControllerScript.new()
	root.add_child(validation_battle)
	_check(validation_battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 5)], [Vector2i(3, 3)]), "validation encounter starts")
	var original_player_cell: Vector2i = validation_battle.get_actor("sevrin").cell
	var original_enemy_cell: Vector2i = validation_battle.get_actor("vanguard_00").cell
	_check(not validation_battle.start_encounter(Vector2i(2, 2), [Vector2i(4, 4), Vector2i(4, 4)]), "duplicate enemy positions are rejected")
	_check(not validation_battle.start_encounter(Vector2i(2, 2), []), "empty enemy roster is rejected")
	var unknown_types: Array[String] = ["sorcerer"]
	_check(not validation_battle.start_encounter(Vector2i(2, 2), [Vector2i(4, 4)], [], unknown_types), "unknown enemy archetype is rejected")
	var mismatched_types: Array[String] = ["vanguard", "marksman"]
	_check(not validation_battle.start_encounter(Vector2i(2, 2), [Vector2i(4, 4)], [], mismatched_types), "mismatched archetype list is rejected")
	_check(validation_battle.get_actor("sevrin").cell == original_player_cell, "invalid setup preserves existing player state")
	_check(validation_battle.get_actor("vanguard_00").cell == original_enemy_cell, "invalid setup preserves existing enemy state")
	_check(validation_battle.blocked_cells.has(Vector2i(3, 3)), "invalid setup preserves existing blockers")
	validation_battle.queue_free()

	print("Battle controller test run complete. Failures: ", failures)
	quit(1 if failures > 0 else 0)
