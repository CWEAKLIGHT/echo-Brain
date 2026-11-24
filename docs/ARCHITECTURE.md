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
