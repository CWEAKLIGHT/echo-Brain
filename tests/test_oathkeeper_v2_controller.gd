extends SceneTree

const ControllerScript = preload("res://scripts/battle/battle_controller.gd")
const ActorScript = preload("res://scripts/actors/battle_actor.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_oath_vow_passive_and_shield_application()
	_test_oath_shield_validation_and_duration()
	print("Oathkeeper v2 controller tests complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _test_oath_vow_passive_and_shield_application() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	_check(battle.start_encounter(Vector2i(1, 1), [Vector2i(2, 1)]), "Oath Vow encounter starts")
	battle.actors["ally_test"] = ActorScript.new("ally_test", "player", Vector2i(1, 2), 1000, "support", 500, 200, 200)

	_check(battle.get_oath_vow_stacks() == 0, "Oath Vow begins with zero stacks")
	_check(battle.request_oath_shield("ally_test"), "Oath Shield can target a nearby allied test unit")
	_check(battle.ap.current == 2, "Oath Shield spends exactly one AP")
	_check(battle.get_actor("sevrin").shield == 195, "Sevrin receives the DEF-scaled base shield")
	_check(battle.get_actor("ally_test").shield == 150, "ally shield independently respects 15 percent max-health cap")
	_check(battle.get_oath_vow_stacks() == 0, "Oath Shield works with zero Oath Vow stacks")

	_check(battle.end_player_turn(), "enemy attack resolves against Sevrin")
	_check(battle.get_oath_vow_stacks() == 1, "successful enemy active attack grants one Oath Vow stack")
	_check(battle.get_actor("sevrin").shield < 195, "incoming damage is absorbed by Sevrin's shield")
	_check(battle.get_actor("sevrin").health < battle.get_actor("sevrin").max_health, "damage beyond shield reduces health")
	_check(battle.get_actor("ally_test").shield == 150, "the ally's independent shield is not affected by Sevrin being hit")

	_check(battle.request_oath_shield("sevrin"), "Oath Shield can target Sevrin alone")
	_check(battle.get_oath_vow_stacks() == 0, "Oath Shield consumes all current Oath Vow stacks")
	_check(battle.get_actor("sevrin").shield >= 214, "one Oath Vow stack increases the newly calculated shield")
	battle.queue_free()


func _test_oath_shield_validation_and_duration() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	_check(battle.start_encounter(Vector2i(1, 1), [Vector2i(7, 7)]), "Oath Shield duration encounter starts")
	battle.actors["ally_near"] = ActorScript.new("ally_near", "player", Vector2i(3, 1), 1000, "support", 500, 200, 200)
	battle.actors["ally_far"] = ActorScript.new("ally_far", "player", Vector2i(4, 1), 1000, "support", 500, 200, 200)

	_check(not battle.request_oath_shield("missing_actor"), "Oath Shield rejects unknown targets")
	_check(not battle.request_oath_shield("vanguard_00"), "Oath Shield rejects enemy targets")
	_check(not battle.request_oath_shield("ally_far"), "Oath Shield rejects allies beyond two Manhattan cells")
	_check(battle.ap.current == 3, "invalid Oath Shield targets do not spend AP")
	_check(battle.request_oath_shield("ally_near"), "Oath Shield accepts an ally exactly two cells away")
	var initial_shield: int = battle.get_actor("sevrin").shield
	_check(initial_shield == 195, "initial self shield matches base formula")
	_check(battle.request_oath_shield("ally_near"), "recasting Oath Shield refreshes duration")
	_check(battle.get_actor("sevrin").shield == initial_shield, "recasting an equal shield does not stack shield values")

	_check(battle.end_player_turn(), "first player turn ends")
	_check(battle.get_actor("sevrin").shield == initial_shield, "shield remains through the first enemy phase and next player turn")
	_check(battle.end_player_turn(), "second player turn ends")
	_check(battle.get_actor("sevrin").shield == 0, "shield expires at the end of the second player turn")
	_check(battle.get_actor("ally_near").shield == 0, "ally shield expires at the same two-turn boundary")
	battle.queue_free()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
