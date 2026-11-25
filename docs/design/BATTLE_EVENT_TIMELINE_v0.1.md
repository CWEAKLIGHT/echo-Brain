# ECHO — Battle Event and Resolution Timeline v0.1

> Status: Working specification for Phase 0  
> Target: Prototype 0.1  
> Branch: `prototype/0.1`  
> This document separates confirmed rules from proposed ordering and unresolved decisions. A proposed sequence is not an approved gameplay rule until explicitly accepted.

## 1. Purpose

Define a single, inspectable order for resolving battle actions and their consequences. The goal is to prevent systems from independently applying damage, death, telegraph cancellation, status effects, companion actions, or turn transitions in conflicting orders.

This document is a design and implementation contract draft. It does not implement gameplay code.

## 2. Scope

### Included

- Player action request, validation, target confirmation, and execution
- AP spending
- Movement and attack resolution boundaries
- Damage and death handling
- Enemy telegraph creation, cancellation, and execution boundaries
- Companion command and support-action boundary
- End-of-turn and battle-end checks
- Event logging requirements

### Excluded from Prototype 0.1

- Run economy and chapter progression
- Echo contracts and world-tone modifiers
- Collections and broad status-stack synergies
- Full meta-progression and unlock systems
- In-run save, checkpoint, or restoration

## 3. Confirmed rules

The following are already confirmed project rules and must not be silently altered:

1. The battlefield is a square grid and movement is orthogonal only; diagonal movement is not allowed.
2. A prototype move costs 1 AP and can move up to two grid cells.
3. The base player turn budget is 3 AP.
4. Walls, obstacles, and other units block movement.
5. Unused AP is cleared at the end of the turn.
6. Actions resolve immediately. The player may cancel only before target confirmation; an executed action cannot be undone.
7. Enemy telegraphs are generated at the start of the player turn.
8. Enemy execution follows a fixed order that is clearly shown to the player.
9. An enemy's telegraph is canceled immediately when that enemy dies.
10. Prototype companion actions are issued by the player and then execute automatically. The companion has one independent support action per player turn and does not spend the player's 3 AP.
11. The companion has independent health and can be attacked or defeated.
12. There is no in-run save, checkpoint, or restoration. Only out-of-run progression may persist.

## 4. Proposed action lifecycle

The following lifecycle is a proposed technical sequence for review. It does not settle unresolved gameplay outcomes such as control-versus-telegraph behavior.

### 4.1 Player action

1. **Input** — UI sends an action request containing actor, action definition, and intended target or destination.
2. **Validation** — authoritative battle rules check actor state, available AP, range, line/path legality, target validity, and other action requirements.
3. **Preview** — UI displays the validated target/range result. Preview must not mutate battle state or spend AP.
4. **Confirmation boundary** — player confirms the action. Cancellation is allowed only before this boundary.
5. **Commit cost** — the action's AP cost is deducted once. If validation fails, no AP is spent.
6. **Resolve action** — the authoritative action resolver applies movement, attack, or skill effects.
7. **Resolve consequences** — resulting damage, defeat, telegraph lifecycle changes, and eligible triggers are processed according to the approved event order.
8. **Refresh presentation** — UI reads the authoritative state and updates AP, actors, telegraphs, and feedback.
9. **Check battle end** — evaluate victory/defeat conditions after the action's consequences have settled.

**Open implementation question:** whether AP is deducted immediately before or immediately after the action's state mutation. The proposal above deducts after successful confirmation and before resolution, so an action cannot execute without paying its cost. This needs approval before code is written.

### 4.2 Failed or canceled action

- A canceled action before target confirmation must not change battle state or spend AP.
- An invalid action request must not change battle state or spend AP.
- An action that has crossed the confirmation boundary is not undoable.
- Error feedback should explain why an action is unavailable without exposing internal implementation details.

## 5. Proposed movement resolution

