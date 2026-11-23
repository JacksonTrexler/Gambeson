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

## Segments and risk (Tests/run.gd head documents usage)
- `t.sh <wt> <segment>`: ai (189 tests), ui (115), rules (270), sims (12), tools (12), content (441; default for a file no line lists, so new skill tests need no entry). Table: Tests/segments.txt. Segment names are not substring words; they combine (`ai ui`, `ai quick`).
- `risk` runs only Tests/risk.txt (26 tests, ~680 checks, seconds); `quick` keeps risk tests even if slow.txt lists them (+7 s: combat_test.test_battles, test_envoy, skills_test.test_wiring). Risk = a failure means the game itself is broken and loosened pins can't see it: whole AI fights, saving, core rules, skill wiring, forecast odds.
- Call: segments by file, not per-test headers (158 files, one table, nothing to touch per new test).

## Mutations
- AI.act returns [] for units named *3 -> sims_test.test_fight_outcome fails "no unit sits the fight out". AI.act empty for a whole side: first version passed (the idle side just died); added "each side moved or struck >= half", now fails. AI.gd restored.

## Numbers
Full: 11033 checks, 0 failed, 1039 tests (was 11030/1038), test time ~60 s (was 58). Quick 10193 checks, 957 tests, 48 s (was 9756 / 41 s). 
## Undone
level_down 0.07 band left (exact odds: check_test forecasts); no per-test risk comments beyond risk.txt.
