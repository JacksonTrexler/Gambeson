# w6-audit: Wave 2 and Wave 1 follow-up cards against the code

Verdicts as of branch w6-audit (queue.md and todo.md untouched). Skipped by instruction: AI turn cost cache card.

| Card | Verdict | Evidence |
|---|---|---|
| Interject's and Snapping Turtle's checks take the reaction bonus | built | Behaviours/interject.gd `check_bonus()` feeds `contest()` in both the `hit` and `snap` branches and `foils()` (41128d4). Snapping Turtle has no check of its own: it re-asks Interject as `&"snap"` (Behaviours/snapping_turtle.gd), so that is the check the bonus must reach, and does. `t.check = true` already declared; `CHECK_PER_RANK` named; row in Tests/param_test.gd `test_concrete_scaled` (interject). |
| The AI casts Skeleton | built (this branch) | Scripts/AI.gd `_summon()` (called in `act()`), consts BODY / SUMMON_SEEN / SUMMON_CAP; `Behaviour.bodies()` (Scripts/Behaviour.gd), overridden in Behaviours/summon_per_rank.gd; Tests/summon_test.gd `test_ai_raises_host`; sim `host` in Tests/sims/ai_sim.gd. |
| Deathlust AI awareness | partly | Built: AI.gd `_wear()` asks `wearing()` hooks, so a killing blow's exhaustion is unworn (88f5fe1; Tests/deathlust_test.gd). Unbuilt: the HUD float or log line on Deathlust's relief (no HUD.gd mention; Behaviours/deathlust.gd `neutralized()` only relieves silently); the AI does not price the relief a death in reach gives other counts. |
| Hunt sim: hiders in range from round 1 | built (tuning not done) | Tests/sims/hunt_10v10.gd `near` variant, sweep.sh `SIM=` (62f0fed). No `AI.LOST` retune was recorded; LOST stays 0.5 (Scripts/AI.gd:41). |
| Edge-pan sideways and drag | built | Scripts/BattleCamera.gd:92 middle-drag pans, Tests/meadows_test.gd (2a2cdb6). |

## Calls
- Skeleton AI: BODY 5.0 HP per body; foe must be a read within 10 tiles (SUMMON_SEEN); side cap 12 units; not when posture is defensive or temper stoic; a cast tile is the free tile within the skill's reach nearest the foe. `bodies()` is a generic Behaviour hook (no Skeleton special case) so any summon behaviour joins by overriding it.
- Snapping Turtle: no code change, the card's second half is satisfied through Interject's `snap` branch.
- Sim `host` is a new scenario in ai_sim.gd (names made up: none).

## As built / sim
Sim before and after (ai_sim, n=4, all scenarios): only `host` differs, bodies 0.00 -> 8.00; every other line identical. Damage in `host` stays 0.00 in both (the raised skeletons do not reach the soaker 9 tiles off in 10 rounds); neutral elsewhere.
Mutation: BODY = 0 fails `test_ai_raises_host` (2 checks); reverted.
