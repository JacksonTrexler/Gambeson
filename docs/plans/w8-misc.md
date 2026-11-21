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

## 3. Sim: Skeleton with the foe in walking reach
`Tests/sims/ai_sim.gd`: `_host` now calls `_hosts(n, foe_x, name)`; new scenario `hostnear` (soaker 5 tiles off, caster at 4,3, 10 rounds). Names: none made up.
`Tests/sims/sweep.sh BODY "0 5" hostnear` (BODY 0 = the AI before `_summon()`), damage to a 900 HP soaker that never hits back:
| | bodies | damage (n=8) | damage (n=24) |
|---|---|---|---|
| BODY 0 (never raises) | 0 | 30.50 | 30.83 |
| BODY 5 (today) | 6.0 | 30.25 | 32.83 |
| SUMMON_CAP 4 (n=8) | 2.0 | 41.62 | |
| SUMMON_CAP 12 (n=8, today) | 6.0 | 30.25 | |
Reading: with the foe in reach, raising a host is about neutral on damage over 10 rounds (the caster's AP goes to casts rather than its own Strikes, and Skeletons strike weakly); a small
cap (fewer casts) does clearly better here (+35%). The soaker never fights back, so what bodies are worth as targets and blockers is not measured. Call: left BODY, SUMMON_SEEN and SUMMON_CAP
as they are (the value of a body is a design call; if damage is what matters, a cap near 4 is the number to look at). Question for the user.

## 4. Retune AI.LOST (0.5 -> 0.35)
Sweep: `SIM=hunt_10v10 Tests/sims/sweep.sh LOST "..." near n=4` (find_rate over 20 rounds, 10 rangers vs 10 hiders, near start; first find round in brackets):
| LOST | still-near | moving-near |
|---|---|---|
| 0 | 0.70 (12.3) | 0.72 (13.3) |
| 0.25 | 0.70 (12.3) | 0.72 (13.3) |
| 0.35 | 0.72 (12.3) | 0.75 (13.5) |
| 0.45 | 0.70 (12.3) | 0.57 (13.5) |
| 0.5 (was) | 0.32 (8.3) | 0.53 (12.5) |
| 1, 2 | = 0.5 | = 0.5 |
Reading: the lost-foe guess is a look from where the hunter stands. From 0.5 (= WORTH, the least a look must take in to be cast) up, the rangers cast it and stand looking
where they already are, and find less than half as many in this field (0.32 vs 0.70), though the first find comes sooner (8 vs 12). Below WORTH it is never cast alone (it only adds to another guess
at its tile), and the results are flat from 0 to 0.35; 0.45 is mixed. The original fix's own sim (`ai_sim hunt`, n=30, one hunter, found-rounds): 0.5 gives 4.67 / 5.10 (still / moving), anything below 0.5
gives 5.07 / 5.37, the pre-fix numbers. So no value serves both: the near hunt wants it under WORTH, the lone stuck hunter wants it at WORTH.
Call: **0.35**, the best near numbers, a value inside the flat region and not on the edge. This all but turns off the stuck-hunter fix (0.4 of a round slower in the lone hunt sim); if the
stuck hunter matters more, put it back to 0.5 and instead stop the look repeating where it stands. Question for the user.
Tests: `evidence`, `sight`, `hunt`, `search`, `ai` words pass unchanged (none pins the value).

## 5. Utumno art, second pass
Screenshots: the sibling's own (`scratchpad/shot_w8-icons/02_skills.png`, `03_skills_scrolled.png`, from the code with `Skill.icon_ink`) show the skills screen with the coloured icons under each state; I did not take new ones.
Reading: learned (Mana, Mage Armor): full colour, read well. Open (Clairvoyance, Forage): slightly dimmed, read well. Locked/unknown ("?" dashed, e.g. the 4th-tier icon): at 0.4 x 0.55 alpha a dark coloured icon is
close to illegible on the dark red field; the grey letter placeholders in the same state are likelier readable. Not changed (the tint is the sibling's).
Items (`Icons/Items/`, copied from `/Users/jtrex/assets/utumno`, sources untouched, 16x16 copied as is like the skills; the item icons are drawn untinted and `icon.py check` fixes no size):
- broken-doom-plate (32x32) -> plate; broken-blue-robes (32x32) -> robe; rare-blade -> starblade; shadowflame-sword -> burning_blade; bronze-lil-heart -> heart; body-plus -> heart_up; lil-speed -> hobnail_boots;
  cursed-accessory -> shackles (a cursed binding trinket).
Leaving the matching up to the user's eye: these are guesses by name and look. Left unused: the helms (no helm item), the shields (no shield item), broken-astral-robes (no astral robe), fear, poison,
snake-debuff, the grave, the tilesets and the rest of the old list.
Statuses: none mapped. A status has no icon field: a unit card shows a text mark and only Suspicion's eye is a texture, wired in HUD.gd. Giving statuses art is code (an `Effect` icon), not a mapping, so it needs the user's call.
`Shade.png`, `Elmit.png`: left alone.
