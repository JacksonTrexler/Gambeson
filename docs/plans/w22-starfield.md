# w22-starfield: cracked-startile mending and star_source/star_rate read the signal field
Goal: follow-up of w22-signal ("Next"): drop the per-read lattice BFS and the charge-reach mender; Battle._field() (cached) answers all.

## Calls
1. Mapping: a cracked startile's progress a round = signal_at(c) (0 at a source's edge .. SIGNAL_FULL 5 on the source); goal SIGNAL_FULL (5). Old rate was 1 progress/round toward goal = distance; new = old x signal/full with goal 5 rounds-at-full. No signal (-1) or edge (0): holds. HUD "Repairing n/5" reads as before (HUD untouched).
2. REPAIR_COST (5% charge drawn to begin) dropped, with REPAIR_SPAN, _mender(), Layer.source: Stardust regrowth already draws nothing; mending is now free in signal. Open question: a sink for charge?
3. Envoy: startiles (rank 0, charge-bearing sources) radiate min(5, 1 tile/20% charge): Battle._rank() gives a charged `starpower` tile SIGNAL_FULL rank (not Terrain.power_rank on startile: star_place reads rank>1 to power generators). Side effect: a charged startile also feeds panes (live circuit) and regrows Stardust near it, and powers lapse-startiles beside it.
4. star_source(c) = fullest of the live sources in the field's feed list at lattice tile c (null off lattice / dead); star_rate unchanged formula (STAR_SLOW..FAST by that source's charge). So the link is now the signal's reach, not wiring only: a full source reaches 5 tiles past a broken pane (cut shows only beyond reach). Empty sources are dead (null, rate 1).

## As built
Battle.gd: SIGNAL_FULL const; _repair_tiles cracked branch by signal; _mender/REPAIR_*/Layer.source removed; star_source/star_rate on _field(); _rank unranked charged source.
Tests updated: stack_test.test_startile (two cracked tiles, signal 3 vs 1: faster one mends first, nothing drawn, 5 rounds on signal 1 = the mending-by-signal check), stars_test.test_lattice (empty source = dead circuit; reach past a broken pane; cut beyond reach). Unchanged and green: astral_test, tower_test, starbuilding_test, stack_test.test_repair_out_of_reach.
Mutations (each fails): progress 1/round instead of signal (stack_test.test_startile 3 fails); mend with no signal (test_repair_out_of_reach); startile unranked (test_startile).
Perf: star_rate read 10.4 us (BFS, 11-tile lattice) -> 0.93 us (cache).
Suite 11816 -> 11853 checks, 0 failed (1098 tests).
