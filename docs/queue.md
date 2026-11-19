# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-18. Reconciled against the code after ?185 to ?191.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), Skeleton, Deathlust, the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing.

## Wave 4: the user's answers of 2026-11-19 (docs/agents/answers-2026-11-19.md; after Wave 3 lands)
A. **Strike-only rules and `friction`** (amends Wave 3 card 2): Heavy Strike, Glancing Strike and any skill with "strike" in its name apply only to `Strike` skills (the word strike in them); they still apply when a strike is chained into another skill, but only to the strike part (Jam crits, Chaser follows with Strike: Heavy Strike pools only Strike's rolls). Chaser can proc only rank times. Add utility tag `friction` (the user's word) as one generic rule: within one skill use, attack rolls after the first rank rolls get disadvantage plus a growing -1 per extra roll; apply it to Chaser and anything else that can loop. Opus/medium. Files: Battle attack roll, heavy_strike.gd, glancing strike, chaser.gd.
B. **Density**: ?185 to ?191 OK (Favour scaling; slot counts double under Density, Cram's penalties scale too). A skill is eligible for density +/- if it has a scaling part and a penalty part that can be boosted or tamped down. +density: harder scaling, much shorter range, much harder checks for the target to pass, easier ones for enemies to overcome; -density the reverse. A skill whose trade cannot be a fair Faustian bargain stays ineligible; redesign skills so as few as possible are. Opus/medium.
C. **Balance knobs** (after B): optional scaling coefficients on the tags Impact, Range and Modified (an obviously dominant or weak skill may get one without asking); a `β` tag (+/-, stronger or weaker scaling); a `d` (Cohen) tag (+/-, early ranks stronger or weaker, smoothing out with rank). β and d are visible only to a viewer or commander with `very high` int. Apply each to one obvious skill to test the feature; do not apply defensively. Sonnet/high.
D. **Aggressive tagging** (after B and C): tag and parameterize skills widely so they are easier to scale later; continue from ?191's 22 concrete skills and any missing tags. Sonnet/high.
E. **Consolidate todo.md** (after the wave's docs keeper): drafts in the scratchpad `condense/` (requirements.md with its facing line superseded by ?142's answer, todo.md, moves.md); refresh with ?185 onward and the answers; apply moves.md first, commit docs/requirements.md beside completed.md, replace todo.md with the condensed version (open questions only, about 80 lines). Sonnet/medium.

## Wave 3: the user's answers of 2026-11-18, second batch (docs/agents/answers-2026-11-18b.md; next question is 192)
Builders read the answers file for exact wording. The user's names go in with `--human` (no ??); `glance`, `curse`, `cc`, `equipment`, `summon`, Pillar and Burnout are the user's tags. Order: 1, 2, 3 and 10 first; 4 and 7 next; 5, 6 after 3 and 4; 8 after 7; 9 after 3 and 5; 11 is the docs keeper's first task.

1. **Intentional facing and control tags (?142, ?146)**: only a unit's own intentional actions turn it; revert ?188's forced-move turn (push, warp, teleport do not turn). Fear is the unit moving itself: it faces where it goes and spends movement AP for it. `shove` only on skills whose force moves a unit; tag `cc` on every skill and status that impairs a unit's ability to act (stun, fear, entrance, sleep, grapple, disables). Sonnet/high. Files: Unit facing, Battle.drive, Skills/*.tres tags, Statuses. Collides with: none.
2. **Per-use strike rules and Chaser**: Glancing Strike's +rank goes on the first rank attack rolls of each skill use; Heavy Strike works on one skill use (any skill), pooling every attack roll in that use including automatic repeats an effect triggers, a manual re-target being a new use. Chaser (Rogue t8, after Backstab): on a crit, use an active skill within rank actives of the rightmost active on the hotbar, at a rank no higher than Chaser's. Opus/medium. Files: Battle attack roll, Behaviours/heavy_strike.gd, glancing strike. Collides with: none.
3. **Traits by tooling, Skill Slot +1, ?165**: traits declared explicitly through the tools (`skill.py new --trait`, `unit.py` innate traits) and checked, not inferred. Skill Slot +1: learned, a trait (far right, no slot used) adding one hotbar slot, costing points the first time; on an item an equipment effect, disabled like others. Always-on passives show no on/off indication. Sonnet/high. Files: Util/skill.py, Util/unit.py, HUD hotbar, Unit.equipped. Collides with: 5, 6.
4. **Exhaustion retune, Burnout, Deathlust (?182)**: mild on a first use; bites from the 2nd cast of the same regular ability, the 3rd caster skill in a row, or the 4th different active in a turn. `Burnout` a child of exhaustion for every `int` skill: harsher penalties, harsher on `mana`. Reconcile with Burnout.gd (?121). Deathlust radius rank 1 self and adjacent, +1 a rank; relief curved, as a percentage. Opus/medium. Files: Exhaustion, Burnout.gd, deathlust behaviour. Collides with: 5.
5. **Cram, Pillar, caster bonus slots** (after 3 and 4): Cram (Mage, Specialist Student t7): Caster Skill Slot +1 + rank, a Pillar (rightmost slot; disabled if any other Pillar skill is). Converts rank regular slots into caster bonus slots, disabled if a non-caster skill is slotted there or a slotted Pillar is disabled. Burnout penalty times rank in those slots. Opus/medium.
6. **Student tree inside the Mage general tree** (after 3): Mage general = its own skills plus every skill of the Specialist Student tree (a Specialist flex tree any class can pick), by tree composition in data. Create Student if missing. Sonnet/high. Files: Trees/, Util/skill.py tree wiring.
7. **Enchanted items and lent prereqs (?143)**: enchanting an item enchants the skills it lends (+1 rank unless a lent skill has its own enchant effect). An item's armor becomes an `equipment` skill it lends (generally +armor). Lent skills count as prerequisites; losing one disables its dependents. Sonnet/high. Files: Item.gd, enchant, prerequisites. Collides with: 8, 9.
8. **Power Armor, Scrap Plating** (after 7): Power Armor (martial protection prowess, caster abjuration, astral capstone): extra armor slot, on while power is at least 100% - rank x 10%; blows it blocks hit power for damage / rank. Scrap Plating (martial protection prowess, specialist smith t5): an armor slot giving at most rank Defense; armor AP penalties stack additively. Stub missing trees with the tools. Sonnet/high.
9. **Coyote set** (after 3, 5): Coyote Charm (epic trinket) and Coyote Scepter (epic weapon) with the Curse of the Coyote `curse`; generic "disable" and "instant death" hooks, Borrowed Time when enchanted. Opus/medium. Use `Util/item.py`.
10. **Skeleton AP, Wake and Rake (?181)**: summoned units spend all but up to rank + cast mod AP on arrival; Wake and Rake (Caster general) adds rank to the AP `summon` units keep; tag Skeleton `summon`. Sonnet/medium.
11. **Glossary (?180)**: Lancin and Lancela get their own headings in docs/g-glossary.md; light formatting only. Sonnet/low (docs keeper).

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

## Needs the user (not queued)
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
