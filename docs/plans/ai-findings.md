# AI findings from the sim, and a retreat that leaves tiles (q3-ai, 2026-11-16)

Branch `q3-ai`. Cards "AI findings from the sim" and "Allies coordinate a retreat" (docs/queue.md; ?176, ?177). Read `ai-sim.md`, `ai-walks.md`.
No names made up (one constant, `AI.LOST`, is a number), so no ` ??`.

## 1. The stuck hunter (hunt-still, seed 1)
**Reading.** Not a sweep that never lapses: the sweep does lapse (SWEEP_TURNS 4). The hunter had no clue left to lapse. `_hunt` forgets a sighting once the
hunter is within a tile of it (`seen.erase`), and `clues()` is built from sightings, so a hider the hunter once saw, found nothing at the spot and failed to spot
(concealment 7) leaves *no* clue: `clues()` empty, `_search` false, `_hunt` nowhere to go. Seed 1 printed `clues n=0` from round 2 on, the hider 3 tiles away.
**Fix.** One more guess in `clues()`: a foe its side made out once (`sighted_when` keeps it after `last_seen` forgets), living, a foe, and placed by no sighting
now -> `LOST` (0.5, = WORTH) at the tile the hunter stands on. A guess like the others: a look there rules it out for SWEEP_TURNS (`swept_lately`), then it looks
again. `sighted_when` and `sight_test`'s "no one to be found: its side forgets it" are untouched. A look from where it stands takes in the hider's neighbourhood,
which is where the hunt ended.
**Sim** (n = 30; hunt-still found-rounds / looks per run): 5.07 / 2.20 -> 4.67 / 3.23; hunt-moving 5.37 / 2.27 -> 5.10 / 3.63; clash (debris, seen) 4.40, 4.10 and
ambush 4.43 (HP lost 4.70) unchanged. Cost: about one more Observe a battle, which only a unit with nothing else to do casts.
*Call:* `LOST` = WORTH rather than a tuned number (a single look's worth: no sweep gets the unit looking twice a round). `clues()` is also read by nothing else.

## 2. Poach
**Reading: correct, and the sim's fault.** Poach's conditions are a foe at half its HP or less *that this caster has never aimed a skill at* (`Battle.aimed()`,
per caster). The `rider` sim's cheap foe started at 3/4 of its HP (not bloodied) and v(1) hit it first, so the condition could never hold. Its price is right
(`ai_tactics_test.test_prices_the_rest`: half its AP and cost back, counted). With the foe at half HP (sim fix) Poach is used once a run, as the opener on the
bloodied foe, then never again on that foe (aimed at): that is the card's text, not a bug. rider before / after: strike 17.25 / 14.55, poach 0.00 / 1.00,
slam_jam 3.00 / 2.05, rounds 4.12 / 3.30 (n = 20 after). No AI change.

## 3. Line-up threshold
`ai_tactics_test.test_line_up_gain_threshold`. Every gain `_driven()` can tell is a multiple of PUSH x RIDER (a push tile is PUSH, a Kick's water or trap rider is
RIDER = 2 push tiles, a slam is whole HP), so the threshold `< PUSH x RIDER` is the smallest real difference: the test stages the least one (open ground beside
the foe 0.5, a water tile two off 1.0) and expects the walk, then stages no gain (the only tile in reach has bare ground between: 0) and expects it to stay.
Mutations (rule broken, test fails, reverted): `<` -> `<=`, `< 0`, and `< 2 x PUSH x RIDER` all fail it.

## 4. Allies coordinate a retreat
**A rule a seam test can tell from `_room()`: kept, as a tie-break only.** `_room()` counts open tiles beyond a tile, and an ally still to move occupies *its*
tile, not the one it is about to choose, so `_room` is blind to where the ally means to go. New: `_claimed()` runs `_retreat()` (with `claim` off, so no
recursion) for each living, able ally of u's that hasn't moved this turn (`move_left() >= movement`) and is within `safe` of `from`: the tiles it would back off
to as things stand. `_retreat`'s key gets a fourth, last element, 0 for a claimed tile, 1 otherwise, only when `safe > 0` (the starve walk): after the shove,
gap and room, so it never trades distance or room for an ally's convenience, it only breaks the tie the first one found used to win.
*Call:* a tie-break, not a reservation (the ally may still choose otherwise once u has moved; no state is kept between units); "yet to move" is read off
`move_left()` (a unit that struck and stayed hasn't moved either; it just claims a tile it may not use).
**Test:** `ai_tactics_test.test_retreat_leaves_an_allys_tile`: finds a spot for v(2) whose own retreat is exactly the tile v(1) alone would take, then v(1) takes
another with the same gap and room (the room count is equal by construction, so it can't be what chose), and with v(2) already moved it takes the original.
Mutation: the fourth key element pinned to 1 fails it.
**Sim `grudge` (n = 40):** Lancin HP lost 2.12, starving turns 0.82, Grudge blows 2.00, foe killed 40 - identical before and after. The sim's two Lancin start a few
tiles apart on a wide map, so they seldom want the same tile and it can't show the benefit either way; the rule costs one `_retreat` per ally in the Grudge unit's reach on a starve turn.
*Open for review:* kept because the card asks for a rule a test can tell apart and this is one that is cheap and never worse on the first three keys; drop it
(`_claimed`, the `claim` parameter, the key element, the test) if no crowded battle shows a gain.

## As built
`Scripts/AI.gd` (`LOST`, `clues()`, `_retreat`'s `claim` and fourth key, `_claimed`), `Tests/evidence_test.gd` (`test_clues_lost_foe`),
`Tests/ai_tactics_test.gd` (`test_line_up_gain_threshold`, `test_retreat_leaves_an_allys_tile`), `Tests/sims/ai_sim.gd` (per-round debug prints in hunt, the rider
foe at half HP). No existing test changed.
