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

**Confirmed targeting principle:** use a mixed targeting model. The target mode is selected by each action's design rather than forcing every enemy action into one universal lock type. An action may lock to an actor, a grid cell, or an area. The chosen mode and its consequences must be clear in the telegraph.

**Confirmed target-movement and defeat behavior:** actor-locked actions continue tracking their designated actor; tile-locked actions resolve at the originally marked cell; area-locked actions resolve in the originally marked area. If an actor-locked action's designated target is defeated before execution, that action is canceled, does not retarget another actor, and does not refund or compensate player AP. The enemy's action slot is considered resolved for that phase.

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

**Confirmed Prototype 0.1 enemy role roster (three ordinary enemies):**
1. **Melee Vanguard:** creates close-range pressure and tests spacing, movement, and defensive responses. Its approved behavior direction is a hybrid: it normally pursues and applies steady melee pressure, then uses a charged strike when its conditions are met. Detailed behavior and initial tuning values are specified in Section 10.1; numerical balance remains subject to playtesting.
2. **Ranged Marksman:** creates long-range threats and tests positioning, line-of-fire, and ranged telegraph responses.
3. **Area Controller:** creates area threats and tests area denial, repositioning, and timing.

Only these three battlefield roles are confirmed at this stage. Names, visual designs, base stats, exact actions, targeting-mode assignments, priorities, and numerical values remain to be specified; the role descriptions do not approve any particular attack.


## 10.1 Melee Vanguard — Prototype 0.1 behavior specification

> Status: implementation baseline selected by the project maintainer under delegated design authority. Numerical balance remains subject to playtesting.

### Role and learning objective

The Melee Vanguard is the introductory pressure enemy. It teaches the player to read distance, preserve escape routes, and distinguish an actor-tracking attack from a fixed-cell attack. Its behavior is intentionally deterministic and uses no hidden target changes.

### Runtime profile (initial tuning values)

| Property | Initial value | Notes |
|---|---:|---|
| Health | 6 | Tuning baseline; not a final balance claim |
| Movement | Up to 2 orthogonal cells | One movement action per enemy phase |
| Basic attack damage | 1 | Actor-locked |
| Charged strike damage | 2 | Tile-locked |
| Basic attack range | Manhattan distance 1 | Adjacent orthogonal cells only |
| Charged strike range | Manhattan distance 2 | Target cell must be reachable by a clear orthogonal line |
| Charged strike footprint | One marked cell | No splash damage |

### Action A — Pursuit

- Used when neither attack is legal.
- Select the living player-controlled actor with the shortest Manhattan distance; ties resolve by stable actor ID.
- Find a shortest legal path toward that actor, using a deterministic neighbor order: up, right, down, left.
- Move up to two cells along that path, stopping before an occupied or blocked cell.
- If no legal step reduces distance, create an explicit `wait` intent. The wait occupies the enemy's visible execution-order slot and resolves without movement or damage.
- Pursuit is not an attack and creates no damage telegraph. The enemy's movement intent and destination should still be inspectable in the execution-order panel.
- Movement never crosses diagonal edges, walls, obstacles, or occupied cells.

### Action B — Basic melee attack

- Legal when a living player-controlled actor is orthogonally adjacent.
- Target mode: **actor-locked**.
- Select the adjacent target with the lowest current health ratio; ties resolve by stable actor ID.
- Telegraph: show the source enemy, named target, and the target actor's current cell.
- At execution, follow the same target actor if it has moved.
- If that target is defeated before execution, cancel the action; do not retarget.
- Initial damage: 1.

### Action C — Charged strike

- Legal when a living player-controlled actor is exactly two orthogonal cells away on a straight, unobstructed line.
- Target mode: **tile-locked**.
- Select the eligible target by lowest current health ratio, then stable actor ID.
- Telegraph the single original target cell, with a distinct charge marker and an explicit 2-damage preview.
- The attack resolves at that original cell even if the actor moves away. It does not track the actor and does not expand to nearby cells.
- If the original cell becomes blocked or otherwise illegal under the shared action validation rules, cancel the strike and log the reason.
- Initial damage: 2.
- No displacement, stun, armor break, or terrain effect in Prototype 0.1.

### Selection priority and phase behavior

At player-turn start, select exactly one intent for the upcoming enemy phase:
1. Charged strike, if legal.
2. Basic melee attack, if legal.
3. Pursuit, if a legal step reduces distance.
4. Wait.

The selected intent and all target parameters are captured when the telegraph is generated. The AI is not rerun during execution. A later battlefield change may invalidate the captured action, but may not cause a replacement action to be selected.

### Player counterplay

- Move away from a charged strike's marked cell.
- Use a successful control effect to cancel the Vanguard's current telegraph.
- Defeat the Vanguard before its execution slot.
- Use defensive or protective skills to mitigate an actor-locked basic attack.
- Use obstacles and positioning to prevent or delay a legal pursuit/charge line.

