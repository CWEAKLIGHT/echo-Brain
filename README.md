# ECHO

A 2D turn-based tactical roguelite prototype for Android (landscape-first), built with Godot 4.x and GDScript.

## Project status

**Milestone:** Prototype 0.1 foundations and first playable battle slice  
**Engine target:** Godot 4.7.x Standard  
**Primary platform:** Android (landscape-first)  
**Current validation:** Source-level review and authored tests only. Godot editor import, script parsing, test execution, Android export, and device behavior still require runtime verification.

This repository is the independent home of ECHO and is separate from the Shiguang project.

## Open and run on Windows

1. Download and extract a Godot 4.x Standard Windows x86_64 build.
2. Extract the ECHO project ZIP to a normal folder.
3. Open Godot and choose **Import**.
4. Select the extracted folder's `project.godot` file.
5. Open the project and press **F5** to run the configured main scene.

The project does not require the .NET build of Godot. The first desktop run does not require Android export templates.

## Current Prototype 0.1 battle slice

- One playable character: Sevrin, the Oathkeeper.
- An 8×8 orthogonal grid battlefield.
- Three ordinary enemy archetypes: Vanguard, Marksman, and Area Controller.
- Three AP per player turn.
- Player movement costs 1 AP and allows up to two orthogonal cells.
- Basic adjacent attack costs 1 AP.
- Enemy intents are captured at the start of the player turn and displayed in a deterministic order.
- Vanguard: adjacent actor-locked melee, tile-locked charged strike, or pursuit.
- Marksman: orthogonal line-of-sight aimed shot at provisional range 3–6.
- Area Controller: provisional fixed five-cell orthogonal-cross ground pulse.
- Enemy damage, death, intent cancellation, and battle victory/defeat termination.
- Mouse and touch input for movement, attack, and End Turn.

The current battle view is a functional debug/prototype presentation, not final art. The temporary Hunter companion, complete Oathkeeper skill set, final battlefield art, and Android export are not yet complete.

## Design constraints

- Top-down square-grid battlefield; no diagonal movement.
- A move costs 1 AP and can move up to two orthogonal cells.
- Base player AP is 3 per turn.
- Actions resolve immediately; they may only be canceled before target confirmation.
- Enemy telegraphs are created at the start of the player turn and execute in a clearly visible fixed order.
- Ordinary enemy telegraphs must accurately match their eventual execution.
- No mid-run save, checkpoint, or run restoration system. Only out-of-run progression may persist.

Unconfirmed enemy values and behaviors remain provisional implementation choices for Prototype 0.1 playtesting, not final balance approvals.

## Repository layout

- `docs/`: design notes and project status
- `scenes/main/`: main entry scene
- `scripts/battle/`: grid rules, AP, intents, and battle controller
- `scripts/actors/`: runtime actor model
- `scripts/ui/`: first-pass battle view
- `tests/`: headless test harness scripts

## Test harnesses

After importing the project in Godot, the two test scripts can be run from a terminal with a compatible Godot executable:

```text
godot --headless --path . --script res://tests/test_core_rules.gd
godot --headless --path . --script res://tests/test_battle_controller.gd
```

These commands are instructions only; the test harnesses have not yet been executed successfully in a Godot runtime. Do not treat them as passed until actual output confirms completion with zero failures.

## Scope and project isolation

Prototype 0.1 scope is intentionally frozen. Run progression, contracts, collections, economy, and the full roguelite chapter loop are outside this prototype.

ECHO is independent from Shiguang. Do not add GitHub Actions workflows, paid automation, or changes to the Shiguang repository as part of this project.
