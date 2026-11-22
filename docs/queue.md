# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-22. Reconciled against the code after ?192 to ?244 (the next question is 245).

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: Wave 9 cards 1 to 7 (the behaviour rule, Disturbed, undead and Restless Dead, Grave Aura, icon states, the Siren trait, the typing pilot, ?235 to ?240) and the follow-ups built (Utumno third pass, Deathlust log and plate slot, the band row test and 16:9 columns, the Party button and pack loot, the AI turn cost in part, ?241 to ?244); the user's third batch (answers-2026-11-20c) is all built (?226 to ?231 and the follow-ups: First Chair forecast, prep tests, a `pack` unit, the Skeleton sim, the `AI.LOST` retune, rounding on heals and the log, party outfits, ?232 to ?234), Wave 8 cards 1 to 4 (party size without the floor, unique names and ?? on tags, free lends and the band, coloured icons) and the follow-ups w8-layout and w8-ai1 built (a wider multi-slot slot, a column break off spans, Deathlust's float and pricing, plate tolls, crit loops in the forecast, a defensive cc read), Wave 7 cards A to H (passive signage, widescreen and verbiage, facing and level in the glow, studies UX, preparation uses, the Bard skills, utumno art), Wave 6 (equipment links, multi-slot skills, the Party, the audit), Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), the AI casts Skeleton, Interject's and Snapping Turtle's bonus, the near hunt sim, Deathlust (its AI unwear), the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing in flight.
Built 2026-11-22 (?235 to ?244): w9-disturb, w9-icons, w9-siren, w9-undead, w9-typing, w9-grave, w9-band, w9-party, w9-aiturn, w9-aiplate.
Built 2026-11-21 (?232 to ?234): w8-fc, w8-misc, w8-outfits.
Built 2026-11-21 (?226 to ?231): Wave 8 cards 1 to 4 and the follow-ups of w8-layout and w8-ai1.
Built 2026-11-20 (?218 to ?225): Wave 7 cards A to H. Built 2026-11-20 (?214 to ?217): Wave 6 (equipment links `innate` / `optional`, multi-slot skills, the persistent roster and Party, the queue audit). Built 2026-11-19 (?198 to ?213): Wave 3 cards 5, 6, 8, 9, Wave 4 cards A to D and Wave 5 (cc and shove, save lapses, museum sim, Chaser and Heavy Strike, density, plating, friction, Coyote, the Floater card, Student, Journeyman, difficulty words).

## Wave 4: the user's answers of 2026-11-19 (docs/agents/answers-2026-11-19.md; cards A to D built, ?202 to ?205)

## Wave 3: the user's answers of 2026-11-18, second batch (docs/agents/answers-2026-11-18b.md)
All eleven cards are built (?192 to ?201). Nothing left here.

## Wave 2 follow-ups (the user's answers of 2026-11-18 are all built, ?185 to ?191; the rules stand: no balancing now, tune by check difficulty, price effects that stop actions high)

## Wave 1: follow-ups from ?178 to ?183 (all need nothing from the user)

### AI turn cost: the per-read floor (after ?243)
- Source: docs/todo/systems.md (?183, ?243)
- Scope: w9 took the unit turn 68 to 59 ms and `end_turn` 235 to 100 (15v15 here); at M3 x 4 the unit turn is ~235 ms against the 100 budget. Next: the per-read floor ~250 us (`Unit.kit` ~45, `defense` ~25, `_dim` ~25, `trickery` ~18), a cross-stretch cache behind a mutation version on Unit, `route()` tile reads memoized per stretch, `react()` asking every unit's `on_passives` per moment, `_sightings` and `_first_look` re-reading 29 units. `busy_fight` digest 47676114 must not change.
- Read: docs/plans/w9-aiturn.md, docs/plans/r-sims.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/Unit.gd, Scripts/Perception.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: none

## Wave 5: follow-ups from ?206 to ?213 (all need nothing from the user)


## Wave 6 follow-ups: from ?214 to ?217 (all need nothing from the user)