1. Validate the complete requested path.
2. Reject diagonal, blocked, out-of-bounds, or otherwise illegal movement.
3. Confirm the move and charge 1 AP.
4. Move the actor along the accepted path.
5. Publish the resulting position.
6. Evaluate any movement-triggered effects only if such effects exist in the current prototype rules.
7. Check battle-end conditions if movement can cause a relevant terminal condition.

**Open:** whether movement is always atomic (all requested cells or none) or can stop at the last legal cell. Recommended prototype baseline: atomic validation and all-or-nothing movement, to avoid ambiguous partial-cost behavior. This recommendation is not yet approved.

## 6. Proposed attack and damage resolution

A candidate order for a confirmed attack is:

1. Revalidate the committed action's target and required conditions.
2. Resolve hit/miss or other attack outcome, if such outcomes exist in the approved combat model.
3. Calculate damage using the approved damage formula.
4. Apply damage to the target.
5. Evaluate defeat immediately when health reaches zero or below.
6. If an enemy is defeated, mark it defeated and cancel its telegraph immediately.
7. Resolve any approved on-hit, on-damage, on-defeat, or interruption effects in their explicitly defined priority.
8. Refresh UI and event log.
9. Check battle-end conditions.

**Not decided here:** armor formula, critical hits, damage rounding, overkill handling, simultaneous damage, status ordering, and whether a defeated unit can produce any already-queued trigger. These require a dedicated combat math and event-priority decision.

## 7. Enemy telegraph lifecycle boundaries

Confirmed lifecycle facts:

- Telegraphs are created at the start of the player turn.
- The enemy's telegraph is canceled immediately when that enemy dies.
- Enemy actions execute in a fixed visible order.

Required invariant:

> The telegraph display and the eventual enemy execution must be derived from the same authoritative action/intent definition. UI must not independently reconstruct the enemy's attack.

The following remain open and must be resolved in the Enemy AI and Telegraph System specification:

- Target moves before execution.
- Target leaves the telegraphed area.
- Successful control or interruption.
- Failed control or interruption.
- Earlier enemy actions invalidate later enemy plans.
- Terrain changes after telegraph creation.
- No legal target or destination remains at execution time.
- Whether a telegraph is locked to a target, a tile/area, or a revalidated rule.

No fallback behavior is approved by this document.

## 8. Proposed player-turn and enemy-phase boundaries

The current confirmed high-level flow is:

1. Player turn begins; enemy telegraphs are generated.
2. Player takes actions within the 3 AP budget.
3. Player ends the turn.
4. Enemies execute in the fixed visible order.
5. State settlement occurs.
6. The next player turn begins.

A more detailed candidate phase breakdown is:

### Player turn start

- Reset the player's AP to the approved turn budget.
- Generate enemy intents/telegraphs from enemy decision data.
- Freeze and display the execution order for the upcoming enemy phase.

**Open:** exact ordering between AP reset, status duration updates, companion support availability reset, and telegraph generation.

### Player action window

- Accept only validated player actions.
- Keep existing telegraphs stable unless a confirmed rule explicitly cancels or changes one.
- Do not let the UI mutate authoritative battle state.

### Player ends turn

- Clear unused AP.
- Close the player action window.
- Begin enemy execution.

### Enemy phase

- Process enemies in the visible fixed order.
- Before each enemy acts, determine whether its actor and planned action remain eligible under the final approved telegraph rules.
- Resolve its action through the same action definition used by the telegraph.
- Cancel the telegraph immediately if the enemy dies before its turn to act.

The eligibility and fallback rules are open; this document does not define them.

### Turn settlement and next turn

- Resolve approved end-of-phase effects.
- Evaluate victory/defeat.
- If battle continues, begin the next player turn and generate the next set of telegraphs.

**Open:** whether end-of-phase effects happen before or after the final victory/defeat check. This must be resolved with the status and event-priority rules.

## 9. Companion action boundary

Confirmed:

- Player issues a command.
- Companion executes automatically.
- Companion has one independent support action per player turn.
- This action does not consume the player's 3 AP.

Open decisions:

