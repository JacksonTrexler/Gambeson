# A purpose-built AI sim (q2-sim, 2026-11-16)

Branch `q2-sim`. Card "A purpose-built AI sim" in `docs/queue.md` (?159, ?162, ?164, ?167, ?173). No names made up, so no ` ??`.

## The sim set (built)
`Tests/sims/ai_sim.gd`, outside the suite (`run.gd` reads only `Tests/*_test.gd`):
`godot --headless --path . -s Tests/sims/ai_sim.gd -- [scenario words] [n=8] [debug]`. About 6 s for all at n=10. It prints one
`SIM <scenario> k=v ...` line each. Per-process save, settings and key-bind files (`*_sim_<pid>`, as run.gd), removed at the end.
`Tests/sims/sweep.sh CONSTANT "v1 v2 v3" [sim args]` edits one `const` in `Scripts/AI.gd` or `Scripts/Battle.gd` (they can't be set at run time),
runs the sim, and puts the file back.

| scenario | staged | read off |
|---|---|---|
| `hunt-still`, `hunt-moving` | Observe user (wis 16) after a hider (Hide's debris, concealment 7) seen once, 5-7 tiles off; the mover walks 2 tiles a round | rounds until v1 makes it out (cap 10), unfound, Observe casts |
| `ambush` | the hider (concealment 7) strikes v1 from behind every round | rounds to find it, HP lost, Observes |
| `kick-margin-*` | Kick (rank 1/3, strength 10/40) vs Strike, foe 0..3 tiles from the map edge with its back to it, open ground, an ally behind it | `score(Kick) - score(Strike)` (positive: it kicks) |
| `kick-fight` | seeded 6-round duel on the edge and in the open | Kicks used |
| `grudge` | Grudge II unit down in the corner (0,0); two Lancin units 2-6 tiles off and a half-HP foe between | Lancin HP lost, starving turns, foe killed |
| `rider` | Strike, Poach, Slam Jam II vs a sturdy foe and a half-HP one, an ally beside | uses of each, rounds to win |
| `armor-bare/plated` | foe dimly made out (its Defense unread), bare or Defense 20 | each skill's true worth, the AI's price, chance it takes |
| `worn` | Exhaustion on, Strike and Hex 10 rounds on a soaker | uses, damage |
| `hide` | Invisibility for an ally, a watcher of rising wisdom | where it stops hiding |

Calls: the AI is deterministic, so seeds only vary dice and (hunt, grudge) the start tiles; the choice scenarios (`kick-margin`, `armor`, `hide`)
are read straight off the AI's prices instead of over seeds. `Test` is reused (`class Sim extends Test`) for `stage`, `v`, `slot`, `soak`.
