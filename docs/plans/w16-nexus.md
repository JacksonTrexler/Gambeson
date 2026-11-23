# w16-nexus: Astral Nexus (tower dungeon)
Goal: Dungeons/astral_nexus.tres + Scenes/astral_nexus_play.tscn on tower portal 2; tiles starpower_generator, astral_void; Power Star trinket.
User: orange generators; startile grid, somewhat broken, round generators; starpanes fill most gaps; astral void; 4-6 hostile starmen; drops Power Star (energy potion, Power only; refills w/ overflow Power at rank*15%, up to max base Power).

## Readings
- Tower: GamutsTower.PORTALS[i] <-> scene `dungeons` array; Dungeon.tres (name, scene, blurb, goal, enemies, rewards, reward_floors, color).
- Lattice exists (Astral Envoy): Battle.starpanes (cells), Battle.starpower {cell: fill}, TileStack `stacked`; Terrain.source/pane; startile = source+brittle; starlight x2..x5 Power regen on lattice.
- Void: no impassable terrain exists; paths use on_map(); Battle._cost = exit+enter+drag. Flight costs 1.
- Overflow: Unit.grant_energy(n) clamps at max_energy; overflow = n - got. Potions: trinket, restores, emptied()/filled() dup idiom, Battle.use_item/restore. Items are saved by id (state lost over save).

## Calls
1. astral_void: Terrain enter=99, tags void,detrimental; on map, so a tile, not a gap. Effectively impassable by budget; flyers cross at 1. No fall damage.
2. starpower_generator: Terrain layer, source=true, passes=true, not brittle, tag star,generator; starts full (scene starpower dict 1.0). Inert beyond being a full source (x5 Power regen on its lattice). No self-recharge.
3. Power Star: Item.soaks (share per rank of wearer's overflow Power kept, powered wearer only) + Item.held (Power stored, cap wearer max_energy); used from slot gives held as Power then held=0 (copy, as emptied()). Rank 1 = 15%.
4. Drops with held 0.