### Acceptance tests

1. At Manhattan distance greater than 2, the Vanguard selects pursuit or wait, never an attack.
2. At distance 2 on a clear straight line, it telegraphs a tile-locked charged strike.
3. At orthogonal adjacency, it telegraphs an actor-locked basic attack.
4. A diagonal target is not considered adjacent and cannot be charged.
5. A wall or obstacle between the Vanguard and the charged-strike target prevents that strike.
6. Moving the target after a basic-attack telegraph does not change the actor target.
7. Moving the target after a charged-strike telegraph does not move the marked cell.
8. Defeating the Vanguard cancels its telegraph immediately.
9. Successful control cancels the current telegraph; failed control leaves it unchanged.
10. If an earlier action blocks the original charged-strike cell, the strike cancels without retargeting or falling back to another action.
11. Equal-distance and equal-health ties always resolve identically across repeated runs.
12. The visible intent and actual execution report the same action ID, target mode, target, footprint, and damage.

### Tuning note

Health and damage are deliberately conservative starting values for the first playable encounter. They must be tested against the Oathkeeper's finalized health, armor, defensive skills, and the other two enemy types before being treated as balanced.



## 10.2 Ranged Marksman — provisional implementation specification

> Status: Prototype implementation choice, not a separately owner-approved balance rule. This section establishes a deliberately small first implementation for review and playtesting; it does not expand Prototype 0.1 scope.

### Role and learning objective

The Ranged Marksman creates a distant, readable single-cell threat. It teaches the player to use cover and break a firing lane rather than treating distance alone as safety.

### Runtime profile (provisional tuning values)

| Property | Initial value | Notes |
|---|---:|---|
| Health | 4 | Provisional; lower durability than the Vanguard |
| Attack damage | 2 | Provisional |
| Attack range | Manhattan distance 3–6 | Straight orthogonal line only |
| Targeting mode | Tile-locked | Fires at the captured cell, not a tracking actor |
| Footprint | One cell | No splash damage |
| Execution priority | 2 | After the Vanguard's charged strike and basic melee |

### Action — Aimed shot

- Legal only when the player is 3–6 Manhattan cells away on the same row or column and the complete firing lane is clear.
- A wall, obstacle, or intervening occupied cell blocks the shot.
- Capture the player's current cell as the single affected cell. The intent records action ID `aimed_shot`, target mode `TILE_LOCKED`, and damage 2.
- Telegraph the exact marked cell and a distinct ranged-shot marker; show the expected 2 damage.
- At execution, resolve only against a living player-controlled actor occupying the captured cell. If the cell is empty, cancel with `marked_cell_empty`; never follow the actor or retarget.
- Revalidate the original firing lane at execution. If a new blocker makes that lane illegal, cancel with `marked_cell_line_blocked`.
- The Marksman does not move as part of this action.

### No-shot fallback

- If range, alignment, or line-of-fire requirements are not met at planning time, create an explicit `wait` intent.
- If a previously valid shot becomes illegal after telegraph generation, cancel the shot. Do not convert it into a wait, pursuit, or another attack.
- This first implementation intentionally omits repositioning and multi-cell shots to keep the telegraph/execution contract testable.

### Player counterplay

- Move out of the marked cell before the enemy phase.
- Break the firing lane with an obstacle or another unit where the rules permit.
- Defeat or interrupt the Marksman before its execution slot.
- Avoid assuming diagonal alignment creates a valid shot.

### Acceptance tests

1. A player 3–6 cells away on a clear orthogonal line produces an aimed-shot intent.
2. The intent is tile-locked and captures the player's original cell and 2 damage.
3. A player outside the range, on a diagonal, or behind a blocker does not produce an aimed shot.
4. Moving away from the marked cell makes the shot cancel without damage.
5. Moving to a different cell does not cause the shot to track the player.
6. A blocker introduced into the firing lane before resolution cancels the shot.
7. A blocked or out-of-range Marksman receives a visible wait intent.
8. Repeated planning with the same board state produces the same intent.

### Implementation boundary

Encounter initialization now accepts an optional archetype array parallel to the enemy-cell array. An omitted array preserves the existing all-Vanguard fixtures. Supported values are explicitly validated (`vanguard`, `marksman`, `area_controller`); unknown values or a mismatched array length reject the entire setup before live state is mutated. The actor stores its archetype, and both intent generation and UI presentation read that field. Enemy IDs retain the archetype prefix and original encounter index.


## 10.3 Area Controller — provisional implementation specification

> Status: Prototype implementation choice under delegated development authority. Shape, range, health, damage, and priority are provisional and require playtesting; this does not expand Prototype 0.1 scope.

### Role and learning objective

The Area Controller creates a fixed, avoidable zone threat. It teaches the player to read a multi-cell telegraph and spend movement to leave the threatened footprint before the enemy phase.

### Runtime profile (provisional tuning values)

