# w18-ai-siphon: AI prices Power Siphon
## Calls
1. Hook: Battle.hazard() (the one estimate behind route(), AI approach/retreat dread, HUD forecast): when `ends` and on_lattice(c), each circuit_ends(c) effect goes through _owe_wound; new case "power_siphon" owes max(round(amount*max_hp),1) HP. HP priced like other turn-end ground (HAZARD_TILES per HP). No AI.gd branch.
2. Power gain not weighed (wash for all; _owe only holds losses). Skipped: small benefit for Power reserves.
3. Generators recharging from siphoned Power: skipped (not trivial: needs a Battle hook choosing a generator and charge bookkeeping).
4. Known-ness: circuit_ends reads the true circuit, not the unit's read (siphon is plain on-screen status). Call.
## As built
- Battle.gd hazard + _owe_wound; Tests/stars_test.test_siphon_priced (hazard end vs pass vs off vs cut circuit; route price). Mutation (gate off) fails 2 checks.
- Timing: circuit_ends only runs on lattice tiles (on_lattice early-out); busy_fight 15v15 (no lattice) mean 20.5 / p95 46 ms per unit turn: flat.
- Suite 11320 checks, 0 failed (1063 tests); start count not noted before edit.
