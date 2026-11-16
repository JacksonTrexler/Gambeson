# More contextual clues for searching (z-search, 2026-11-15)

Branch `z-search`. Card: docs/queue.md "More contextual clues for searching" (docs/plan.md Phase 5 item 16).
Baseline suite 8269 checks, 0 failed (868 tests); now 8287, 0 failed (872 tests). Tests: `Tests/evidence_test.gd`.

## Readings and calls

1. **One scoring function, `AI.clues(b, u) -> {tile: weight}`.** A weight of 1 is "a foe's worth". `AI._search()` sums the weights
   inside an Observe's look for every tile in reach and casts at the best (nearest on a tie), if it takes in at least `WORTH` (0.5).
   A later clue joins by calling `AI._clue(out, tile, weight)`; nothing else changes. Weights are constants at the top of AI.gd
   (`SUSPICIOUS` 1, `DEBRIS` 1, `MARKED` 0.5, `LAST_SEEN` 0.5, `REACH` 0.5, `HIT` 1): all guesses.
2. **Signs and guesses.** Suspicious tiles, debris and foe marks are *signs* (they stay until dealt with). Last seen, reach and
   blows are *guesses*: a tile the side searched lately (`Battle.swept`, written by `Battle.search()`, `SWEEP_TURNS` 4 side turns)
   drops out of the guesses, or an Observe user would look at the same spot forever; and a tile where it sees a unit it
   can place isn't where the unseen one is.
3. **Last seen + reach.** `Battle.sighted()` now also records the turn and the foe's movement as read (`Read.stats`, 0 if it
   couldn't read it; the AI then assumes the foe walks as far as itself). `LAST_SEEN` goes on the tile, `REACH` is shared evenly
   among the tiles the foe could have reached: `Battle.reckon_reach(viewer, foe, from, budget)`, a Dijkstra over ground the *viewer*
   makes out (`known_ground`, unread ground is plain), each step priced by `Battle.stride()`, budget = movement x rounds
   since (capped at `REACH_TURNS` 3). Total per foe is 1. *Calls:* rounds = ceil(side turns elapsed / sides); a walk
   goes in a line (ceil(distance) tiles), so a tile also has to lie within `budget` as the crow flies; the foe's own movement
   effects and passives price the steps (stride takes its unit) and nobody stands in its way. Marks are priced as the walker
   knows them (stride's `expected`), a small residue of "its knowledge" rather than the viewer's.
4. **Where a blow came from.** `Battle._on_taking_hit` (the existing Unit signal) calls `_note_attack`: for a blow in a cast by
   a foe the victim can't place, its side keeps every tile on the side the blow landed (the hit's `flank`/`rear` tags, else front)
   within that skill's reach (`skill_range`), `HIT_TURNS` 6 turns. The attacker's real tile is never used; test checks it is
   no likelier than its neighbours. *Call:* only blows inside a cast (not bleeds or traps), and not area casts without a Cast.
5. **Marks and debris.** Foe marks the viewer knows of (`known_marks`) are `MARKED` each; debris fades (`DEBRIS / (1 + rounds old)`).
6. **After searching it still hunts.** `act()` used to hunt only if it hadn't searched; now it looks, then heads for where its side
   last saw a foe (otherwise battle-start sightings would pin every Observe user in place for rounds).
7. Observe users with no clue but old sightings now search at battle start (they used to need a hint or debris): combat sims shift.

## As built

`Scripts/AI.gd` (`clues`, `_clue`, `_search`, `_remember`, constants), `Scripts/Battle.gd` (`sighted_when`, `attacks`, `swept`,
`sighted`, `rounds_since`, `reckon_reach`, `_note_attack`, `attacks_on`, `swept_lately`, `search`), `Tests/evidence_test.gd`.
Tests (one per seam): `test_clues_weigh` (weights by age, cap, swept), `test_clues_reach_by_known_ground` (known ground prices it,
hidden ground doesn't), `test_clues_attack`, `test_ai_searches_by_clues` (last seen, mark, debris, blow; the foe's true cell
changes nothing; no second look). Mutations checked, each fails a test: LAST_SEEN/REACH zero, reach turn cap, true terrain in
the reach, no side filter, no swept discount, no movement budget.
