# ECHO — Project Status

## Current milestone

**Phase 1 — Prototype 0.1 foundations in progress**

The GitHub repository and minimal Godot project skeleton have been created. Foundational gameplay scripts and an authoritative battle model have been committed; Godot engine validation is still pending.

## Prototype 0.1 target

- Sevrin (Oathkeeper) as the sole playable character
- One temporary Hunter companion
- Three ordinary enemy types
- One complete battlefield
- Five to six skills
- Three AP per player turn
- Enemy telegraph system
- Victory and defeat resolution
- Android landscape and touch interaction

## Implementation order

1. P0 — Grid, movement, AP, attacks, and damage.
2. P1 — Enemy telegraphs, interference, skill ranges, and telegraph/execution consistency.
3. P2 — Hunter companion and its independent support action.
4. P3 — Death, win/loss conditions, settlement, and restart loop.
5. P4 — Android layout, touch controls, performance, export, and device testing.

## Explicit exclusions from Prototype 0.1

No run economy, chapter progression, Echo contracts, collections, full unlock system, or in-run save/checkpoint/restore system.

## Current status

- [x] Private repository created
- [x] GitHub connector access verified
- [x] Initial project skeleton committed
- [ ] Import and open in Godot editor
- [ ] Validate the project on a Godot 4.x installation
- [ ] Complete D0 design-rule review
- [x] Begin P0 gameplay implementation (grid/AP/actor primitives and a test harness committed)\n- [x] Add authoritative battle controller and captured enemy intents\n- [x] Add controller scenario test harness\n- [x] Connect battle controller to a first-pass playable battle view\n- [ ] Run both headless test harnesses in Godot 4.x

## Safety and scope constraints

- ECHO is independent from Shiguang.
- Do not add GitHub Actions workflows or paid automation without separate approval.
- Do not implement in-run persistence, checkpoints, or run restoration.
- Unconfirmed design proposals remain unresolved until explicitly approved.


## Latest implementation note

Foundational scripts and a headless test harness have been added on `prototype/0.1`. They have been committed and are awaiting Godot 4.x runtime validation. Do not treat the tests as passed until the project is imported and the harness is executed in Godot.


## Latest implementation note

The runtime battle model now supports validated player movement and adjacent attacks, a 3-AP turn budget, captured melee-vanguard intents (actor-locked basic attack, tile-locked charged strike, deterministic pursuit up to two cells), enemy-phase execution, damage/defeat, and victory/defeat termination. Controller scenarios cover key lock and turn behaviors. The code and test harnesses are committed but have not been run in Godot 4.x; treat all runtime behavior as unverified until engine execution.


## Playable-slice presentation

The main scene now opens an 8×8 tactical board with Sevrin, two Melee Vanguard units, obstacle cells, enemy intent previews/order, AP and health display, tap-to-move, tap-to-attack, and an End Turn control. Landscape-first viewport settings are configured. This is an unvalidated first-pass UI: no Godot runtime, Android export, or device test has been performed in this environment.


## Static review — 2026-11-24

- Encounter setup now validates the full player/enemy/obstacle layout before changing the active battle state. Invalid duplicate or overlapping enemy positions no longer leave a partially replaced encounter.
- Battle UI intent rendering and enemy-order labels now use the named `IntentState` enum rather than numeric state literals; active, resolved, and canceled states are distinguished.
- Added controller scenarios verifying that an invalid encounter setup is rejected without mutating the currently active encounter.
- This is a source-level review and test-harness update only. Godot 4.x import, script parsing, headless execution, Android export, and device behavior remain unverified because no Godot runtime is available in the current environment.

- Encounter validation now also rejects an empty enemy roster, preventing a nominally started encounter with no possible victory condition. A regression scenario covers this rejection and verifies the prior encounter remains intact.

- Enemies that have no legal pursuit route now receive an explicit, visible `wait` intent instead of silently disappearing from the execution order. The wait intent resolves without movement or damage; a controller scenario covers a fully blocked enemy.

