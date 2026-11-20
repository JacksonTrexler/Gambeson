# w7-wide: widescreen hotbar, one lead-in per description line

User, 2026-11-20 (answers-2026-11-20b): "skills don't fit in widescreen"; "In general cut down / standardize skill verbiage: no multiple 'On a foe' lines".

## Readings
- Stretch is `canvas_items`, aspect `expand`, scale `integer` on a 480x270 design: a wider window gets more width, never more height, so the left panel (full window height, card + hotbar + traits + hint + buttons) is as tall as ever. The hotbar was a VBox of 13 px slots: a level-20 bar of 12 ran off the bottom (panel grows both ways, so the card's head and the buttons were clipped too). Wider windows had room for a second column; they just never used it. Screenshots (before and after, levels 1/12/20/28, windows 960x540, 1920x1080, 1920x1200, 2560x1080, 3456x972) are in scratchpad `shot_w7-wide/`.
- Multi-slot skills show "(continued)" in the slot they cover; unchanged.
- Description lines: only dual ("Ally or foe") skills had repeats: the Skill's own "On a foe: Attack" and "On a foe: deals", plus a behaviour's "On a foe: draws it" (Sing). 8 skills at rank 1.

## Calls
1. Wrap, not scale: the hotbar and traits are `SlotColumns` (new Container): one column while it fits, else the fewest columns that do, slots shared evenly, filled top to bottom (so a multi-slot skill's "(continued)" slot stays under it except across a column break; I did not move the break off a span).
2. The HUD gives each its room (`HUD._fit_bar`): window height less the panel's other rows. Columns are MIN_WIDTH 62 px (a name needs room); the panel may take BAR_SHARE 0.45 of the window width, then columns squeeze down to 40 px (names cut) rather than clip. At 16:9 a level-20 bar is 2 columns; level 1 is unchanged (one column, same width).
3. Refit each frame in `_process` (a hint or a name wraps differently once the panel widens, settling over a few frames); per selection it only ever tightens, so columns cannot flip back and forth.
4. Descriptions: one shared pass, `Skill.merge_leads()`, at the end of `markup()`: every later line with the same "On <who>: " lead joins the first with "; ", order kept. It reads what behaviours and effects say too, so a new one joins in without knowing. Facts unchanged; I did not rewrite behaviour wording or lowercase joined segments ("On an ally: Luck: ...; it gains ...").
5. Sing's foe line still has an inner sentence ("...comes. On a suspicious one, a contest ..."), now followed by "; draws it up to...": left, not reworded.

## As built
Files: Scripts/SlotColumns.gd (new), Scenes/UI/hud.tscn (Hotbar, Traits are SlotColumns), Scripts/HUD.gd (_fit_bar, _process), Scripts/Skill.gd (merge_leads, lead_of).
Tests: new `Tests/slot_columns_test.gd` (layout table, min width, squeeze, column-major order); `sweep_test.test_description_leads` (every skill, ranks 1-3: no lead repeats; dual spell and Sing; merge_leads unit). Updated wording: `adventurer_test.test_starter_spells_on_allies` ("On a foe: Attack (int mod); deals ..."), `lure_test` (Sing: "; draws it up to 2 tiles ..."), `equip_test.test_traits` (type SlotColumns).
Mutation spot-checks: merge_leads bypassed -> test_description_leads fails (26); cols forced to 1 -> slot_columns_test fails (7). Both reverted.
Suite: 10457 checks, 0 failed (989 tests) at start; 10532 checks, 0 failed (991 tests) at end.
Undone: slot spans are not kept whole across a column break; a very large bar at 16:9 (4+ columns) squeezes names.
