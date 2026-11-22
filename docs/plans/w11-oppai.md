# w11-oppai: the AI weighs a foe's Opportunist (?246 follow-up)
Goal: `_approach` prices ending a walk beside a foe whose reaction would strike it. Files: Scripts/AI.gd, Scripts/Behaviour.gd, Behaviours/opportunist.gd, Tests/ai_tactics_test.gd.

## Calls
1. Generic hook `Behaviour.strikes(r, holder, rank) -> Skill` (null default; r = a `&"beside"` moment): "the skill the holder would use at once on r.subject". Opportunist.react now uses it (was static `target_skill`, no other callers). Any later reaction that strikes on `beside` joins by overriding it. (Behaviour.gd is outside the card's file list: the one-method edit is the generic reading.)
2. `AI._strikers(b,u,t,reads)`: once per `_approach`, foes within 2 tiles of the target, alive, reacting, read as foes and located, whose reaction-tagged passive u makes out (Read.skills/kit, as `_moments`). Usually empty: `_struck` is not called then (gate, no turn cost).
3. `AI._struck(b,u,c,strikers)`: for strikers beside c, `strikes()` with u standing at c (`b.standing`), expected blow = damage_range avg x hit_chance, summed, capped at u.hp. Added to the candidate's cost as `STRUCK` (0.5 tiles of walking per HP; guess, like DREAD) in `_approach` only; `route()` untouched (it prices ground, not foes).
4. Only tiles the striker's skill reaches count: Rake does not reach a diagonal, so the AI takes the diagonal beside a Siren (in_reach decides, same as the game).
5. Not weighed: the cost of the striker's Energy/AP, other walks (`_line_up`, `_retreat`, flee), a struck walker's later fate.

## As built / tests
- Test: ai_tactics_test.test_approach_weighs_opportunist (Siren read, the Opportunist seen, a tile beside her costs, out of reach none, `_approach` picks the unstruck side; an ally's reaction is none). Mutation: term dropped from `_approach` -> it fails (reverted).
- Suite: start 10871 checks (w11-cast end), end 10875, 0 failed (1031 tests).
- Digest `busy_fight` 15 rounds=10: 3296533323 before, 3296533323 after (unchanged: no Siren in it). ai_sim: 26 SIM lines identical to base (diff empty): nothing to explain.
- Unit turn here ~36 ms mean (w11-cast final 37.7): no change.
- Not done: other planners, `route()` pricing, visual check.
