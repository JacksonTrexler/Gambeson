# w24-assault: Assault (card 6b)

Goal: t3 Specialist skill "Assault" (user's name, --human): pick rank+1 allies in order, then targets; each picked ally walks and uses its leftmost attack on up to rank targets, nearest first (AI.assault seam, 6a). Blocked: an ally on a needed tile may make a medium wis+dex hybrid check to step aside. Effects bearing `assault` that a participant gains during it are shared with every participant, and end with it.

## Readings
- Picks: Behaviour.picks(c) (Warcry) -> HUD toggles foes into `picked` (HUD.pickable: foes only), Battle.cast(..., picked) -> Cast.picked. Self skill (self_only), its key again casts.
- AI.assault(b, units, targets, per): walks via _approach (returns the target's own cell when no free tile beside it), then leftmost attack on per nearest.
- No hybrid check helper: Battle._side_mod takes an Array as best-of.
- Effect.bears: tags a status bears (Unit.afflicted(tag)).

## Calls
- Picks: new Behaviour hook `allies(c) -> int`: how many of its picks() are allies (the rest foes). HUD.pickable takes an ally while fewer than that are picked, a foe while fewer than the rest. Generic: any later skill picking allies and foes.
- Assault picks: rank+1 allies + rank targets (card: "select a target" but "up to rank selected targets"; one target suffices). Caster is not a participant (it directs); an ally pick of the caster isn't possible (a click on itself casts).
- Nothing picked (quick cast, AI): the nearest rank+1 allies it can place, the nearest foe.
- Each participant pays its own AP/Energy for its attack and its own movement; Assault itself costs the caster `--cost "low cost"` (modest), AP by calculator.
- Yield: "needed" tiles = those beside its first target within its leftmost attack's range (melee: orthogonal at range 1). None free: each ally (friends, not stopped) on one, nearest the attacker first, rolls d20 + mean(wis, dex check mods) vs flat medium DC 12 (Battle.check o.hybrid); passing, it is placed (no movement paid) on a free tile beside itself, one still beside the target preferred; the attacker then walks to the freed tile. One success per attacker. A blow reaching past 1.5 never asks (it finds its own tile). Foes never yield. No HUD signal/log line for the step-aside (seen as a move).
- Hybrid check: `hybrid = true` option on Battle.check/sides: an Array of stats counts as their mean (Unit.rounded: luck rounds), not the best.
- Sharing: tag `assault` (Glossary, kind target, human: user's word). After each participant acts, any status bearing `assault` on a participant that isn't on the others is put on each (same turns, rank). At the assault's end those statuses come off every participant. No content bears it yet (latent seam, like Tags meant for later skills).
- AI doesn't cast Assault (no worth hook); the AI's own group turn (6a) already acts in step.


## As built
- Skills/assault.tres: specialist, offensive; self_only, hostile false, rolls false; cost "low cost" (4 AP, 1 Energy at I-III); impactful; no_density set; glyph As; Trees/general_specialist.tres tier 3 after Tactician.
- Behaviours/assault.gd: picks 2 x range_rank + 1, allies range_rank + 1; allies_of / foes_of (picked in order, else nearest); apply -> AI.assault(b, allies, foes, range_rank); terms rank_range; describe / describe_as.
- Scripts/Behaviour.gd allies(c) hook; Battle.allies_of(); HUD.pickable() takes allies when allies_of > 0, _toggle_pick caps allies and foes each at their share, hint "click allies, then foes".
- Scripts/Battle.gd: check/sides/_side_mod option `hybrid` (Array stat -> mean, Unit.rounded).
- Scripts/AI.gd assault(): _make_way() (yield), _aside(), _around(), _share(); shared assault statuses erased from all participants at the end.
- Tag `assault` (mechanic.py, human, kind target, #c8503c).
- Tests: ai_tactics_test.test_assault (hybrid mean < best odds; pick order [h2, h1, h3] -> used order [h2, h1], h3 sits out; yield + move into freed tile; assault status ends; _share to participants only). warcry_test HUD picks: Assault takes 2 allies + 1 foe, hint. Stub Tests/assault_test.gd deleted (sweep covers casting).
- Mutations: no _make_way -> 2 fail; ally cap rank+2 -> 2 fail; no end-erase -> 1 fail. Reverted.
- Suite: 11952 checks, 0 failed (1108 tests). skill.py / mechanic.py check ok; launch: only "resources still in use".
