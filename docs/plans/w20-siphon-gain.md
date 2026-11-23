# w20-siphon-gain: AI weighs siphon's Power gain
## Calls
1. In Battle._owe_wound "power_siphon": HP owed less SIPHON_POWER_HP (0.5) per Power gained, for u.powered() only, gain = min(max(round(amt*max_energy),1), room). Floored at 0 by _owe (no negative "bonus": hazard() stays losses-only so HUD forecast keys unchanged; a gain>loss tile is just free, not a lure).
2. Non-powered units (Energy) unchanged: regen makes it a wash.
3. 0.5 HP/Power is a guess.
## As built
- Battle.gd; Tests/stars_test.test_siphon_priced extended (Starman with room vs full). Mutation (gain dropped): 1 fail.
- Timing: only runs under ends and on_lattice (early-out), busy_fight has no lattice: flat by construction, not re-benched.
- Suite 11452 checks, 0 failed (1069 tests); start count not noted.
