# w16-testaudit: what the 20/80 passes lost; segments; risk tier
User 2026-11-23: "under 20/80 was anything of terrible importance lost? / high regression risk? consider segmenting tests".
Start: 11030 checks, 1038 tests, 0 failed (sum of test times 58 s).

## Audit (w13-tests 35 loosened pins, 4 removed; w14-stare envoy; busy_fight digest)
| cut | risk | action |
|---|---|---|
| tier numbers -> order relations (~20 pins) | low: tiers only order unlocks; relations keep order | none |
| content pins (princess, Icor/Alabaster stats, loot text, tower menu, tab names) | low: data, not rules | none |
| 3 describe tests, bio timid | low: sweep describes; timid folded into stance_test.test_craven (mutated in w13) | none |
| sample loops (level_down 0.04->0.07 n=600, doubt 400->250, whiff 200) | low-med: a DC off by 1 (~5%) can slip level_down's 3.5-sigma band | left: exact odds covered by check_test forecasts |
| astral_test.test_envoy (401 -> 372 checks) | low: fewer checks because the AI's fight differs (far turns), same invariants per unit per turn, same "battle ends" | none |
| busy_fight digest -> OUTCOME checks | MED: the sim is outside the suite, so nothing in `quick` played a whole AI fight (combat_test, envoy are slow-listed) | `sims_test.test_fight_outcome`: 10 v 10 in parties, the OUTCOME checks in the suite (2 s); risk tier |
