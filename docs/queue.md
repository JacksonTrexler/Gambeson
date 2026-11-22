# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-21. Reconciled against the code after ?192 to ?234 (the next question is 235).

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: the user's third batch (answers-2026-11-20c) is all built (?226 to ?231 and the follow-ups: First Chair forecast, prep tests, a `pack` unit, the Skeleton sim, the `AI.LOST` retune, rounding on heals and the log, party outfits, ?232 to ?234), Wave 8 cards 1 to 4 (party size without the floor, unique names and ?? on tags, free lends and the band, coloured icons) and the follow-ups w8-layout and w8-ai1 built (a wider multi-slot slot, a column break off spans, Deathlust's float and pricing, plate tolls, crit loops in the forecast, a defensive cc read), Wave 7 cards A to H (passive signage, widescreen and verbiage, facing and level in the glow, studies UX, preparation uses, the Bard skills, utumno art), Wave 6 (equipment links, multi-slot skills, the Party, the audit), Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), the AI casts Skeleton, Interject's and Snapping Turtle's bonus, the near hunt sim, Deathlust (its AI unwear), the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing in flight.
Built 2026-11-21 (?232 to ?234): w8-fc, w8-misc, w8-outfits.
Built 2026-11-21 (?226 to ?231): Wave 8 cards 1 to 4 and the follow-ups of w8-layout and w8-ai1.
Built 2026-11-20 (?218 to ?225): Wave 7 cards A to H. Built 2026-11-20 (?214 to ?217): Wave 6 (equipment links `innate` / `optional`, multi-slot skills, the persistent roster and Party, the queue audit). Built 2026-11-19 (?198 to ?213): Wave 3 cards 5, 6, 8, 9, Wave 4 cards A to D and Wave 5 (cc and shove, save lapses, museum sim, Chaser and Heavy Strike, density, plating, friction, Coyote, the Floater card, Student, Journeyman, difficulty words).

## Wave 4: the user's answers of 2026-11-19 (docs/agents/answers-2026-11-19.md; cards A to D built, ?202 to ?205)

## Wave 3: the user's answers of 2026-11-18, second batch (docs/agents/answers-2026-11-18b.md)
All eleven cards are built (?192 to ?201). Nothing left here.

## Wave 2 follow-ups (the user's answers of 2026-11-18 are all built, ?185 to ?191; the rules stand: no balancing now, tune by check difficulty, price effects that stop actions high)

## Wave 1: follow-ups from ?178 to ?183 (all need nothing from the user)

### AI turn cost: a per-act read cache and `_line_up`'s foresee
- Source: docs/todo/systems.md (?183)
- Scope: `r-aiperf` halved it (?184) but a unit turn is still over budget (100 ms a unit turn, 1000 ms an `end_turn` at M3 x 4; `Tests/sims/busy_fight.gd`). A per-act cache of a unit's reads (invalidated by any state change), `suspicious()` reusing the act's reads and skipping units beyond every viewer's range, `_line_up` foreseeing fewer tiles, a Brood-free fast path in `Unit.stat`.
- Read: docs/plans/r-sims.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/Unit.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: the AI cards below (AI.gd: the `AI.LOST` retune, the Skeleton sim)

## Wave 5: follow-ups from ?206 to ?213 (all need nothing from the user)


## Wave 6 follow-ups: from ?214 to ?217 (all need nothing from the user)




## Wave 7 follow-ups: from ?218 to ?225 (all need nothing from the user)





## Wave 8 note (2026-11-21)
The user's third batch (docs/agents/answers-2026-11-20c.md) is all built (?226 to ?231 and the follow-ups, ?232 to ?234). The AI turn cost card above stays; the wider HUD slot is built. Follow-ups below need no user input (the user's calls are listed under "Needs the user").

## Wave 8 follow-ups: from ?230 to ?234 (all need nothing from the user)

### Utumno art, third pass
- Source: docs/todo/systems.md (?233)
- Scope: locked coloured icons are nearly illegible (0.4 at 0.55 opacity): try a lighter dim such as 0.55 and screenshot the skills screen; statuses stay unmapped (needs the user).
- Read: docs/plans/w8-misc.md, docs/plans/w8-icons.md
- Files: Scripts/Skill.gd (`icon_ink`), Tests/skills_test.gd
- Model: sonnet/medium
- Collides with: none

