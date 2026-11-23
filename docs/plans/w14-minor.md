# w14-minor: Opportunist pricing, rest of ?253
Files: Scripts/AI.gd (_struck), Tests/ai_tactics_test.gd.
## Calls
1. (a) flee already priced: _flee/_keep_away/_recover-less paths all go through _away -> _retreat (w12), which passes `reads`. Opportunist fires only on a walk's END beside the holder (Battle.gd ~3546 react(&"beside")), so a step that only passes beside costs nothing: no pricing to add. Unpriced still: _recover (Starmote lattice walk), _escape (fixed tiles), _hunt/_keep_up (narrow reads: no foe read there). Left alone (niche).
2. (b) route() not done: it lives in Battle, has no reads/strikers; pricing there means a Battle->AI hook or reads threaded into the planner, and a walk's end is already priced by the callers. Guess: not worth it.
3. (c) _struck: per [holder, pool] tally of what counted blows take (Unit.cost_from vs energy / reserve store); a blow beyond the pool counts 0. Order = strikers order (hotbar rank). Still not modelled: a holder's pool spent by its own non-reaction skills later in the turn.
## Tests
- ai_tactics_test.test_approach_weighs_opportunist: +2 checks (same blow twice from one pool: Energy 3 prices one, 6 prices both). Mutation: tally dropped -> fails; reverted.
- Suite 11027 checks, 0 failed (1037 tests). busy_fight 15: OUTCOME ok, unit turn mean 24.4 ms (p95 49.9).
