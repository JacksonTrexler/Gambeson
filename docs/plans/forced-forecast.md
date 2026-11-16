# Forced moves: forecast and AI (z-forced, 2026-11-15)

Card "Forced moves: forecast and AI" (docs/queue.md; ?146). Reads: fear.md (call 7: forecast and AI untouched),
facing.md (forced moves turn nobody), ai-prices.md (Kick's `driven()`, `riders` / `spill`). Turning (hit or
forced move) is ?142, left alone. No names made up, so no ` ??`; no skill added.

## Calls

1. **One reader of a forced move: `Battle.course()`**, the read-only twin of `displace()` (walk, draw, teleport):
   `{went, left, into, end}`. `Battle.foresee_drive(by, t, from, dir, n, teleport, verb)` turns it into a
   `Behaviour.foresee` dict: a line ("Shoves it 2 tiles back to (6, 3)", with ", then slams X (N each)" when
   stopped), `lo`/`hi` = the slam (as `_slam()` deals it), `riders` = `PUSH` (0.5, moved from Kick) a tile, `spill`
   = the slam on the unit struck (an ally of the pusher counts against). Kick's own `driven()` is gone; it calls
   this, so its note now also names the end tile (its two tests updated, not weakened).
2. **Who foresees.** `Battle.foresee()` now also reads the skill's own `effects` for `shove`/`fear`/`entrance`
   (`DRIVES`), as `cast()` would put them on the target (not on a foe for a `dual` skill; amount x impact rank if
   per_rank x `by_mod`), and `Displace.foresee()` (Sing's draw, Send Off, any carrier) uses `moves()`, the same test
   `apply()` makes. Effects a behaviour puts on through `Cast.put()` are that behaviour's to foresee. Minimal: the
   HUD needed no change (`_hurt()` already shows notes and the slam in lo/hi).
3. **Fear and entrance foresee the first move only**, not the repeat each of its turns (the source may have
   moved); the line doesn't say it repeats. Flat damage mitigation, boosts and reactions on the slam aren't
   counted (as Kick's).
4. **AI: no new scoring.** Seeking a push on a foe and avoiding one into its own side is `foresee()`'s riders and
   spill through `AI.score()` (a tile is worth `PUSH x RIDER`; a slam into an ally nets out against the foe's
   damage). Landing on its own units: `Effect.helps() < 0` already covers the three (`HARMFUL`), and `AI._support`
   now skips a support skill whose effects harm, so it never casts a fear-carrying "buff" on an ally.
   Not done: the AI doesn't walk to a tile to line up a shove against a wall, and doesn't weigh being shoved by
   foes in its own positioning (`_away` etc.).
5. **`drive()` in Aura's and Coordinate's (`Battle._link`) effect loops**, after `a.by` is set, as the other three
   sites. An aura's shove drives each ally from its caster (the caster, being `by`, is skipped).
6. **Tags on skills' own `tags`: not added.** Skills that carry a forced move are Sing (draw) and Send Off (teleport)
   through `Displace`, and Kick through `push`. The move already carries its tag (`driven`, the slam's hit tags); a
   skill's `tags` are the whole cast's (Send Off's blow is divine and love, not a shove), so tagging it would make
   every modifier keyed to the tag read the blow, the cost and the effects too, and mislabel Kick's. Open for the
   user if "a skill tagged shove" is wanted.

## Tests (by seam)

`Tests/forced_test.gd`: `test_the_forecast_reads_where_it_ends` (foreseen end tile = where shove, fear and entrance
really leave it; ally/foe spill; a dual skill's effects skip a foe), `test_a_stop_short_is_foreseen` (edge slam
equals what the cast took), `test_displace_foresees` (push, draw, teleport), `test_aura_and_coordinate_drive`.
`Tests/ai_tactics_test.gd`: `test_forced_moves_are_priced` (a shove is sought; into an ally worth less than into a
foe; a fear-carrying support skill isn't given to an ally, a helpful one is). Changed: two Kick notes in
`ai_tactics_test` now end "to (6, 3)" / "to (5, 3)".

Mutations (each reverted, each failed a test): no `drive` in Aura (1); none in `_link` (1); `_support` harm filter
removed (1); `Displace.foresee` empty (crash, 1); effects not read in `foresee` (2); `course` ignoring units (3);
spill sign ignored (3).

## As built
`Scripts/Battle.gd` (`foresee`, `course`, `foresee_drive`, `PUSH`, `VERBS`, `_link`), `Behaviours/displace.gd`
(`moves`, `foresee`), `Behaviours/kick.gd`, `Behaviours/aura.gd`, `Scripts/AI.gd` (`_support`).
