# w21-focus: quick / right click, double tap focuses; a plain left click targets after a short hold-off

Task (user): quick or right clicking / quick or double tapping a unit or tile focuses them rather than instantly targeting (delay to target on left click or tap short, < 0.25 s; none if already focused), so a unit's info can be reviewed before targeting.

## Readings
- Pointer path: `HUD._unhandled_input` -> `click(c, force, inspect, alt)` -> `_run(intent())`. Right click = `cancel()`. Touch arrives as emulated mouse buttons (`ScreenTouch` only used by BattleCamera for 2-finger pans), so one path covers mouse and tap. Tests/AI/keys call `click()`/`use_slot()` directly.
- The card (`%Card`) shows `selected`; the tile pane shows `pane_cell()` (hover). Existing "focus" = `select()`, which drops the armed skill when it lands on a foe (Shift-click inspect). Focusing a foe by `select` would lose the player's aim, defeating "review, then target with a skill".

## Calls
1. Focus is its own state, `HUD.focus_cell` (a tile; the unit is whoever's made out there, `focused_unit()`), not `select()`: the selected unit, armed skill and bar stay, so the next click on the focused foe targets at once (no delay).
2. Card shows `focused_unit()` when it is not the selected unit; the tile pane (`pane_cell`) shows `focus_cell` first. Pinned: mouse motion does not unpin (touch has no hover). Cleared by `click()` (any left click that acts), `select()`, `cancel()` (Esc / right click on the focused tile / off-map).
3. Left press -> `press()`: waits `TARGET_HOLD = 0.2` s (const, < 0.25) in `_pending`, `tick_press(delta)` from `_process` (tests advance it by hand). Second press on the same tile inside the wait, the OS `double_click` flag, or a right click -> `focus()`, pending dropped.
4. No wait: tile already focused; Ctrl/Meta/Shift/Alt held (deliberate chords: strike-at, inspect, alt cast); preparation phase; off the map. A click on a different tile settles the waiting one first (fires it), then waits itself. Any key press and `cancel()` drop the pending click.
5. Right click: on a tile not yet focused -> focus (also while aiming/picking, so a foe can be read while aiming); on the focused tile or off the map -> `cancel()` as before. So disarming by right click now takes two clicks when the pointer is over the map (the first focuses what is under it). Esc clears the focus first, then steps back as before.
6. Every tile gets the delay, walks included (the task says unit or tile); `click()` itself has none.
7. Visual: white corner brackets on the focused tile (Overlay), pulsing; the card and pane are the main indicator. Shot `S/shot_w21focus/` (foe focused in an entry battle: card shows it, brackets on it).

## As built
- Scripts/HUD.gd (`TARGET_HOLD`, `focus_cell`, `_pending`, `press`, `tick_press`, `right_click`, `focus`, `unfocus`, `focused_unit`; edits in `_unhandled_input`, `click`, `select`, `cancel`, `pane_cell`, `_card_info`, `_process`), Scripts/Overlay.gd (brackets), Tests/hud_test.gd (`test_focus` + `pointer()` helper: events through `_unhandled_input`, hold-off advanced by `tick_press`; 16 checks).
- No existing test changed (all use `click()`/keys).
- Mutations (all caught): hold-off 0, focused tile still waits, second click not focusing, right click cancel-only, key not dropping pending, focus selecting the unit, pending not settled by another tile.
- Suite: 11514 -> 11530 checks, 0 failed (1077 tests).
