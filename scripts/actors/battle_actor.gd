class_name BattleActor
extends RefCounted

## Runtime actor state only. This object is never serialized for in-run restoration.

var actor_id: String
var team: String
var archetype: String = "vanguard"
var cell: Vector2i
var max_health: int
var health: int
var is_defeated: bool = false


func _init(
	p_actor_id: String,
	p_team: String,
	p_cell: Vector2i,
	p_max_health: int,
	p_archetype: String = "vanguard"
) -> void:
	actor_id = p_actor_id
	team = p_team
	archetype = p_archetype
	cell = p_cell
	max_health = maxi(1, p_max_health)
	health = max_health


func apply_damage(amount: int) -> int:
	if is_defeated or amount <= 0:
		return 0

	var applied := mini(amount, health)
	health -= applied
	if health <= 0:
		health = 0
		is_defeated = true
	return applied


func is_alive() -> bool:
	return not is_defeated and health > 0
