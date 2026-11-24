# w24-siphon
Card: (a) unpowered starwork radiates nothing, rank n reaches n tiles; (b) generator 5%, near units lose 5% max HP, units ON generator/pane/tile gain, siphon = medium Con check, tile rank penalty.

## Readings / calls
- (a) already holds, no change: signal_sources() gives 0 to a pane without a live source in its 4-neighbour circuit (on_lattice side-on), radiate() reaches `power` tiles Manhattan. Covered by astral_test.test_signal (rank 3 reach, dead circuit, 5 tiles). No new test.
- Check: one roll per unit per turn end (not per source) in end_turn, `check(u, con, null, dc(medium), {penalty: rank, tiles: 1})`; rank = highest rank among feeding sources (new Battle.signal_rank(c)). Pass = no power_siphon afflicted. Penalty is per-rank flat (rank 5 generator = -5, rank 1 pane = -1).
- Gen-own-tile (footing.at_end) is not rolled: standing on it is the gain case.
- On a source tile (generator, startile, starpane: _on_source) _siphon() skips the HP loss and keeps the gain (5% max Energy/Power, min 1). "Small Energy or moderate Power": reused the existing siphon gain (Energy, Power if powered; same 5%) rather than a new stat; _starlight already adds the lattice boost on top.
- Units near who fail still get the existing gain too (data effect unchanged); only on-tile units skip the drain.
- AI _owe_wound pricing unchanged (does not know the check or on-source): slightly overprices on-tile ends. Not touched.
- Unit on a pane now carries the power_siphon status (gain only) when the circuit is live.

## As built
Battle.gd: end_turn check, signal_rank(), _on_source(), _siphon() skips drain on source. Effect.gd comment. Tests/stars_test.gd test_siphon extended (rank odds, near drained by weak Con, hardy spared with mutation check, on generator and on pane: gain no HP loss, signal_rank); unit staged beside the wire (3,2) since (3,1) is a pane.
Mutation: forcing the check to always fail -> "hardy are spared" fails; reverted.
