# ECHO

A 2D turn-based tactical roguelite for Android, built with Godot 4.x and GDScript.

## Project status

**Phase:** Project setup / Phase 0  
**Prototype target:** Prototype 0.1  
**Engine:** Godot 4.x  
**Primary platform:** Android (landscape-first)  
**Mode:** Single-player, offline

This repository is the independent home of ECHO. It is separate from the Shiguang project.

## Prototype 0.1 scope

- One playable character: Sevrin, the Oathkeeper
- One temporary Hunter companion
- Three ordinary enemy types
- One complete battlefield
- Five to six skills
- A three-AP player turn
- Enemy telegraphs and tactical interference
- Victory and defeat resolution
- Touch-first Android controls

The prototype scope is intentionally frozen. Run progression, contracts, collections, economy, and the full roguelite chapter loop are outside Prototype 0.1.

## Design constraints

- Top-down square-grid battlefield; no diagonal movement.
- A move costs 1 AP and can move up to two orthogonal cells.
- Base player AP is 3 per turn.
- Actions resolve immediately; they may only be canceled before target confirmation.
- Enemy telegraphs are created at the start of the player turn and execute in a clearly visible fixed order.
- Ordinary enemy telegraphs must accurately match their eventual execution.
- No mid-run save, checkpoint, or run restoration system. Only out-of-run progression may persist.

When a rule is not confirmed, implementation must not silently turn a proposal into a final rule. Track unresolved decisions in design documentation before implementing them.

## Repository layout

```
.
├── docs/                 # Project and technical documentation
├── scenes/
│   └── main/             # Main entry scene
├── scripts/              # GDScript source
│   ├── core/
│   ├── battle/
│   ├── actors/
│   ├── data/
│   └── ui/
└── project.godot
```

## Getting started

1. Install a compatible Godot 4.x release.
2. Clone this repository.
3. Import the repository folder in Godot.
4. Run the project using the main scene.

The current commit establishes the project skeleton only. Gameplay systems are not implemented yet.
