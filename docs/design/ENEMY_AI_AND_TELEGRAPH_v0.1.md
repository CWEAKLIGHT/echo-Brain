# ECHO — Enemy AI and Telegraph System v0.1

> Status: Phase 0 working specification  
> Target: Prototype 0.1  
> Branch: `prototype/0.1`  
> This document defines responsibilities, data boundaries, and test requirements. Unapproved behavior remains explicitly open.

## 1. Purpose

The Enemy AI and Telegraph System makes enemy threats understandable before they resolve and ensures that the displayed threat matches the action that actually executes.

Core design promise:

> The enemy's threat must be understandable, the player's choices must matter, and the rules must be trustworthy.

For ordinary enemies, the telegraph must accurately represent the eventual target, area, damage, and special effects. A special enemy may alter an intent only when the change is clearly disclosed to the player before it matters. Special telegraph-changing enemies are outside Prototype 0.1 unless separately approved.

## 2. Prototype 0.1 scope

Included:
- Three ordinary enemy types
- Deterministic intent selection from each enemy's legal action set
- Telegraph generation at the start of the player turn
- Visible enemy execution order
- Telegraph cancellation when its source enemy dies
- Execution through the same authoritative intent/action definition used to render the telegraph
- Basic handling and logging for invalidated intents, subject to decisions in Section 13

Excluded:
- Boss phases and special intent mutation
- Complex learning/adaptive AI
- Procedural enemy traits
- Large enemy affix pool
- Hidden telegraph changes
- Enemies that deliberately deceive the player

## 3. System responsibilities

### EnemyDecisionSystem

Responsible for:
- Reading the enemy's current authoritative state.
- Enumerating actions the enemy is allowed to perform.
- Evaluating legal targets, tiles, and areas.
- Selecting one intent using the approved priority and tie-breaking rules.
- Producing an intent record without directly changing the battlefield.

It must not:
- Spend player AP.
- Change player or companion state during planning.
- Independently draw UI telegraph shapes.
- Execute damage during intent generation.

### TelegraphSystem

Responsible for:
- Receiving the selected intent record.
- Creating and maintaining the telegraph representation.
- Exposing the exact target, area, effect summary, source enemy, and execution order to UI.
- Canceling the telegraph immediately when its source enemy dies.
- Updating or invalidating an intent only through explicit approved rules.

It must not independently decide a different target, area, or damage value from the action record.

### EnemyActionResolver

Responsible for:
- Executing the intent's action definition at the enemy phase.
- Applying effects through the shared battle/action resolution pipeline.
- Reporting the actual resolved result.
- Marking the intent resolved or canceled exactly once.

It must not re-run an unconstrained AI choice at execution time and silently replace the displayed intent.

### Battle UI

Responsible for presenting authoritative data:
- Enemy identity and current state
- Telegraph shape and affected cells
- Target identity where applicable
- Estimated damage and special effects where known
- Enemy execution order
- Clear visual differentiation between multiple enemies' telegraphs

UI is a read-only presentation layer. It must not independently calculate targeting or outcomes.

## 4. Intent data model (proposed)

An intent should be represented as a stable runtime record. Field names are provisional.

**Confirmed targeting principle:** use a mixed targeting model. The target mode is selected by each action's design rather than forcing every enemy action into one universal lock type. An action may lock to an actor, a grid cell, or an area. The chosen mode and its consequences must be clear in the telegraph. Exact per-action assignments and movement behavior remain to be specified.

| Field | Purpose |
|---|---|
| intent_id | Unique battle-local identifier |
| source_actor_id | Enemy that owns the intent |
| action_definition_id | Shared action definition to be executed |
| target_mode | Confirmed mixed model: actor-locked, tile-locked, or area-locked, selected per action |
| target_actor_id | Target actor, if applicable |
| target_cell | Target grid cell, if applicable |
| affected_cells | Resolved area preview |
| damage_preview | Expected damage or a clearly defined range |
| effect_preview | Status, displacement, summon, or other effect summary |
| execution_order | Visible order index |
| creation_turn | Player turn in which it was created |
| state | Proposed: active, resolved, canceled, invalidated |
| disclosure | Any special rule the player must be told before execution |

The intent record is runtime battle data only. It must not be persisted for in-run restoration.

## 5. Intent generation lifecycle

At the start of each player turn:

1. Begin the new player turn using the approved turn-start sequence.
2. Read the current positions, health, statuses, terrain, and actor availability.
3. For each living and eligible enemy, enumerate its available actions.
4. Filter actions whose requirements are not met.
5. Enumerate legal targets or target cells for each candidate action.
6. Select an intent using a deterministic, documented selection rule.
7. Resolve the telegraph geometry and preview values from the selected action definition.
8. Assign the visible execution order.
9. Publish the completed intent list to the UI.
10. Open the player action window.

The exact relation between AP reset, status updates, companion availability reset, and telegraph generation remains governed by the Battle Event Timeline decision process.

No enemy should generate an active attack telegraph if it is defeated, disabled from acting under an approved rule, or otherwise ineligible. The exact definition of disabled remains to be finalized with status/control rules.

## 6. Selection policy

Prototype AI should be simple, legible, and testable rather than sophisticated.

Planning baseline:
- Each ordinary enemy has a small, authored action set.
- Candidate actions are filtered by legality before selection.
- Priority rules are explicit and stable.
- If two candidates have equal priority, a documented tie-breaker selects one.
- Randomness, if later used, must not cause the telegraph and execution to diverge. Any random choice is made during intent generation and captured in the intent record.

Open:
- Whether ordinary enemies use fixed priority, weighted choice, distance rules, or a small deterministic state machine.
- Whether a tie is resolved by fixed action ID order, target distance, or a stored random choice.
- Whether an enemy with no legal attack waits, guards, repositions, or uses a fallback action.

