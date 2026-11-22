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
(nothing yet)
