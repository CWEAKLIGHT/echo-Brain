class_name BattleActor
extends RefCounted

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


func apply_damage(raw_damage: int, damage_type: String = "physical") -> int:
	if is_defeated or raw_damage <= 0:
		return 0
	var resistance: int = defense if damage_type == "physical" else (magic_resistance if damage_type == "magical" else 0)
	var mitigated: int = CombatMathScript.calculate_damage(raw_damage, resistance)
	var applied: int = mini(mitigated, health)
	health -= applied
	if health <= 0:
		health = 0
		is_defeated = true
	return applied


func is_alive() -> bool:
	return not is_defeated and health > 0


const CombatMathScript = preload("res://scripts/battle/combat_math.gd")
