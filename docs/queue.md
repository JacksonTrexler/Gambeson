# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-16. Reconciled against the code after ?170 to ?174.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: forced moves (forecast and AI), Warcry's default-pick preview, Guide rings and check tests, AI tuning, path foresight, the checks tail and rebate affordability, equip follow-ups, tooling guards, AI support 2, the HUD glow and Guide bundle, param rest, param, save follow-ups, the foe look-over, AI prices, equipping and the test tidy, search clues, Warcry's picker and card icons, besides the item tool, dissonance, rebates, forced unshape, bio text and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
- `z-maps`: unbounded maps, the camera and spawning (Battle.gd, Overlay.gd, BattleCamera.gd, Scenes/). Nearly every Battle and Overlay card collides with it: hold those until it merges.

## Wave 1: the AI, after `z-maps` merges

### A purpose-built AI sim
- Source: docs/todo/systems.md (?159, ?162, ?164, ?167, ?173)
- Scope: a scratch battle set that exercises what the museum cannot (an Observe user hunting a hider; a Kick against a wall; a Grudge unit in a corner; a rider skill), run over seeds with each constant low and high, to tune the clue weights and caps (`SUSPICIOUS` ... `HIT`, `REACH_TURNS`, `SWEEP_TURNS`), `GUESS_DEFENSE`, `POINT`, `RIDER`, `PUSH`, `STARVE`, `AI.SEEN`, `AI.WORN`. Keep the sim out of the suite (slow) unless a small version is cheap. Record each choice and the table. The museum's Hex-over-Strike balance (?87) is not here: cost tuning is the user's.
- Read: docs/plans/ai-tuning.md, docs/plans/search-clues.md, docs/plans/ai-prices.md
- Files: Scripts/AI.gd, Tests/ (a scratch driver)
- Model: sonnet/high
- Collides with: AI cards below (AI.gd)

### Exhaustion wear for heals and supports
- Source: docs/todo/systems.md (?167, ?173)
- Scope: `AI._wear` prices strikes only; weigh heals and supports for the cost exhaustion adds too, with a test by seam.
- Read: docs/plans/ai-support-2.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd
- Model: sonnet/medium
- Collides with: the purpose-built sim (AI.gd)

### AI positioning for forced moves, and the other walks on route()'s price
- Source: docs/todo/systems.md (?170); docs/todo/ui.md (?174)
- Scope: the AI walks to a tile that lines up a shove against a wall and weighs being shoved by foes in `_away`; flee, kite and retreat walks price cells with `route()` (as `_approach` does); the Grudge unit's own approach and allies coordinating a retreat (?173); tune `SUSPECT_TILES` with a hinted-trap sim.
- Read: docs/plans/forced-forecast.md, docs/plans/path-foresight.md, docs/plans/ai-tuning.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd, Tests/path_test.gd
- Model: sonnet/high
- Collides with: the AI cards above (AI.gd)

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
