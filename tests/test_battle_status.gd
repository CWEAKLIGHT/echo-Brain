extends SceneTree

const BattleStatusScript = preload("res://scripts/battle/battle_status.gd")
const StatusCollectionScript = preload("res://scripts/battle/battle_status_collection.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var statuses: BattleStatusCollection = StatusCollectionScript.new()

	_check(statuses.apply_status(&"oathguard", "sevrin", "sevrin", 1, 1, 1, &"enemy_phase_end"), "one-trigger defensive status can be applied", failures)
	_check(statuses.has_status("sevrin", &"oathguard"), "applied status can be queried", failures)
	var guard: BattleStatus = statuses.get_status("sevrin", &"oathguard")
	_check(guard != null and guard.remaining_triggers == 1, "status exposes remaining trigger count", failures)
	_check(statuses.consume_trigger("sevrin", &"oathguard"), "status trigger can be consumed", failures)
	_check(not statuses.has_status("sevrin", &"oathguard"), "status is removed after final trigger", failures)

	_check(statuses.apply_status(&"judgment_mark", "sevrin", "marksman", 1, 1, 1, &"enemy_phase_end"), "judgment mark can be applied to another actor", failures)
	_check(statuses.expire_boundary("marksman", &"enemy_phase_end") == 1, "phase boundary expires matching status", failures)
	_check(not statuses.has_status("marksman", &"judgment_mark"), "expired status is no longer present", failures)

	_check(statuses.apply_status(&"exposed", "sevrin", "vanguard", 1, 3, -1, &""), "unlimited status can be applied", failures)
	_check(statuses.apply_status(&"exposed", "sevrin", "vanguard", 1, 3, -1, &"", BattleStatusScript.STACK_ADD), "stack policy adds stacks", failures)
	var exposed: BattleStatus = statuses.get_status("vanguard", &"exposed")
	_check(exposed != null and exposed.stacks == 2, "additive stack policy increments stacks", failures)
	_check(statuses.apply_status(&"exposed", "sevrin", "vanguard", 1, 3, 2, &"player_phase_start", BattleStatusScript.STACK_REFRESH), "refresh policy is accepted", failures)
	exposed = statuses.get_status("vanguard", &"exposed")
	_check(exposed != null and exposed.remaining_triggers == 2 and exposed.expiry_boundary == &"player_phase_start", "refresh policy resets trigger count and expiry boundary", failures)
	exposed = statuses.get_status("vanguard", &"exposed")
	_check(exposed != null and exposed.stacks == 2, "refresh policy preserves existing stack count", failures)
	_check(statuses.apply_status(&"exposed", "sevrin", "vanguard", 1, 3, -1, &"", BattleStatusScript.STACK_REPLACE), "replace policy is accepted", failures)
	exposed = statuses.get_status("vanguard", &"exposed")
	_check(exposed != null and exposed.stacks == 1, "replace policy resets stack count", failures)

	_check(not statuses.apply_status(&"", "sevrin", "vanguard"), "empty status ID is rejected", failures)
	_check(not statuses.apply_status(&"invalid", "sevrin", "vanguard", 0), "zero stack application is rejected", failures)
	_check(statuses.remove_status("vanguard", &"exposed"), "status can be removed explicitly", failures)
	_check(statuses.clear_actor("marksman") == 0, "clearing an actor with no statuses is safe", failures)
	_check(statuses.clear_actor("vanguard") == 0, "cleared status collection remains empty", failures)

	print("Battle status test run complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
