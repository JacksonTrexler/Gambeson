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
