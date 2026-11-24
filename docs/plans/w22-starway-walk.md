# w22-starway-walk
Goal: a walk crossing a powered Starway tile before its last tile hops at once to the pair.
Built: Battle `_exit_of(u, cell)` (pair if powered+free, else cell; shared with `_portal`), `_cross(u, path, costs)` called in `travel` after `walk()`: edits path/costs in place (hop = pair appended, cost 0), `ported` emitted after `traveled`. First portal only (not chained).
Calls:
- Rest of path continues from the pair only if its next tile is adjacent (chebyshev 1) to the pair; else walk ends on the pair.
- A walk ending on its hop's pair skips the end-of-walk `_portal` (no hop back).
- Path folded into `passed`: hop tile counts as a tile walked (u.walked count), 0 cost; flames/marks/debris on it apply. Only the portal entry's own effects (enter hooks) are as before for passed tiles.
- AI path preview (Path overlay, walk(expected)) unchanged; still blind to Starways.
- Passing tiles of the continued walk past the pair are not re-checked for portals.
Tests: starbuilding_test.test_starway +2 checks (continue, end). Mutation: `_cross` never hops -> both fail.
Suite: 11807 checks, 0 failed (1097 tests).
