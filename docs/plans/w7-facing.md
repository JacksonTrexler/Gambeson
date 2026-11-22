# Facing in the glow (branch w7-facing, 2026-11-20)

The user (answers-2026-11-20b): "No need to indicate the direction a unit is facing unless wisdom is high. Indicate look direction by making glow strength subtly stronger in that direction instead of an arrow: it should be subtle it doesn't come up super often and shouldn't be something players constantly think about."

## Readings
- Facing was drawn as a pale chevron (`Unit.heading_tick`, a child of the sprite, so a silhouette hid it) shown to everyone. It is gone.
- The glow was a bare `Sprite2D` (radial gradient, `modulate` set by `Unit.set_glow()` / `HUD._apply_look()`), with no shader.

## Calls
1. **High wisdom is the word "high"** (`Unit.HEADING_SIGHT := &"high"`, `Difficulty.WORDS`: the `difficult` rung). `Difficulty.STAT_SCORE` gains `difficult: 14` (+2), beside `unfair: 16` (very high, the adventurer's). 14 is my pick: high but under what the adventurer has across, so it needs only a little wisdom, not a specialist. Say if it should be 16 (then only adventurers and such read it).
2. **The viewer is `HUD.eyes()`**: the selected unit if the player is commanding one, else its observer (leader, else whoever of its side stands). The same eyes the HUD already draws the map through, not a new notion. `Unit.reads_heading(viewer)` is the one rule (`viewer.stat(&"wisdom") >= Difficulty.stat_at(HEADING_SIGHT)`).
3. **Whose facing shows**: every visible unit, own side and foes alike, except a silhouette (only a shape of it is made out). A disguise gives nothing away: the lean is its true facing, same as the old chevron.
4. **A lean, not a pointer**: the glow's alpha is up to 1.5x on the facing side (`Unit.HEADING := 0.5`), fading by `smoothstep(-0.1, 1, cos)` round to nothing a little behind square-on. Strength is a screen-space vector, `heading`: its direction is the facing, its length the lean; zero (the default) is the plain glow, so targeting reads exactly as before.
5. **Glow API**: `Scenes/UI/unit_glow.gdshader` on each unit's own `Glow` material (`GLOW_SHADER`). Uniforms are one per thing the glow says (now only `heading`); `Unit.glow_param(name, value)` is the one way in. The level-up flash and level radius (next builder) add a uniform and a line each; `set_glow()`'s modulate and scale are untouched and still own side colour, strength and targeting.
6. **Decided in `HUD.look_of()`**: it gains `heading` (`HUD.heading_seen(u)`), applied by `_apply_look()` through `Unit.see_heading()`; `Unit.facing`'s setter refreshes the glow, so a turn shows at once.

## As built
`Scenes/UI/unit_glow.gdshader`, `Unit.gd` (chevron, `heading_tick` and `_draw_tick` removed; `glow_param`, `reads_heading`, `see_heading`, `_show_heading`), `HUD.gd` (`look_of`, `heading_seen`, `_apply_look`), `Difficulty.gd` (`STAT_SCORE`).

## Tests
New: `hud_test.test_facing_in_the_glow` (wisdom 13 reads none; 14 leans the foe's glow the way it faces; follows a turn; no `Facing` node on anyone). Mutation: `reads_heading` returning true fails it; reverted. No existing test changed (none read the chevron). Screenshot check: a Meadows battle, facings set round the compass, leader wisdom 8 vs 16: even glow vs a visible but gentle lean (`scratchpad/shot_w7-facing/cmp2.png`).