- Added a provisional Ranged Marksman implementation specification: orthogonal line-of-fire, range 3–6, tile-locked single-cell aimed shot, 2 provisional damage, and explicit wait/cancel behavior. This is a design baseline for implementation and playtesting, not a claim that the archetype is implemented or balance-approved.

- Implemented explicit enemy archetypes on runtime actors and optional, validated encounter archetype input. Existing encounters without an archetype list remain Vanguard encounters; unknown types and mismatched lists are rejected before state mutation.
- Implemented the provisional Ranged Marksman aimed shot: orthogonal line-of-fire at range 3–6, tile-locked single-cell target, 2 damage, execution-time range/line revalidation, and wait intent when no legal shot exists. Added controller scenarios for a valid shot, blocked lane, and minimum-range failure. These tests are committed but not run in Godot 4.x.

- Mixed-enemy review found and corrected a priority mismatch: Marksman aimed shots now use execution priority 2, after Vanguard charged strikes (0) and basic melee (1). Added mixed-roster coverage verifying the visible order and actual damage resolution, plus rejection tests for unknown/mismatched archetype input. Test harness remains unexecuted pending Godot 4.x runtime access.
- Added a Marksman tile-lock evasion regression scenario: moving Sevrin off the marked cell cancels the aimed shot without damage. This is source-level test coverage only; no Godot test execution has occurred.

- Implemented the provisional Area Controller archetype: explicit `area_controller` encounter type, five-health provisional profile, range-2–4 fixed orthogonal-cross `ground_pulse`, area-locked one-damage resolution, and explicit cancellation when the captured area is empty. Added a distinct `C` actor marker and cross-cell telegraph rendering.
- Added controller scenarios for area-lock metadata, damage to a player remaining in the footprint, and evasion by moving outside the captured area. Added the provisional behavior and acceptance criteria to the enemy specification.
- Source-level implementation and test authoring only. Godot 4.x parsing and execution remain unverified because the runtime is unavailable in this environment.

- Added a boundary regression scenario verifying the area-locked cross footprint is clipped to valid cells when its center is at the map corner.

- Mixed-archetype integration pass: added a controller scenario with Vanguard, Marksman, and Area Controller active together. The scenario checks one captured intent per enemy, the shared priority/tie-break order, fixed telegraph geometry, and damage resolution matching the displayed sequence. Added a second scenario confirming that an intervening Vanguard blocks the Marksman's firing lane at planning time. Updated the first-pass battle scene to instantiate all three archetypes so the prototype view exposes the complete ordinary-enemy roster. These are source-level changes and authored tests only; Godot import, parsing, and test execution remain pending.


## Static review — configured grid bounds

- Corrected encounter validation so obstacle and enemy coordinates are checked against the controller's configured `grid_size`, rather than calling the bounds helper without its required dimensions.
- Added regression scenarios using a 6×6 configured board: valid in-bounds setup is accepted, while an enemy or obstacle at x=6 is rejected.
- Controller and test files were re-fetched after the commits to verify the exact changes. This remains source-level review only; Godot import, parsing, and test execution are still pending.


## First Windows Godot import feedback — occupied Dictionary type

- A tester opened the project with Godot 4.7.2 stable on Windows and reported a parser error in `scripts/ui/battle_view.gd:183`: Godot could not infer the type of `occupied`.
- Confirmed that `BattleController.get_occupied_cells()` returns `Dictionary`; changed the local declaration to explicitly type `occupied: Dictionary`.
- The fix was committed to `prototype/0.1` and re-fetched for verification. The project has not yet been re-imported or run after this fix; further parser errors may appear and should be handled from the tester's next screenshot.


## Follow-up static parser-risk review

