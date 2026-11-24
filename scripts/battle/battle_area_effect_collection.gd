class_name BattleAreaEffectCollection
extends RefCounted

const BattleAreaEffectScript = preload("res://scripts/battle/battle_area_effect.gd")

## effect_id -> BattleAreaEffect. Reapplying the same ID replaces that effect.
var _effects: Dictionary = {}


func apply_effect(effect: BattleAreaEffect) -> bool:
	if effect == null or not effect.is_valid():
		return false
	_effects[effect.effect_id] = effect
	return true


func get_effect(effect_id: StringName) -> BattleAreaEffect:
	var value = _effects.get(effect_id)
	if value == null:
		return null
	return value as BattleAreaEffect


func remove_effect(effect_id: StringName) -> bool:
	return _effects.erase(effect_id)


func expire_boundary(boundary: StringName) -> int:
	if boundary == &"":
		return 0
	var expired_ids: Array[StringName] = []
	for key in _effects.keys():
		var effect: BattleAreaEffect = _effects[key] as BattleAreaEffect
		if effect.expiry_boundary == boundary:
			expired_ids.append(effect.effect_id)
	for effect_id in expired_ids:
		_effects.erase(effect_id)
	return expired_ids.size()


func get_damage_reductions_for_actor(actor) -> Array[int]:
	var reductions: Array[int] = []
	var effect_ids: Array[StringName] = []
	for key in _effects.keys():
		effect_ids.append(StringName(key))
	effect_ids.sort()
	for effect_id in effect_ids:
		var effect: BattleAreaEffect = _effects[effect_id] as BattleAreaEffect
		if effect.effect_type != BattleAreaEffectScript.EFFECT_DAMAGE_REDUCTION:
			continue
		if effect.affects_actor(actor) and effect.magnitude > 0:
			reductions.append(clampi(effect.magnitude, 0, 100))
	return reductions


func get_effect_count() -> int:
	return _effects.size()


func clear_all() -> int:
	var count: int = _effects.size()
	_effects.clear()
	return count
