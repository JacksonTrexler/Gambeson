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
- Yield: when no free tile beside its first target (approach returns the target cell), each ally (friends, not stopped) beside that target, nearest the attacker first, rolls d20 + mean(wis, dex check mods) vs flat medium DC 12 (Battle.check o.hybrid); passing, it is placed (no movement paid) on a free tile beside itself, one still beside the target preferred; the attacker then walks to the freed tile. One success per attacker.
- Hybrid check: `hybrid = true` option on Battle.check/sides: an Array of stats counts as their mean (Unit.rounded: luck rounds), not the best.
- Sharing: tag `assault` (Glossary, kind target, human: user's word). After each participant acts, any status bearing `assault` on a participant that isn't on the others is put on each (same turns, rank). At the assault's end those statuses come off every participant. No content bears it yet (latent seam, like Tags meant for later skills).
- AI doesn't cast Assault (no worth hook); the AI's own group turn (6a) already acts in step.
</content>
</invoke>
<invoke name="Bash">
<parameter name="command">W=/private/tmp/claude-501/-Users-jtrex-projects-Gambeson/7fee0a29-8427-4247-aa04-0dd589cd5d04/scratchpad/wt-w24-assault; cd $W; grep -n "AI\.\|AI\b" Behaviours/*.gd | head -3; grep -n "specialist\|offensive" Scripts/Glossary.gd | head -5; cat Skills/strategist.tres | sed -n 1,30p