- The Windows Godot 4.7.2 report identified an inference failure at the UI call to `get_occupied_cells`. In addition to the explicit `Dictionary` annotation in `battle_view.gd`, the controller method now declares its return type as `-> Dictionary` and its local map as `Dictionary`.
- Re-scanned all tracked GDScript files in the current prototype tree for inferred declarations involving method calls. Remaining matches use concrete built-in constructors/helpers or functions with explicit return types; no additional same-pattern untyped getter call was found in this scan.
- Reviewed the main scene resource path and `project.godot` main-scene setting; both point to the tracked `scenes/main/main.tscn` and `scripts/ui/battle_view.gd` resources.
- These are source-level checks only. Godot editor import, parser validation, runtime behavior, and test-suite execution remain unverified until the tester reimports the latest ZIP and runs the project.

## Static audit follow-up — Godot 4.7.2 Windows feedback

- Re-fetched the project configuration, main scene, battle view, battle controller, grid rules, AP budget, intent model, actor model, and both test harnesses from `prototype/0.1`.
- Confirmed `project.godot` points to `res://scenes/main/main.tscn`, and that scene references the tracked `res://scripts/ui/battle_view.gd` script.
- Confirmed the earlier `occupied` inference issue is addressed by an explicit `Dictionary` declaration at the UI call site and an explicit `-> Dictionary` return type on `get_occupied_cells()`.
- Reviewed remaining inferred local declarations (`:=`) across the tracked GDScript files. Calls used for inferred values now have declared return types; other matches derive from typed parameters, built-in constructors, literals, or built-in integer helpers.
- Found and corrected stale README text that still described the repository as an unimplemented skeleton. README now describes the current playable battle slice, Windows import/run steps, test-harness commands, and the still-unverified runtime status.
- Static review did not reveal another confirmed parser error. This is not equivalent to Godot parsing or execution: only a Godot 4.7.2 import and actual test run can establish that. The tester should re-download the latest ZIP before retrying so the fixes and README are included.


## Chinese-first interface and scaled combat — 2026-11-24

- Set the in-game battle interface, status messages, action labels, unit labels, and battlefield glyphs to Simplified Chinese by default.
- Added four combat attributes to every runtime actor: health, attack, defense, and magic resistance.
- Added a shared multiplier-based damage formula and separate physical-defense / magical-resistance mitigation.
- Updated the Oathkeeper and three enemy archetypes to thousand-scale baseline values; added 0.7×–1.5× multipliers to current enemy attacks and a 1.0× player basic attack.
- Added docs/combat_stats_zh-CN.md as the numeric baseline and rules reference, plus regression cases for multipliers and mitigation.
- Source files and tests were committed and re-fetched. Godot 4.7.2 parsing and runtime test execution have not yet been performed; do not mark the tests as passed until they run in the engine.


## Sevrin tactical skill kit design — 2026-11-24

- Authored a five-active-skill design for Sevrin plus the existing basic attack: Oathguard Stance, Watchwall, Judgment Mark, Echo Counter, and Oath Severance (Chinese in-game names are specified in the design document).
- The kit emphasizes defensive timing, area protection, intent-aware marking, conditional counterattacks, and a high-cost interrupt rather than damage-only buttons.
- Documented AP costs, target/range rules, duration, status consumption, intent cancellation, combo turns, event/settlement order, edge cases, and initial balance parameters.
- This is a design specification only. No skill implementation has been committed yet; implementation must follow the documented order with per-step static review and Godot 4.7.2 validation when an engine environment is available.


## Data-driven skill foundation — 2026-11-24

- Added a typed `SkillDefinition` Resource with stable skill ID, Simplified Chinese display name/description, AP cost, target mode, range, damage type/multiplier, effect ID, duration, and judgment-mark requirement.
- Added an Oathkeeper skill catalog containing the five designed skills as data; this does not yet execute skills or change the existing battle loop.
- Added a dedicated skill-definition test harness covering catalog size/order, validation, AP costs, targeting/range, mark requirements, and invalid zero-AP data. Corrected the harness to aggregate failures reliably rather than passing an integer counter by value.
- Re-fetched the new scripts and test file after writing. This remains source-level verification only. Godot 4.7.2 import and execution are still required; do not mark the new harness as passed until it runs in-engine.
