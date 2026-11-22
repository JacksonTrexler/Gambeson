# w9-band: the band's row reservation test + 9-slot bar with spans at 16:9

Goal: (1) HUD test for band's row reservation (`_fit_bar`); (2) L20 mage 16:9: bar 9 slots, spans 2/3/2 -> bar takes 4 rows
(3 cols), band left 1 row -> 3 narrow cols, "Hollo"/"Darkvisi" cut (S/shot_w9-band/before_L20_1920x1080.png).
Files: Scripts/HUD.gd (_fit_bar), Scripts/SlotColumns.gd (_plan), Tests/slot_columns_test.gd, new test in Tests/hud_test.gd.

## Reading
Room at 16:9 = 5 rows (design 270 px). Band wants 2 rows (2 cols whole names), so bar must stand in 3 rows. 3 cols x 3 rows
can't hold spans 2,3,2 whole (cuts: [0-3][4-6][7-8] = 4 rows), and `_fit_bar`'s MIN_ROWS floor (4) also stops it going lower.
Plan: a span-bearing bar may take one more column (down to FLOOR_WIDTH, width allowing) rather than more rows; the MIN_ROWS floor
relaxes to the tallest span when the bar has spans.

## Done
- `SlotColumns._plan`: if a span can't be kept whole in the `layout_for` columns, try one more column at a time (up to what
  `max_width` holds at FLOOR_WIDTH 40, or n), first that keeps spans whole; else the old plan. New `whole()`, `tallest_run()`.
- `HUD._fit_bar`: the MIN_ROWS (4) floor is the bar's tallest span when it has spans (never above MIN_ROWS), so the bar can give
  the band its rows. Shots: before/after_L12|L20_* in S/shot_w9-band/.
  L12 (7 slots, spans 2,3) 1920x1080: now 3 cols, all bar and band names whole (was band cut). L20 (9 slots, spans 2,3,2): band
  whole in 2 cols ("Hollow Bones", "Darkvision"), bar in 4 squeezed cols (~51 design px: "Strik", "Aeth", "M" for Mana).
  Same at 1280x720, 960x540 (one design). 960x720 and L28 unchanged (one column).
- Tests: `hud_test.test_band_rows` (root size 480x270; band as tall as `standing_rows`, spans whole, bar+band in `_fit_room`),
  `slot_columns_test.test_runs` (+2 checks: 4th column; none when width lacks). Mutations (each failed, reverted): floor kept at 4 (1),
  no extra column (1 hud, 1 slot_columns), reservation dropped (2).

## Calls (questions)
1. L20 at 16:9 trades names: band whole, bar names cut hard (4 columns of ~51). Both can't be whole: room is 5 rows, needs 6 (or
   4 wide columns ~62 = 254 px > the 0.45 BAR_SHARE). Alternative: only add a column while it stays >= MIN_WIDTH (then L20 is as
   before, band cut). One-line: `SlotColumns._plan` bound `most`. Which names matter more?

