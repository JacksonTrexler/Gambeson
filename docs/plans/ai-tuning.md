# AI tuning and the last prices (z-aitune, 2026-11-16)

Branch `z-aitune`. Card "AI tuning and the last prices" in `docs/queue.md` (?159, ?162, ?164, ?167). No names made up, so no ` ??`.

## Readings and calls

### 1. Defense through a lie (`_lie`)
1. `Perception._lie` now flips `Read.defense` like `hp` does: with chance `twist` (fixed per observer, target, field) it is mirrored about
   **MIRROR = 20** (`max(20 - d, 0)`): plate reads as bare cloth, cloth as plate. *Call:* 20 is a guess at "an armored unit's ceiling"; a
   point under reads as a point over, a medium armor (~12) reads 8. The armor's *name* and the trims stay true (not part of the lie; open).
2. **One reader.** `Read.believed(unknown := -1)` is the `guess` argument `Battle.hit_chance()` takes (the Defense the viewer takes t to have).
   `AI._chance` passes `r.believed(GUESS_DEFENSE)`; `HUD.odds`, the tip's "N% to hit" pass `view(t).believed()`. `hit_chance`'s guess now still adds
   the tagged difference (`t.defense(tags) - t.defense()`, so a rear attack still reads -2 on a guessed or believed Defense, as on the true one).
   The HUD's DF card row shows `r.defense`; the log's roll shows `roll.defense + Read.skew(t)` (the roll's own figure carried over by the lie).
   Not covered by a test: `HUD.odds` itself (a liar whose faction also flips is read as an ally and takes no odds; no stable way to stage one that doesn't).

### Tests
- `hud_test.test_a_lied_defense_is_believed`: the read is mirrored; the AI's chance is the lied one; the card and the log's roll show it.
  Mutations (each fails it, reverted): AI ignoring the lie; log without skew; card without it; `_lie` without the flip.

### 2. Grudge retreat
Read as: the unit *starving* a Grudge unit of its melee (`_starve`) backs off to a tile it can back off from again next round, not the corner furthest
away (ai-prices.md "Not done"). Kept small: `AI._away(b, u, from, safe := 0)` now picks through `_retreat()`. With `safe` > 0 every tile at least
that far counts the same (gap capped at `safe`), and of those the one with the most `_room()` wins: free tiles within the unit's own movement of it that lie
further from the Grudge unit than it does (straight lines and bare ground, as `starve_worth` does; a corner has 0). `_starve` passes
`safe = movement + 2` of the Grudge unit (one tile past its reach, `movement + 1`). Without `safe` (every other `_away` caller, `_keep_away`, `_recover`)
nothing changes. *Not done:* Grudge units' own approach; allies don't coordinate who retreats where; the turn after, g's new position isn't foreseen
(room is against where it stands now).
Test: `ai_tactics_test.test_starving_keeps_room_to_retreat` (the wiser tile is out of reach and has more room than the furthest tile; a corner has
none; the starving turn walks to it). Mutations (each fails it, reverted): `_starve` not passing `safe`; `_room` counting equal-distance tiles.

### 3. Tuning by simulation: no number changed
Method: a scratch sim (not kept; `Tests/combat_test.fight()` per seed on the museum, counting each unit's skill uses from the log) run for each
constant moved to a low and a high value, one at a time, over combat_test's 8 seeds (about 20 s a run); then `soak`-size 30 seeds before and after.
Values tried: SUSPICIOUS 0.5/2, DEBRIS 0.5/2, MARKED 0.25/1, LAST_SEEN 0.25/1, REACH 0.25/1, HIT 0.5/2, REACH_TURNS 2/5, SWEEP_TURNS 2/8,
GUESS_DEFENSE 10/14, POINT 0.25/1, RIDER 0.5/2, PUSH 0.25/1, STARVE 2.5/10, SEEN 0.8/0.95, WORN 0.6/0.9.

- **Result: every run is identical** to the base (8 seeds: Lancin 6, Nemes 2, 108 turns, same skill-use counts). The extremes (POINT 50, WORN 0,
  GUESS_DEFENSE 40) move only the turn count (108 -> 114), not the winner.
- 30 seeds, before this branch (a30a25d) and after: **Lancin 26 / Nemes 4, 413 turns both**, skill uses identical, so the lie and the retreat don't touch
  the museum: Alabaster Strike 134, Icor Hex 125 / Strike 92, Siren Rake 104 / Drown 42, Villager1 Strike 63, Villager2 Strike 116, Villager3 Hex 97 /
  Strike 105, Villager4 Hex 106 / Strike 140. (Icor's Hex over Strike is ?87's cost balance, the user's.)
- **Why:** the museum fight has no Observe user, hiding foe, Kick, Grudge or rider skill, and no wounded-unseen Defense, so the clue weights, STARVE, PUSH, RIDER
  never come up, and the rest only reorder equal-looking blows. A museum battle can't tell these numbers apart; with no evidence to move them, **all stay as
  they are** (SUSPICIOUS 1, DEBRIS 1, MARKED 0.5, LAST_SEEN 0.5, REACH 0.5, HIT 1, REACH_TURNS 3, SWEEP_TURNS 4, GUESS_DEFENSE 12, POINT 0.5, RIDER 1,
  PUSH 0.5, STARVE 5, SEEN 0.9, WORN 0.8). Chasing a change would be a guess, which they already are. *Open for the user:* a purpose-built sim (an Observe
  user hunting a hider across the seeds; a Kick against a wall; a Grudge unit in a corner) is what would tune the clue weights, STARVE and PUSH; nothing
  in the repo builds one, and I didn't add one to the suite (one more slow test).
- Not done from the queue card: weighing heals and supports for exhaustion wear (`_wear` only prices strikes; the museum shows nothing to measure it on).

## As built
`Scripts/Perception.gd` (`MIRROR`, `_lie`), `Scripts/Read.gd` (`believed`, `skew`), `Scripts/Battle.gd` (`hit_chance` guess), `Scripts/AI.gd` (`_chance`, `_away`,
`_retreat`, `_room`, `_starve`), `Scripts/HUD.gd` (`odds`, tip, `_roll_text`, `_defense_line`), `Tests/hud_test.gd`, `Tests/ai_tactics_test.gd`.
No existing test changed.
