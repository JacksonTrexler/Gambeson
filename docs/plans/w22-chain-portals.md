# w22-chain-portals
Goal: chained Starways (exit walked to the next entry) seen by reach, AI route, and the walk.
Found: reckon_reach and _route Dijkstra already chain (a landing is a settled tile, _exit_of re-read each). Gap: travel()'s _cross() did one hop: the 2nd Starway emitted no `ported` and its exit tile was skipped (position still right).
Built: `_cross` loops: after a hop, keeps scanning the rest of the path from the tile after the exit; returns flat [entry, exit, ...]; travel emits `ported` per pair, ends-on-exit check uses hop[-1].
Calls: no change to reckon_reach/_hops (already correct); cost model unchanged (hop free, walk costs); `ported` emitted once per hop.
Test: starbuilding_test.test_ai_hops_starway +3 checks (route price, travel+ported pairs across two, reach across two). Mutation: old single-hop _cross -> ported check fails ([(4,3),(8,3)] only).
Test note: painting past the map edge widens it; w.refresh() for fresh movement.
