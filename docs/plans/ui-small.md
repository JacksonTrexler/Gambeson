# Small UI items (branch `q-ui`)

Seven open items. Tests: `Tests/ui_small_test.gd` (5 tests, 13 checks). Frames in `scratchpad/shot_q-ui/`.

## Readings

- Nothing persisted but key binds (`KeyBinds`, `user://keybinds.cfg`). No Settings value was saved.
- Floating numbers (`Overlay.float_text` / `float_roll`) ran on plain tweens; `HUD._hurry()` only reached the walks and the turn show.
- The Guide's Playing page spelled "Hold F" in a constant string.
- A near-miss gap already had two rings (the skill's reach round the caster, a ring round the target) but only when the plan couldn't get in reach at all (`Overlay._gap`).
- The faction border is the bar trim (`Unit.trim`, a 1px StyleBoxFlat border); high contrast only brightened glow and text.
- "Worn skill": the todo comes from `docs/plans/exhaustion.md` (2026-11-09), where "worn" meant exhausted (worn by use). The exhaustion pips on the slot were built later (356ebb1), so that reading is already done. The brief's reading, a skill changed by worn equipment, matches `Unit.mods()` (an emblem's modifier), which showed as symbols on the tooltip only.

## Calls

1. **Settings saved** in `user://settings.cfg`, a new `Prefs` class (`get_pref`, `put`, one section). Routed through it: allied glow, high contrast, suspicious marks, keep slot, hand over (all the HUD's Settings toggles; trivially the same shape). Loaded as the HUD builds its Settings. The tests point `Prefs.SAVE` at `user://settings_test.cfg` (`Tests/run.gd`, cleared before each test) so the suite never reads or writes the player's file.
2. **Floaters hurried** through the same `Overlay.hurry()` the walks use (tracked tweens, scaled at creation and each frame). Same factor `HUD.HURRY`.
3. **Guide key**: `{hurry}` in the page text, filled by `KeyBinds.key_of(&"hurry")` when the page is read. Other fixed keys in the Guide (P, H, Space, Tab) are still words; left.
4. **Near-miss circles**: when the hovered target is within 1 tile beyond the skill's reach from where the caster stands (`Overlay.NEAR`), two small faint circles, one on each unit, plus a dashed line from the reach ring's edge to the target's circle. It shows whether or not a walk would get there (the case the todo is about is where the caster's own tile decides). Circle radius is drawn at 0.17 tiles per point of size, not the real 0.05 / 0.02 contributions (a few pixels, invisible); the picture says "bigger units reach further", not the exact arithmetic. No numbers or text. Luck.MARGIN is not shown.
5. **High-contrast borders**: the trim becomes 2px and stands out one pixel further so it doesn't cover the bars (`Unit._heavy_trim`, driven by `set_glow`'s existing contrast flag).
6. **Worn mark**: a small gold diamond on the slot (left of the type stripe) whenever the unit's worn emblem modifies that skill (`SkillSlot.modded`). The exhaustion reading needed nothing new (pips exist).
7. **Screenshots**: see below.

## What the screenshots showed

- **Tapped saturation** (`sat_levels.png`: plain, 75%, 0%, 50%): 0% is clear grey with a weak glow; 50% is plainly half-faded; 75% is only a faint dulling, hard to tell from full colour on this dark Fighter sprite (a lighter sprite would show it better). All three read as intended; the 75% step is subtle by design (SAT_LOW).
- **Jam's "Jammed ??"**: a Jammed unit's card shows a red "Jm" chip (the Jam skill's mark), beside the status icons. The name "Jammed ??" appears only in the chip's tooltip and the Glossary, not on the chip.
- Hover onto a tile in the museum logs "No TileSet atlas source with id -1" (HUD._tile_icon); not from this branch, left.

## As built

`Scripts/Prefs.gd` (new), `Scripts/HUD.gd` (settings load/save), `Scripts/Overlay.gd`, `Scripts/Guide.gd`, `Scripts/Unit.gd` (`_heavy_trim`, `_stack`), `Scripts/SkillSlot.gd`, `Tests/run.gd`, `Tests/ui_small_test.gd`.
