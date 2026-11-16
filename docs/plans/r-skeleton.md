# Skeleton and Mortis Arcalís (branch r-skeleton)

The user: "new spell Skeleton, it creates 2 undead weak skeletons per rank." and "Mortis Arcalís:"
(nothing followed). "Arcalís" is the user's word for arcane/magic broadly.

## Readings and calls

1. **Mortis Arcalís is a school (a tree)**, named by the user (`--human`, no ??): `Trees/mortis_arcalis.tres`
   (`role.py tree`, tag magical). Skeleton is its first skill. Tab colour (a pale green) is a placeholder.
2. **Where: the Mage's School choice** (`role.py tab mage --into School`), not a Wizard tab. The Mage already
   holds the School choice (Radiance, Currents, Stone, Shadow, Stars, Illusion) and the Wizard borrows
   "School" through Mastery, so one place offers it to both; Illusion went in the same way. The Wizard's
   own trees are lines of study (Arcane, Transgression), not schools.
3. **Undead needs no new tag**: `undead` is already a Unit tag (Perception.NATURES reads it as dead/unholy,
   PersonaPanel lists it). Only its colour was missing (`mechanic.py color undead "#9aa98a"`, placeholder).
4. **Skeleton unit** (`Scenes/skeleton.tscn`, `unit.py`, name `--human`): tag undead, vibe Hollow, aura -1,
   appearance "Skeleton", temper aggressive, class-less, faction unaligned (only a default: summon sets it),
   level 1, HP 6, Energy 4, str 10 dex 10 con 8 int 3 wis 6 cha 2, Strike only. Weaker than the Pike
   (HP 8, level 2) and the Shade (HP 8); it is many of them that count. Placeholder sprite `Units/Skeleton.png`.
5. **Skeleton skill** (`Skills/skeleton.tres`, name `--human`): tags magical, dark, int (so Darkness
   resistances/modifiers can see it; `dark` is only a damage tag, it deals none); a tile skill, range 3
   (radius), not hostile; priced by the calculator (AP 4, cost 3: rank impact "summon", impact impactful).
   Price does not grow with rank; the count does (2 x rank), as every rank-impact skill.
6. **Generic behaviour** `Behaviours/summon_per_rank.gd`: exports `scene` and `per_rank` (2); count =
   `per_rank x c.impact_rank()`, so a modifier that raises rank impact raises the host. Any later
   summon sets another scene and number.
7. **Who controls them**: they are the caster's faction, ordinary units: the player's allies are commanded
   by the leader or act on their own through the AI, as any ally does (no `uncontrolled` flag, no owner
   field). On the AI's side they are AI's.
8. **How long**: permanent; nothing ends them but a death (then `neutralized` fires as for any unit).
   They don't die with the caster. No cap on how many a side has; the cost and the turns are the limit.
9. **Where**: each on the free tile nearest the tile aimed at (`Battle.summon`, `free_near`), so the first
   is on it, the rest around it; the tile is within range 3 of the caster.
10. **Past free tiles**: `free_near` widens its box over the map, so only a full map says no; the rest
    simply don't come (the cast and its price still stand).
11. **They arrive with their AP spent**: they act from their side's next turn (no free hits on the
    turn they rise). `Battle.summon` refreshes a unit on its side's turn, so the behaviour zeroes the AP;
    Battle.gd is untouched.

## Tests

- New `Tests/summon_test.gd` (one seam): rank 2 raises 4, caster's side, near the tile, AP spent, says its
  count, one dies and `neutralized` says killed, AP back next turn.
- The stub `Tests/skeleton_test.gd` (skill and unit) deleted: `sweep_test` casts the skill at rank 2 on a tile.
- Mutations (each fails `summon_test`, then reverted): count = per_rank (no rank); summon on another side;
  AP not zeroed.
- `tooling_test` (mechanic check) caught the missing `undead` colour.

## As built / undone

- Everything above is built. Starting suite 8619 checks, 923 tests; final 8632 checks, 0 failed (924 tests).
- Undone: the AI never casts Skeleton on its own (no tile-summon plan in AI.gd); no art beyond placeholders;
  no cap or duration on skeletons.
