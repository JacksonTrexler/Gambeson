# w12-oppcost: Opportunist cost, and the struck blow in the other planners (?252)
Files: Scripts/AI.gd, Tests/ai_tactics_test.gd.

## Calls
1. Cost: `_struck` prices a striker only if `holder.funding(skill, b.price_cut(..))` is non-null (the actual affordability, as Battle.can_afford). AP is not asked: the blow is an interrupt free action (Battle.INTERRUPT_AP 99), so Energy/reserve is the whole gate. Not modelled: a striker's Energy running out across several walkers or several strikers beside one tile (each priced alone).
2. `_strikers(b,u,at,within,reads)`: generalised from (t) to a centre + radius; reused by all three planners. `_approach`: (t.cell, 2) as before. `_line_up`, `_retreat`: (u.cell, ceil(move_left)+1). Empty almost always: `_struck` not called then (gate).
3. `_struck` returns 0 for c == u.cell (staying is no walk; opportunist fires on arrival only).
4. `_line_up`: struck HP subtracted from each tile's worth (worth is in score() terms, ~HP), after the scan and before the ranking; base (own tile) unaffected. Plain HP, not STRUCK-scaled (STRUCK is tiles of walking, that is _approach's unit).
5. `_retreat`: struck HP added to the first key term with `_shoved` (both HP lost on arrival), so it ranks before gap/room.
6. Not done: flee/other walks, route() pricing.

## Tests
- ai_tactics_test.test_approach_weighs_opportunist extended (Siren): out of Energy (Rake free as is: cost set to 3 and restored) -> no blow; `_retreat` avoids tile beside her (blind picks beside); `_line_up` stays out of her reach vs takes the slam tile when she is unread. `_strikers` calls updated to the new signature.
- Mutations (each fails, reverted): term dropped from _line_up; from _retreat; funding check from _struck. (_approach's term: done in w11.)
- Suite: start 10875 checks (w11-oppai), end 10881, 0 failed (1031 tests; one test extended).
- Digest busy_fight 15 n=2 rounds=10: 3296533323 before, 3296533323 after (unchanged). Unit turn mean 36.8 ms here (w11: ~36-37.7): no slower.
