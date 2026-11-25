class_name EnemyCatalog
extends RefCounted

## Loads the enemy profiles from data/enemies/. Adding a stat variant means
## adding one .tres here and referencing its archetype id from a level; adding a
## new behaviour still means writing a _generate_*_intent branch.

const VANGUARD_DEFINITION = preload("res://data/enemies/vanguard.tres")
const MARKSMAN_DEFINITION = preload("res://data/enemies/marksman.tres")
const AREA_CONTROLLER_DEFINITION = preload("res://data/enemies/area_controller.tres")

const DEFAULT_ARCHETYPE: String = "vanguard"


static func definitions() -> Array:
	return [VANGUARD_DEFINITION, MARKSMAN_DEFINITION, AREA_CONTROLLER_DEFINITION]


static func get_definition(archetype_id: String) -> EnemyDefinition:
	for definition in definitions():
		if String(definition.archetype_id) == archetype_id:
			return definition
	return null


static func has_definition(archetype_id: String) -> bool:
	return get_definition(archetype_id) != null


static func known_archetype_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition in definitions():
		ids.append(String(definition.archetype_id))
	return ids
