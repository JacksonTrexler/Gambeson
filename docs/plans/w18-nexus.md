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
6. Power Siphon = new Effect stat `power_siphon` (not `siphon`: that tag exists) (amount 0.05) on the generator's at_end, name "Power Siphon" (--human). Read at turn end after tick (Battle._siphon): lose amount x max HP, gain amount x max_energy via grant_energy (Power if powered, else Energy), each at least 1. A status for one turn: shows on the unit; skills can apply it later.
7. Generator art: darker orange (#c25a12) with a yellow star (PIL), Tiles/starpower_generator.png.

8. Overlay: a layer with its own `look` draws it (generic; the generator is the only one now). Lattice star still drawn on top.
9. Power Siphon status counts as helpful by Effect.helps() (mixed: HP out, Power in); cleanses won't strip it. Not in HARMFUL.
10. Starmen (starkind) on the circuit are siphoned too; the party lands on a startile (on the circuit).

## As built
- Battle.circuit_ends(c), Battle._siphon(u) (after tick, before _sap); at_end loop afflicts circuit_ends for 1 turn (+1).
- Effect stat power_siphon; Terrain/starpower_generator.tres at_end Power Siphon 0.05, turns 1; Tiles/starpower_generator.png #a84a0c + yellow star.
- Scripts/AstralNexus.gd: _sprinkle, _wires (Prim + 1 loop), _put, _near; floor_cells; 29x17; START (1,8) (scene spawns too).
- Scripts/Overlay.gd _layers draws t.look.
- Tests: stars_test.test_siphon (new); tower_test.test_nexus updated (4-6 gens, in bounds, one live circuit, floor/void, same seed same circuit). Mutations: circuit_ends -> [] fails test_siphon; no wires fails test_nexus.
- Suite 11094 checks, 0 failed (1048 tests). Visual: S/shot_w18-nexus/m00000049.png (orange star generators, pane wires).
## Next
- Nothing open. Possible: AI weighing the siphon (it walks the circuit blind to it); generators recharging from siphoned Power.
