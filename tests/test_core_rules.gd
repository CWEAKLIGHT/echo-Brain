extends SceneTree

const GridRulesScript = preload("res://scripts/battle/grid_rules.gd")
const APBudgetScript = preload("res://scripts/battle/ap_budget.gd")
const BattleActorScript = preload("res://scripts/actors/battle_actor.gd")

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
	var blocked := {}
	var occupied := {}

	var one_step: Array[Vector2i] = [Vector2i(1, 0)]
	_check(GridRulesScript.is_path_legal(Vector2i.ZERO, one_step, Vector2i(8, 8), blocked, occupied), "one orthogonal step is legal")

	var two_steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
	_check(GridRulesScript.is_path_legal(Vector2i.ZERO, two_steps, Vector2i(8, 8), blocked, occupied), "two orthogonal steps are legal")

	var diagonal: Array[Vector2i] = [Vector2i(1, 1)]
	_check(not GridRulesScript.is_path_legal(Vector2i.ZERO, diagonal, Vector2i(8, 8), blocked, occupied), "diagonal step is rejected")

	var too_long: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	_check(not GridRulesScript.is_path_legal(Vector2i.ZERO, too_long, Vector2i(8, 8), blocked, occupied), "path longer than two cells is rejected")

	blocked[Vector2i(1, 0)] = true
	_check(not GridRulesScript.is_path_legal(Vector2i.ZERO, one_step, Vector2i(8, 8), blocked, occupied), "blocked cell is rejected")
	blocked.clear()

	occupied[Vector2i(1, 0)] = true
	_check(not GridRulesScript.is_path_legal(Vector2i.ZERO, one_step, Vector2i(8, 8), blocked, occupied), "occupied cell is rejected")
	occupied.clear()

	var ap = APBudgetScript.new(3)
	_check(ap.current == 3, "AP starts at maximum")
	_check(ap.spend(2) and ap.current == 1, "AP spend succeeds once")
	_check(not ap.spend(2) and ap.current == 1, "insufficient AP does not mutate budget")
	ap.clear()
	_check(ap.current == 0, "ending turn clears unused AP")
	ap.reset()
	_check(ap.current == 3, "new turn resets AP")

	var actor = BattleActorScript.new("test_enemy", "enemy", Vector2i(3, 3), 3)
	_check(actor.apply_damage(2) == 2 and actor.health == 1 and actor.is_alive(), "damage reduces health deterministically")
	_check(actor.apply_damage(5) == 1 and actor.health == 0 and actor.is_defeated, "lethal damage clamps health to zero and defeats actor")
	_check(actor.apply_damage(1) == 0, "defeated actor cannot take additional damage")

	print("Core rules test run complete. Failures: ", failures)
	quit(1 if failures > 0 else 0)
