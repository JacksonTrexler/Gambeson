# w18-fog: fog of war (F7)

Goal (user): "Perception range: units can only see others within full wis range. tiles outside this radius are in the 'fog of war'."

## Readings (existing sight, reused)
- `Battle.sight` (on in every battle) + `perception_range(o)` = wisdom total tiles (halved by the `fog` area condition).
- `in_range(o,t)`: 0 beyond, 1 within full range of any side member (where only), 2 within half (how it looks); shared across the side (`_eyes`).
- `read()` -> `_plain()` gives `Perception.nothing()` at in_range 0: unit not located. So "only see others within full wis range" already holds.
- HUD draws others through `view()` = read (unlocated -> hidden); `pickable()` needs `located()`.
- AI: every target/react path goes through reads + `located()` (`_foe`, `_strike`, `_best_target`, `_far`, `_hunt` on `sightings`; stare/investigation (`suspicious`, `_vanish`) use in_range >= 2). Nothing new needed: no added AI cost.
- Missing: the tiles. No fog drawn, no memory of seen ground.

## Calls
- Fog radius = `perception_range` (full ring, not half), same number as unit sight; union over the player's side (`command.faction()`); hidden where `sight` is off.
- Three shades: in sight clear; explored (seen once, out of sight now) dimmed (alpha 0.45); never seen darker (alpha 0.75), terrain faintly visible, not black. "Remembered" = the dim shade, not a stored terrain copy (terrain doesn't change under fog visually; a changed tile shows its new look).
- Memory lives in `Battle.explored[faction]` (generic: any side, AI may later use it); only filled when asked (`sight_cells()`), so AI sides pay nothing.
- Drawn as one Sprite2D (1 px a tile ImageTexture over the map's used rect, nearest filter), above the Overlay, below the units; updated only on HUD refresh when the side's eyes change (key of cells+ranges). No per-frame draw, no whole-map loop per refresh (rect rebuild only when the map's used rect changes).
- Units in fog: already hidden by read(); pings / Clairvoyance still show (skills beat fog).

## Files
Scripts/Battle.gd (sight_cells, explored), Scripts/Overlay.gd (fog sprite), Scripts/HUD.gd (hook), Tests/sight_test.gd.

## Done / next
As built (5ac29ac):
- `Battle.sight_cells(f)` (union of members' full perception ranges via `cells_near`, same `+0.0001` edge as in_range) and `Battle.explored`.
- `Overlay.fog_of_war(b, f)`, `fog_at(c)`, `FOG_UNSEEN` 0.75 / `FOG_EXPLORED` 0.45; Sprite2D "Fog" sibling after Overlay; freed in `HUD._exit_tree`. Called from `HUD._refresh()` with `command.faction()` (null when the battle is over: fog lifts).
- AI: no change (already read-gated). Test pins it: a foe 2 tiles off past wisdom 1 isn't struck.
- Test: `sight_test.test_fog` (AI no strike, side union + edge, HUD not pickable/hidden, fog shades unseen/clear/explored). Mutations caught: in_range ignoring sight (2 fails), no clearing (2), no re-dim (1), no distance check in sight_cells (1).
- Timings: suite 11255 checks/1058 tests 63 s -> 11260/1059 65 s. busy_fight 30 unit turn target mean 116 p95 284 -> 115 / 282 ms (sim has no HUD; unchanged). Meadows: fog_of_war forced redraw 0.88 ms (541 tiles in sight, 48x48 rect); refresh with fog unchanged skips it (key).
- Visual: S/shot_w18fog2/ (Meadows, zoomed out): clear ring, dark unseen, dimmed explored after the leader moves.
Undone: known_ground doesn't consult explored (AI pathing through unseen terrain unchanged); fog not shown on the minimap (none); tiles' looks under fog are the live ones, not a frozen copy.
