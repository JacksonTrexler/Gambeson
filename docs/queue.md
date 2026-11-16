# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-15. Reconciled against the code after ?145 to ?154.

Before launching a wave, drop any card whose source line is now `[x]`. The old cards for the item tool, dissonance, screenshot checks, price rebates, forced unshape, bio text, foresight as an Effect stat, Pace's hurry and one-line log, the third-reserve drain and the map AP and movement drain are built and gone. Waves are ordered by the files they share (Battle.gd, AI.gd, HUD.gd): run a wave's cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
- `x-equip`: equipping skills (SkillGrid, Settings, Unit slots, HUD).
- `z-search`: more contextual clues for searching (AI.gd, Perception.gd).
- `z-warcry`: choose Warcry's foes (warcry.gd, HUD.gd).
- `z-tidy`: test tidy and the `_expose` rename (hud_test, sweep_test, Battle._expose, Glossary).
- `z-icons`: item icons on the card and in spoils (HUD.gd, Loot.gd).

## Wave 1: free of the in-flight areas
Why first: no AI.gd, HUD.gd or equip files. Start once `z-tidy` has merged (it renames in Battle.gd).

### Param: the deferred skills
- Source: docs/plans/param.md:97; docs/plans/route.md:65; docs/todo/systems.md (?133, ?134)
- Scope: parameterize the 6 deferred Battle.gd skills; `terms()` for Strike and the elemental reads; markup for the 7 UNSAID entries; route Rift turns and the Look dissonance rank's text; a "missed" hook so a lost save or contest can run behaviours (record the call). (`describe_as` is done, ?148.)
- Read: docs/plans/param.md, docs/plans/route.md, docs/plans/skill-modifiers.md
- Files: Scripts/Battle.gd, Scripts/Skill.gd, Scripts/SkillTerms.gd, Scripts/Behaviour.gd, Util/skill.py
- Model: opus/medium
- Collides with: Checks tail, Forced moves, Rebate affordability (Battle.gd)

### Save follow-ups
- Source: docs/todo/systems.md (Saving, ?145)
- Scope: a "delete save" / "new game" button on the entry screen; a save when quitting from inside Gamut's Tower; the HUD marker picker's setting kept in `Prefs`. Not the equipped-set hook (that waits on `x-equip`).
- Read: docs/plans/saving.md, docs/plans/hud-markers.md
- Files: Scripts/Save.gd, Scripts/Entry.gd, Scripts/GamutsTower.gd, Scripts/Prefs.gd, Tests/save_test.gd
- Model: sonnet/medium
- Collides with: none

### Foe bio look-over
- Source: docs/todo/systems.md (?154)
- Scope: a shift-click look-over of a foe or ally that opens the sheet with the viewer's `Read` (`open(u, false, r)`), showing `Bio.line()` as built; nothing new in the text.
- Read: docs/plans/bio-text.md, docs/plans/ui-small.md
- Files: Scripts/HUD.gd, Scripts/CharacterSheet.gd, Tests/bio_test.gd
- Model: sonnet/medium
- Collides with: `z-warcry`, `z-icons` (HUD.gd): start after they merge

## Wave 2: the AI and forced moves
Why second: they touch AI.gd and Battle.gd, so they follow `z-search` and `z-tidy`.