Prototype recommendation for evaluation, not yet approved: use authored priority rules and deterministic tie-breaking; avoid fresh random selection at execution time.

## 7. Telegraph presentation requirements

Each ordinary enemy telegraph should communicate, when applicable:

- Which enemy will act.
- Which actor is targeted, or which cell/area is threatened.
- Exact threatened cells.
- Expected damage, or a clearly labeled damage range if the combat formula makes an exact value impossible.
- Special effects such as push, pull, stun, armor reduction, or terrain change.
- The enemy's position in the execution order.

Presentation requirements:
- Multiple enemies must remain distinguishable without relying on color alone.
- Use shape, outline, pattern, icon, and/or source markers in addition to color.
- Telegraphs must remain readable on a landscape phone screen.
- Provide a way to inspect overlapping threats individually.
- Do not obscure the grid or critical unit silhouettes more than necessary.
- Long-press or another explicit inspection interaction may reveal details; exact gesture behavior belongs to the UI specification.

## 8. Intent stability and invalidation

The telegraph is generated at the start of the player turn and should remain stable during the player action window unless a confirmed rule changes or cancels it.

The following cases require explicit policy decisions:

### Source enemy dies
Confirmed: cancel its telegraph immediately. It must not execute later.

### Target moves
Open: does the action continue to target the original actor, the original cell, or a newly evaluated target? The telegraph must communicate the selected model.

### Target leaves the threatened area
Open: does the action resolve against the original area, fail, or use a documented fallback?

### Target is defeated before execution
Open: determine whether the action is canceled, retargeted, or resolves at its original location. No silent retargeting.

### Enemy is controlled or interrupted
Open: define success and failure effects, duration, and whether the telegraph is canceled, delayed, weakened, or retained.

### Earlier enemy action changes the board
Open: define what happens when a preceding enemy pushes a unit, blocks a tile, defeats a target, or otherwise invalidates a later enemy's intent.

### Terrain changes
Open: determine whether the telegraph geometry is locked or recalculated after terrain changes. Any change must be disclosed before execution.

The implementation must never silently replace a telegraphed action with a materially different action.

## 9. Execution lifecycle

At the beginning of the enemy phase:

1. Close player input.
2. Read the already published execution order.
3. Visit each intent in that order.
4. Check whether its source enemy is still alive and eligible.
5. Apply the approved invalidation policy.
6. Resolve the action using the same action definition and captured intent parameters used by the telegraph.
7. Record actual target, affected cells, damage, and effects.
8. Mark the intent resolved or canceled exactly once.
9. Continue to the next intent unless the battle has reached a terminal state.

The execution resolver must not perform a new unconstrained target search that contradicts the displayed telegraph.

## 10. Three-enemy content specification template

Each Prototype 0.1 enemy must be documented with:

- Name and battlefield role
- Base health and movement, once approved
- Action definitions and AP/turn timing if relevant
- Targeting mode
- Range and area geometry
- Damage/effect preview
- Selection priority and tie-breaker
- Telegraph appearance and iconography
- Player counterplay options
- Invalid-target behavior
- Test cases

Enemy archetype proposals for discussion only:
1. **Vanguard / melee pressure:** threatens a nearby actor or adjacent cells; teaches spacing and movement.
2. **Marksman / line or ranged threat:** threatens a clearly marked line, lane, or target; teaches line-of-fire and repositioning.
3. **Disruptor / area control:** threatens a small area or applies a disclosed control effect; teaches area denial and timing.

These are role proposals, not confirmed enemy identities, art, stats, or final actions.

## 11. Failure handling

- If an intent cannot be created, record a planning failure with a reason.
- If an intent becomes invalid, apply only the approved fallback policy.
- Never allow a defeated enemy to execute an action.
- Never leave a stale telegraph after its source enemy dies.
- Never silently retarget an action.
- If an unexpected runtime error occurs, fail safely: do not invent a new attack outcome; record the failure and preserve a recoverable battle state where possible. This does not mean saving the run to disk.

## 12. Test and acceptance requirements

1. At player-turn start, every eligible ordinary enemy receives exactly one valid intent if the encounter rules require one.
2. Every displayed telegraph is derived from its intent record.
3. Every executed enemy action uses the same intent record and action definition.
4. Displayed target, area, damage, and effects match actual execution.
5. Enemy execution order shown to the player matches actual execution order.
6. Killing an enemy during the player turn immediately removes its telegraph.
7. A defeated enemy never acts.
8. An invalidated intent follows the documented fallback and is never silently replaced.
9. Overlapping telegraphs can be inspected on a phone-sized landscape display.
10. Repeated encounters do not produce stale telegraphs, duplicate enemy actions, or soft-locks.

## 13. Decisions required before implementation

1. Assign actor-locked, tile-locked, or area-locked targeting to each Prototype 0.1 enemy action; the overall mixed targeting model is confirmed.
2. Target movement before execution.
3. Target leaves threatened area.
4. Target defeated before execution.
5. Control/interruption success behavior.
6. Control/interruption failure behavior.
7. Fixed enemy execution-order sorting rule.
8. Later intent invalidated by an earlier enemy action.
9. Terrain changes after telegraph generation.
10. No legal target/action fallback.
11. Ordinary enemy action-selection policy and tie-breaker.
12. Exact preview format for variable damage or conditional effects.
13. Telegraph overlap inspection and layering behavior.

## 14. Change control

Confirmed rules may only be changed with explicit project-owner approval and a decision-log entry. All recommendations and archetype examples in this document remain proposals until approved. Prototype 0.1 scope remains frozen.
