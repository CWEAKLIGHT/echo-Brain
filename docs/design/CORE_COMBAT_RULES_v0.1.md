# ECHO — Core Combat Rules v0.1

> Status: Maintainer-selected implementation baseline under delegated design authority  
> Target: Prototype 0.1  
> This document closes the first-pass rules needed to implement P0. Values marked as tuning baselines must be validated in playtests.

## 1. Scope

This specification covers the smallest reliable combat loop: grid occupancy, orthogonal movement, player AP, direct attacks, health, defeat, turn transitions, and deterministic enemy intent execution. It does not add armor, critical hits, random hit chance, status stacking, run persistence, or meta-progression.

## 2. Grid and movement

- The battlefield is a bounded square grid. Prototype encounter target: 8×8 initially; dimensions remain encounter-tuning data.
- Cells are addressed by integer coordinates.
- Orthogonal adjacency only. Diagonal movement and diagonal attacks are not legal unless a later action explicitly defines otherwise.
- Walls, obstacles, and living actors block movement.
- A movement request contains a complete ordered path of one or two cells.
- Validate the entire path before committing. If any step is out of bounds, diagonal, blocked, occupied, repeated, or non-adjacent to the previous cell, reject the entire move and spend no AP.
- A valid move costs 1 AP, deducted once immediately before state mutation.
- Movement is atomic: either all requested steps occur or none do.
- Movement does not trigger opportunity attacks or hidden reactions in Prototype 0.1.

## 3. Player AP

- Player AP maximum and turn-start value: 3.
- Prototype move: 1 AP.
- Prototype basic attack: 1 AP.
- Basic skill: 1 AP.
- Strong skill: 2 AP.
- Unused AP is cleared when the player ends the turn.
- A request is validated before AP is spent. AP is deducted after confirmation and immediately before execution.
- If execution cannot begin because validation fails, no AP is spent.
- Once execution begins, the action is not reversible and AP is not refunded, including when a later captured target becomes invalid before an enemy action resolves.
- No AP refund or extra-action trigger is implemented in the first combat slice.

## 4. Health and damage

- Health is integer-valued.
- Prototype damage is deterministic, direct integer subtraction.
- No hit chance, critical hits, damage variance, armor mitigation, damage-over-time, or damage reflection in the first combat slice.
- Damage is clamped so current health never falls below zero.
- An actor is defeated immediately when health reaches zero.
- A defeated actor is removed from occupancy and cannot move, act, be selected as a new target, or receive further actions.
- When an enemy is defeated, its current telegraph is canceled immediately.
- The first slice uses explicit per-action damage values. A shared formula can be introduced later if the skill roster requires it.

## 5. Player action transaction

Every player action follows one authoritative path:

1. Receive action request.
2. Validate actor state, AP, target, range, path/line, and action-specific requirements.
3. Produce a read-only preview.
4. Wait for player confirmation.
5. Deduct AP once.
6. Resolve the action and apply its effects.
7. Resolve defeat and telegraph cancellation immediately.
8. Publish resulting events and refresh UI.
9. Check terminal battle conditions.

Canceling before confirmation or submitting an invalid request changes neither AP nor battle state. No action can be undone after confirmation.

## 6. Turn flow

1. At player-turn start, set player AP to 3 and refresh the companion's one support-action availability.
2. Generate one intent for each eligible living enemy using current authoritative state.
3. Sort intents by action priority (special attack, ordinary attack, movement/wait), then stable board position (row, then column), then stable actor ID.
4. Publish the complete order and telegraphs before accepting player actions.
5. Player performs actions and may issue the companion's one command during this action window. Companion commands execute immediately after validation and do not spend player AP.
6. When the player ends the turn, clear unused AP and close player input.
7. Execute the already captured enemy intents in the displayed order. Do not rerun AI or select replacement actions.
8. Resolve each action's effects and immediate defeats before proceeding to the next intent.
9. Check battle result. If the battle continues, begin the next player turn.

No timed status effects are included in the first combat slice, so no status-duration tick is inserted into this sequence.

## 7. Enemy intent execution

- An intent is a captured action definition plus source, target mode, target actor/cell/area, preview, and order.
- Telegraph presentation and execution read the same intent record.
- Actor-locked attacks track the same actor; tile-locked attacks resolve at the captured cell; area-locked attacks resolve in the captured area.
- A defeated source enemy cannot act and its telegraph is canceled.
- If a captured intent is no longer legal, cancel it and record a reason. Never retarget, switch skills, expand an area, or silently replace the intent.
- Successful control cancels the affected enemy's current intent immediately; failed control leaves it unchanged.
- An invalidated enemy action consumes that enemy's action slot for the phase.

## 8. Battle end

- Victory: all ordinary enemies in the encounter are defeated.
- Defeat: the Oathkeeper is defeated.
- Companion defeat alone does not end the battle.
- The battle result is committed once after the current atomic action and its immediate defeat consequences settle.
- Once terminal, reject further combat input and cancel all remaining enemy intents.
- Prototype 0.1 does not contain multi-target simultaneous damage chains; if later introduced, simultaneous terminal outcomes require a new explicit rule.

## 9. Event order and invariants

For a damage action:
1. Confirm action and pay cost (for player actions).
2. Apply integer damage.
3. Clamp health to zero.
4. If health is zero, mark defeated and remove occupancy.
5. If the defeated actor is an enemy, cancel its telegraph immediately.
6. Emit the resolved action/damage/defeat events.
7. Evaluate victory/defeat.
8. Reject further actions if terminal.

Core invariants:
- Invalid or pre-confirmation-canceled player actions spend no AP.
- A confirmed player action pays AP exactly once.
- Movement is orthogonal, bounded, and atomic.
- A defeated actor never acts again.
- Enemy telegraph and execution use the same captured intent.
- Visible enemy order equals actual execution order.
- Companion support never silently spends player AP.
- No in-run battle state is serialized for restoration.

## 10. First-slice test checklist

- [ ] Legal one-cell and two-cell moves succeed for 1 AP.
- [ ] Diagonal, blocked, occupied, out-of-bounds, and malformed paths reject atomically.
- [ ] Invalid/canceled actions preserve AP and state.
- [ ] Confirmed actions deduct AP exactly once.
- [ ] AP cannot become negative.
- [ ] Damage is deterministic and health clamps at zero.
- [ ] Defeated actors are removed from occupancy and cannot act.
- [ ] Enemy death immediately cancels its telegraph.
- [ ] Enemy order is stable and matches execution.
- [ ] Actor/tile/area lock behavior matches the captured intent.
- [ ] Successful and failed control produce the specified telegraph behavior.
- [ ] Victory/defeat commits once and blocks further input.
- [ ] No battle-state save or checkpoint is created.
