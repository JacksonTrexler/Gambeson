# Warcry's preview (z-wcpreview)

## Readings
Card: draw the default "nearest N" faintly while a pick-N skill is armed with nothing picked; generic for any `picks()` skill; cast and AI unchanged.

## Calls
1. New hook `Behaviour.defaults(c) -> Array[Unit]` (default empty), the counterpart of `picks()`: what the skill takes when nothing is picked. `Battle.defaults_of(caster, skill)` unions the behaviours' answers (as `picks_of` sums), `HUD.preview()` is that while `picking()` and `picked` is empty. Warcry's `chosen()` falls back to the same `defaults_of(c)`, so the preview and the cast cannot drift.
2. Not drawn through `Behaviour.footprint()`: that hook answers "which tiles an area covers for a hovered cell", while the default is a set of units with no cell to hover. Reusing it would have meant a fake cell argument. Footprint is left for area skills.
3. Look: the picked foes' red brackets, but thin and faint (alpha 0.25 + pulse) and no number; the first pick clears it.

## As built
Behaviour.gd, Battle.gd, HUD.gd (`preview`), Overlay.gd (`_draw_picks`), Behaviours/warcry.gd, Tests/warcry_test.gd (extended `test_the_hud_toggles_picks`: preview is the nearest foe with nothing picked, empty after the first pick). Frames: `S/shot_z-wcpreview/` (m00000100.png preview, m00000118.png picks).
Mutation: preview ignoring `picked.is_empty()` fails "the first pick clears the preview".
