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
8. The Monster arrives in its class outfit (gambeson, dagger; now in Unit.monster() itself), nick "<Path> Monster".
9. AI price: `bodies()` = count x (rank + 1): a level L class unit weighs as L + 1 Skeletons (a level 1 Monster ~10 HP + dagger vs a Skeleton's 6); else 1 body (5) never repays 4 AP + 3 cost (7.5) and the AI never casts it.
10. Price: calculator "even" -> 4 AP, 3 cost at every rank (as Skeleton); impact impactful from the behaviour's terms; rank_impact "level".
11. Tool: skill.py check reads a behaviour's parent (`extends "res://Behaviours/x.gd"`) for its hooks.

## As built
Files: Skills/thesis_of_theseus.tres + Icons/Skills/thesis_of_theseus.png, Behaviours/theseus.gd (extends summon_per_rank.gd: count 1, make, choices, path, bodies, terms, describe), Behaviours/summon_per_rank.gd (make() split out), Roles/wizard.tres (Transgression, needs 5), Trees/elmon.tres (needs 5), Scripts/Behaviour.gd (choices(), Cast.chose), Scripts/Battle.gd (bring(), _chosen, cast_at(.., chose), choices_of()), Scripts/HUD.gd (chose, _pick_choice via _choose), Scripts/Unit.gd (openers(), monster_paths(), monster() outfit), Util/skill.py (parent hooks).
Tests: new Tests/thesis_of_theseus_test.gd test_theseus (choices = 3 paths; Starmen, Sirens chosen -> level 3 Monster, traits at I, AP kept <= rank + mod; none chosen -> Skeletons (fewest); cap 5 none Disturbed; cap 2 -> 2 left in hand; AI._summon raises a level 1 Monster; describe says level). Sweep covers the cast. No existing test changed.
Mutations (each failed the test): level 1 not rank (2); chosen ignored (2); no fewest (1); bodies without the level weight (AI, 1); no overflow (cap, 1).
Visual: S/shot_w18-theseus (m00000110: path picker Starmen / Sirens / Skeletons / Cancel; m00000168: Sirens Monster raised 2 tiles off, log "Thesis of Theseus II").
Suite: start 11293 checks, 0 failed (1061 tests); end 11317, 0 failed (1062 tests). skill/role check ok; launch clean.

## Undone
- Dark mage (Mortis Arcalís too small for t6) and dark cleric (no death tree, ?240): not placed.
- The Monster's level - 1 skill points stay unspent (no AI spend); its picks are path only (no trait design).
- Elemental Strike still uses its own HUD branch (_pick_element), not Behaviour.choices(): could migrate.
- Walk-then-cast: the picker comes on the hotbar press, before aiming; a cast by click without a press picks for itself.
