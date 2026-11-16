# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-16. Reconciled against the code after ?178 to ?183.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: the Meadows HUD tally, edge-pan, the cheaper unseen summon, allies' retreat tie-break, the AI findings from the sim (hunt-still, Poach, the line-up test), Skeleton, Deathlust, the big sims, the dictionary and glossary, unbounded maps, AI walks, the AI sim and tuning, forced moves, Warcry's preview, Guide rings, AI tuning, path foresight, the checks tail, equip follow-ups, tooling guards, AI support 2, param rest, save follow-ups, AI prices, search clues and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
- `r-aiperf`: AI turn cost (`Scripts/AI.gd`, `Battle.read` callers). Cards below that touch AI.gd or `read()` collide with it; wait.

## Wave 1: follow-ups from ?178 to ?183 (all need nothing from the user)

### AI turn cost: a per-act read cache and `_line_up`'s foresee
- Source: docs/todo/systems.md (?183)
- Scope: only if `r-aiperf` leaves it over budget (100 ms a unit turn, 1000 ms an `end_turn` at M3 x 4; `Tests/sims/busy_fight.gd`). A per-act cache of a unit's reads (invalidated by any state change), `suspicious()` reusing the act's reads and skipping units beyond every viewer's range, `_line_up` foreseeing fewer tiles, a Brood-free fast path in `Unit.stat`.
- Read: docs/plans/r-sims.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/Unit.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: `r-aiperf`

### The AI casts Skeleton
- Source: docs/todo/classes.md (?181)
- Scope: a tile-summon plan in `AI.gd`: when a side has room and a foe is in reach, cast a summon skill (`summon_per_rank`) at a tile near itself; price it by the bodies it adds. Sim before and after.
- Read: docs/plans/r-skeleton.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd, Tests/summon_test.gd
- Model: sonnet/high
- Collides with: `r-aiperf` (AI.gd), the next card

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
- Test stubs, Option A or B: ?144.
- Actives must be equipped to work (AI included) and a global auto-equip toggle: ?163. The green "on" dot now only shows for toggles: ?165.
- Skill Slot +1: is its slot the hotbar's center or the tree's? ?3, ?165.
- The museum's balance: Hex still outscores Strike after the AI weighs wear; cost tuning: ?87, ?167.
- Forced moves: turning. A unit that is hit turns toward its attacker, and push, pull, send and teleport turn the moved unit: facing's call that hits and forced moves turn nobody: ?142 (the forecast and AI are built, ?170).
- Should a skill that carries a forced move be tagged `shove` (Send Off, Kick)? ?146, ?170.
- The lied Defense's mirror point (`Perception.MIRROR` 20) and whether the armor's name lies too: ?173.
- The AI's "nowhere to switch" case (a unit with one toggle and no pool holding enough): ?130.
- The Siren's balance: dissonance by distance doubts its lure more (7 to 9, penalty 3 to 5); keep, or `LIE_FAR` 1.25: ?152.
- Does a weapon or armor enchant raise the item's rank (armor drag), or only its lent skills'? ?143. Lent skills as prerequisites: ?143.
- Skills that force an unshape (a Dispel, a Hex of the beast), and whose tool it is: ?126, ?153. Skills carrying fear, shove or entrance: ?146.
- Winded's meaning: ?126. Burnout: burnt max, out-of-combat, other gains: ?121. A Life tree: ?121, ?122, ?124.
- Price table or computed prices: ?131. The 27 concrete skills: ?133. Retuning colours: ?125.
- `Unit.guard` on helpless: ?127. 0-AP actions while tapped: ?119. Merchant tree for Drone: ?119.
- Item rank-up, sources for the Habergeon family: ?118.
- Snapped forms (Gallantry, Final Act): ?140. A flank or rear rider skill: ?142.
- Gods and classes not designed: Divinity trees for Ramut, Urlo, Drael, Vetruvis, Survival skills, Paladin leadership Flex, burn tier cap (?122, ?81); Wizard and Mage real trees (?70); Martial and Specialist roots (?15); more Rogue, Bard, Luun, Elmon and Hogel skills; the cut-off Demon / Warlock / Dark Magic skill; Skill Slot +1, Trade Skills, Grind (?2, ?3, ?11).
- Inspire, Sundering, Silent Strike and Sunder (?13); Charm (?14); Discipline's initiative half and the Pike unit (?80, ?82, ?120).
- Energize and Power Transfer (siphon-sorcerer plan: named, not defined); Commitment to the bit (a Cultist tree); clout earned in play and more tempers (?91, ?93); more resources (Rage, Hype, Clout, Gold) and shops; round and initiative lines using the arrow (ui.md:8); Astral Envoy tuning (?29).
