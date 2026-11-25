extends SceneTree

const MainScene = preload("res://scenes/main/main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_no_default_basic_attack()
	await _test_self_skill_controls()
	await _test_target_skill_flow()
	print("Battle view skill integration test run complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _test_no_default_basic_attack() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	var controller: Variant = view.get("controller")
	_check(int(view.get("selected_skill")) == -1, "battle view starts with no selected player skill")
	_check(view.get("SKILL_BAR").size() == 4, "player skill bar no longer exposes basic attack")
	var enemy = controller.get_actor("vanguard_00")
	var starting_ap: int = controller.ap.current
	_tap_cell(view, enemy.cell)
	_check(controller.ap.current == starting_ap, "clicking an enemy without selecting a skill does not spend AP")
	_check(enemy.health == enemy.max_health, "clicking an enemy without selecting a skill does not attack")
	view.queue_free()
	await process_frame


func _test_self_skill_controls() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	var controller: Variant = view.get("controller")

	_tap_skill(view, 1)
	_check(controller.get_actor("sevrin").shield > 0, "V2 Oath Shield activates from the skill bar")
	_check(controller.ap.current == 2, "V2 Oath Shield spends one AP through the battle view")

	var sevrin = controller.get_actor("sevrin")
	sevrin.ultimate_energy = 5
	_tap_skill(view, 2)
	_check(controller.statuses.has_status("sevrin", &"absolute_guard"), "Absolute Guard activates from the skill bar")
	_check(sevrin.ultimate_energy == 0 and controller.ap.current == 0, "Absolute Guard spends five energy and two AP through the battle view")

	view.queue_free()
	await process_frame


func _test_target_skill_flow() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	var controller: Variant = view.get("controller")
	var marksman = controller.get_actor("marksman_02")
	_check(marksman != null, "main encounter exposes the expected Marksman target")

	_tap_skill(view, 0)
	var cancel_event := InputEventMouseButton.new()
	cancel_event.pressed = true
	cancel_event.button_index = MOUSE_BUTTON_RIGHT
	view.call("_input", cancel_event)
	_check(int(view.get("selected_skill")) == -1, "right mouse cancels target selection without selecting a default attack")
	_tap_skill(view, 0)
	_tap_cell(view, marksman.cell)
	_check(controller.statuses.has_status("marksman_02", &"oathkeeper_mark"), "V2 Judgment Mark can be selected and confirmed on the battlefield")
	_check(controller.ap.current == 2, "V2 Judgment Mark spends one AP through the battle view")
	_check(marksman.health < marksman.max_health, "V2 Judgment Mark deals damage when confirmed")

	_tap_skill(view, 3)
	_tap_cell(view, marksman.cell)
	_check(controller.summon_cooldown_remaining() > 0, "Hunter Summon remains available after the V2 skill bar switch")

	view.queue_free()
	await process_frame


func _tap_skill(view: Node, index: int) -> void:
	var position := Vector2(1090.0, 112.0 + float(index) * 56.0 + 25.0)
	view.call("_handle_tap", position)


func _tap_cell(view: Node, cell: Vector2i) -> void:
	var position := Vector2(384.0 + float(cell.x) * 64.0 + 32.0, 72.0 + float(cell.y) * 64.0 + 32.0)
	view.call("_handle_tap", position)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
