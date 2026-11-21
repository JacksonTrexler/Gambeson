# w8-misc: five follow-ups (builder notes)

## 1. Preparation tests the plan left out
`Tests/prep_test.gd` `test_doubt_sides`: a trickster's 30-point `inquire` check bonus does not reach its side of `doubt()` (`their_tags = []`);
an Inquisition use via `prepare()` wins about 264/400 against 210/400 for a plain doubt (leader far from the siren, so no "close" edge).
Mutations: dropping `their_tags = []` fails it; `prepare` passing edge 0 fails it (gap 8 vs 54). Margin chosen: +30. No rules change.

## 2. Units carrying a pack
Two new units, via `unit.py new` (Fighter role, faction nemes, `--color` sprite, names " ??"): **Scrapper ??** (level 3, brave, Scrap Plating 3, pack Brigandine + Habergeon)
and **Bulwarker ??** (level 5, stoic, Power Armor 2, pack Half Plate + Plate). Calls:
- No new items and no loot: the existing armors (Items/) are the pack, so `item.py` had nothing to add. Dropping a defeated unit's pack as loot is not built (a new rule).
- `unit.py --set` cannot write an item array (needs ext resources), so the `pack =` line and its ext_resources were added to the two .tscn by hand after the tool ran (`unit.py check` ok).
- Their stats are the villager's (12s; Bulwarker str/con 14): at the default 5s the unit has 4 AP and armor costs 10 - dex mod, so it could never afford to dress.
  This also says armor-in-battle is dear: a unit with no dex will never dress (a design note, not changed).
- They are placed in no battle scene (every test starts from the museum). Checked in battle by `plating_test.test_packs`: each, summoned out of reach, dresses its slot through `AI.act`.