### Deathlust's log line and the AI's plate slot
- Source: docs/todo/systems.md (?231, ?232)
- Scope: a log line when Deathlust relieves exhaustion (use `Overlay.face()` styling); the AI's plate slot switching off as Power runs down in its reckoning; price `sure_crit` doubling in the crit-loop forecast.
- Read: docs/plans/w8-ai1.md, docs/plans/w8-fc.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/HUD.gd, Tests/deathlust_test.gd, Tests/plating_test.gd
- Model: sonnet/high
- Collides with: the AI cards (AI.gd), the turn cost card

### The band's row reservation test and the 9-slot band at 16:9
- Source: docs/todo/systems.md (?228, ?230)
- Scope: a HUD test for the band's row reservation; fix the 9-slot bar with three spans still wrapping band names at 16:9 (screenshot `S/shot_w8-bar/`).
- Read: docs/plans/w8-layout.md, docs/plans/w8-bar.md
- Files: Scripts/HUD.gd, Scripts/SlotColumns.gd, Tests/slot_columns_test.gd
- Model: sonnet/high
- Collides with: none

### Party button on a solo roster; share `Battle.from_role`; a pack as loot
- Source: docs/todo/systems.md (?233, ?234)
- Scope: show the Party button on a solo roster so the stash is reachable between battles; make `Battle.from_role()` static and call it from `PartyPanel.outfit()`; a defeated unit's `pack` dropping as loot (a new rule: confirm the shape in the plan first, keep it a tag-driven hook).
- Read: docs/plans/w8-outfits.md, docs/plans/w8-misc.md
- Files: Scripts/Entry.gd, Scripts/PartyPanel.gd, Scripts/Battle.gd, Tests/save_test.gd, Tests/plating_test.gd
- Model: sonnet/high
- Collides with: none

## Wave 9: the user's answers of 2026-11-22 (docs/agents/answers-2026-11-22*.md; first question is 235)
Run 2-3 at a time, Sonnet unless noted. One card per builder; compact briefs; each keeps `docs/plans/<branch>.md`. Land on `origin/main` (SKILL.md).

