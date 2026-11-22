# Meadows tails (q3-meadows, 2026-11-16)

Three queue cards left over from `unbounded-maps.md`.

## Readings and calls (for review)

1. **Turn clock over the tally.** The tally ("Demons slain: n / 30 ...") was left-anchored at x=170 and
   grew rightward into the HUD's clock (centred on x=240). Call: the tally is now a right-aligned label
   spanning x 80..226 (`Meadows.TALLY_LEFT/RIGHT`), so it grows leftward and always ends clear of the
   clock (a two-digit number is ~12 wide). Not changed: the clock (HUD), which other tests pin. The
   left end (80) is just right of the left panel; the longest text ("... the portal opens in 10", ~130 px)
   fits.
2. **Edge-pan.** `BattleCamera.edge_dir(pointer, view, clear)` (static, pure): the pointer within 3 design
   pixels of an edge pushes that way (corners diagonal), unless it is over one of the HUD's side panels
   (`Root/Left`, `Root/Right`, each grown by the 3 px, since the panels sit 3 px in from the edge).
   Consequence of the HUD's layout: the side panels fill the left and right edges, so in practice the
   top and bottom edges pan between them. Calls: the arrow keys win when held; no pan while a panel
   (Settings, skills) is open; no pan when the pointer has left the window or the app lost focus, or
   before it has ever moved (the camera keeps its own last pointer, null until then). The Setting is
   `BattleCamera.edge_pan` (static, like `Unit.auto_equip`), default on, a "Edge-pan the camera" check in
   Settings, saved as Prefs `edge_pan`. Speed is the arrow keys' (`PAN`). Panning behaves as the keys do
   (lets go of the unit; the next action/turn/Home takes it back).
3. **Summon search.** In `summon(..., unseen_by)` the first guess is now the nearest free tile past
   every watcher's perception range (`beyond_sight()`, a distance, no read), confirmed by one read
   (`unseen_at`); only if no such tile reads unseen does it fall back to the old nearest-unseen search.
   A call: a nearer tile that is concealed (brush, fog of the unit's own hiding) used to win; now a
   tile beyond sight does, unless none exists. Fog still brings it nearer (range halves).

## Tests and mutation spot-checks
- `meadows_test.test_plane`: the tally ends left of the clock. Mutation (`TALLY_RIGHT` 250): fails.
- `meadows_test.test_camera`: `edge_dir` at the top, bottom, right edges, the middle, and over a panel.
  Mutation (ignore `clear`): "over a HUD panel at the edge: no pan" fails.
- `hud_test` (the Settings test): the check is on by default, and switching it off is saved.
- `meadows_test.test_spawning`: an unseen summon lands past the party's perception range.

## Timings
Meadows seed 7, five unseen Siren summons asked 3 tiles from the player (M3, headless): before 111, 121, 127, 137, 145 ms;
after 13.3, 13.7, 13.8, 14.3, 14.2 ms (about 9x faster). Each lands 13 tiles out, just past the party's perception range.
(A `-s` timing script must declare `var _first: Test` before anything else, or the scripts load in a cycle and hang.)

## As built
- Commits: tally `40aba32`, edge-pan `ba62f04`, summon search (this commit).
- Frames: `S/shot_q3-meadows/` (m00000313 clock and tally, side by side; m00000090 view panned down by
  the pointer at the bottom edge).
