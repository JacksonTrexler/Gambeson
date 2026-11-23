# w21-hudpanels: objective panel top left, tile pane top right and fading

Task: objective panel top left (not over menus; tracks the map objective, ? when unknown); tile panel always top right, fading while the camera scrolls.

## Readings
- No objective concept existed. Battle ends by elimination (`sides_left() < 2`, `lasting` sides excepted) or `escape()`. Only the Meadows had a goal (30 kills -> portal) shown by its own CanvasLayer `_tally` Label (top middle-left, layer 5).
- Tile pane (`%TilePane`) showed only while hovering, in the map corner diagonally away from the pointer (`_place_pane`). `_panel_open()` (spellbook/skills/settings/persona/sheet) already hides it, and the camera.
- Camera scroll = the Camera2D's screen centre moving (BattleCamera: edge/arrow/drag/gesture pan, follow glide). Detected by watching `get_viewport().get_camera_2d().get_screen_center_position()` per frame, so every cause counts, no new signal.

## Calls
1. Generic objectives: `Battle.objectives: Array[Callable]` (side -> text, `\n` splits lines) + `objective_lines(f)` + signal `objective_changed`. A map registers a callable; Meadows registers `objective()` (kills "Demons slain: y / 30", portal clock) and its `_tally` Label is gone (its test line replaced). Default line, from the HUD: "Foes left: N", dropped when a foe side is in `Battle.lasting` (no end by elimination: the map's own objective stands alone).
2. Unknown count: `?` whenever `battle.sight` (fog on): the player can't know no one else is out there; with some made out, "Foes left: ? (3 seen)" (seen = `unit_seen`, the same located-test the map uses). Fog off: the exact count of units it can see.
3. Menus: the objective panel hides while `_panel_open()` (same predicate as the tile pane and camera); not moved or dimmed, since the book/skills/settings cover the whole map. Hidden once the battle is OVER (the Victory panel says it).
4. Placement: both panels clamp to the visible map rectangle between the side panels (`_corners()`, from the old `_place_pane`): objective at its top left, tile pane at its top right (so a small map's panels stay on the map). Turn clock (top middle) and Banner are not moved.
5. Tile pane always up: `pane_cell()` = hovered tile; pointer off the map (over a panel) -> last tile shown; before any -> selected unit's (else leader's) tile. A hovered tile that has gone still hides it (test kept).
6. Fade: `fade_step`: to 0.2 at 6/s while the view moves, back to 1 at 2.5/s once still for 0.25 s. The objective panel does not fade (task names the tile panel only).
7. Input untouched (w21-focus).

## As built
- Scripts/Battle.gd (signal, `objectives`, `objective_lines`), Scripts/Meadows.gd (hook, `_tally` removed), Scripts/HUD.gd (`pane_cell`, `_corners`, `_place_pane`, `_fade_pane`, `fade_step`, `objective_lines`, `foes_text`, `_show_objective`, `_place_objective`; consts `PANE_FADED/FADE_OUT/FADE_IN/REST`), Scenes/UI/hud.tscn (`Objective` panel).
- Tests: `hud_test.test_corner_panels` (new, 14 checks: foes count / ?, hooks, lasting, placement, pointer-independence, last-tile, fade, menus); `meadows_test.test_plane` tally-position check replaced by `objective_lines`, +1 line in the portal test.
- Visual: `S/shot_w21hp/` (base/a1 entry battle, meadows_base/meadows_scroll, entry_menu): objective top left, pane top right, faint while panning, both hidden under Settings.
