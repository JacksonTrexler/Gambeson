# w18-theseus: Thesis of Theseus (t6, dark nature): design and summon a Monster at rank level

User: "Wizards, warlocks, dark mages, dark clerics have t6 skill `dark` `nature` Thesis of Theseus: Casting it allows them to design and summon a monster at rank level."
Readings: follow-up.md F18, F19 (no Answer: best guesses used).

## Calls
1. Placement (t6 = tier 6 = root `needs = 5`): Wizard's Transgression root (forbidden lore, blood magic: its dark wing) and Elmon (the Warlock's patron tree, beside Death, also needs 5; a Wizard's Witchery Pact reaches it too). "Dark mage" = a Mage on Mortis Arcalís, but that root holds 2 skills, so no t6 there: not placed (waits for the tree to grow). "Dark cleric": no dark god / death-cleric tree (?240): waits.
2. Tags dark, nature (both exist) + magical, int (as Skeleton: a spell, int its stat for the soft cap and kept AP).
3. Rank level: the Monster's level = the cast's impact rank (rank, raised by a modifier that raises rank impact). One Monster a cast.
4. Design = pick a path only (Starmen, Sirens, Skeletons); traits come free (Unit.monster). Its unspent skill points (level - 1) stay unspent.
5. Generic hook, not a per-skill branch: `Behaviour.choices(c)` (labels) + `Cast.chose`; `Battle.cast_at(.., chose)`; HUD asks with its `_choose` panel when a tile skill's behaviour has choices, before aiming. Empty/invalid chose: the behaviour picks (as the AI).
6. AI pick: the path fewest on its side (a unit counts for a path if it holds any of that path's opening traits: a Siren scene, a Starman, a Monster of it), ties by Battle.rng.
7. Summon rules: behaviour extends summon_per_rank (soft cap rank + stat mod, kept AP, Disturbed past the cap, raised_by); `make()` split out so a subclass makes its own unit; Battle.summon split into `bring(u, ..)` for a built unit.
8. The Monster arrives in its class outfit (gambeson, dagger), nick "<Path> Monster".

## Done
## Next
