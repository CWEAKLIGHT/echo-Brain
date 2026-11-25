class_name LevelCatalog
extends RefCounted

## Fixed Prototype 0.1 level list. Levels are ordered from a single-rule lesson
## to a mixed roster, per the encounter design principles: differences between
## levels come from enemy mix, starting cells, and terrain, never from random
## placement or hidden enemy decisions.

const EncounterDefinitionScript = preload("res://scripts/battle/encounter_definition.gd")


static func create_prototype_levels() -> Array[EncounterDefinition]:
	var levels: Array[EncounterDefinition] = []

	levels.append(_make_level(
		&"lesson_charge",
		"第一课 · 蓄力",
		"先锋在正前方两格时会锁定你脚下的格子蓄力。看清预兆，移动一格就能让它落空。",
		Vector2i(1, 3),
		[Vector2i(3, 3)],
		["vanguard"],
		[]
	))

	levels.append(_make_level(
		&"lesson_lane",
		"第二课 · 射线",
		"神射手只在同一直线、距离 3–6 格时开火，贴太近反而打不到。沿直线冲进去，逼它待机。",
		Vector2i(1, 3),
		[Vector2i(6, 3)],
		["marksman"],
		[Vector2i(4, 1), Vector2i(4, 5)]
	))

	levels.append(_make_level(
		&"lesson_mixed",
		"第三课 · 混编",
		"三种敌人同场：先锋逼近、射手锁格、术士覆盖十字区域。先解决哪一个，决定这局的走向。",
		Vector2i(1, 3),
		[Vector2i(5, 3), Vector2i(6, 6), Vector2i(1, 0)],
		["vanguard", "area_controller", "marksman"],
		[Vector2i(3, 1), Vector2i(3, 2)]
	))

	return levels


static func level_count() -> int:
	return create_prototype_levels().size()


static func _make_level(
	p_level_id: StringName,
	p_display_name_zh: String,
	p_tactical_hint_zh: String,
	p_player_cell: Vector2i,
	p_enemy_cells: Array[Vector2i],
	p_enemy_archetypes: Array[String],
	p_obstacles: Array[Vector2i]
) -> EncounterDefinition:
	var level: EncounterDefinition = EncounterDefinitionScript.new()
	level.level_id = p_level_id
	level.display_name_zh = p_display_name_zh
	level.tactical_hint_zh = p_tactical_hint_zh
	level.player_cell = p_player_cell
	level.enemy_cells = p_enemy_cells.duplicate()
	level.enemy_archetypes = p_enemy_archetypes.duplicate()
	level.obstacles = p_obstacles.duplicate()
	return level