## Wave 7 follow-ups: from ?218 to ?225 (all need nothing from the user)





## Wave 8 note (2026-11-21)
The user's third batch (docs/agents/answers-2026-11-20c.md) is all built (?226 to ?231 and the follow-ups, ?232 to ?234). The AI turn cost card above stays; the wider HUD slot is built. Follow-ups below need no user input (the user's calls are listed under "Needs the user").

## Wave 8 follow-ups: from ?230 to ?234 (all need nothing from the user)

(Built, ?241 to ?244: Utumno third pass, Deathlust log and plate slot, the band row test and columns, the Party button and pack loot.)

## Wave 9 follow-ups: from ?235 to ?244 (all need nothing from the user)
Cards 1 to 7 are built (?235 to ?240). Run 2-3 at a time, Sonnet unless noted. One card per builder; each keeps `docs/plans/<branch>.md`. Land on `origin/main` (SKILL.md).

### Opportunist (the Siren's reaction)
- Source: docs/todo/systems.md (?237)
- Scope: the Siren's Opportunist (uses its first active on enemies that run into it; `git show 4fe2c05`): a new "moved beside it" reaction trigger fired from Battle's move path plus a `Behaviour.react` (the `chaser.gd` pattern). Detective (needs a removed Investigation system) and Ambush (a watch hook) stay unbuilt.
- Read: docs/plans/w9-siren.md, docs/plans/reactions.md
- Files: Scripts/Battle.gd, Behaviours/, Skills/, Tests/
- Model: sonnet/high. Collides with: none

### Typing: the 27 untyped declarations, then Save.gd
- Source: docs/todo/systems.md (?239)
- Scope: type the 27 untyped declarations (Save.gd 12, Unit.gd 5, Battle.gd 4, Game.gd 3, Skill.gd 2, PartyPanel.gd 1) for safety, not speed; do not type shared dict params without a helper; suite and digest unchanged.
- Read: docs/plans/w9-typing.md
- Files: Scripts/Save.gd, Unit.gd, Battle.gd, Game.gd, Skill.gd, PartyPanel.gd
- Model: sonnet/medium. Collides with: the AI turn cost card (Unit.gd, Battle.gd)

### Show `shows_boon` and name Restless Dead on the unit
- Source: docs/todo/systems.md (?237, ?238)
- Scope: show `Read.boon` where a unit is read (the Bio or tile panel, as `shows_tags` is); the Bio and HUD name "Restless Dead ??" on a restless unit; allies noticing on a walk, not only a cast (`Undead.settle`).
- Read: docs/plans/w9-siren.md, docs/plans/w9-undead.md
- Files: Scripts/HUD.gd, Scripts/Undead.gd, Tests/undead_test.gd
- Model: sonnet/medium. Collides with: none

