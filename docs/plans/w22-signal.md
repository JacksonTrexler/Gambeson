# w22-signal: astral power as a field (signal), Stardust, Nexus ranks
Goal (F1 answer): sources radiate signal; decays 1/tile, Manhattan (diagonal = 2); every 20% power = 1 tile; carried along generators and wiring; star flooring needs it; Stardust left by broken startiles regrows in y = signal distance turns. Generators rank 5, starpanes rank 1; generators on larger platforms.

## Readings
- F1 "x" = signal (user's answer); supersedes w18-nexus call 1 ("x" read as an arm length 1-2).
- Existing lattice (Battle): startile = charged source (starpower/charge, 0..STAR_CAPACITY), starpane = side-on link; star_source()/circuit_ends() BFS per read; cracked startile mends by charge reach (REPAIR_SPAN: 20% = 1 tile, already the same 20% rule).
- "starpanels"/"starpanes": both = the existing starpane tile (one tile, display name kept).

## Calls
1. Terrain field `power_rank` (generic source: anything with a rank radiates). Generator 5, starpane 1, startile 0.
2. A source's signal = min(rank, floor(5 x charge/capacity)) for a charged layer (generator); a chargeless one (starpane) radiates its full rank only when powered: on a lattice component (side-on, Battle.on_lattice) holding a ranked source with charge > 0. Wiring carries power, not strength: each powered pane re-emits 1 (the walkway), generators radiate their own reach (the platform).
3. Field = per cell: signal left (power - distance, >= 0: in signal = powered), nearest reaching source's distance, and the live generators feeding it. Pure Manhattan through anything (astral: no obstacles). Battle.radiate(sources) static and generic ({cell: power} in); Battle.signal_at()/signal_near() read a cache.
4. Cache key = [layer version (bumped in _register/_unregister), panes.hash(), charge.hash()]: recomputed only when tiles or charge change, never per read (a read = two native dict hashes).
5. Stardust (--human): new tile, a layer that passes (overlay), tag star, repairs_into startile, new Terrain flag `regrows` (mends by signal, draws nothing). Each round (Battle._repair_tiles) in signal: goal = nearest-source distance (>= 1), +1 progress; at goal -> startile. Out of signal: progress holds. "y turns" read as rounds (as cracked startiles count).
6. Break chain: startile -> cracked startile (as before, charge mend unchanged) -> Stardust (cracked's breaks_into; was: gone). "startiles somewhat fragile": cracks first, dust second. Cracked's charge-mend kept so the Envoy (no generators) still mends.
7. Power Siphon reads the field: circuit_ends(c) = at_end of the live generators whose signal (own reach, or through their powered panes) reaches c, c's own aside. Wider than the old lattice-only reach (platforms, walkways). Forecast (_owe) gate on_lattice -> in signal.
8. "Exist": the Nexus lays star flooring only inside signal (tested). No decay of unpowered startiles (would wreck the Envoy); open question.
9. Nexus: generator platform = startile diamond radius 2 (was a 1-2 cross + diagonal panes); Stardust on 30% of the rest of each generator's reach on floor; beside wires 40% startile walkway, 30% Stardust (regrows in 1 round: panes build walkways out).
10. "signal" a Glossary term (mechanic.py tag, --human, kind ground).

## Done
(see As built)

## Next
