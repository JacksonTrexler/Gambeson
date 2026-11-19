# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-19. Reconciled against the code after ?192 to ?197 (the next question is 198).

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), Skeleton, Deathlust, the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
`w3-cram` (Wave 3 card 5), `w3-student` (card 6), `w3-armor` (card 8). Card 9 (the Coyote set) follows once 5 lands.

## Wave 4: the user's answers of 2026-11-19 (docs/agents/answers-2026-11-19.md; after Wave 3 lands)
A. **Strike-only rules and `friction`** (amends Wave 3 card 2): Heavy Strike, Glancing Strike and any skill with "strike" in its name apply only to `Strike` skills (the word strike in them); they still apply when a strike is chained into another skill, but only to the strike part (Jam crits, Chaser follows with Strike: Heavy Strike pools only Strike's rolls). Chaser can proc only rank times. Add utility tag `friction` (the user's word) as one generic rule: within one skill use, attack rolls after the first rank rolls get disadvantage plus a growing -1 per extra roll; apply it to Chaser and anything else that can loop. Opus/medium. Files: Battle attack roll, heavy_strike.gd, glancing strike, chaser.gd.
B. **Density**: ?185 to ?191 OK (Favour scaling; slot counts double under Density, Cram's penalties scale too). A skill is eligible for density +/- if it has a scaling part and a penalty part that can be boosted or tamped down. +density: harder scaling, much shorter range, much harder checks for the target to pass, easier ones for enemies to overcome; -density the reverse. A skill whose trade cannot be a fair Faustian bargain stays ineligible; redesign skills so as few as possible are. Opus/medium.
C. **Balance knobs** (after B): optional scaling coefficients on the tags Impact, Range and Modified (an obviously dominant or weak skill may get one without asking); a `β` tag (+/-, stronger or weaker scaling); a `d` (Cohen) tag (+/-, early ranks stronger or weaker, smoothing out with rank). β and d are visible only to a viewer or commander with `very high` int. Apply each to one obvious skill to test the feature; do not apply defensively. Sonnet/high.
D. **Aggressive tagging** (after B and C): tag and parameterize skills widely so they are easier to scale later; continue from ?191's 22 concrete skills and any missing tags. Sonnet/high.
E. **Consolidate todo.md** (after the wave's docs keeper): drafts in the scratchpad `condense/` (requirements.md with its facing line superseded by ?142's answer, todo.md, moves.md); refresh with ?185 onward and the answers; apply moves.md first, commit docs/requirements.md beside completed.md, replace todo.md with the condensed version (open questions only, about 80 lines). Sonnet/medium.

## Wave 3: the user's answers of 2026-11-18, second batch (docs/agents/answers-2026-11-18b.md; the remaining cards)
Builders read the answers file for exact wording. The user's names go in with `--human` (no ??); `glance`, `curse`, `cc`, `equipment`, `summon`, Pillar and Burnout are the user's tags. Built 2026-11-19 (?192 to ?197): cards 1, 2, 3, 4, 7, 10 and 11, so numbers 5, 6, 8 and 9 remain. 5, 6, 8 run now (builders above); 9 after 5.

5. **Cram, Pillar, caster bonus slots** (after 3 and 4): Cram (Mage, Specialist Student t7): Caster Skill Slot +1 + rank, a Pillar (rightmost slot; disabled if any other Pillar skill is). Converts rank regular slots into caster bonus slots, disabled if a non-caster skill is slotted there or a slotted Pillar is disabled. Burnout penalty times rank in those slots. Opus/medium.
6. **Student tree inside the Mage general tree** (after 3): Mage general = its own skills plus every skill of the Specialist Student tree (a Specialist flex tree any class can pick), by tree composition in data. Create Student if missing. Sonnet/high. Files: Trees/, Util/skill.py tree wiring.
8. **Power Armor, Scrap Plating** (after 7): Power Armor (martial protection prowess, caster abjuration, astral capstone): extra armor slot, on while power is at least 100% - rank x 10%; blows it blocks hit power for damage / rank. Scrap Plating (martial protection prowess, specialist smith t5): an armor slot giving at most rank Defense; armor AP penalties stack additively. Stub missing trees with the tools. Sonnet/high.
9. **Coyote set** (after 3, 5): Coyote Charm (epic trinket) and Coyote Scepter (epic weapon) with the Curse of the Coyote `curse`; generic "disable" and "instant death" hooks, Borrowed Time when enchanted. Opus/medium. Use `Util/item.py`.

## Wave 2 follow-ups (the user's answers of 2026-11-18 are all built, ?185 to ?191; the rules stand: no balancing now, tune by check difficulty, price effects that stop actions high)

### Interject's and Snapping Turtle's checks take the reaction bonus
- Source: docs/todo/systems.md (?191)
- Scope: `Reaction.contest()` / `odds()` take an optional `bonus` (Gallantry uses it); wire Interject's dex check and Snapping Turtle's check to it, each reading its rank through the holder's modifiers with rank I exactly as now, so they scale like Gallantry. Declare the channel (`skill.py terms`), keep the difficulty a named constant, add a row to `param_test`'s table.
- Read: docs/plans/w2-param.md
- Files: Behaviours/interject.gd, Behaviours/snapping_turtle.gd, Tests/param_test.gd
- Model: sonnet/medium
- Collides with: none

## Wave 1: follow-ups from ?178 to ?183 (all need nothing from the user)

### AI turn cost: a per-act read cache and `_line_up`'s foresee
- Source: docs/todo/systems.md (?183)
- Scope: `r-aiperf` halved it (?184) but a unit turn is still over budget (100 ms a unit turn, 1000 ms an `end_turn` at M3 x 4; `Tests/sims/busy_fight.gd`). A per-act cache of a unit's reads (invalidated by any state change), `suspicious()` reusing the act's reads and skipping units beyond every viewer's range, `_line_up` foreseeing fewer tiles, a Brood-free fast path in `Unit.stat`.
- Read: docs/plans/r-sims.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/Unit.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: the AI cards below (AI.gd)

### The AI casts Skeleton
- Source: docs/todo/classes.md (?181)
- Scope: a tile-summon plan in `AI.gd`: when a side has room and a foe is in reach, cast a summon skill (`summon_per_rank`) at a tile near itself; price it by the bodies it adds. Sim before and after.
- Read: docs/plans/r-skeleton.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd, Tests/summon_test.gd
- Model: sonnet/high
- Collides with: the AI-cost card (AI.gd), the next card

### Deathlust AI awareness
- Source: docs/todo/systems.md (?182)
- Scope: the AI weighs a kill's exhaustion discount (the kill skill gains no use; a death in reach eases every count) and Deathlust's float or log line on the HUD. Use the `wearing` and `neutralized` hooks, not a Deathlust special case.
- Read: docs/plans/r-deathlust.md
- Files: Scripts/AI.gd, Scripts/HUD.gd, Tests/deathlust_test.gd
- Model: sonnet/medium
- Collides with: `r-aiperf` (AI.gd), the card above

### Hunt sim: hiders in range from round 1
- Source: docs/todo/systems.md (?178, ?183)
- Scope: a variant of `hunt_10v10.gd` with hiders placed within the Rangers' reach, to measure the search apart from the ten-round walk; tune `AI.LOST` with it (`sweep.sh`).
- Read: docs/plans/r-sims.md, docs/plans/ai-findings.md
- Files: Tests/sims/hunt_10v10.gd, Tests/sims/ai_sim.gd
- Model: sonnet/medium
- Collides with: none

### Edge-pan sideways and drag
- Source: docs/todo/systems.md (?179, ?175)
- Scope: the HUD's side panels cover the left and right edges, so edge-pan only works top and bottom; find a way to pan sideways (a thin margin past the panels, or a middle-drag) without taking the mouse buttons others use.
- Read: docs/plans/meadows-tails.md
- Files: Scripts/BattleCamera.gd, Tests/meadows_test.gd
- Model: sonnet/medium
- Collides with: none

## Wave 5: follow-ups from ?192 to ?197 (all need nothing from the user)

### Floater: `.claude/skills` mention the new tool verbs
- Source: docs/todo/systems.md (?192, ?194)
- Scope: `.claude/` is out of bounds for builders and the docs keeper. `new-skill` and `new-unit` should mention `skill.py new --trait`, `skill.py trait`, `unit.py trait` and `unit.py new --trait`; `new-mechanic` should mention `mechanic.py carry`; `new-item` `item.py lend` and `skill.py new --lent`. Also lower `FLAG_CEILING` in `Util/skill.py` if a merge removed a field (`python3 Util/skill.py check` says).
- Model: sonnet/low (floater)
- Collides with: none

### Cram reads the new seams
- Source: docs/todo/systems.md (?194, ?195)
- Scope: `w3-cram` should read `Unit.bar_size()` / `_grants()` for caster bonus slots, a slot kind for the "slightly darker" untyped slot (docs/todo/ui.md), and `Burnout.penalty()` for the rank multiplier. Not a new card; a note for the card 5 brief.
- Collides with: card 5

### The AI weighs `cc` and `shove`
- Source: docs/todo/systems.md (?192)
- Scope: the AI reads `Unit.afflicted()` to price what an enemy cc does to a unit's turn, and weighs a `shove` slam; use the tags, not skill names. Sim before and after.
- Read: docs/plans/w3-facing.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: the AI cards in Wave 1 (AI.gd)

### Save `Unit.leaned` and `waived`
- Source: docs/todo/systems.md (?196)
- Scope: the save carries `leaned` (and `waived`) so a loaded unit that learned on a lent skill still lapses when it loses it; a save/load round-trip test.
- Read: docs/plans/w3-lent.md
- Files: Scripts/Unit.gd, the save code, Tests/lent_test.gd
- Model: sonnet/medium
- Collides with: none

### Exhaustion retune: museum sim check
- Source: docs/todo/systems.md (?195)
- Scope: run the museum sims before and after the retune (`Tests/sims/ai_sim.gd`, `sweep.sh`) and report whether Hex still outscores Strike; no tuning (the user said no balancing now), numbers only.
- Read: docs/plans/w3-exhaust.md
- Model: sonnet/medium
- Collides with: none

### The AI casts Chaser's interrupt and Heavy Strike's pool well
- Source: docs/todo/classes.md (?193)
- Scope: after Wave 4 card A lands, check the AI picks within the rank reach and the hit forecast counts a pooled blow; tests in `chaser_test` and `heavy_strike_test`.
- Collides with: Wave 4 card A

## Needs the user (not queued)
- Wave 3 calls for review: ?192 (cc audit edges, the slam on a flee), ?193 (Chaser placement), ?194 (Skill Slot +1 gating), ?195 (the numbers), ?196 (Armor ?? in the trait strip), ?197 (Wake and Rake's tier, "cast mod").
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