## Needs the user (not queued)
- Calls for review: ?198 (Cram's readings, tier 7, no swap on arrival), ?200 (Defense adds, Power is Energy share, where Abjuration and Smith are offered), ?201 (postpone and overcome stats), ?202 (the `strike` tag, friction's numbers), ?203 and ?204 (the disable trade; confirm the flags `no_density` and `scaling`, the viewer and the dials), ?192 (cc audit edges, the slam on a flee), ?193 (Chaser placement), ?194 (Skill Slot +1 gating), ?195 (the numbers), ?197 (Wake and Rake's tier, "cast mod"), ?206 (cc prices), ?208 (Student flex picker, Journeyman's tier and max rank; the "Brawn as Brains ??" skill is now the user's "Meathead", ?204), ?209 (do recoveries add Exhaustion uses?), ?211 (the synonyms), ?212 (Send Off's ward on a foe sent away), ?213 (`pack`, POINT, DELAY, the loot table), ?214 to ?217 (below; ?214 was reworked and closed in ?228).
- Wave 6 (?214 to ?217): which skill first carries a rarity or `slots`, a Mythic unplaceable before level 4, a wide skill cheaper to disable, runs across two granting skills (?215); recruiting and dismissing members and where recruits come from, what a death does to a roster member (?216); Skeleton's AI numbers (?217).
- Wave 7 (?218 to ?223): command readiness and the glow's size (?221); whether intel-only uses roll, tier 2 for "low" (?222). Wave 7 (?224, ?225): the passive-sign calls, the held rounding pieces, wrap rather than scale, merged "On <who>" lines (todo.md).
- Closed 2026-11-21 by the user's third batch (answers-2026-11-20c): ?216 (party size, solo at 1: built, ?226), ?218 (confirmed), ?220 and ?222 (names, ?227), ?223 (coloured against white icons, ?229), ?214 (reworked, ?228).
- Wave 8 (?226 to ?231, todo.md): whether a role's or species' own skills (Strike on a villager) should also be free (?228); what flight means beyond its movement cost (?228); the plain lend now free for Broadsword, Hobnail Boots, the Coyote kit (?228); the 9-slot bar at 16:9 (now ?241); the Deathlust log, plate lapse and `sure_crit` are built (?244).
- Wave 8 batch 3 (?232 to ?234): `AI.LOST` 0.35 against 0.5 (?233); `SUMMON_CAP` (gone: the Disturbed soft cap replaced it, ?238; a cap of 4 did +35% damage in `hostnear`, ?233); the w8-bar calls (a lend free by default, an optional one costs a slot, Hollow Bones' flight and defense numbers, ?228). Metrics: `docs/agents/metrics.csv`.
- Wave 9 (?235 to ?244): level 20 at 16:9, whole band names or whole bar names (?241); keep "Seaborn ??" and `betrayal ??`, and `shows_boon` as the home of the shows_* look family (?237); the soft cap leaves a low-int caster with no summons (?238; no Undead faction); a death-cleric tree for Grave Aura (?240); whether to expand typing (?239); `AI.BLOCKS` 3 (?244); the unit turn still over budget at M3 x 4 (?243).
- Retuning colours: ?125.
- Closed 2026-11-18: ?87, ?167, ?152, ?173 keep as built (the user: no balancing now); ?144, ?163, ?142 answered and built (?185 to ?188); ?131 and ?133 answered and built (?190, ?191).
- Open from Wave 2: which more skills are traits, and whether `insignia` and `badge` reach a trait (?185); tier placement of Backstab, Glancing Strike and Heavy Strike and the natural-20 reading (?186); Striking Intellect's placement and whether `attack_stat` reaches other attacks (?189); whether the 26 "flat rank" profiles should scale, the 38 hand-set prices, health costs (?190); the 22 skills left concrete and Gallantry's check difficulty (?191).
- The AI's "nowhere to switch" case (a unit with one toggle and no pool holding enough): ?130.
- Skills that force an unshape (a Dispel, a Hex of the beast), and whose tool it is: ?126, ?153.
- Winded's meaning: ?126. Burnout: burnt max, out-of-combat, other gains: ?121. A Life tree: ?121, ?122, ?124.
- `Unit.guard` on helpless: ?127. 0-AP actions while tapped: ?119. Merchant tree for Drone: ?119.
- Item rank-up, sources for the Habergeon family: ?118.
- Snapped forms (Gallantry, Final Act): ?140. A flank or rear rider skill: ?142.
- Gods and classes not designed: Divinity trees for Ramut, Urlo, Drael, Vetruvis, Survival skills, Paladin leadership Flex, burn tier cap (?122, ?81); Wizard and Mage real trees (?70); Martial and Specialist roots (?15); more Rogue, Bard, Luun, Elmon and Hogel skills; the cut-off Demon / Warlock / Dark Magic skill; Trade Skills, Grind (?2, ?11).
- Inspire, Sundering, Silent Strike and Sunder (?13); Charm (?14); Discipline's initiative half and the Pike unit (?80, ?82, ?120).
- Energize and Power Transfer (siphon-sorcerer plan: named, not defined); Commitment to the bit (a Cultist tree); clout earned in play and more tempers (?91, ?93); more resources (Rage, Hype, Clout, Gold) and shops; round and initiative lines using the arrow (ui.md:8); Astral Envoy tuning (?29).
