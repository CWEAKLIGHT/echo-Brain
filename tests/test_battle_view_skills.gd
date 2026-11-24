extends SceneTree

const MainScene = preload("res://scenes/main/main.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_self_skill_controls()
	await _test_target_skill_flow()
	print("Battle view skill integration test run complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _test_self_skill_controls() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	var controller: Variant = view.get("controller")

	var oathguard_key := InputEventKey.new()
	oathguard_key.pressed = true
	oathguard_key.keycode = KEY_2
	view.call("_input", oathguard_key)
	_check(controller.statuses.has_status("sevrin", &"oathguard"), "keyboard shortcut 2 activates Oathguard Stance")
	_check(controller.ap.current == 2, "Oathguard Stance spends one AP through the battle view")

	_tap_skill(view, 2)
	_check(controller.area_effects.get_effect(&"watchwall") != null, "mouse skill button activates Watchwall")
	_check(controller.ap.current == 1, "Watchwall spends one AP through the battle view")

	_tap_skill(view, 4)
	_check(controller.statuses.has_status("sevrin", &"echo_counter"), "mouse skill button prepares Echo Counter")
	_check(controller.ap.current == 0, "Echo Counter spends one AP through the battle view")

	view.queue_free()
	await process_frame


func _test_target_skill_flow() -> void:
	var view: Node = MainScene.instantiate()
	root.add_child(view)
	await process_frame
	var controller: Variant = view.get("controller")
	var marksman = controller.get_actor("marksman_02")
	_check(marksman != null, "main encounter exposes the expected Marksman target")

	_tap_skill(view, 3)
	var cancel_event := InputEventMouseButton.new()
	cancel_event.pressed = true
	cancel_event.button_index = MOUSE_BUTTON_RIGHT
	view.call("_input", cancel_event)
	_check(int(view.get("selected_skill")) == 0, "right mouse cancels target selection before confirmation")
	_tap_skill(view, 3)
	_tap_cell(view, Vector2i(1, 0))
	_check(controller.statuses.has_status("marksman_02", &"judgment_mark"), "Judgment Mark can be selected and confirmed on the battlefield")
	_check(controller.ap.current == 2, "Judgment Mark spends one AP through the battle view")

	marksman.cell = Vector2i(2, 3)
	_tap_skill(view, 5)
	_tap_cell(view, Vector2i(2, 3))
	_check(not controller.statuses.has_status("marksman_02", &"judgment_mark"), "Oath Severance consumes the selected target's Judgment Mark")
	_check(marksman.is_defeated, "Oath Severance applies its damage through the battle view")
	_check(controller.intents.any(func(intent): return intent.source_actor_id == "marksman_02" and intent.cancel_reason == "oath_severance"), "Oath Severance interrupts the target's active intent")
	_check(controller.ap.current == 0, "Judgment Mark plus Oath Severance spends three AP through the battle view")

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
