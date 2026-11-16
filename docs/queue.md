# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-15. Reconciled against the code after ?164 to ?169.

Before launching a wave, drop any card whose source line is now `[x]`. Built and gone: the checks tail and rebate affordability, equip follow-ups, tooling guards, AI support 2, the HUD glow and Guide bundle, param rest, param, save follow-ups, the foe look-over, AI prices, equipping and the test tidy, search clues, Warcry's picker and card icons, besides the item tool, dissonance, rebates, forced unshape, bio text and the older cards. Waves are ordered by the files they share (Battle.gd, AI.gd, HUD.gd): run a wave's cards in parallel only where "Collides with" says none.

## In flight (not here to launch)
- `z-forced`: forced moves, the forecast and the AI (Battle.gd, AI.gd, HUD.gd).
- `z-wcpreview`: Warcry's default-pick preview (HUD.gd, Overlay.gd, warcry_test).

## Wave 1: the AI, after `z-forced` merges

### AI tuning and the last prices
- Source: docs/todo/systems.md (?159, ?162, ?164, ?167)
- Scope: run the sims and tune the clue weights and caps (`SUSPICIOUS` ... `HIT`, `REACH_TURNS`, `SWEEP_TURNS`), the price constants (`GUESS_DEFENSE`, `POINT`, `RIDER`, `PUSH`, `STARVE`), and `AI.SEEN` (0.9) and `AI.WORN` (0.8); weigh heals and supports for exhaustion wear too; read Defense through a lie (`_lie`/`twist`) in the AI and the HUD together; a Grudge unit plans a retreat tile so as not to be cornered next round. Record each choice. The museum's Hex-over-Strike balance (?87) is not here: cost tuning is the user's.
- Read: docs/plans/search-clues.md, docs/plans/ai-prices.md, docs/plans/ai-support-2.md, docs/plans/checks-tail.md
- Files: Scripts/AI.gd, Scripts/Read.gd, Scripts/HUD.gd, Tests/ai_tactics_test.gd, Tests/evidence_test.gd
- Model: sonnet/high
- Collides with: Path foresight, `z-forced` (AI.gd)

### Path foresight
- Source: docs/todo/ui.md:188-190 (?137); docs/plans/path.md:47
- Scope: foresee Meander's `passes_by` for traps and count `at_end` effects (per_tile and its wards are done, ?150); `AI._approach` reuses the route's line risk instead of its own and `pass_cost` for unit-blocked routes; tune `HAZARD_TILES` and `STEER_MARGIN` by the sims.
- Read: docs/plans/path.md, docs/plans/tile-marks.md
- Files: Scripts/AI.gd, Scripts/Battle.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: AI tuning, `z-forced` (AI.gd)

## Wave 2: small tails, free of the in-flight areas

### Guide rings and check tests
- Source: docs/todo/ui.md (?168); docs/todo/systems.md (?164)
- Scope: a Guide line for the near-miss rings; mutation-proof Hitch's `apply()` options and `hit_chance`'s Level Down branch (a test each).
- Read: docs/plans/hud-glow-guide.md, docs/plans/checks-tail.md
- Files: Scripts/Guide.gd, Tests/hud_test.gd, Tests/check_test.gd
- Model: sonnet/medium
- Collides with: `z-wcpreview` (HUD.gd, only if the Guide edit reaches it)

## Wave 3: the large piece, alone

### Unbounded maps, camera and spawning
- Source: docs/todo/systems.md:46; docs/plan.md Phase 7 item 27
- Scope: a map that streams chunks, a camera that pans and follows units, spawning out of view (`Battle.summon()` is the start); Infernal Meadows' 30-kill portal stays a later battle.
- Read: docs/plans/route.md, docs/plans/path.md
- Files: Scripts/Battle.gd, Scripts/Overlay.gd, Scripts/BattleCamera.gd, Scenes/
- Model: opus/medium
- Collides with: nearly every Battle and Overlay card; run alone

## Needs the user (not queued)
- Test stubs, Option A or B: ?144.
- Actives must be equipped to work (AI included) and a global auto-equip toggle: ?163. The green "on" dot now only shows for toggles: ?165.
- Skill Slot +1: is its slot the hotbar's center or the tree's? ?3, ?165.
- The museum's balance: Hex still outscores Strike after the AI weighs wear; cost tuning: ?87, ?167.
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
