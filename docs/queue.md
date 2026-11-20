# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-19. Reconciled against the code after ?192 to ?213 (the next question is 214).

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: Wave 2 (traits, facing, glance, Striking Features and Intellect, cost profiles, parameterized skills), traits, facing by move or aim, glance and its skills, test stubs Option A, the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), Skeleton, Deathlust, the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing. Built 2026-11-19 (?198 to ?213): Wave 3 cards 5, 6, 8, 9, Wave 4 cards A to D and Wave 5 (cc and shove, save lapses, museum sim, Chaser and Heavy Strike, density, plating, friction, Coyote, the Floater card, Student, Journeyman, difficulty words).

## Wave 7: the user's answers of 2026-11-20, second batch (docs/agents/answers-2026-11-20b.md; run after Wave 6 lands)
Builders read the verbatim file for exact wording. Names the user gave go in with `--human`.

### A. Facing, shown subtly
- Scope: remove the facing chevron or arrow. Show facing only to a viewer with high wis (the `Difficulty.WORDS` scale), as glow subtly stronger on the facing side.
- Files: the unit glow shader, HUD. Model: sonnet/high. Collides with: B (same shader; B after A)

### B. Glow by level
- Scope: a unit's glow flashes to 2x intensity briefly on level up; a higher-level unit has a subtly larger glow and a lower-level one a subtly smaller one, against the viewer's side (record the reference chosen). Only while the glow is not showing targeting.
- Model: sonnet/medium, after A

### C. Studies UX
- Scope: "No studies left" (only on click); a magnifying-glass cursor icon on a studyable tile or unit, greyed when none left; the preparation banner a top box, title "Preparing", then "Study: X" in smaller text (Surveys, Evaluates and Inquisitions show the same way).
- Files: HUD. Model: sonnet/high. Collides with: D (HUD), E after C

### D. Passive signage (only the parts with no noticeable performance cost; hold the rest and say so)
- Scope: muted styling on passives' name and number, unmuting or flashing on activation (frequent ones just unmute); one generic signal (Behaviour to Battle to HUD) so a passive acting on a unit shows a brief floater `<icon> Name amount` above a non-viewed unit, in the tag colour; Luck shows "Luck +1" with a small sparkle only when it enabled an action; impact amounts italic when rounded down, bold when rounded up; spellbook traits and armor passives muted. Profile a busy fight before and after.
- Model: opus/medium. Collides with: C (HUD)

### E. Surveyor, Evaluator, Inquisitor (Specialist general, low tier)
- Scope: also offered to Fighter and Druid (Surveyor), Fighter (Evaluator), Cleric and Paladin (Inquisitor). Rank uses during preparation (Surveys: tile intel only, with advantage; Evaluates: unit intel only, no suspicion; Inquisitions: suspicion only, extra investigation checks with advantage, no intel), and +rank on the matching checks in battle. One generic "preparation uses" mechanic that Study shares.
- Model: sonnet/high, after C

### F. Bard skills
- Scope: String Theory (mid: the higher of int or cha for performance checks, via the `attack_stat` / `check` hook); Conductor (high: if the unit rested last turn, +rank to command limits and range); Symphony (units in command range get +1 on checks for each check a commanded unit passes, up to rank; the first unit to act is "First Chair" with +rank impact on its first skill); add `impact` to the Glossary as the user defined it.
- Model: sonnet/high

### G. Widescreen and verbiage
- Scope: fix the hotbar at 16:9 and wider (screenshots); standardize and cut skill description wording (no multiple "On a foe" lines; one phrasing per outcome, shared across describe() helpers).
- Files: HUD hotbar layout, describe helpers. Model: sonnet/high

### H. Placeholder art from /Users/jtrex/assets/utumno
- Scope: about 90 PNGs (skip .aseprite; a siren is there). Map them onto skill icons, unit sprites and status icons where a name or subject fits; copy each used file to its fixed path and leave the source untouched; record the mapping in docs; `icon.py check` passes.
- Model: sonnet/medium

## Wave 6: the user's answers of 2026-11-20 (docs/agents/answers-2026-11-20.md; running)

