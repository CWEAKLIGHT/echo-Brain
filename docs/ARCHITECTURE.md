# ECHO — Initial Architecture Boundaries

This document records the initial project boundaries, not a completed implementation architecture.

## Planned code areas

- `core/`: shared runtime coordination and foundational types.
- `battle/`: battle flow, grid, AP, actions, telegraphs, resolution, and combat events.
- `actors/`: player, companion, and enemy runtime actors.
- `data/`: typed definitions and configuration resources.
- `ui/`: battle HUD, targeting, telegraph presentation, and touch interaction.
- `scenes/`: Godot scene composition.

## Authority boundaries

1. Gameplay systems own authoritative state. UI reads and presents that state; it must not independently calculate outcomes.
2. Enemy intent presentation and enemy execution must use the same action definition and resolution rules.
3. Battle events must resolve through a documented, deterministic order.
4. Persistent progression and temporary run state must remain separate.
5. Temporary run state must not be serialized for restoration after process termination.
6. Content definitions should be data-driven where doing so does not obscure the rules or complicate the prototype.

## Planned battle responsibilities

- Grid and movement validation
- Player AP budget and action validation
- Action execution and damage resolution
- Enemy decision and telegraph generation
- Telegraph lifecycle and enemy execution
- Companion command and support execution
- Death and battle-end resolution

These are responsibility boundaries only. Detailed interfaces, event order, formulas, and unresolved telegraph-interference rules must be specified and reviewed before implementation.

## Initial scene

`scenes/main/main.tscn` is the application entry scene. It currently contains only a `Node2D` and a minimal script. It is not yet a battle scene.


## Implemented foundational modules — Prototype 0.1

The first implementation slice now contains:

- `scripts/battle/grid_rules.gd`: pure orthogonal grid/path validation and Manhattan-distance helpers.
- `scripts/battle/ap_budget.gd`: deterministic AP ledger with reset, spend, and end-turn clear operations.
- `scripts/actors/battle_actor.gd`: runtime actor identity, team, grid position, integer health, damage, and defeat state.
- `tests/test_core_rules.gd`: dependency-free Godot SceneTree test harness for path validation, AP behavior, and health/defeat behavior.

These are foundational primitives, not yet a complete playable battle loop. The UI and battle scene do not consume them yet. Runtime validation requires Godot 4.x and remains pending.


## Authoritative battle model — first integration slice

The following runtime pieces now exist on `prototype/0.1`:

- `scripts/battle/battle_intent.gd`: captured enemy action snapshot with actor/tile/area target-mode enum and one-way active/resolved/canceled lifecycle.
- `scripts/battle/battle_controller.gd`: owns encounter runtime state, player AP actions, turn boundaries, deterministic enemy intent generation, enemy-phase execution, damage/death, terminal results, and ordered battle events.
- `tests/test_battle_controller.gd`: headless SceneTree scenarios for tile-lock evasion, two-cell pursuit, actor-lock tracking, and immediate terminal handling.

Current integration limitations:
- The controller currently spawns a single Oathkeeper and Melee Vanguard instances only.
- Companion commands, control skills, ranged/area enemies, UI rendering, and a complete encounter scene are not yet integrated.
- The controller is not yet connected to `main.tscn`.
- Godot 4.x runtime import and test execution remain pending.


## First playable presentation layer

- `scripts/ui/battle_view.gd` draws the 8×8 board, blocked cells, actors, enemy telegraphs, AP/health, captured enemy order, and an end-turn control.
- `scenes/main/main.tscn` now launches this battle view, which creates and owns a runtime `BattleController`.
- Touch and mouse input share the same handler: tap a reachable cell to move (up to two orthogonal cells), tap an adjacent enemy to attack, and tap End Turn to resolve captured enemy intents.
- `project.godot` now requests landscape orientation and a canvas-items stretch mode for the 1280×720 landscape-first layout.

This is a functional first-pass debug presentation, not final art or production UI. It requires Godot 4.x import and device validation.
