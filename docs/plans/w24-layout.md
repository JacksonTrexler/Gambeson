# w24-layout: Astral Nexus layout
Card: 2-3 generators, empty pockets, few 2-wide startile-only bridges (2 x pane rank long) between panes; ranks/map/starmen scale with difficulty; starmen vindictive to princesses; "starnests": very rare neutral princess + bigger horde.
## Calls
- "Starnest" = the Nexus (nest of generators). Skill Starnest (Behaviours/star_place.gd, shape nest) spawns no units; unchanged.
- Difficulty d (battle.difficulty .5..1.5), linear: map 33x21 +(8,6)*(d-1); gen rank 4+(d-1) (3..5, capped SIGNAL_FULL); pane rank 2+(d-1) (1..3); starmen rand(3,5)*d.
- Ranks set at battle ready via Layer.power; generator charge = 20*rank/5 (full for its rank).
- Bridges: 1-3 attempts; a straight run of 2*rank panes (panes at both ends) turned to startiles, plus a parallel row = 2 wide. As many as fit.
- Pockets: map bigger, 2-3 gens, VOIDED .15 -> .3.
- Rare nest: 4% (export `rare`), horde x1.75, one AstralPrincess in new neutral faction Factions/wanderers.tres (not Starmen: same faction would be friends). Starmen are hostile to her by bio grudges astral (verified in starman.tscn: vindictive, grudges astral); no AI change.
- START const -> instance `start`; WIDTH/HEIGHT -> width/height. layout() gets optional reach.
## Tests
tower_test.test_nexus updated (counts, ranks, bridges, scaling).
## As built
Done: AstralNexus.gd (scaling, bridges, prune unlit walkway, rare princess), Factions/wanderers.tres, tower_test updated (+rare nest). Gotcha: ready.connect with .bind per cell collapsed to one connection; one lambda loops instead. Bridge ends widened to 2 panes so side row is in signal. Mutation spot-check: not run.
