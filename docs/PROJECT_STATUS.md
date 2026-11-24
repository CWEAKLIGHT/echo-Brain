# ECHO — Project Status

## Current milestone

**Phase 0 — Project setup and design closure**

The GitHub repository and minimal Godot project skeleton have been created. No gameplay systems have been implemented or tested in-engine yet.

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
- [ ] Begin P0 gameplay implementation

## Safety and scope constraints

- ECHO is independent from Shiguang.
- Do not add GitHub Actions workflows or paid automation without separate approval.
- Do not implement in-run persistence, checkpoints, or run restoration.
- Unconfirmed design proposals remain unresolved until explicitly approved.
