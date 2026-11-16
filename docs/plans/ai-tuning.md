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