### 1. Meathead (?204)
- Scope: rename "Brawn as Brains ??" to "Meathead" (the user's name: no `??`, `ai = true` dropped). Done in the step-0 commit; the docs keeper fixes the mentions in todo.md and docs/todo/classes.md.
- Model: sonnet/low (docs keeper)

### 2. Equipment-skill links: `optional` and `innate` (?196)
- Source: the user, 2026-11-20: "those tags are associated with an equipment's association to a skill rather than the skill itself (Igna may be provided for no equip cost by a robe, and with a slot equip cost on a medium armor set)".
- Scope: `optional` (the wearer may put the lent skill on the hotbar) and `innate` (the lent skill needs no slot) are properties of an item's link to a skill, not of the skill. Armor's own `equipment` skill is innate. Keep `skill.py check`'s "never on the hotbar" rule light, read through the link.
- Files: Scripts/Item.gd, Util/item.py, Unit.equipped, the HUD hotbar
- Model: sonnet/high
- Collides with: card 3 (hotbar code; card 3 runs after)

### 3. Multi-slot skills
- Scope: a skill may take several hotbar slots. Default 1, restricted as usual (martial skills may use martial bonus slots, etc.). A skill with a rarity takes more by default: Rare 2, Epic / Very Rare 3, Legendary 4, Mythic 5. An explicit slots property or tag overrides it. Work it into Cram's caster bonus slots, Density's slot doubling, traits (still 0) and the disable ordering (one skill spanning several slots).
- Model: sonnet/high, after card 2
- Collides with: card 2

### 4. Persistent units and the Party (?206)
- Scope: the player's units keep learned skills, ranks, equipped bar, items, level and XP across battles in `Save.gd` (version bump, migration of an old save), filling the `lapses` plumbing. A configurable Party: size is level / 4 + the base cha mod if positive, at least 2 (level = the hero's or leader's: record the call). The player picks who is in it from a (simple) roster screen; a battle fields the party. Class units stay fresh where they are only NPCs.
- Files: Scripts/Save.gd, Scripts/Game.gd, Scripts/Entry.gd or a roster scene, Unit serialization
- Model: opus/medium
- Collides with: cards 2 and 3 only through Unit.equipped (keep it to serialization)

### 5. Queue audit
- Scope: check the Wave 1 and 2 cards below against the code; report which are built (the builder writes `docs/plans/w6-audit.md`, does not edit queue.md); run the unbuilt ones that need no user input.
- Model: sonnet/medium

## Wave 4: the user's answers of 2026-11-19 (docs/agents/answers-2026-11-19.md; cards A to D built, ?202 to ?205)

## Wave 3: the user's answers of 2026-11-18, second batch (docs/agents/answers-2026-11-18b.md)
All eleven cards are built (?192 to ?201). Nothing left here.

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

## Wave 5: follow-ups from ?206 to ?213 (all need nothing from the user)

### A defensive cc read in the AI
- Source: docs/todo/systems.md (?206)
- Scope: the AI backs off, or does not close, when a foe's Stun or other `cc` is likely to land on it (read `Unit.afflicted()` and the foe's `afflicts` forecast on the threat side). Sim before and after.
- Read: docs/plans/w5-ai1.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: the AI cards in Wave 1 and below (AI.gd)

### A unit carrying a `pack`
- Source: docs/todo/classes.md (?213)
- Scope: give one or two units an `@export Unit.pack` (armor carried) through `unit.py` and loot through `item.py`, so `AI._dress()` has something to equip; check it in a battle.
- Read: docs/plans/w5-ai2.md
- Files: Scenes/, Loot/, Tests/plating_test.gd
- Model: sonnet/medium
- Collides with: none

### Forecast crit-triggered loops
- Source: docs/todo/systems.md (?206, ?213)
- Scope: the forecast counts Chaser's chase and Jugular's recast when a crit triggers them (use `Behaviour.Forecast`, no per-skill case).
- Read: docs/plans/w5-ai1.md
- Files: Scripts/AI.gd, Tests/chaser_test.gd
- Model: sonnet/high
- Collides with: the AI cards in Wave 1 and above (AI.gd)

### The AI weighs its own plates' tolls
- Source: docs/todo/classes.md (?213)
- Scope: the AI reads `Behaviour.slot_toll()` for its own plated slots (Power Armor's Power cost) when it decides to block or equip.
- Read: docs/plans/w5-ai2.md
- Files: Scripts/AI.gd, Tests/plating_test.gd
- Model: sonnet/medium
- Collides with: the AI cards in Wave 1 and above (AI.gd)

## Needs the user (not queued)
- Calls for review: ?198 (Cram's readings, tier 7, no swap on arrival), ?200 (Defense adds, Power is Energy share, where Abjuration and Smith are offered), ?201 (postpone and overcome stats), ?202 (the `strike` tag, friction's numbers), ?203 and ?204 (the disable trade; confirm the flags `no_density` and `scaling`, the viewer and the dials), ?192 (cc audit edges, the slam on a flee), ?193 (Chaser placement), ?194 (Skill Slot +1 gating), ?195 (the numbers), ?197 (Wake and Rake's tier, "cast mod"), ?206 (cc prices), ?208 (Student flex picker, Journeyman's tier and max rank, "Brawn as Brains ??"), ?209 (do recoveries add Exhaustion uses?), ?211 (the synonyms), ?212 (Send Off's ward on a foe sent away), ?213 (`pack`, POINT, DELAY, the loot table).
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
