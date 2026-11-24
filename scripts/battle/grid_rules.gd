class_name GridRules
extends RefCounted

## Pure grid validation helpers. Gameplay state remains owned by the battle controller.

static func is_inside_bounds(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func is_path_legal(
	start: Vector2i,
	path: Array[Vector2i],
	grid_size: Vector2i,
	blocked_cells: Dictionary,
	occupied_cells: Dictionary,
	max_steps: int = 2
) -> bool:
	if path.is_empty() or path.size() > max_steps:
		return false

	var previous := start
	for cell in path:
		if not is_inside_bounds(cell, grid_size):
			return false
		if manhattan_distance(previous, cell) != 1:
			return false
		if blocked_cells.has(cell) or occupied_cells.has(cell):
			return false
		previous = cell

	return true


static func has_clear_orthogonal_line(
	start: Vector2i,
	target: Vector2i,
	blocked_cells: Dictionary,
	occupied_cells: Dictionary,
	ignore_target_occupant: bool = true
) -> bool:
	if start == target:
		return false
	if start.x != target.x and start.y != target.y:
		return false

	var step := Vector2i(signi(target.x - start.x), signi(target.y - start.y))
	var cursor := start + step
	while cursor != target:
		if blocked_cells.has(cursor) or occupied_cells.has(cursor):
			return false
		cursor += step

	if blocked_cells.has(target):
		return false
	if not ignore_target_occupant and occupied_cells.has(target):
		return false
	return true
