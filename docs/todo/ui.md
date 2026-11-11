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
- [x] **Silhouettes and the four strengths of glow** (2026-11-09): built (`docs/done/ui.md`; plan and calls in `docs/plans/silhouettes-glow.md`). (?84)
- [ ] **Area skills give no glow**; the tiles in range stay the overlay's job.
- [ ] **"Somewhat" could offer the unsure walk on a forced click**, as Strike's forced charge does. Not built. (?84)
- [ ] **The command glow follows the leader only**: a party member with its own reach isn't walked.
- [ ] **Watch the cost of the reach map on big maps**: it is now computed while a skill is armed (it was skipped).
- [x] **Suspicion marks** (2026-11-10): built (`docs/done/ui.md`; the plan's "Revised" section). (?84, ?96)
- [x] **Suspicion held only by allies other than the leader shows no mark**: answered 2026-11-11, built; while a unit is commanded its own read shows (`HUD.eyes()`). (?96, ?99)
- [x] **Sight by unit** (2026-11-11, `w-sight`): the card chip reads "?"; while the player commands a unit, the map, marks, glow and reads follow that unit's eyes; marks are kept per viewer. Plan: `docs/plans/silhouettes-glow.md`, end of "Revised"; `hud_test.test_sight_by_unit`. (?96, ?99)
- [ ] **Battle UI v2** (`docs/ui-ux-v2.md`; planned, nothing built): one `Intent` for what a click means, a selected slot that never blocks walking, the hover table, cues in place of words, pace. Steps: Intent (M), focus and slot (S), hover rows (M), words-to-cues (S each), pace (S). (?90)

84. **Silhouettes and glow - answered (2026-11-10), built (`v-suspicion`, ?96).** Suspicion on a concealed or hiding unit: a black shadow in the fog. Suspicion on unconcealed trickery: an immediate fading ? on the unit, neutral glow and faction colours, as if unaffiliated. High suspicion or discovery on unconcealed trickery: an immediate fading ! on the unit, coloured in its true faction, regular faction colours. The rest stands as built, except that suspicion alone no longer makes a black shape (first call below, replaced). Plan: `docs/plans/silhouettes-glow.md`, "Revised 2026-11-10".
    - A black shape is only for what might be a monster in the brush: the viewer has placed the unit, can't tell its side, and something stands between (darkness, fog, brush, hiding; too far to make out under limited sight; or suspicion of the unit or its tile). A unit in plain view that the viewer can't identify keeps its colours with a neutral grey glow. The viewer's own side never draws black; an ally of another side only when really hidden or in the dark.
    - **Suspicion alone makes a black shape, even in daylight** (your "suspicious hiders"). Say if it should need darkness or cover too.
    - The glow has four strengths, 0.3 / 0.65 / 1.25 / 1.6 of the plain glow (sizes 0.8 / 0.9 / 1.15 / 1.3), plain between somewhat and mostly. Skill armed: fully in range now, mostly a sure walk brings it in range (a click walks and uses the skill), somewhat only an unsure walk does, barely not this turn. Nothing armed: the player's own units, by the leader's walk toward them. A walk is unsure when the walker is held, the ground isn't vouched for, or it steps on a known trap.
    - **Clicking a "somewhat" target does not walk**: the note only says "Out of reach", because no sure walk gets there. Say if it should offer the unsure one.
    - **Glow strength is unreadable on a black shape**: the shape has no colour or edge for the glow to show on, so a silhouette says nothing about reach. Say if it should keep a faint rim.
    - Other calls: too far to make out counts as concealment; a spent unit glows barely and is grey; a far one in colour can also glow barely; the command glow judges one straight walk of the leader (cheap, and can under-report "mostly"); high contrast lifts the glow of the own side and any unit with a level; `Unit.command_look` is gone, `set_glow` and `set_saturation` replace it. Own units still drain with AP; one only out of command reach stays in colour (new command state `far`).
96. **Suspicion marks - answered (2026-11-11), built (`w-sight`, ?99).** "Unit card should just read ? / suspicion tracked by unit not just leader, while commanding unit player sees through their eyes." The card now reads "?", and each unit holds its own suspicion; while a unit is commanded the view is its eyes (call below, ?99). Built on judgement before that, my calls: Your ruling on 84, built on `v-suspicion` (`docs/plans/silhouettes-glow.md`, "Revised"). My calls:
    - **The unit card reads "Suspected"** while a "?" stands.
    - **A merely suspected non-trick gets no mark** and keeps its ordinary look: a "?" is only for something that would fool the viewer but for its suspicion (trickery, a front, Conspire).
    - **Bar trim turns neutral** while the "?" stands, with the glow and colours, as if unaffiliated.
    - **The "!" uses the existing reveal** (each stack takes a rank off trickery, so it shows once the read is no longer deceived): no new threshold. Say if you wanted a separate "high suspicion" level.
    - **Suspicion held only by allies other than the leader shows no mark** (todo above). Say if a side-mate's doubt should show.
90. **Battle UI v2 - planned, open (2026-11-09); the four points asked 2026-11-10; best guesses given 2026-11-11, proposed and awaiting your "go".** `docs/ui-ux-v2.md`; nothing built. Four points to settle before the hover table:
    - Does resting by clicking yourself end the whole side's turn, or only that unit's? **Proposed:** only that unit's turn.
    - "First offensive skill from the selected slot": search rightward only, or wrap around? **Proposed:** the hover search wraps around the hotbar.
    - Odds as three bands (solid, broken, faint brackets), or keep the percentage when Defense is known? **Proposed:** bands on the map; the exact % on a held modifier key or the expanded card once Defense is known.
    - A self skill: confirm with a second key press, a click on yourself, or both? **Proposed:** either.

99. **Sight by unit - built on judgement, open for review (2026-11-11).** Your ruling on 96, built on `w-sight` (`docs/plans/silhouettes-glow.md`, end of "Revised"). My calls:
    - **A unit counts as commanded while selected on the player's turn even after its orders are spent**, so the view doesn't jump to the leader as the last order goes. Say if it should drop back.
    - **The camera and the spellbook still follow the leader** (`observer()` is unchanged); only what is drawn and read follows the commanded unit.
    - **Each viewer keeps its own memory of marks**, so switching units pops nothing, but returning to a viewer whose read of a unit changed while away pops once.

## Suspicion's eye, the clock, moving together, the spellbook (2026-11-11)

101. **Suspicion's eye and the log's ?, ! and !? - built on judgement, open for review (2026-11-11).** "Keep [suspicion] as a utility effect... a purple eye instead of multiple suspicious-of buffs"; "in logs only call out suspects if an odd tile/unit is discovered (?) or its identity is revealed (!)". My calls:
    - **One eye for everything suspected**, its corner counting them (from 2); its tooltip names each unit as the *suspicious unit* knows it (the name it goes by to it, else "A <looks>", else "Something") and each tile as it looks to it ("Grass at 3, 4"), with the ranks it sees through. The eye is `Icons/Effects/suspicion.png`, drawn white and tinted purple (`HUD.SUSPICION`), replaceable like any placeholder.
    - **"?"** is a unit's *first* stack of suspicion of a unit or tile (inspecting, doubting, or being told); **"!"** is when that suspicion makes it see through: a lie that no longer fools it, or something hidden now plain. The per-stack "suspects" lines are gone; being told isn't logged. The investigation lines (seeing through Hide) stay as they were.
    - Every unit on the player's side logs its own "?" and "!", so one discovery can read as several lines when allies are told. Say if only the commanded unit's (or the first) should show.
103. **Turn clock - built on judgement, open (2026-11-11).** "wisdom + (int/2) seconds to act... a timer on the top middle". My calls: the player's (the leader's) wisdom and intelligence *scores*, half rounded down (wis 12, int 11: 17 s); a second more for the turn banner; it pauses only while Settings is open - the spellbook, skills screen and character sheet all count; red in its last 5 seconds; running out ends the turn as End Turn would (idle allies act on their own). Off when nobody's watching (`pace` 0: tests, sims) and switchable (`HUD.turn_clock`).
104. **Faction moves together - built on judgement, open (2026-11-11).** "Faction moves can take place visually simultaneously once player turns are wrapped." Every batch of units acting on their own - other sides' turns, and the player's idle allies once End Turn is pressed - moves at once, their walks animating side by side, then the turn ends once the longest walk is done. Each still *decides* in turn (one sees where the last moved). Sides still take their turns one after another, with the banner between. `HUD.together` turns it off.
106. **Demo level - built (2026-11-11).** A Level box on the entry screen, 1 to 20, default 1; the starter gets a skill point a level past the first, as levels from earlier battles already did.
107. **Spellbook detail - built on judgement (2026-11-11).** "In spellbook share UI with skill tree to display skill information." The skills screen's footer is now its own piece (`SkillDetail`), and the spellbook has one under its columns: click an entry to see it in full, as the skills screen shows it (rank, tier, spec chips, text) with no buy button. It opens on the first entry; the spellbook is a little taller.
108. **"Cut hover to 1 second" - read as tooltips, open (2026-11-11).** The tooltip delay was already 1.0 s (project settings). What made hovering slow was likely the unit card rebuilding its icons on every refresh, which restarts the delay (and can pull a tooltip away); the card now skips a refresh when nothing on it changed. If you meant another hover (the tile pane, the unit card on hovering a unit, the Guide), say which.
