# Todo: UI and styling

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

## Log

The grammar (in `docs/done/rules.md`): `Actor Skill Rank --> Target (ours - theirs)`, `-x>` for a miss or failure, an unknown roll dropped (`(15)`), short verbs, no closing periods.
- [ ] Round and initiative lines, skill toggles ("Lancin: Wary on") and party lines don't use the arrow yet. Should they?

## Elsewhere

- [ ] Settings › Gameplay toggles, starting with auto-equip, once Equipping exists.
- [ ] The Adventurer's extra slot is a base slot, slightly darker. (?3)
- [ ] When targeting, if a unit is just out of range from the caster's current tile, show small circles for both units' sizes so the gap is visible. *Now:* a near miss is decided by luck, with no explanation.
- [ ] Lore keeper: one reference per skill, and its hover description is what the skill is built from. (?8)

8. Lore keeper: skill data (numbers) + optional flavour text + small behaviour scripts for one-off mechanics. Is that the "hybrid" you mean?

53. Tiers now read **T1**, T2 (capital T, matching the tree's row labels) rather than "tier 1". You wrote "t1" - capital fine?
54. Tab colours I inferred: each class's own tab (Adventurer brass, Fighter steel, Paladin gold, Rogue sea green, Bard rose, Wizard blue, Warlock violet, Cleric parchment white), gods by domain (Ramut bronze, Eros pink, Sol orange, Urlo cyan, Luun violet, Drael blue, Vetruvis earth brown), patrons (Elmon teal, Hogel pale yellow), Calling: Freedom sky blue, Species tan, Knowledge parchment. Martial is #d27a70. Any to change?
55. "Polymorphized / codified": I codified effects as data - one definition per term (`Glossary`), referenced by every skill and tile, with the markup carrying what each piece is. The rules behind them still run off flags in `Battle`. Is that what you meant, or do you want effects rebuilt as classes, one script per kind with its own apply and describe (a big refactor; see 8)?
56. Offense and defense mods are coloured in descriptions only; no screen lists a unit's stats yet. Want a stats block (on the character sheet) showing each mod and whether it's working for offense or defense now?

## Commanding and tiles (see `docs/plan-composability.md`)

- [ ] **Drop the "too far to hear you" tip.** Instead gray out an unreachable unit's hotbar / ineligible orders, and raise the prominence of units that *can* be commanded this turn.
- [ ] **Commanded units desaturate progressively**: 100% -> 50% saturation as they're ordered, grayscale once fully tapped out.
- [ ] **Default orders for low-info commanders** (0 cha, or low wisdom/info): ATTACK (default offensive skill), DEFEND (default defensive skill), HELP (default support skill), each shown only if the unit has a relevant skill. If `commander wis mod + report cha mod <= -5`, all three show with a trailing `?`. Picking an ineligible option wastes the order and locks commanding that unit for the rest of the faction turn.
- [ ] **Tile panel**: don't show `Move 1`; render move cost as a walking-person pictogram + signed number (needs an icon; `Mv -2` until then), not "Mv"; suspicious tiles end their effect list with `?` (after the move cost); drop the `Effects:` header row.
- [ ] **Suspicious-tile overlay**: a translucent grit for disturbed earth, a translucent `?` placeholder elsewhere.
- [ ] **Accessibility options**: "all suspicious tiles use `?`"; "high contrast" (double the allied glow, thicken faction borders, full-white body text).
