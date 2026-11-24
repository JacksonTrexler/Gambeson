# w24-fall: no deliberate falls unless Ctrl
Card: "units can't try to fall by default (ctrl click when targeting landing?)".
## As built
- Battle.footing(u, c, fall := false): fall lets void count. Behaviour.fits_at(..., _fall := false) gets it; Jump passes it on. Battle.cast_at/_cast_at(..., fall := false) -> fits_at.
- After a fall-flagged cast, caster on void without footing is slain (same fall as _restack).
- HUD.intent: it.fall = force (Ctrl); _run passes it to cast_at. AI never passes it (default false). Forced falls untouched.
## Calls
- Ctrl only matters for tile skills (aiming branch); other skills' Ctrl keeps old meaning.
- Falling = slay (existing rule), not a new damage.
- Only landing check takes the param, so any future behaviour using footing()/fits_at inherits Ctrl. Switcheroo/displace (forced moves) unchanged.
- No HUD hint/tooltip for Ctrl yet.
## Tests
- Tests/hop_test.gd test_ctrl_lands_on_void (new, 3 checks); existing void checks unchanged.
