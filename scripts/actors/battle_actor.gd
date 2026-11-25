class_name BattleActor
extends RefCounted

const CombatMathScript = preload("res://scripts/battle/combat_math.gd")

## Runtime combatant stats and damage resolution.

var actor_id: String
var team: String
var archetype: String = "vanguard"
var cell: Vector2i
var max_health: int
var health: int
var attack: int
var defense: int
var magic_resistance: int
var is_defeated: bool = false


func _init(
	p_actor_id: String,
	p_team: String,
	p_cell: Vector2i,
	p_max_health: int,
	p_archetype: String = "vanguard",
	p_attack: int = 1000,
	p_defense: int = 0,
	p_magic_resistance: int = 0
) -> void:
	actor_id = p_actor_id
	team = p_team
	archetype = p_archetype
	cell = p_cell
	max_health = maxi(1, p_max_health)
	health = max_health
	attack = maxi(0, p_attack)
	defense = maxi(0, p_defense)
	magic_resistance = maxi(0, p_magic_resistance)


func apply_damage(
	raw_damage: int,
	damage_type: String = "physical",
	final_reduction_percent: int = 0,
	resistance_penalty: int = 0,
	additional_reduction_percents: Array[int] = []
) -> int:
	if is_defeated or raw_damage <= 0:
		return 0
	var base_resistance: int = defense if damage_type == "physical" else (magic_resistance if damage_type == "magical" else 0)
	var resistance: int = maxi(0, base_resistance - maxi(0, resistance_penalty))
	var mitigated: int = CombatMathScript.calculate_damage(raw_damage, resistance)
	var final_damage: int = mitigated
	# Contextual reductions (for example, area protection) resolve after resistance.
	for reduction_percent in additional_reduction_percents:
		var reduction: int = clampi(reduction_percent, 0, 100)
		if reduction > 0 and final_damage > 0:
			final_damage = maxi(1, floori(float(final_damage) * float(100 - reduction) / 100.0))
	# Personal defensive states resolve last, preserving their existing precedence.
	var personal_reduction: int = clampi(final_reduction_percent, 0, 100)
	if personal_reduction > 0 and final_damage > 0:
		final_damage = maxi(1, floori(float(final_damage) * float(100 - personal_reduction) / 100.0))
	var applied: int = mini(final_damage, health)
	health -= applied
	if health <= 0:
		health = 0
		is_defeated = true
	return applied


func is_alive() -> bool:
	return not is_defeated and health > 0