| Property | Initial value | Notes |
|---|---:|---|
| Health | 5 | Provisional |
| Attack damage | 1 | Per player-controlled actor in the footprint |
| Effective range | Manhattan distance 2–4 | Measured from controller to the player cell at planning time |
| Targeting mode | Area-locked | Captures the original footprint |
| Footprint | Center cell plus its orthogonal neighbors | Up to five cells; clipped at map boundaries |
| Execution priority | 1 | Shares the Vanguard basic-melee tier; stable row/column/actor-ID tie-break applies |

### Action — Ground pulse

- If the player is 2–4 Manhattan cells away, capture the player’s current cell as the center of a five-cell orthogonal cross: center, up, right, down, and left.
- Cells outside the map are omitted. The resulting affected-cell list is fixed in the intent.
- The action uses `ground_pulse`, target mode `AREA_LOCKED`, and provisional damage 1.
- At execution, damage every living player-controlled actor still occupying a captured cell.
- If no living player-controlled actor remains in the captured area, cancel with `marked_area_empty`. Do not move the area, retarget, or select a replacement action.
- If the player is outside the 2–4 planning range, create an explicit `wait` intent.
- This initial implementation has no line-of-sight requirement, movement, persistent hazard, status effect, or multi-turn zone.

### Player counterplay

- Read all highlighted cells, not only the center marker.
- Use movement to leave the entire cross-shaped footprint before ending the turn.
- Defeat or interrupt the Area Controller before its execution slot.

### Acceptance tests

1. A player at Manhattan distance 2–4 produces an area-locked `ground_pulse` intent.
2. The intent captures the fixed cross footprint and one-damage preview.
3. Boundary cells are clipped without generating out-of-bounds cells.
4. A player remaining in the footprint takes the captured damage.
5. A player leaving the footprint takes no damage and the intent cancels as `marked_area_empty`.
6. A player outside the planning range produces a visible wait intent.
7. Resolution never recenters the footprint or silently selects another action.

### Implementation boundary

Encounter initialization now accepts `area_controller` as a third explicit archetype. The actor stores that archetype; the battle UI uses a distinct `C` marker and renders each captured area cell from the intent record. All numerical values and the cross footprint remain provisional pending runtime playtesting.


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

**Confirmed control/telegraph interaction:** when a control effect successfully interrupts an enemy, that enemy's current telegraph is canceled immediately. If the control attempt fails, its telegraph remains unchanged and the enemy proceeds with its planned action. A control effect changes only the affected enemy's telegraph; it does not alter other enemies' intents.

**Confirmed enemy execution order:** enemies execute in a fixed, deterministic order. Sort by a predefined enemy action-priority value; when priorities tie, use a stable battlefield-position order. Show the complete order to the player before the enemy phase begins, and keep it fixed for that phase.

**Confirmed handling of earlier-enemy battlefield changes:** later enemies keep their already-telegraphed target mode and target. Actor-locked actions continue tracking the same actor; tile-locked actions resolve at the original cell; area-locked actions resolve in the original area. If a later action becomes genuinely impossible to execute because the battlefield has changed (for example, its required path or conditions no longer exist), cancel that action. Do not silently choose a new target or generate a replacement attack.

**Confirmed terrain-change interaction:** an existing telegraph remains unchanged after terrain changes. If the original action can still execute, it resolves against its original target and area. If the terrain change makes the action impossible, cancel it. Terrain changes must not silently expand the attack area or change its target.

**Confirmed no-legal-action fallback:** if an enemy's telegraphed action cannot legally execute at resolution time, cancel that action. Do not select a new target or switch to another skill. Do not refund or compensate player AP. Record the cancellation reason in the battle log/debug event for inspection.

**Confirmed Prototype 0.1 action-selection direction:** use a simple deterministic priority AI. During intent generation, check eligible special actions first, then ordinary attacks, then movement or waiting as the final fallback. When multiple legal choices exist within the same priority, select using a fixed deterministic tie-break rule rather than a fresh random choice. Once an intent is generated and telegraphed, its plan remains fixed for the turn; the resolver must not rerun unconstrained target or skill selection at execution time. Exact per-enemy action priorities and tie-break keys will be specified in the enemy content specifications.

## 13. Decisions required before implementation

1. Assign actor-locked, tile-locked, or area-locked targeting to each Prototype 0.1 enemy action; the overall mixed targeting model is confirmed.
2. Whether tile-locked or area-locked actions have any additional range/line-of-sight invalidation conditions after telegraph generation.
5. Exact control success/failure conditions, resistance values, and duration/effect details (to be specified by the relevant skill and combat rules).
11. Exact per-enemy action priority tables and deterministic tie-break keys.
12. Exact preview format for variable damage or conditional effects.
13. Telegraph overlap inspection and layering behavior.

## 14. Change control

Confirmed rules may only be changed with explicit project-owner approval and a decision-log entry. All recommendations and archetype examples in this document remain proposals until approved. Prototype 0.1 scope remains frozen.
