extends SceneTree

const ControllerScript = preload("res://scripts/battle/battle_controller.gd")
const ActorScript = preload("res://scripts/actors/battle_actor.gd")
const AreaEffectScript = preload("res://scripts/battle/battle_area_effect.gd")
const AreaEffectCollectionScript = preload("res://scripts/battle/battle_area_effect_collection.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_watchwall_cast_and_expiry()
	_test_team_filter_and_dynamic_position()
	_test_damage_order_and_magic()
	_test_refresh_and_edge_clipping()
	_test_collection_relations_and_expiry()
	print("Battle area effect test run complete. Failures: ", failures.size())
	quit(1 if not failures.is_empty() else 0)


func _test_watchwall_cast_and_expiry() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	var marksman_types: Array[String] = ["marksman"]
	_check(battle.start_encounter(Vector2i(1, 1), [Vector2i(5, 1)], [], marksman_types), "Watchwall encounter starts")
	_check(battle.request_watchwall(), "Watchwall can be cast during the player phase")
	_check(battle.ap.current == 2, "Watchwall spends exactly one AP")
	var effect = battle.area_effects.get_effect(&"watchwall")
	_check(effect != null and effect.center_cell == Vector2i(1, 1), "Watchwall stores its cast-time center")
	_check(effect != null and effect.affected_cells.size() == 5, "Watchwall captures the center and four orthogonal cells")
	_check(effect != null and effect.target_relation == &"same_team", "Watchwall targets the caster's team rather than fixed actor IDs")
	_check(battle.end_player_turn(), "Watchwall enemy phase resolves")
	_check(battle.get_actor("sevrin").health == 11419, "Watchwall reduces post-resistance physical damage by 20 percent")
	_check(battle.area_effects.get_effect_count() == 0, "Watchwall expires at the next player phase start")
	battle.queue_free()


func _test_team_filter_and_dynamic_position() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	_check(battle.start_encounter(Vector2i(2, 2), [Vector2i(7, 7)]), "team-filter encounter starts")
	var ally_inside = ActorScript.new("ally_inside", "player", Vector2i(3, 2), 5000, "support", 1000, 0, 0)
	var ally_moving = ActorScript.new("ally_moving", "player", Vector2i(5, 5), 5000, "support", 1000, 0, 0)
	var enemy_inside = ActorScript.new("enemy_inside", "enemy", Vector2i(2, 1), 5000, "vanguard", 1000, 0, 0)
	battle.actors["ally_inside"] = ally_inside
	battle.actors["ally_moving"] = ally_moving
	battle.actors["enemy_inside"] = enemy_inside
	_check(battle.request_watchwall(), "Watchwall can be cast with additional friendly actors present")
	battle._apply_damage("ally_inside", 1000, "test_source", "physical_probe", "physical")
	_check(ally_inside.health == 4200, "same-team actor inside the area receives 20 percent protection")
	battle._apply_damage("enemy_inside", 1000, "test_source", "physical_probe", "physical")
	_check(enemy_inside.health == 4000, "opposing-team actor inside the area receives no friendly protection")
	battle._apply_damage("ally_moving", 1000, "test_source", "physical_probe", "physical")
	_check(ally_moving.health == 4000, "friendly actor outside the area receives no protection")
	ally_moving.cell = Vector2i(2, 3)
	battle._apply_damage("ally_moving", 1000, "test_source", "physical_probe", "physical")
	_check(ally_moving.health == 3200, "moving into the area grants protection at hit time")
	ally_moving.cell = Vector2i(5, 5)
	battle._apply_damage("ally_moving", 1000, "test_source", "physical_probe", "physical")
	_check(ally_moving.health == 2200, "moving out of the area removes protection at hit time")
	battle.queue_free()


func _test_damage_order_and_magic() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	_check(battle.start_encounter(Vector2i(2, 2), [Vector2i(7, 7)]), "damage-order encounter starts")
	var ally = ActorScript.new("ally_guarded", "player", Vector2i(2, 1), 5000, "support", 1000, 0, 0)
	var magical_ally = ActorScript.new("ally_magical", "player", Vector2i(2, 3), 5000, "support", 1000, 0, 0)
	battle.actors["ally_guarded"] = ally
	battle.actors["ally_magical"] = magical_ally
	_check(battle.request_watchwall(), "Watchwall is active for damage-order checks")
	_check(battle.statuses.apply_status(&"oathguard", "sevrin", "ally_guarded", 1, 1, 1, &"enemy_phase_end"), "personal defensive status can coexist with area protection")
	battle._apply_damage("ally_guarded", 1000, "test_source", "physical_probe", "physical")
	_check(ally.health == 4480, "damage order is resistance then area 20 percent then personal 35 percent")
	battle._apply_damage("ally_magical", 1000, "test_source", "magical_probe", "magical")
	_check(magical_ally.health == 4200, "Watchwall reduction also applies to magical damage")
	battle.queue_free()


func _test_refresh_and_edge_clipping() -> void:
	var battle = ControllerScript.new()
	root.add_child(battle)
	_check(battle.start_encounter(Vector2i(2, 2), [Vector2i(7, 7)]), "refresh encounter starts")
	_check(battle.request_watchwall(), "first Watchwall cast succeeds")
	battle.get_actor("sevrin").cell = Vector2i(4, 4)
	_check(battle.request_watchwall(), "second Watchwall cast refreshes the same effect")
	_check(battle.area_effects.get_effect_count() == 1, "recasting does not create duplicate area effects")
	var refreshed = battle.area_effects.get_effect(&"watchwall")
	_check(refreshed != null and refreshed.center_cell == Vector2i(4, 4), "recasting replaces the locked center with the new cast-time position")
	_check(refreshed != null and not refreshed.affected_cells.has(Vector2i(2, 2)), "old footprint is replaced rather than retained")
	battle.get_actor("sevrin").cell = Vector2i.ZERO
	_check(battle.request_watchwall(), "Watchwall can be cast at a map corner")
	var edge_effect = battle.area_effects.get_effect(&"watchwall")
	_check(edge_effect != null and edge_effect.affected_cells.size() == 3, "edge footprint clips cells outside the map")
	_check(battle.area_effects.get_effect_count() == 1, "corner recast still maintains one Watchwall effect")
	battle.queue_free()


func _test_collection_relations_and_expiry() -> void:
	var collection = AreaEffectCollectionScript.new()
	var friend = ActorScript.new("friend", "player", Vector2i(1, 1), 1000, "support", 1000, 0, 0)
	var enemy = ActorScript.new("enemy", "enemy", Vector2i(1, 1), 1000, "vanguard", 1000, 0, 0)
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	var any_effect = AreaEffectScript.new(&"any", AreaEffectScript.EFFECT_DAMAGE_REDUCTION, "source", "player", Vector2i(1, 1), cells, AreaEffectScript.TARGET_ANY, 10, &"player_phase_start")
	var allies_effect = AreaEffectScript.new(&"allies", AreaEffectScript.EFFECT_DAMAGE_REDUCTION, "source", "player", Vector2i(1, 1), cells, AreaEffectScript.TARGET_SAME_TEAM, 10, &"player_phase_start")
	var enemies_effect = AreaEffectScript.new(&"enemies", AreaEffectScript.EFFECT_DAMAGE_REDUCTION, "source", "player", Vector2i(1, 1), cells, AreaEffectScript.TARGET_OTHER_TEAM, 10, &"player_phase_start")
	_check(collection.apply_effect(any_effect), "area effect collection accepts any-target effects")
	_check(collection.apply_effect(allies_effect), "area effect collection accepts same-team effects")
	_check(collection.apply_effect(enemies_effect), "area effect collection accepts opposing-team effects")
	_check(allies_effect.affects_actor(friend) and not allies_effect.affects_actor(enemy), "same-team filter is independent of actor IDs")
	_check(enemies_effect.affects_actor(enemy) and not enemies_effect.affects_actor(friend), "opposing-team filter is independent of actor IDs")
	_check(any_effect.affects_actor(friend) and any_effect.affects_actor(enemy), "any-target filter accepts either team")
	_check(collection.get_damage_reductions_for_actor(friend).size() == 2, "collection resolves only effects applicable to the current actor")
	_check(collection.get_damage_reductions_for_actor(enemy).size() == 2, "opposing actor receives only matching area effects")
	_check(collection.expire_boundary(&"player_phase_start") == 3, "collection expires all effects at their configured phase boundary")
	_check(collection.get_effect_count() == 0, "expired area effects are removed from the collection")
	var persistent_effect = AreaEffectScript.new(&"persistent", AreaEffectScript.EFFECT_DAMAGE_REDUCTION, "source", "player", Vector2i(1, 1), cells, AreaEffectScript.TARGET_ANY, 5)
	_check(collection.apply_effect(persistent_effect), "area effect may intentionally have no automatic expiry")
	_check(collection.expire_boundary(&"player_phase_start") == 0 and collection.get_effect_count() == 1, "persistent effect remains until explicitly removed")
	_check(collection.remove_effect(&"persistent") and collection.get_effect_count() == 0, "persistent effect can be removed explicitly")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
