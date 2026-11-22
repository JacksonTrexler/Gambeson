# Level in the glow (branch w7-glow, 2026-11-20)

The user (answers-2026-11-20b): "On level up, flash a units glow to 2x intensity briefly. Units with a higher level have a subtly larger glow, lower level have a subtly smaller glow. (while not indicating targeting)".

## Calls
1. **Flash**: `Unit.level_up()` emits `leveled_up(u)`; the unit itself reacts (`_on_leveled_up`): a tween of the glow shader's `flash` uniform from `Unit.FLASH` (2.0) down to 1 over `FLASH_TIME` (0.6 s, ease out). Alpha is clamped on screen, so a glow already near full gains less than a true 2x.
2. **Reference**: the average level of the player's side (`Battle.members(command.faction())`), not the selected unit, so sizes don't jump as selection moves. Viewer-side, same for every unit.
3. **Scale**: `Unit.level_reach(level, ref)` = 1 + 0.03 per level of difference (`REACH_PER_LEVEL`), clamped to +-0.15 (`REACH_MAX`). Applied by growing the shader's quad (`reach` uniform, in `vertex()`), so the gradient is not clipped; `set_glow()`'s scale is untouched.
4. **"Not indicating targeting"**: `HUD._target_glow()` (lifted out of `glow_of()`, which is unchanged in result) says what an armed/aimed skill does to a unit's glow; any unit it speaks of keeps plain size (`NOT_TARGETED` = -2 otherwise). Readiness for an order (own side's command glow) is not targeting, so it is sized: on the player's own turn with a skill armed, only foes the skill reaches stay plain-sized. Say if command readiness should also hold the size.
5. **Silhouettes** (only a shape made out) get plain size, as with facing; everyone else uses its true level, own side and foes alike, disguises included.
6. **Refresh**: the size is a `look_of()` field (`reach`) applied in `_apply_look()` via `Unit.see_reach()`, so it follows on the next HUD refresh, not instantly on a level up.

## As built
`Scenes/UI/unit_glow.gdshader` (`flash`, `reach`, `vertex()`), `Unit.gd` (signal, consts, `_on_leveled_up`, `level_reach`, `see_reach`), `HUD.gd` (`look_of` reach, `level_reach`, `_target_glow`, `glow_of`).

## Tests
New: `hud_test.test_glow_by_level` (table on `Unit.level_reach`, foe sized vs side average, plain while targeting, flash after level up). Mutations: ignoring targeting; flash starting at 1: both failed, reverted. No existing test changed. Screenshot: Meadows with levels 1/5/10 (`scratchpad/shot_w7-glow/cmp.png`): reaches 0.89 / 1.01 / 1.15.
