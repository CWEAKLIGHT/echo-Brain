extends Node2D

const ControllerScript = preload("res://scripts/battle/battle_controller.gd")
const CELL_SIZE: float = 64.0
const BOARD_ORIGIN := Vector2(384.0, 72.0)
const BOARD_SIZE := 8
const END_TURN_RECT := Rect2(1010.0, 620.0, 210.0, 64.0)

var controller
var status_message: String = "Tap a cell to move. Tap an adjacent enemy to attack."


func _ready() -> void:
	controller = ControllerScript.new()
	add_child(controller)
	controller.battle_event.connect(_on_battle_event)
	controller.battle_finished.connect(_on_battle_finished)
	controller.start_encounter(
		Vector2i(1, 3),
		[Vector2i(5, 3), Vector2i(6, 6)],
		[Vector2i(3, 1), Vector2i(3, 2)]
	)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("#17191d"), true)
	_draw_header()
	_draw_board()
	_draw_telegraphs()
	_draw_actors()
	_draw_hud()


func _draw_header() -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(48, 52), "ECHO  /  PROTOTYPE 0.1", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#e4dfd3"))
	draw_string(font, Vector2(48, 82), "THE FIRST WATCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9b9a94"))


func _draw_board() -> void:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var cell := Vector2i(x, y)
			var rect := _cell_rect(cell)
			var fill := Color("#292c31") if (x + y) % 2 == 0 else Color("#24272c")
			draw_rect(rect, fill, true)
			draw_rect(rect, Color("#45484c"), false, 1.0)
			if controller.blocked_cells.has(cell):
				draw_rect(rect.grow(-5.0), Color("#101114"), true)
				draw_rect(rect.grow(-5.0), Color("#55504a"), false, 2.0)


func _draw_actors() -> void:
	for actor_id in controller.actors:
		var actor = controller.actors[actor_id]
		if not actor.is_alive():
			continue
		var center := _cell_center(actor.cell)
		var body_color := Color("#a8a08b") if actor.team == "player" else Color("#873f3b")
		var outline := Color("#e7d7ae") if actor.team == "player" else Color("#d58b78")
		draw_circle(center, 22.0, body_color)
		draw_arc(center, 22.0, 0.0, TAU, 48, outline, 3.0)
		var glyph := "S" if actor.team == "player" else "V"
		draw_string(ThemeDB.fallback_font, center + Vector2(-7.0, 7.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#17191d"))


func _draw_telegraphs() -> void:
	for intent in controller.intents:
		if intent.state != 0:
			continue
		match intent.action_id:
			"charged_strike":
				var rect := _cell_rect(intent.target_cell).grow(-4.0)
				draw_rect(rect, Color(0.65, 0.12, 0.10, 0.24), true)
				draw_rect(rect, Color("#e36a5e"), false, 4.0)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 20.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd7cb"))
			"basic_melee":
				var target = controller.get_actor(intent.target_actor_id)
				if target != null and target.is_alive():
					draw_arc(_cell_center(target.cell), 29.0, 0.0, TAU, 48, Color("#e3a35d"), 4.0)
			"pursuit":
				for path_cell in intent.affected_cells:
					draw_rect(_cell_rect(path_cell).grow(-10.0), Color(0.75, 0.61, 0.31, 0.22), true)
					draw_rect(_cell_rect(path_cell).grow(-10.0), Color("#c5a45c"), false, 2.0)


func _draw_hud() -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(48, 145), "TURN  %02d" % controller.turn_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#d9d4c8"))
	draw_string(font, Vector2(48, 180), "AP  %d / %d" % [controller.ap.current, controller.ap.maximum], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#d4b77b"))
	draw_string(font, Vector2(48, 235), "SEVRIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e4dfd3"))
	var sevrin = controller.get_actor("sevrin")
	if sevrin != null:
		draw_string(font, Vector2(48, 263), "HP  %d / %d" % [sevrin.health, sevrin.max_health], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b9b7ad"))
	draw_string(font, Vector2(48, 330), status_message, HORIZONTAL_ALIGNMENT_LEFT, 360, 15, Color("#aaa79e"))
	draw_rect(END_TURN_RECT, Color("#4b4030"), true)
	draw_rect(END_TURN_RECT, Color("#c4a66c"), false, 2.0)
	draw_string(font, END_TURN_RECT.position + Vector2(35.0, 40.0), "END TURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f0e5d0"))
	if controller.phase == ControllerScript.BattlePhase.FINISHED:
		draw_rect(Rect2(330.0, 300.0, 620.0, 110.0), Color(0.06, 0.07, 0.08, 0.94), true)
		draw_string(font, Vector2(510.0, 365.0), "BATTLE  " + controller.battle_result.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#e4d2aa"))


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(BOARD_ORIGIN + Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return _cell_rect(cell).position + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)


func _handle_tap(position: Vector2) -> void:
	if controller.phase != ControllerScript.BattlePhase.PLAYER:
		return
	if END_TURN_RECT.has_point(position):
		controller.end_player_turn()
		queue_redraw()
		return

	var grid_position := (position - BOARD_ORIGIN) / CELL_SIZE
	var cell := Vector2i(floori(grid_position.x), floori(grid_position.y))
	if cell.x < 0 or cell.y < 0 or cell.x >= BOARD_SIZE or cell.y >= BOARD_SIZE:
		return

	for actor_id in controller.actors:
		var actor = controller.actors[actor_id]
		if actor.team == "enemy" and actor.is_alive() and actor.cell == cell:
			if controller.request_player_attack(actor_id):
				status_message = "Attack resolved."
			else:
				status_message = "Enemy must be orthogonally adjacent; 1 AP required."
			queue_redraw()
			return

	var path := _path_to_cell(controller.get_actor("sevrin").cell, cell)
	if path.is_empty():
		status_message = "That destination is blocked or beyond the two-cell move limit."
	elif controller.request_player_move(path):
		status_message = "Moved. 1 AP spent."
	else:
		status_message = "Move unavailable. Check AP and path."
	queue_redraw()


func _path_to_cell(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var came_from := {start: start}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var occupied := controller.get_occupied_cells("sevrin")
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for direction in directions:
			var next: Vector2i = current + direction
			if next.x < 0 or next.y < 0 or next.x >= BOARD_SIZE or next.y >= BOARD_SIZE:
				continue
			if controller.blocked_cells.has(next) or occupied.has(next) or came_from.has(next):
				continue
			came_from[next] = current
			queue.append(next)
	if not came_from.has(goal) or goal == start:
		return []
	var reversed_path: Array[Vector2i] = []
	var cursor: Vector2i = goal
	while cursor != start:
		reversed_path.push_front(cursor)
		cursor = came_from[cursor]
	if reversed_path.size() > 2:
		return []
	return reversed_path


func _on_battle_event(_event: Dictionary) -> void:
	queue_redraw()


func _on_battle_finished(result: String) -> void:
	status_message = "Encounter complete: " + result
	queue_redraw()
