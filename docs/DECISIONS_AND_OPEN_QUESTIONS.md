# ECHO — Decisions and Open Questions

Use these labels consistently:

- **Confirmed** — explicitly approved by the project owner.
- **Planning baseline** — current planning direction, not necessarily final.
- **Open** — requires a decision.
- **To test** — requires prototype evidence.
- **Rejected** — explicitly ruled out.

## Confirmed foundations

- 2D turn-based tactical roguelite.
- Android, landscape-first; single-player and offline.
- Godot 4.x with GDScript.
- Pure top-down square-grid battlefield.
- Prototype movement costs 1 AP and moves up to two orthogonal cells.
- Base player turn budget is 3 AP.
- Actions resolve immediately and may only be canceled before target confirmation.
- Enemy telegraphs are generated at the start of the player turn.
- Telegraph targeting uses a mixed model: each action may lock to an actor, a grid cell, or an area according to its design; the telegraph must communicate the selected mode.
- Actor-locked attacks continue tracking their designated actor; tile-locked attacks resolve at the originally marked cell; area-locked attacks resolve in the originally marked area.
- If an actor-locked action's designated target is defeated before execution, that action is canceled, does not retarget another actor, and does not refund or compensate player AP; the enemy's action slot is considered resolved.
- A successful control/interruption immediately cancels the affected enemy's current telegraph; a failed control leaves that telegraph unchanged. The effect does not alter other enemies' telegraphs.
- Enemy execution order is fixed and visibly communicated: sort by predefined enemy action priority, then by stable battlefield position for ties; show the complete order before the enemy phase and keep it fixed for that phase.
- Earlier enemy actions do not silently rewrite later enemies' telegraphed targets: actor locks continue tracking the same actor, tile locks resolve at the original cell, and area locks resolve in the original area. If a later action becomes genuinely impossible because the battlefield changed, cancel it rather than retargeting or generating a replacement attack.
- Terrain changes do not silently alter existing telegraphs: if the original action remains possible, it resolves at its original target/area; if terrain makes it impossible, cancel it. Terrain changes cannot silently expand its area or change its target.
- An enemy's telegraph is canceled immediately when that enemy dies.
- Prototype companion actions are player-commanded, then automatically executed; the companion has one independent support action per player turn.
- No mid-run saves, checkpoints, or run restoration. Out-of-run progression may persist.
- ECHO and Shiguang must remain completely separate.

## Prototype 0.1 scope baseline

One playable Oathkeeper (Sevrin), one temporary Hunter companion, three ordinary enemy types, one battlefield, five to six skills, the AP and telegraph systems, victory/defeat resolution, and Android touch interaction.

## Open questions — do not silently decide in code

- Which targeting mode (actor-locked, tile-locked, or area-locked) should each individual Prototype 0.1 enemy action use?
- Do tile-locked or area-locked actions have additional range/line-of-sight invalidation conditions after telegraph generation?
- What should an enemy do when its planned action has no legal target or destination?
- How should overlapping telegraphs be layered and inspected on a phone screen?
- What is the final event-resolution order for damage, death, status effects, telegraph cancellation, and triggers?
- What are the final damage, armor, health, and control formulas?

## To test

- Battlefield dimensions and camera scale.
- Touch target sizes and long-press behavior.
- Telegraph readability with multiple enemies.
- Encounter pacing and skill balance.
- Performance on target Android hardware.
