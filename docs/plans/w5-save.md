# Save leaned and waived; exhaustion museum-sim check (w5-save)

## Card 1: save `Unit.leaned` and `waived` (?196)

Reading: Save.gd keeps no unit state (hero, level, xp, outfit, stash, equipped bar); a starter is rebuilt each battle
(`Battle.starter()`) and learned skills are not saved at all. So there is no "unit" in the save to hang `leaned` on.
Calls:
1. `Unit.lapses_out()` / `lapses_in(d)`: `{leaned: [skill ids], waived: {skill id: waiver id}}` as plain JSON; empty keys omitted.
   Ids are `Skills/<id>.tres` basenames, as `equipped` already does.
2. `Game.lapses` holds it between battles; `Save.pack()` writes a `lapses` key only when non-empty, `unpack()` reads it
   (missing or not a dictionary = `{}`), `Battle.starter()` calls `lapses_in(Game.lapses)`. No version bump: old saves load.
3. `lapses_in` keeps only skills that exist and that the unit has learned (`base_rank > 0`): a lapse means nothing on an
   unlearned skill. Since learned skills are not themselves saved, in the live game this filter drops everything today.
   The wiring is ready for when learned skills are saved; nothing in the game yet writes `Game.lapses` (nothing calls
   `lapses_out()` at battle end). Left undone on purpose: it would need the learned-skills save, a bigger card.
4. `Tests/run.gd` resets `Game.lapses` per test.

Tests (no new test, no new file): `lent_test.test_lent_prerequisites` extended (JSON round trip into a fresh unit that
learned the same chain, lapses when the lent skill goes, `{}` = nothing leans); `save_test.test_round_trip` checks the key
returns (and an absent key leaves `{}`). Mutation: `lapses_in` appending nothing failed two lent checks; reverted.

## Card 2: exhaustion retune museum-sim check (?195)

Before = 38a36b6^ (28ae12a-era tree, the commit before the retune), after = 38a36b6 (the retune: SAME 1, IN_KIND 2, ANY 3,
Burnout, Deathlust). `godot ... -s Tests/sims/ai_sim.gd -- armor worn rider kick n=16`, each in a detached worktree, run
after the suite. No tuning. (sweep.sh sweeps a constant; not needed for a before/after.)

| sim | before | after |
|---|---|---|
| worn (Strike and Hex worn, 10 rounds on a soaker) | strike 12, hex 3, damage 28.00 | strike 12, hex 5, damage 29.88 |
| armor-bare / armor-plated (GUESS_DEFENSE) | strike 3, hex 5 | identical |
| rider | strike 14.62, poach 1, slam_jam 2.06, hex 0, rounds 3.31, won 12 | identical |
| kick (margins, fight) | all | identical |

Reading: in the exhaustion-sensitive `worn` scenario Strike still gets used most (12 vs Hex 3 before, 5 after), so Hex does
not outscore Strike in uses; the retune moved two picks toward Hex and total damage up 28.00 -> 29.88. Where the AI scores
plans (`armor`), Hex still outscores Strike (5 vs 3), unchanged. Nothing else moved.

## As built
Suite after: 10194 checks, 0 failed (960 tests). Files: Scripts/Unit.gd, Game.gd, Save.gd, Battle.gd, Tests/run.gd,
Tests/lent_test.gd, Tests/save_test.gd, this plan.
