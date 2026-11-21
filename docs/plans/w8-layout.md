# w8-layout: the hotbar's layout (band names, spans as one button, spans kept whole)

Baseline suite: 10619 checks, 0 failed (997 tests). Plans read: w6-slots, w7-wide, w8-bar.

## Readings and calls

1. **The band's names (w8-bar's undone item).** Two causes, one rule. (a) `_fit_bar` reserved the band's room as one column of
   rows and also took off a 3 px gap that the panel's `others` already counts, so the band always got a row too few and wrapped
   into three narrow columns ("Hollo", "Darkvi"). (b) A column was never wider than `MIN_WIDTH` 62 whatever the names. The rule:
   **a slot says what it wants (`SkillSlot.want_width()`, meta `SlotColumns.WANT`: key, icon, whole name, numeral, dot, ring) and
   a column is at least that wide while `max_width` holds the columns; the band reserves the rows its names stand in
   (`SlotColumns.standing_rows()`: the fewest columns that many names fit) before the bar takes the rest.** If the panel's room
   still can't hold them, the columns squeeze as before and names are cut (the tooltip has them whole): the fallback, not a tooltip
   instead. At 16:9 (1920x1080, 1280x720, 960x540; all one 480x270 design) a level-20 mage's band is now two columns, whole names
   ("Hollow Bones", "Darkvision"). A narrower (4:3, 960x720) window is one column for the bar and two for the band.
   Call: the **hotbar uses the same rule** (one rule), so its columns are as wide as its longest name when the width holds them;
   where the rows need more columns than the width holds it still squeezes ("Bludgeo"). Not the band alone, because the same
   cut ran on the bar. A one-column list is unchanged (no minimum width).
   Call: the 3 px gap removed from the band's room is a fix to `_fit_bar`'s arithmetic (the bar may stand 3 px taller in a few
   windows).
2. **A multi-slot skill as one button.** `SlotColumns` lays a skill that spans n slots (meta `RUN`) as one tall button over its
   slots' rows, raised (`z_index` 1); the slots it covers stay beneath it unseen (`self_modulate.a` 0). Calls: *tall*, not wide:
   the list is a vertical stack, so a span is as many rows tall; its content (icon, name, numeral, key) is one row's, centred. The
   button answers for every slot it covers (`SkillSlot.slot_at(y)`): a drop or a right-click on its second row is the covered
   slot's own (index + row), so `bar_place` / `bar_clear` behave as before; a click is `use_slot(anchor)` (it already resolved a
   covered index to its anchor); number keys never touched. The covered slots' number is not drawn (the button shows its first
   slot's, once, as the tooltip does): a covered slot's key still works. "(continued)" stays only where a span had to be cut (item 3).
   `SkillSlot._draw` takes a `top`/`h` pair (the icon line's `size.y` and y changed with it); the icon's colour code is not touched.
3. **Spans kept whole across a column break.** `SlotColumns.starts(runs, cols, fit)`: with no span, the even columns as ever;
   with any, the cut of the slots into at most `cols` columns of at most `fit` rows with every cut between spans, whose tallest
   column is shortest, then whose columns are the most even (a small DP, bar is at most ~20 slots). Never more columns than
   `layout_for` says. A column may be taller than the even share (up to `fit`) to hold a span. If no such cut exists (a span taller
   than a column, too many spans), the even columns, a span cut (as before): the anchor is drawn as tall as its column holds,
   the rest keeps "(continued)". Call: rows may grow past the even share but not past `fit`, i.e. the HUD's own `MIN_ROWS` floor
   can be exceeded by nothing; a window with less room than that still overflows as it already could.

## As built
Files: `Scripts/SlotColumns.gd` (WANT, RUN, `starts`, `_plan`, `standing_rows`, tall layout), `Scripts/SkillSlot.gd` (`want_width`,
`rows`, `slot_at`, `_draw` top/h, drop/right-click rows), `Scripts/HUD.gd` (`_fit_bar` reservation and gap, `_refresh_bar` and
`_refresh_traits` set the metas), `Tests/slot_columns_test.gd` (`test_runs`, `test_names`), `Tests/equip_test.gd`
(`test_multi_slot`: metas, tall slot's drop and right-click rows).
Screenshots `S/shot_w8-layout/`: `before_L20_1920x1080.png`, `after_L20_*` (band whole), `multi_L20_1920x1080.png` and `final_L20_*`
(a level-20 bar with spans of 2, 3 and 2 slots), `multi_L12_1920x1080.png`, `multi_L28_960x720.png`.
Mutation spot-checks (each failed, reverted): `starts` ignoring spans (2 fail), column min width ignoring WANT (1), `slot_at`
returning the anchor's index (1).
Undone: with spans a bar can need its full `fit` rows, leaving the band one row (names cut again at 16:9; tooltips whole); no
HUD test for the band's reservation (the screenshots show it); the covered slots' keys aren't drawn.
