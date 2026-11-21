# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-21. Reconciled against the code after ?192 to ?231 (the next question is 232).

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: Wave 8 cards 1 to 4 (party size without the floor, unique names and ?? on tags, free lends and the band, coloured icons) and the follow-ups w8-layout and w8-ai1 built (a wider multi-slot slot, a column break off spans, Deathlust's float and pricing, plate tolls, crit loops in the forecast, a defensive cc read), Wave 7 cards A to H (passive signage, widescreen and verbiage, facing and level in the glow, studies UX, preparation uses, the Bard skills, utumno art), Wave 6 (equipment links, multi-slot skills, the Party, the audit), Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), the AI casts Skeleton, Interject's and Snapping Turtle's bonus, the near hunt sim, Deathlust (its AI unwear), the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Running in another batch 2026-11-21 (not built, do not launch; cards stay below until it merges): w8-fc (Forecast First Chair, rounding style), w8-misc (prep tests, a `pack` unit, the Skeleton sim, the `AI.LOST` retune, utumno second pass), w8-outfits (party members' outfits).
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

### A unit carrying a `pack`
- Source: docs/todo/classes.md (?213)
- Scope: give one or two units an `@export Unit.pack` (armor carried) through `unit.py` and loot through `item.py`, so `AI._dress()` has something to equip; check it in a battle.
- Read: docs/plans/w5-ai2.md
- Files: Scenes/, Loot/, Tests/plating_test.gd
- Model: sonnet/medium
- Collides with: none

## Wave 6 follow-ups: from ?214 to ?217 (all need nothing from the user)

### Retune `AI.LOST` with the near hunt sim
- Source: docs/todo/systems.md (?178, ?217)
- Scope: run `Tests/sims/hunt_10v10.gd` `near` through `sweep.sh SIM=` over `AI.LOST` (0.5 today) and set it from the numbers; say what the sweep showed.
- Read: docs/plans/w6-audit.md, docs/plans/ai-findings.md
- Files: Scripts/AI.gd, Tests/sims/hunt_10v10.gd
- Model: sonnet/medium
- Collides with: the AI cards (AI.gd)

### A sim where Skeleton reaches the foe
- Source: docs/todo/systems.md (?217)
- Scope: the `host` scenario in `ai_sim.gd` raises bodies (0 to 8) but the skeletons never reach the soaker 9 tiles off in 10 rounds, so damage reads 0.00 both ways. Add a variant with the foe within walking reach and compare damage before and after the AI's `_summon()` (`BODY`, `SUMMON_SEEN`, `SUMMON_CAP`).
- Read: docs/plans/w6-audit.md
- Files: Tests/sims/ai_sim.gd
- Model: sonnet/medium
- Collides with: the AI cards (AI.gd only if the constants move)

### Party members' outfits and the stash
- Source: docs/todo/systems.md (?216)
- Scope: the stash screen is the leader's; let the player open any roster member's outfit (and bar) between battles, saved through the roster entry. No new rules, only the screen reading `Game.roster`.
- Read: docs/plans/w6-party.md
- Files: Scripts/Entry.gd, Scripts/PartyPanel.gd, the stash scene, Tests/save_test.gd
- Model: sonnet/high
- Collides with: none

## Wave 7 follow-ups: from ?218 to ?225 (all need nothing from the user)

### Forecast First Chair and show Cadence
- Source: docs/todo/systems.md (?220)
- Scope: the HUD's and AI's damage previews read the unopened use, so they ignore First Chair's +rank impact; forecast it for the first unit to act. Show Cadence's rank on the unit beyond the status line.
- Read: docs/plans/w7-bard.md
- Files: Scripts/Battle.gd, Scripts/AI.gd, Scripts/HUD.gd, Tests/symphony_bard_test.gd
- Model: sonnet/high
- Collides with: the AI cards (AI.gd), D and G (HUD)

