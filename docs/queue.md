# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-16. Reconciled against the code after ?178 to ?183.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), Skeleton, Deathlust, the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing.

## Wave 2: the user's answers of 2026-11-18 (verbatim in docs/agents/answers-2026-11-18.md)
Run order: 1, 2, 3 and 5 first (2-3 at a time); 4 after 3 (same roll code); 6 after 5; 7 after 6. Rules for all: the user says no balancing now; an underpowered skill is tuned by check difficulty; an effect that stops a unit taking useful actions is precious, price it high.

### 1. Traits (?163)
- Scope: `trait` (the user's word, no ??) is a tag on a skill. A trait is always equipped, sits at the far right of the hotbar, takes no slot, is not hit by skill-disable effects, and is skipped by anything that orders the hotbar (enchant the leftmost rank skills, disable rank skills right to left). One generic way to suppress traits (e.g. a status "traits suppressed for N rounds"), unused for now. Decide which existing skills are traits (species, monster, form innates such as aquatic; list each as a call). Everything else, active or passive, does nothing unless equipped (and toggled if a toggle): check this holds for passives too.
- Model: sonnet/high. Collides with: the HUD hotbar, `Unit.equipped`.

### 2. Facing (?142)
- Scope: a unit faces along the vector from start to finish of its last move, or from its position to the tile it last targeted with a skill, whichever is latest. Call to record: forced moves count as moves (a pushed unit faces along the push).
- Model: sonnet/medium. Collides with: Unit facing code only.

### 3. Glance, Backstab, Glancing Strike, Heavy Strike
- Scope (the user's names, `--human`; the `glance` tag too): a roll in crit range that would miss is a `glance`: a hit for half regular damage. Backstab (Rogue and Slayer martial t4, passive): crit range widens by rank (crits on 20 - rank and up). Glancing Strike (general martial t2): strikes rolled at disadvantage; if the low roll misses but the high one hits, it hits with glance; plus rank to the first rank attack rolls the unit makes each battle (record that reading). Heavy Strike (general martial t5): roll the unit's consecutive strikes as usual, pool their damage into one attack, then a final attack roll + successes + rank must hit or it all misses; on a hit, + successes + rank damage (record the reading). Generic hooks (crit range, glance outcome), not one-off flags.
- Model: opus/medium (design). Collides with: the attack roll in Battle.

### 4. Striking Features and Striking Intellect
- Scope (the user's names): Specialist general Striking Features and Caster general Striking Intellect use cha / int mod for strike attacks if higher. One generic hook for "which stat an attack reads", not two flags.
- Model: sonnet/medium. After card 3 (same roll code).

### 5. Test stubs, Option A (?144)
- Scope: data-only skills get a row in a shared table test (the sweep); only a skill with a `Behaviours/*.gd` gets its own test file; `skill.py`, `unit.py`, `mechanic.py` stop stubbing per-item tests otherwise. Fold per-skill tests of functionally identical skills (basic tagged attack, heal, buff) into tests of the core mechanic. The user authorises editing CLAUDE.md's test line and `.claude/skills/new-skill`, `new-unit`, `new-mechanic`.
- Model: sonnet/high. Collides with: Tests/, Util/.

### 6. Cost identity (?131)
- Scope: the computed price (Pricing: tags, parameters, rank scaling, possibly steep) is every skill's baseline; a skill declares a cost profile in words ("high mana, low ap") that skews that baseline across AP and resources; `skill.py new --cost "high mana, low ap"` takes it, so a Sonnet or Haiku can set one from a description. Plan first in docs/plans/, then build; migrate hand costs to the nearest profile only where cheap; don't balance.
- Model: opus/medium. Collides with: Skills/*.tres, Util/skill.py (after card 5).

### 7. Parameterize the concrete skills (?133)
- Scope: an over-concrete skill should scale on rank, stats and check difficulty, and an underpowered one should be tunable by check difficulty. Take the 27 left concrete and parameterize those that can be.
- Model: sonnet/high. After card 6.

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
- Closed 2026-11-18: ?87, ?167, ?152, ?173 keep as built (the user: no balancing now); ?144, ?163, ?142, ?131, ?133 answered, now Wave 2.
- Skill Slot +1: is its slot the hotbar's center or the tree's? ?3, ?165.
- Should a skill that carries a forced move be tagged `shove` (Send Off, Kick)? ?146, ?170.
- The AI's "nowhere to switch" case (a unit with one toggle and no pool holding enough): ?130.
- Does a weapon or armor enchant raise the item's rank (armor drag), or only its lent skills'? ?143. Lent skills as prerequisites: ?143.
- Skills that force an unshape (a Dispel, a Hex of the beast), and whose tool it is: ?126, ?153. Skills carrying fear, shove or entrance: ?146.
- Winded's meaning: ?126. Burnout: burnt max, out-of-combat, other gains: ?121. A Life tree: ?121, ?122, ?124.
- `Unit.guard` on helpless: ?127. 0-AP actions while tapped: ?119. Merchant tree for Drone: ?119.
- Item rank-up, sources for the Habergeon family: ?118.
- Snapped forms (Gallantry, Final Act): ?140. A flank or rear rider skill: ?142.
- Gods and classes not designed: Divinity trees for Ramut, Urlo, Drael, Vetruvis, Survival skills, Paladin leadership Flex, burn tier cap (?122, ?81); Wizard and Mage real trees (?70); Martial and Specialist roots (?15); more Rogue, Bard, Luun, Elmon and Hogel skills; the cut-off Demon / Warlock / Dark Magic skill; Skill Slot +1, Trade Skills, Grind (?2, ?3, ?11).
- Inspire, Sundering, Silent Strike and Sunder (?13); Charm (?14); Discipline's initiative half and the Pike unit (?80, ?82, ?120).
- Energize and Power Transfer (siphon-sorcerer plan: named, not defined); Commitment to the bit (a Cultist tree); clout earned in play and more tempers (?91, ?93); more resources (Rage, Hype, Clout, Gold) and shops; round and initiative lines using the arrow (ui.md:8); Astral Envoy tuning (?29).
