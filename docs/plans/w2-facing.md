# Facing, wave 2 (branch w2-facing, ?142)

The user: "a unit faces whichever direction they last moved (draw a vector from start to finish) or last targeted with a skill (draw a vector from position to targeted tile)". Lead's ruling: whichever is latest.

## Readings
`Unit.facing` is a precise Vector2 (not 4/8 snapped); `side_of()` (flank/rear/front cone), `hit_tags`, the forecast and `AI._opening` all read it, so keeping the representation keeps them working. Before: walks turned by the last step, casts via `face()`, Interject's swap turned the stand-in, forced moves turned nobody.

## Calls
1. One recorder: `Unit.turn(v: Vector2i)` sets facing to the normalised vector; zero changes nothing. `face(c)` is `turn(c - cell)` (so a skill on its own tile does nothing). Latest wins because each event overwrites.
2. Walk: start-to-finish of the whole walk (`passed[-1] - from`), not the last step (the user's "start to finish"). A walk ending where it began changes nothing.
3. Forced moves (push, pull, send, teleport, effect shoves) are moves: `displace()` turns the unit along `cell - start` when it went. A push stopped at once (went 0) changes nothing.
4. Removed: Interject/Gallantry stand-in turning toward the attacker (`_swapped`). It was neither a move nor an aim of that unit, so under the rule it does not turn. Opening line-up (before any move) kept.
5. Shields Up! and aimed-at-tile skills already face the tile; unchanged.

## Tests
Changed to the new rule: `facing_test.test_moves` (walk faces start to finish), `facing_test` Interject test (now `test_interjector_stays`, no turn), `displace_test.test_any_skill_knocks_back` (foe faces along the push). New: `facing_test.test_latest_wins` (move, skill, forced move, zero vector). Mutation: removing the turn in `displace()` fails both the new seam and the displace test; reverted.