### Preparation tests the plan left out
- Source: docs/todo/systems.md (?222)
- Scope: cover what the plan lists as untested (a trickster's `their_tags = []` on `doubt()`, an Inquisition's advantage on `doubt()`); no rules change.
- Read: docs/plans/w7-prep.md
- Files: Tests/prep_test.gd
- Model: sonnet/medium
- Collides with: none

### Utumno art, second pass
- Source: docs/todo/systems.md (?223)
- Scope: screenshot the skills screen with the coloured icons under each state tint and report whether they read; map more of the unused sources (items, statuses, the `Shade.png` and `Elmit.png` slots only if the user confirms they are placeholders) by the plan's method, leaving sources untouched; `icon.py check` passes.
- Read: docs/plans/w7-art.md
- Files: Icons/, Items/ icons, docs/plans/w7-art.md
- Model: sonnet/medium
- Collides with: G (verbiage, only if it touches icons)

### Rounding style on the other heals and the log
- Source: docs/todo/systems.md (?224)
- Scope: italic (rounded down) and bold (rounded up) for heals other than regen (thread `rounded` through the heal paths to the HUD), for the log's amounts (RichTextLabel italic/bold faces), and for previews only if one rounding can be named; keep the cost nil (re-run `Tests/sims/busy_fight.gd -- 15 20 n=3`).
- Read: docs/plans/w7-passives.md
- Files: Scripts/Battle.gd, Scripts/Unit.gd, Scripts/HUD.gd, Scripts/Overlay.gd, Tests/passive_signs_test.gd
- Model: sonnet/high
- Collides with: the AI cards (AI.gd), the forecast card (HUD)

## Needs the user (not queued)
- Calls for review: ?198 (Cram's readings, tier 7, no swap on arrival), ?200 (Defense adds, Power is Energy share, where Abjuration and Smith are offered), ?201 (postpone and overcome stats), ?202 (the `strike` tag, friction's numbers), ?203 and ?204 (the disable trade; confirm the flags `no_density` and `scaling`, the viewer and the dials), ?192 (cc audit edges, the slam on a flee), ?193 (Chaser placement), ?194 (Skill Slot +1 gating), ?195 (the numbers), ?197 (Wake and Rake's tier, "cast mod"), ?206 (cc prices), ?208 (Student flex picker, Journeyman's tier and max rank; the "Brawn as Brains ??" skill is now the user's "Meathead", ?204), ?209 (do recoveries add Exhaustion uses?), ?211 (the synonyms), ?212 (Send Off's ward on a foe sent away), ?213 (`pack`, POINT, DELAY, the loot table), ?214 to ?217 (below; ?214 was reworked and closed in ?228).
- Wave 6 (?214 to ?217): which skill first carries a rarity or `slots`, a Mythic unplaceable before level 4, a wide skill cheaper to disable, runs across two granting skills (?215); recruiting and dismissing members and where recruits come from, what a death does to a roster member (?216); Skeleton's AI numbers (?217).
- Wave 7 (?218 to ?223): command readiness and the glow's size (?221); whether intel-only uses roll, tier 2 for "low" (?222). Wave 7 (?224, ?225): the passive-sign calls, the held rounding pieces, wrap rather than scale, merged "On <who>" lines (todo.md).
- Closed 2026-11-21 by the user's third batch (answers-2026-11-20c): ?216 (party size, solo at 1: built, ?226), ?218 (confirmed), ?220 and ?222 (names, ?227), ?223 (coloured against white icons, ?229), ?214 (reworked, ?228).
- Wave 8 (?226 to ?231, todo.md): whether the Mage's stub "Accord ??" is the right rename (?227); whether a role's or species' own skills (Strike on a villager) should also be free (?228); what flight means beyond its movement cost (?228); the plain lend now free for Broadsword, Hobnail Boots, the Coyote kit (?228); the 9-slot bar with three spans still cutting band names at 16:9 (?230); no Deathlust log line, plate slot lapsing as Power runs down, `sure_crit` unpriced (?231).
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