### 1. Docs keeper: the behaviour rule; Accord confirmed (sonnet/low)
- Scope: add to docs/requirements.md the user's rule of thumb: a unit's behaviour should be inferable from the unit itself (prideful, pitiful, pragmatic, capable: plain targeting, going for downs, squaring up, hedging); player units and those they command have behaviour too (autobattle, or control stripped by cognitive disruption). Accord is confirmed: drop its ?? (the Mage's old Harmony stub; every place the name appears) and close ?227's question.
- Collides with: none

### 2. Disturbed and Disturbance
- Scope: Warlock mid tier skill Disturbance: one unit in rank range; check very difficult against a non-leader, easy against a leader. Failing: Disturbed for rank rounds: cannot be commanded or give commands, acts only on its own behaviour (AI-driven even on the player's side). Disturbed is a reusable status tagged `cc`.
- Files: Skills/, Behaviours/, Scripts/AI.gd, Scripts/Battle.gd, Tests/
- Model: sonnet/high. Collides with: 3, 7 (AI.gd)

### 3. Undead and Restless Dead (after 2)
- Scope: tag `undead` on skeletons (and zombies if one exists or is trivial). `undead` + Disturbed uses the behaviour "Restless Dead ??": attacks the nearest visible non-undead, allies preferred on ties. Allies who notice (medium-easy persona check) treat it as an enemy; brainwashed or hostile allies move after the noticing ones. Removing Disturbed from an undead unit eliminates it. A separate Undead faction is allowed if healthier: record the call. Necro summon soft cap: rank + skill stat mod; summons over the cap gain Disturbed as a trait, furthest from the summoner first, until under the cap (replaces the `SUMMON_CAP` idea, ?233).
- Model: opus/medium. Collides with: 2, 4, 7

### 4. Grave Aura (after 3)
- Scope: tier 3 on Warlock necromancy and death-cleric (place on the trees that exist, record the call). Gives the holder persona: undead; allied undead make no checks against persona.
- Model: sonnet/medium. Collides with: 3

### 5. Icon states
- Scope: disabled icons 25% saturation, 70% brightness; untoggled 15% saturation, 85% brightness. One hook so each disabling effect shows why a skill is disabled, plus one example. A non-colour cue for colourblind players. Covers locked coloured icons (the Utumno third pass above).
- Files: Scripts/Skill.gd (`icon_ink`), Scripts/HUD.gd, Scripts/IconButton.gd if present, Tests/
- Model: sonnet/medium. Collides with: none

### 6. Siren trait passive
- Scope: from commit 4fe2c05 (`git show 4fe2c05`) make one `trait` passive on the current Siren: Oceanic (+2 str, dex, con; cheaper movement in water; needs a generic terrain condition on effects), Rake (double damage against trusting targets), the `aquatic` tag, movement 2, `shows_boon`. Rebuild Detective, Ambush, Opportunist if they fit the current systems, else record a question.
- Model: sonnet/high. Collides with: none

### 7. Typing pilot
- Scope: GDScript untyped-declaration warnings on, as warnings. Type the hot paths in AI.gd and Battle's planning code. Measure AI turn cost before and after (timing driver or `Tests/sims/busy_fight.gd`). If it speeds things up or catches real bugs, expand file by file with spare capacity.
- Model: sonnet/medium. Collides with: 2, 3 (AI.gd): run after or rebase

### 8. Remaining follow-ups
- The cards above under "Wave 8 follow-ups" and "AI turn cost" that need no user input, when slots are free.

## Needs the user (not queued)
- Calls for review: ?198 (Cram's readings, tier 7, no swap on arrival), ?200 (Defense adds, Power is Energy share, where Abjuration and Smith are offered), ?201 (postpone and overcome stats), ?202 (the `strike` tag, friction's numbers), ?203 and ?204 (the disable trade; confirm the flags `no_density` and `scaling`, the viewer and the dials), ?192 (cc audit edges, the slam on a flee), ?193 (Chaser placement), ?194 (Skill Slot +1 gating), ?195 (the numbers), ?197 (Wake and Rake's tier, "cast mod"), ?206 (cc prices), ?208 (Student flex picker, Journeyman's tier and max rank; the "Brawn as Brains ??" skill is now the user's "Meathead", ?204), ?209 (do recoveries add Exhaustion uses?), ?211 (the synonyms), ?212 (Send Off's ward on a foe sent away), ?213 (`pack`, POINT, DELAY, the loot table), ?214 to ?217 (below; ?214 was reworked and closed in ?228).
- Wave 6 (?214 to ?217): which skill first carries a rarity or `slots`, a Mythic unplaceable before level 4, a wide skill cheaper to disable, runs across two granting skills (?215); recruiting and dismissing members and where recruits come from, what a death does to a roster member (?216); Skeleton's AI numbers (?217).
- Wave 7 (?218 to ?223): command readiness and the glow's size (?221); whether intel-only uses roll, tier 2 for "low" (?222). Wave 7 (?224, ?225): the passive-sign calls, the held rounding pieces, wrap rather than scale, merged "On <who>" lines (todo.md).
- Closed 2026-11-21 by the user's third batch (answers-2026-11-20c): ?216 (party size, solo at 1: built, ?226), ?218 (confirmed), ?220 and ?222 (names, ?227), ?223 (coloured against white icons, ?229), ?214 (reworked, ?228).
- Wave 8 (?226 to ?231, todo.md): whether a role's or species' own skills (Strike on a villager) should also be free (?228); what flight means beyond its movement cost (?228); the plain lend now free for Broadsword, Hobnail Boots, the Coyote kit (?228); the 9-slot bar with three spans still cutting band names at 16:9 (?230); no Deathlust log line, plate slot lapsing as Power runs down, `sure_crit` unpriced (?231).
- Wave 8 batch 3 (?232 to ?234): `AI.LOST` 0.35 against 0.5 (?233); `SUMMON_CAP` 12 or lower (replaced by the Disturbed soft cap, Wave 9 card 3; a cap of 4 did +35% damage in `hostnear`, ?233); the w8-bar calls (a lend free by default, an optional one costs a slot, Hollow Bones' flight and defense numbers, ?228). Metrics: `docs/agents/metrics.csv`.
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
