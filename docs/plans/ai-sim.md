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

Later changes to the set: `clash` (two clues pull apart: debris at one end, a last sighting at the other, equally far; the hider is at one, the other end
is a decoy; the look is cut to 2 tiles and the cover raised to 6 so one look can't take in both); `grudge` has a standing foe at the first Lancin's
shoulder (so a strike is on offer against the starving) and Lancin strength 20; `rider` foes are sturdy (4x and 1.5x HP), strength 12.
Hider cover is one shared Effect (a fresh `effect()` per round stacks, which first made every hider unfindable: a sim bug, not the AI's).

## Tuning: each constant low / mid / high
Method: `sweep.sh`, one constant at a time, n = 12 seeds (n = 30 or 60 where a number moved); the AI is deterministic, so seeds only vary dice and start tiles
(n = 60 repeats n = 30's numbers closely). Rounds are to find the hider (lower is better). "base" = value at the start of this branch.

| constant | values | what moved | call |
|---|---|---|---|
| SUSPICIOUS | .5 / 1 / 2 | nothing (hunt, clash, ambush identical) | keep 1: the set builds no suspicion before a search (a hunter finds a tile suspicious only by looking) |
| MARKED | .25 / .5 / 1 | nothing | keep .5: no foe lays a mark in the set |
| LAST_SEEN | .25 / .5 / 1 | .25 only: clash-seen 4.23 -> 4.60 rounds, 2.5 -> 2.0 looks; .5 = 1 | keep .5 (a plateau above it) |
| REACH | .25 / .5 / 1 | nothing | keep .5 |
| HIT | .5 / 1 / 2 | nothing (ambush's one blow-clue sits on one side whatever its weight) | keep 1 |
| REACH_TURNS | 2 / 3 / 5 | nothing | keep 3 |
| SWEEP_TURNS | 1 / 2 / 4 / 8 | monotone: ambush 3.40 / 4.03 / 4.43 / 4.83 rounds (HP lost 3.7 / 4.3 / 4.7 / 5.1), hunt-still 4.73 / 4.93 / 5.07 / 5.13, looks 3.1 / 2.5 / 2.2 / 2.1 (n = 30). clash unmoved | keep 4: 4 -> 2 gains 0.4 rounds for 0.4 more casts, inside the noise (SE ~0.5); 1 would look again on its next turn and break `evidence_test`'s "no second look" |
| **DEBRIS** | 1 / 2 / 3 / 4 | clash-debris 4.93 / 4.70 / 4.30 / 4.08 rounds (n = 60), clash-seen 4.23 / 4.10 / 4.10 / 4.10, looks 2.5 / 2.8 / 3.3 / 3.1 | **1 -> 3.** A sign outweighs a guess: debris (fresh) now beats LAST_SEEN + its reach spread (about 1) where they pull apart, and a decoy debris costs nothing (clash-seen no worse). 4 gains little more. After merging q2-aiwalks the numbers are the same (4.40 vs 4.93) |
| GUESS_DEFENSE | 10 / 12 / 14 | chance taken for an unread foe .60 / .50 / .40, against truth 1.00 bare and .10 plated (mean .55 = Defense about 10.5); the choices (Strike 3, Hex 5 over 6 rounds) never change | keep 12: no choice flips, and the true mix of unread foes isn't known |
| POINT | .1 / .25 / .5 / 1 / 2 | nothing (rider, worn, armor) | keep .5 |
| RIDER | .25 / .5 / 1 / 2 / 4 | Kick's margin over Strike moves linearly (open 1.66 / 1.90 / 2.38 at .5 / 1 / 2) but is positive everywhere; the rider fight is identical | keep 1 |
| PUSH | .25 / .5 / 1 / 2 | the same: Kick beats Strike by 1.4 to 3.5 on any ground, a wall behind the foe worth 1.4 more, an ally behind it 0.5 less (never enough to flip) | keep .5 |
| STARVE | 1 / 2.5 / 5 / 10 / 20 | identical to 10; at 20 it starves more (1.0 turns, not .75) and the Grudge unit lands less (1.5 blows, not 2.0), HP lost the same | keep 5 (the flip lies between 10 and 20, far past a kill's KILL 5) |
| AI.SEEN | .8 / .9 / .95 | the watcher's wisdom where it stops hiding an ally: 30 / 36 / 40 (Intelligence 20 caster) | keep .9: only a flip point to read, no outcome measured |
| AI.WORN | .6 / .8 / .9 | nothing: the floor never binds in 10 rounds on a soaker | keep .8 |

Findings, not constants: (1) an Observe user that has swept its last clue stands next to a hider and never looks again (hunt-still, seed 1: adjacent for
8 rounds); (2) Poach is never chosen over Strike/Slam Jam in the rider set (used 0 times at any POINT or RIDER), whose price is the cost of 1 Energy at 0.5 and a rider
of 1 only on a felling blow; (3) Kick dominates Strike on price even in the open, so PUSH and RIDER can't be tuned here without a rival at par; (4) after
q2-aiwalks (5e6c5fc) the Grudge set's Lancin HP lost fell from 3.75 to 2.00 with the same STARVE flat spot.

## As built
`Tests/sims/ai_sim.gd`, `Tests/sims/sweep.sh` (+ .uid), `Scripts/AI.gd` (`DEBRIS` 1.0 -> 3.0). No test written (the sim is the artefact; the suite already covers `clues` weights by age
through `AI.DEBRIS`, `evidence_test.test_clues_weigh`). Full suite: see report.