### AI prices what it ignores
- Source: docs/todo/systems.md (?138, ?150)
- Scope: AI estimates a foe's Defense from `Read` as the player does; prices Poach's Energy/Focus refund and its regain on a neutralizing blow, and Slam Jam's interrupt; Kick's trap blast on bystanders and its push distance (forecast says "back"); Starving Grudge with allies in reach or over several rounds; holding a Final Act unit back as such (today the discount only lowers the kill's pull). AP refunds are priced already.
- Read: docs/plans/ai-tactics.md, docs/plans/gaps-react-marks.md
- Files: Scripts/AI.gd, Behaviours/(poach, slam_jam, kick, final_act), Tests/ai_*
- Model: sonnet/high
- Collides with: AI support and weighing, Path foresight (AI.gd)

### Forced moves: forecast, AI and turning
- Source: docs/todo/systems.md (?142, ?146); docs/plans/facing.md:40; docs/plans/fear.md
- Scope: the forecast shows a fear, shove or entrance move and its slam (`Behaviour.foresee`/`Battle.foresee`); the AI treats fear, shove and entrance as harm and seeks or avoids them (no new skill); a unit that is hit turns toward the attacker; push, pull, send and teleport turn the moved unit (record the call); `drive()` in Aura and Coordinate's effect loops; the three tags on a skill's own `tags` only if a skill carries one (else record why not).
- Read: docs/plans/fear.md, docs/plans/facing.md, docs/plans/reactions.md
- Files: Scripts/Battle.gd, Scripts/Unit.gd, Scripts/AI.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: AI prices (AI.gd), Param, Checks tail (Battle.gd)

## Wave 3: AI support, checks and HUD follow-ups
Why third: smaller wins on the same files, after wave 2.

### AI support and weighing
- Source: docs/todo/systems.md:101,107,286,288 (?98, ?87, ?130)
- Scope: prices a `stamina` skill's extra effect (Move ??); weighs a raised exhaustion cost and varies (museum balance, ?87); HUD "help" orders count Heal (fold `Skill.heals()` into `Skill.serves()`); a switch where no pool holds enough. Heal as a heal, Resuscitate over Heal, resting for Focus and Grudge are built.
- Read: docs/plans/ai-support.md, docs/plans/ai-tactics.md, docs/plans/exhaustion.md
- Files: Scripts/AI.gd, Scripts/Skill.gd, Scripts/HUD.gd, Tests/museum/sim tests
- Model: opus/medium
- Collides with: AI prices, Path foresight

### Checks tail and rebate affordability
- Source: docs/todo/systems.md (?141, ?148, ?151)
- Scope: a forecast for Level Down's bar and investigating; the DC rolls (Burnout, Stun, Bandwagon, dodges) on `check(.., against: dc)`; Hitch and Slam Jam as a declared `SkillCheck`; `can_afford` and the AI's affordability using the rebated price (a unit with half of Poach's AP can start it), and auto, spread and tile casts taking the cut where there is a target to ask.
- Read: docs/plans/checks.md, docs/plans/polish-11-15.md, docs/plans/price-refunds.md
- Files: Scripts/Battle.gd, Scripts/Unit.gd, Scripts/Check.gd, Behaviours/(hitch, slam_jam, poach), Tests/check_test.gd
- Model: sonnet/high
- Collides with: Param, Forced moves (Battle.gd)

### HUD glow and Guide bundle
- Source: docs/todo/ui.md:43-46,172-175 (?84, ?136); docs/plans/silhouettes-glow.md:58; docs/plans/exhaustion.md:51
- Scope: a glow for area skills; "somewhat" offers the unsure walk on a forced click (as Strike's forced charge); the command glow walks a party member with its own reach; profile the reach map on big maps; the Guide spells P, H, Space, Tab as keys; near-miss circles to scale and Luck.MARGIN shown; fix the museum tile hover "No TileSet atlas source with id -1" in `HUD._tile_icon`; the Jammed ?? name on the chip; the allied glow stronger on grass maps; static skill descriptions (skills screen, spellbook) show the exhaustion-adjusted cost note; re-check Warcry's marks on a busy board by screenshot.
- Read: docs/plans/silhouettes-glow.md, docs/plans/ui-v2.md
- Files: Scripts/HUD.gd, Scripts/Overlay.gd, Scripts/Guide.gd, Scripts/Spellbook.gd, Scripts/SkillDetail.gd
- Model: sonnet/high
- Collides with: Foe bio look-over (HUD.gd); `x-equip`

## Wave 4: after `x-equip` merges
Why: they read the equip plumbing and sit on SkillGrid, Unit slots and Settings.

### Equip follow-ups
- Source: docs/todo/ui.md:16; docs/todo/classes.md:17; docs/todo/systems.md (?145, ?149)
- Scope: fill `Save._equipped_out()` and `_equipped_in()` (and save on equipping); the Settings > Gameplay toggle for auto-equip; unequipping a slot-granting skill removes its slots (skills and all); the Specialist tree opens scrolled to its lowest filled tier; the lent ring on the same baseline as the rank pip.
- Read: docs/plans/item-skills.md, docs/plans/saving.md, docs/plans/shots-11-15.md
- Files: Scripts/Settings.gd, Scripts/Unit.gd, Scripts/Save.gd, Scripts/SkillGrid.gd, Scripts/SkillSlot.gd
- Model: sonnet/high
- Collides with: Save follow-ups

### Path foresight
- Source: docs/todo/ui.md:188-190 (?137); docs/plans/path.md:47
- Scope: foresee Meander's `passes_by` for traps and count `at_end` effects (per_tile and its wards are done, ?150); `AI._approach` reuses the route's line risk instead of its own and `pass_cost` for unit-blocked routes; tune `HAZARD_TILES` and `STEER_MARGIN` by the sims.
- Read: docs/plans/path.md, docs/plans/tile-marks.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: AI prices, AI support (AI.gd)

## Wave 5: the large piece, alone

### Unbounded maps, camera and spawning
- Source: docs/todo/systems.md:46; docs/plan.md Phase 7 item 27
- Scope: a map that streams chunks, a camera that pans and follows units, spawning out of view (`Battle.summon()` is the start); Infernal Meadows' 30-kill portal stays a later battle.
- Read: docs/plans/route.md, docs/plans/path.md
- Files: Scripts/Battle.gd, Scripts/Overlay.gd, Scripts/BattleCamera.gd, Scenes/
- Model: opus/medium
- Collides with: nearly every Battle and Overlay card; run alone

## Needs the user (not queued)
- Test stubs, Option A or B: ?144.
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