- Whether the companion command is issued during the player's normal action window or through a separate command window.
- Whether a companion command can be changed after selection but before execution.
- Exact timing of companion execution relative to player actions and enemy telegraphs.
- Whether companion action is available before or after the player ends the turn.
- How a companion action is handled if its selected target becomes invalid.

Until these are approved, code must not assume a final companion timing model.

## 10. Battle-end resolution

Candidate requirements:

- Evaluate victory and defeat only after the current atomic action and its required consequences have settled.
- Once a terminal battle result is committed, reject further combat actions.
- Resolve the result once; repeated event notifications must not duplicate settlement.
- Telegraphs and queued enemy actions must not continue after the battle is terminal.

**Open:** exact win/lose conditions for the Prototype 0.1 encounter and precedence if both sides become defeated in the same resolution chain.

## 11. Event and log requirements

Every authoritative battle event should be traceable with at least:

- Battle-local sequence number
- Event type
- Acting entity ID, if applicable
- Target entity ID, if applicable
- Action/intent ID, if applicable
- Source system
- Result summary
- Relevant state change references

Suggested event categories (names are provisional):

- `action_requested`
- `action_rejected`
- `action_confirmed`
- `ap_spent`
- `actor_moved`
- `attack_resolved`
- `damage_applied`
- `actor_defeated`
- `telegraph_created`
- `telegraph_canceled`
- `enemy_action_started`
- `enemy_action_resolved`
- `companion_command_issued`
- `companion_action_resolved`
- `turn_ended`
- `battle_won`
- `battle_lost`

Event names are implementation suggestions, not player-facing text and not final API names.

## 12. Core invariants

These invariants should be enforced and tested:

1. A rejected or pre-confirmation-canceled action spends no AP.
2. A confirmed action spends its cost no more than once.
3. An action cannot be executed twice from duplicate input.
4. Movement never crosses a blocked cell or diagonal edge.
5. A defeated enemy cannot execute a later action.
6. A defeated enemy's telegraph is removed immediately.
7. Telegraph display and enemy execution share one authoritative intent/action definition.
8. The visible enemy order matches actual execution order.
9. The companion's independent support action does not silently consume player AP.
10. A terminal battle state cannot accept further combat actions.
11. No in-run battle state is written for restoration.

## 13. Prototype 0.1 test cases

- Cancel a move before confirmation: position and AP remain unchanged.
- Submit an invalid move: position and AP remain unchanged.
- Confirm a legal move: exactly 1 AP is spent and the actor moves no more than two orthogonal cells.
- Attempt to cross a wall, obstacle, or unit: movement is rejected.
- Confirm an attack: its AP cost is charged once.
- Defeat an enemy before its scheduled action: its telegraph disappears and it does not act.
- Run a full enemy phase: execution order matches the visible order.
- Compare each ordinary enemy telegraph with its actual executed target, area, damage, and effect.
- Issue a companion command: the companion performs at most one support action for the player turn and player AP is unchanged.
- Trigger battle victory or defeat: the result is committed once and subsequent combat input is rejected.
- Repeatedly play complete encounters: no soft-lock, duplicate action, or stale telegraph appears.

## 14. Decisions required before implementation

The following decisions should be reviewed and approved before P0/P1 implementation:

1. AP charge timing relative to action resolution.
2. Atomic versus partial movement when a requested path is obstructed.
3. Exact damage/death/trigger priority.
4. Target movement and area-exit behavior for telegraphs.
5. Control/interruption success and failure behavior.
6. Fixed enemy execution-order sorting rule.
7. Invalidated later enemy action fallback.
8. Terrain-change behavior after telegraph generation.
9. Companion command and execution timing.
10. End-of-phase status settlement and battle-end check order.
11. Simultaneous defeat precedence.

## 15. Change control

Any change to a confirmed rule must be explicitly approved and recorded in the decision log before implementation. Any proposed sequence in this document remains a proposal until approved. Prototype 0.1 scope remains frozen unless the project owner explicitly authorizes a scope change.
