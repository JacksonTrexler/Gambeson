# Todo: UI and styling

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

## Log

The grammar (in `docs/done/rules.md`): `Actor Skill Rank --> Target (ours - theirs)`, `-x>` for a miss or failure, an unknown roll dropped (`(15)`), short verbs, no closing periods.
- [ ] Round and initiative lines, skill toggles ("Lancin: Wary on") and party lines don't use the arrow yet. Should they?

## Elsewhere

- [x] **Skills as icon boxes** on the trees: letters (or Nerd Font glyphs) as placeholder icons. Built with letters: a skill's glyph or initials (`docs/done/ui.md`).
- [x] **AI placeholder skills** end their names with ?? (`Skill.ai`): the Wizard and Mage stubs and the Berserker's Prowess skills. Others an AI designed can be marked as you find them.
- [x] **"Pick up to x"** boxes around a class's choice of trees (see Picking trees, `docs/todo/classes.md`).

- [ ] Settings › Gameplay toggles, starting with auto-equip, once Equipping exists.
- [ ] The Adventurer's extra slot is a base slot, slightly darker. (?3)
- [ ] When targeting, if a unit is just out of range from the caster's current tile, show small circles for both units' sizes so the gap is visible. *Now:* a near miss is decided by luck, with no explanation.
- [ ] Lore keeper: one reference per skill, and its hover description is what the skill is built from. (?8)

8. Lore keeper: skill data (numbers) + optional flavour text + small behaviour scripts for one-off mechanics. Is that the "hybrid" you mean?

53. Tiers now read **T1**, T2 (capital T, matching the tree's row labels) rather than "tier 1". You wrote "t1" - capital fine?
54. Tab colours I inferred: each class's own tab (Adventurer brass, Fighter steel, Paladin gold, Rogue sea green, Bard rose, Wizard blue, Warlock violet, Cleric parchment white), gods by domain (Ramut bronze, Eros pink, Sol orange, Urlo cyan, Luun violet, Drael blue, Vetruvis earth brown), patrons (Elmon teal, Hogel pale yellow), Calling: Freedom sky blue, Species tan, Knowledge parchment. Martial is #d27a70. Any to change?
55. "Polymorphized / codified": I codified effects as data - one definition per term (`Glossary`), referenced by every skill and tile, with the markup carrying what each piece is. The rules behind them still run off flags in `Battle`. Is that what you meant, or do you want effects rebuilt as classes, one script per kind with its own apply and describe (a big refactor; see 8)?
56. Offense and defense mods are coloured in descriptions only; no screen lists a unit's stats yet. Want a stats block (on the character sheet) showing each mod and whether it's working for offense or defense now?

## Commanding and tiles - shipped (see `docs/done/ui.md`)

All built this pass except two bits of polish:
- [ ] **Walker pictogram** for the tile panel's move cost (needs art); "Mv -N" stands in.
- [ ] **High contrast: thicken faction borders** (the brighter glow and whiter text are in; borders still to do).
- [x] 60. **Built on judgement:** intents come with *either* low cha *or* low info (an inclusive or; an exclusive one would hide them from a commander who is both). Open for review.
- [x] **Colours by AP and command limits** (2026-11-09): units colored normally, desaturating somewhat (not darkening) as an ally runs out of AP, grey once it can't be commanded on the player's turn; allies of other sides not coloured this way; a leader commands cha mod allies a turn, up to cha mod orders each. Built (`docs/done/ui.md`, `docs/done/rules.md`). (?83)

83. **Colours and command limits - built on judgement, open for review (2026-11-09).**
    - The dark units were a shader bug, not the art: it multiplied the texture in twice, squaring every colour. Fixed for every unit.
    - "Showing up black" read as also covering units whose side can't be told, which were painted solid black: they now show their own colours, told apart by a neutral grey glow and no HP bars (the Guide says so). Say if you'd rather keep them as silhouettes.
    - The drain: 1 - 0.45 x (AP spent share)^2, so full colour at a fresh turn, about 89% at half, 55% on the last AP; then grey. Grey covers every reason it can't take an order now - out of AP, out of reach, asleep, a wasted intent, past the limits - so an ally out of reach is grey from the start of the turn and colours up as the leader comes close. The leader greys only when out of AP.
    - Limits: cha mod allies a turn and cha mod orders each, at least 1 of each (a cha 8 villager leads one ally, one order); the command and party effects (Quartz Ring) don't raise them. Every order counts - a move, a skill, a hold, an intent - but a charge's walk and strike count as one. The leader's own actions are unlimited. A unit's card shows "Ordered 1/2" while it can take more, and "Command spent" once the limits bar it; clicking one says why ("Brick gives an ally 2 orders a turn (charisma +2)").
