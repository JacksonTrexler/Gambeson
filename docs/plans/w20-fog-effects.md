# w20-fog-effects (card w18-fog-effects, ?319)
Goal: freeze Overlay-drawn ground effects (layers, marks) to the look last seen, as w18-fog-frozen did terrain.
## Calls
- `Overlay._ghost[cell] = {layers (copied Layer), trodden, marks (tile_view's visible ones)}`, set in `_freeze` (same transition cells as `memory`), erased on re-entry, cleared on rect rebuild.
- `_sighted(c)`: out of sight (fog on, not in `_fog_clear`) draws only the ghost; so layers/marks laid out of sight, and on never-seen tiles, are now hidden (was live leak).
- `_layers` split into `_stack(c, stack, trodden)` shared live/ghost.
- Not frozen: lattice (panes/starpower), debris, traps (HUD-gated already or not asked).
- Marks ghosted as the same Mark object (kind/tint/swell don't change); animation continues.
## Tests
`sight_test.test_fog` +5 checks (ghost set/live/kept/dropped; 1 ms budget on fog_of_war alone). Measured 83 us/move on M3.
Mutations: `_sighted` -> true fails the laid-out-of-sight check; budget <1 us fails. 
## Undone
No visual shot.
