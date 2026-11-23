# w18-nexus: nexus generators, wired circuit, Power Siphon
Goal: rework Astral Nexus: a little larger; starpower generators (darker orange + star) sprinkled, joined by a wired circuit of envoy lattice tiles; Power Siphon at turn end on the live circuit.

## Readings
- Lattice (Battle): startile = source (Battle.STARTILE), starpane = side-on link (Battle.STARPANE); joined side-on via on_lattice(). Same resources referenced (Terrain/startile.tres, starpane.tres), not duplicated.
- Turn end: footing.at_end afflicts (+1, tick takes this turn), then tick, then _sap/_synergize.
- Old layout: startile grid + panes everywhere = one connected lattice; a circuit must stand apart, so the rest becomes stone floor + void.

## Calls
1. Reading of the rule: as written. Each generator: tile (startile) x x (1-2, per generator by seed) out each of its 4 sides, panes on its 4 diagonals (a 3x3+ hub); panes are the wires (they link the lattice side-on). "pane * base power": read as the pane run filling the rest of the way to the next generator (a wire), not a count.
2. Wiring: generators sprinkled by seed (min spacing), joined by L-shaped wires along a nearest-neighbour spanning tree + 1 extra edge (a loop: a circuit, not just a tree). Landing (START) wired in like a node (no generator).
3. Rest of nexus: stone floor within 2 of the circuit, 15% of it void; void beyond; unreachable floor voided. Old startile grid/pane fill dropped.
4. Size 23x13 -> 29x17; generators 4-6 (was 3).
5. Live circuit = lattice cells joined side-on to a source whose terrain has at_end, charge > 0. Generic hook: a lattice source's at_end reaches whoever ends a turn anywhere on its circuit (Battle). Generators the only such source now.
6. Power Siphon = new Effect stat `siphon` (amount 0.05) on the generator's at_end, name "Power Siphon" (--human). Read at turn end after tick (Battle._siphon): lose amount x max HP, gain amount x max_energy via grant_energy (Power if powered, else Energy), each at least 1. A status for one turn: shows on the unit; skills can apply it later.
7. Generator art: darker orange (#c25a12) with a yellow star (PIL), Tiles/starpower_generator.png.

## Done

## Next
