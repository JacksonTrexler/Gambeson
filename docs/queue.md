# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-15. Reconciled against the code after ?155 to ?163.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: param, save follow-ups, the foe look-over, AI prices, equipping and the test tidy, search clues, Warcry's picker and card icons, besides the item tool, dissonance, rebates, forced unshape, bio text and the older cards. Waves are ordered by the files they share (Battle.gd, AI.gd, HUD.gd): run a wave's cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
- `z-checkstail`: the checks tail and rebate affordability (Battle.gd, Unit.gd, Check.gd, hitch, slam_jam, poach).
- `z-hudglow`: HUD glow and Guide bundle (HUD.gd, Overlay.gd, Guide.gd, Spellbook.gd, SkillDetail.gd).
- `z-aisupport`: AI support and weighing (AI.gd, Skill.gd, HUD.gd, sim tests).
- `z-equipfu`: equip follow-ups (the lent ring baseline, Settings, SkillSlot; what is left of the equip card).

## Wave 1: free of the in-flight areas

### Skill tree wiring check
- Source: docs/todo/systems.md (Test tidy, ?156)
- Scope: `skill.py check` fails a skill (not a lent or inherent one) that no tree or role offers, and one a test names but a tree dropped; then the two tree-wiring tests (`trickster_test`, `slam_jam` `test_tree`) can go if the check covers them.
- Read: docs/plans/tidy-11-15.md, docs/plans/skill-tooling.md
- Files: Util/skill.py, Tests/tooling_test.gd
- Model: sonnet/medium
- Collides with: none

### Driver paths for Prefs and KeyBinds
- Source: docs/todo/systems.md (Save follow-ups, ?158)
- Scope: guard `Prefs` and `KeyBinds` paths for a `-s` driver script as `Save.PATH` is (a driver never writes the real settings or binds); `run.gd` keeps its own.
- Read: docs/plans/save-followups.md
- Files: Scripts/Prefs.gd, Scripts/KeyBinds.gd, Tests/run.gd
- Model: sonnet/medium
- Collides with: none

## Wave 2: the AI and Battle, after `z-aisupport` and `z-checkstail` merge
Why: they touch AI.gd and Battle.gd.

### Forced moves: forecast and AI
- Source: docs/todo/systems.md (?146); docs/plans/fear.md
- Scope: the forecast shows a fear, shove or entrance move and its slam (`Behaviour.foresee`/`Battle.foresee`); the AI treats fear, shove and entrance as harm and seeks or avoids them (no new skill); `drive()` in Aura and Coordinate's effect loops; the three tags on a skill's own `tags` only if a skill carries one (else record why not). Turning (a hit or a forced move turns the unit) is held for the user: ?142.
- Read: docs/plans/fear.md, docs/plans/facing.md
- Files: Scripts/Battle.gd, Scripts/AI.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: AI tuning, Param rest (Battle.gd, AI.gd)

### AI tuning and the last prices
- Source: docs/todo/systems.md (?159, ?162)
- Scope: run the sims and tune the clue weights and caps (`SUSPICIOUS` ... `HIT`, `REACH_TURNS`, `SWEEP_TURNS`) and the price constants (`GUESS_DEFENSE`, `POINT`, `RIDER`, `PUSH`, `STARVE`); read Defense through a lie (`_lie`/`twist`) in the AI and the HUD together; a Grudge unit plans a retreat tile so as not to be cornered next round. Record each choice.
- Read: docs/plans/search-clues.md, docs/plans/ai-prices.md
- Files: Scripts/AI.gd, Scripts/Read.gd, Scripts/HUD.gd, Tests/ai_tactics_test.gd, Tests/evidence_test.gd
- Model: sonnet/high
- Collides with: Forced moves, Path foresight (AI.gd)

### Param rest
- Source: docs/todo/systems.md (?134, ?160)
- Scope: route the text of reserves, opens and Downed rules through the modifier reader (the build-time gates stay concrete); a first user of `Behaviour.missed()` only if a skill already wants a rider on a miss (else none: record why).
- Read: docs/plans/param-tail.md, docs/plans/route.md
- Files: Scripts/Skill.gd, Scripts/SkillTerms.gd, Scripts/Battle.gd, Scripts/Behaviour.gd
- Model: sonnet/high
- Collides with: Forced moves (Battle.gd)

## Wave 3: after the AI wave and `z-hudglow`

### Warcry's preview
- Source: docs/todo/systems.md (?157)
- Scope: draw the default "nearest N" faintly before any pick, so the player sees what a quick cast does; no change to the cast or the AI.
- Read: docs/plans/warcry-picker.md
- Files: Scripts/HUD.gd, Scripts/Overlay.gd, Tests/warcry_test.gd
- Model: sonnet/medium
- Collides with: `z-hudglow` (HUD.gd, Overlay.gd)

### Path foresight
- Source: docs/todo/ui.md:188-190 (?137); docs/plans/path.md:47
- Scope: foresee Meander's `passes_by` for traps and count `at_end` effects (per_tile and its wards are done, ?150); `AI._approach` reuses the route's line risk instead of its own and `pass_cost` for unit-blocked routes; tune `HAZARD_TILES` and `STEER_MARGIN` by the sims.
- Read: docs/plans/path.md, docs/plans/tile-marks.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: AI tuning, Forced moves (AI.gd)

## Wave 4: the large piece, alone

### Unbounded maps, camera and spawning
- Source: docs/todo/systems.md:46; docs/plan.md Phase 7 item 27
- Scope: a map that streams chunks, a camera that pans and follows units, spawning out of view (`Battle.summon()` is the start); Infernal Meadows' 30-kill portal stays a later battle.
- Read: docs/plans/route.md, docs/plans/path.md
- Files: Scripts/Battle.gd, Scripts/Overlay.gd, Scripts/BattleCamera.gd, Scenes/
- Model: opus/medium
- Collides with: nearly every Battle and Overlay card; run alone

## Needs the user (not queued)
- Test stubs, Option A or B: ?144.
- Actives must be equipped to work (AI included), the green "on" dot on always-on passives, a global auto-equip toggle: ?163.
- Forced moves: turning. A unit that is hit turns toward its attacker, and push, pull, send and teleport turn the moved unit: facing's call that hits and forced moves turn nobody is open as ?142; the Forced moves card is held to the forecast and the AI until it is answered.
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
