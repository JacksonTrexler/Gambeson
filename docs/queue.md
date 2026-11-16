# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-16. Reconciled against the code after ?175 to ?177.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: unbounded maps, AI walks (wear, shove positioning, route() retreats, Grudge approach), the AI sim and tuning, forced moves (forecast and AI), Warcry's default-pick preview, Guide rings and check tests, AI tuning, path foresight, the checks tail and rebate affordability, equip follow-ups, tooling guards, AI support 2, the HUD glow and Guide bundle, param rest, param, save follow-ups, the foe look-over, AI prices, equipping and the test tidy, search clues, Warcry's picker and card icons, besides the item tool, dissonance, rebates, forced unshape, bio text and the older cards. Run cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
Nothing.

## Wave 1: follow-ups from ?175 to ?177 (all small; the files differ, so they can run together)

### Meadows HUD: the turn clock over "Demons slain"
- Source: docs/todo/systems.md (?175)
- Scope: the turn clock's number draws over the end of the Meadows' "Demons slain" tally at the top centre; lay them out so they don't overlap (check by a screenshot, `visual-check-godot-ui`).
- Files: Scripts/HUD.gd (or the clock's scene), Tests/hud_test.gd
- Model: sonnet/medium
- Collides with: none

### Camera: edge-pan
- Source: docs/todo/systems.md (?175)
- Scope: pan the camera by pushing the mouse to the screen edge, clear of the HUD's edge panels; a setting to turn it off. Arrow-key pan exists.
- Read: docs/plans/unbounded-maps.md
- Files: Scripts/BattleCamera.gd, Scripts/Settings (as found), Tests/meadows_test.gd
- Model: sonnet/medium
- Collides with: the HUD card above only if it touches the same panel

### A cheaper first guess for summons inside sight
- Source: docs/todo/systems.md (?175)
- Scope: an unseen `summon()` that starts inside sight takes ~170 ms reading its way out; guess a tile past perception range first (as the Meadows' formation spawn does, 9-10 ms) and read only to confirm. Measure before and after.
- Read: docs/plans/unbounded-maps.md
- Files: Scripts/Battle.gd, Tests/meadows_test.gd
- Model: sonnet/medium
- Collides with: none

### Allies coordinate a retreat
- Source: docs/todo/systems.md (?176)
- Scope: allies backing off from one Grudge unit shouldn't crowd the same tile out. The rule tried in ?176 (don't end beside an ally still to back off) was no better than `_room()`; find one a seam test can tell apart, or drop the card.
- Read: docs/plans/ai-walks.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: the next card (AI.gd)

### AI findings from the sim
- Source: docs/todo/systems.md (?177, ?176)
- Scope: an Observe user that has swept its last clue stands beside a hider and never looks again (sim `hunt-still`, seed 1); Poach is never chosen over Strike or Slam Jam (sim `rider`); a test for the line-up's gain threshold (`PUSH x RIDER`). Fix what the sim shows and re-run it (`Tests/sims/ai_sim.gd`, `sweep.sh`).
- Read: docs/plans/ai-sim.md, docs/plans/ai-walks.md
- Files: Scripts/AI.gd, Tests/ai_tactics_test.gd
- Model: sonnet/high
- Collides with: allies coordinate a retreat (AI.gd)

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
