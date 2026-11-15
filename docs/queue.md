# Queue: the ready backlog for host sessions
Tasks that need nothing from the user, as cards a host can launch straight into builders (`.claude/skills/coordinate/SKILL.md`).
Maintained by the docs keeper after each merge batch: built cards removed, follow-ups that need no user input added. Date: 2026-11-15.

Before launching a wave, drop any card whose source line is now `[x]`. Waves 2 to 4 assume the "In flight" branches have merged (they share Battle, HUD, AI and Unit).

## In flight (not here to launch)
- `x-equip`: equipping skills.
- `x-save`: saving.
- `x-fear`: fear, shove, entrance.
- `x-gaps`: reaction moments for area skills, AI interrupts, AI weighing enemy reactions, `per_tile` in the hazard estimate, hidden marks' "?", helpful marks attracting, fire as a mark.
- `x-polish`: `describe_as`, facing cue in the forecast, `resolve()` rolls onto the check helper, effect strength at cast.

## Wave 1: tooling and files the running branches don't touch
Why first: the item tool and the AI's pricing unblock later content and sims; the rest avoid Battle.gd and Unit.gd.

### Item tool
- Source: docs/todo/world.md:128 (?135)
- Scope: `Util/item.py new` and `check`, writing `Items/*.tres`, a placeholder icon through `icon.py`, a `.claude/skills/new-item` process, and a line in CLAUDE.md's tool list (the docs keeper does CLAUDE.md after merge). No new items.
- Read: docs/plans/item-icons.md, docs/plans/item-ranks.md, docs/plans/skill-tooling.md
- Files: Util/item.py (new), Util/icon.py, Items/*.tres, .claude/skills/new-item/
- Model: opus/medium
- Collides with: none

### AI prices what it ignores
- Source: docs/todo/systems.md:385-388 (?138)
- Scope: AI estimates a foe's Defense from `Read` as the player does; prices Poach's Energy/Focus refund and its regain on a neutralizing blow, and Slam Jam's interrupt; Kick's trap blast on bystanders and its push distance (forecast says "back"); Starving Grudge with allies in reach or over several rounds.
- Read: docs/plans/ai-tactics.md
- Files: Scripts/AI.gd, Behaviours/(poach, slam_jam, kick), Tests/ai_*
- Model: sonnet/high
- Collides with: x-gaps (AI.gd); wave 2 "AI support and weighing"

### Dissonance by how far the lie is
- Source: docs/todo/systems.md:45; docs/plan.md Phase 5 item 17
- Scope: a distance between the persona's claimed words/tags and the unit's own, from a small similarity table (ask nothing: first-guess numbers, ?? on any new name); replaces today's tally.
- Read: docs/plans/silhouettes-glow.md, docs/plans/clairvoyance.md
- Files: Scripts/Perception.gd, Scripts/Glossary.gd, Tests/perception_*
- Model: opus/medium
- Collides with: none

### Reserve HUD bundle
- Source: docs/plans/hud-markers.md:44; docs/plans/focus.md:84; docs/plans/ui-v2.md:91; docs/plans/exhaustion.md:51
- Scope: the bar shows every reserve, not only `main_reserve()`; Overlay drain on a third reserve; drain on the map bars for AP and movement; a mark on a hotbar slot while its skill is worn by exhaustion; static skill descriptions (skills screen, spellbook) show the exhaustion-adjusted cost note.
- Read: docs/plans/hud-markers.md, docs/plans/focus.md
- Files: Scripts/HUD.gd, Scripts/Overlay.gd, Scripts/SkillSlot.gd, Scripts/Spellbook.gd
- Model: sonnet/high
- Collides with: x-polish, x-equip (HUD.gd); waves 2 and 3 HUD cards

### Screenshot checks
- Source: docs/todo/classes.md:298; docs/todo/world.md:88
- Scope: screenshot (movie maker + scripted input driver, see memory "visual check") the Clairvoyance pings in battle and the Specialist tree with three tier-3 skills; fix only what is plainly broken, else record in the todo docs via the keeper.
- Read: docs/plans/clairvoyance.md, docs/plans/command-skills.md
- Files: none expected (Tests/ driver in the scratchpad)
- Model: sonnet/medium
- Collides with: none

## Wave 2: the AI and the rules that read Battle and Unit
Why second: they touch Battle.gd, Unit.gd and AI.gd, so they follow `x-gaps`, `x-fear` and `x-polish` merging; the AI pricing from wave 1 should be merged first.

### AI support and weighing
- Source: docs/todo/systems.md:101,107,286,288 (?98, ?87, ?130); docs/plans/ai-support.md:62; docs/plans/focus.md:84; docs/plans/downed.md:55; docs/plans/rescue.md:111; docs/plans/recovery.md:81
- Scope: the AI knows Heal/Megaheal are heals (`Skill.heals()` reads `heal_mods`; HUD "help" orders count Heal, folding `Skill.serves()`); casts Resuscitate over Heal on a Downed ally and Intervention; rests to build Focus and holds a shot for it; prices a `stamina` skill's extra effect (Move ??); weighs a raised exhaustion cost and varies (museum balance, ?87); a switch with no pool holding enough; keeps away from a unit under Grudge and heals itself back up under Grudge.
- Read: docs/plans/ai-support.md, docs/plans/ai-tactics.md, docs/plans/exhaustion.md
- Files: Scripts/AI.gd, Scripts/Skill.gd, Scripts/HUD.gd, Tests/museum/sim tests
- Model: opus/medium
- Collides with: wave 1 AI pricing, x-gaps; Path foresight (wave 3)

### Hit turns and forced moves turn
- Source: docs/todo/systems.md:459,461 (?142); docs/plans/facing.md:40
- Scope: a unit that is hit turns toward the attacker; push, pull, send and teleport turn the moved unit (or not, a call to record); the AI walks to a side for a better shot, no longer only as a tie-break.
- Read: docs/plans/facing.md, docs/plans/reactions.md
- Files: Scripts/Battle.gd, Scripts/Unit.gd, Scripts/AI.gd
- Model: sonnet/high
- Collides with: x-fear (forced moves), x-polish (facing cue); AI support card

### Price calculator folds refunds
- Source: docs/todo/classes.md:420 (?126, ?131)
- Scope: Poach's and Slam Jam's discounts enter `Pricing`/the cost calculator so the HUD shows the reduced price beforehand, not a refund after paying.
- Read: docs/plans/slayer.md, docs/plans/param.md
- Files: Scripts/Pricing.gd, Behaviours/(poach, slam_jam), Scripts/HUD.gd
- Model: sonnet/medium
- Collides with: Reserve HUD bundle (HUD.gd), AI pricing card (Poach)

### Foresight as an Effect stat
- Source: docs/plans/ui-v2.md:91; docs/todo/ui.md:154 (?132)
- Scope: move `foresight_used` out of the HUD onto Unit with an Effect stat via `mechanic.py` (named with ??), so a skill or item could raise it; no skill or item is added.
- Read: docs/plans/ui-v2.md, docs/plans/forecast.md
- Files: Scripts/Effect.gd, Scripts/Unit.gd, Scripts/HUD.gd, Util/mechanic.py
- Model: sonnet/high
- Collides with: Reserve HUD bundle, x-polish (Effect strength)

### Forced unshape hook
- Source: docs/todo/classes.md:419 (?126)
- Scope: `Battle.unshape(u)` for a forced unshape or polymorph break, calling `Battle.neutralize(u, &"unshaped")`; test through a stub effect, no new skill.
- Read: docs/plans/slayer.md
- Files: Scripts/Battle.gd, Behaviours/beastshape*, Tests/
- Model: sonnet/medium
- Collides with: Hit-turns card (Battle.gd), x-fear

## Wave 3: HUD, search and routing follow-ups
Why third: smaller wins that sit on HUD.gd and AI.gd, so they wait for the earlier merges.

### Param: the deferred skills
- Source: docs/plans/param.md:97; docs/plans/route.md:65; docs/todo/systems.md:354,369-371 (?133, ?134)
- Scope: parameterize the 6 deferred Battle.gd skills; `terms()` for Strike and the elemental reads; markup for the 7 UNSAID entries; route Rift turns and the Look dissonance rank's text; a "missed" hook so a lost save or contest can run behaviours (record the call).
- Read: docs/plans/param.md, docs/plans/route.md, docs/plans/skill-modifiers.md
- Files: Scripts/Battle.gd, Scripts/Skill.gd, Scripts/SkillTerms.gd, Scripts/Behaviour.gd, Util/skill.py
- Model: opus/medium
- Collides with: x-polish (describe_as), Forced-unshape card, Hit-turns card (Battle.gd)

### Path foresight
- Source: docs/todo/ui.md:188-190 (?137); docs/plans/path.md:47
- Scope: foresee Meander (`passes_by`) and count `at_end` effects; `AI._approach` reuses the route's line risk instead of its own and `pass_cost` for unit-blocked routes; tune `HAZARD_TILES` and `STEER_MARGIN` by the sims.
- Read: docs/plans/path.md, docs/plans/tile-marks.md
- Files: Scripts/AI.gd, Scripts/Route.gd, Scripts/HUD.gd
- Model: sonnet/high
- Collides with: x-gaps (per_tile, marks), AI support card

### More contextual clues for searching
- Source: docs/todo/systems.md:43; docs/plan.md Phase 5 item 16
- Scope: in `AI._search()`, use last-seen positions, where attacks came from, and the tiles a hidden unit could have reached since it was last seen.
- Read: docs/plans/ai-tactics.md, docs/plans/silhouettes-glow.md
- Files: Scripts/AI.gd, Scripts/Perception.gd
- Model: sonnet/high
- Collides with: AI support card, Path foresight (AI.gd)

### HUD glow and Guide bundle
- Source: docs/todo/ui.md:43-46,172-175 (?84, ?136); docs/plans/silhouettes-glow.md:58; docs/plans/ui-v2.md:91
- Scope: a glow for area skills; "somewhat" offers the unsure walk on a forced click (as Strike's forced charge); the command glow walks a party member with its own reach; profile the reach map on big maps; the Guide spells P, H, Space, Tab as keys; near-miss circles to scale and Luck.MARGIN shown; fix the museum tile hover "No TileSet atlas source with id -1" in `HUD._tile_icon`; the Jammed ?? name on the chip; the allied glow stronger on grass maps.
- Read: docs/plans/silhouettes-glow.md, docs/plans/ui-v2.md
- Files: Scripts/HUD.gd, Scripts/Overlay.gd, Scripts/Guide.gd
- Model: sonnet/high
- Collides with: Reserve HUD bundle, x-polish (HUD.gd)

### Choose Warcry's foes
- Source: docs/todo/systems.md:407 (?139)
- Scope: the caster picks which foes Warcry's marks lead toward (click-to-toggle on the aim, default all as now).
- Read: docs/plans/tile-marks.md
- Files: Behaviours/warcry.gd, Scripts/HUD.gd, Tests/
- Model: sonnet/medium
- Collides with: HUD glow bundle, x-gaps (marks)

## Wave 4: after `x-equip` and `x-save` merge, and the larger pieces
Why last: they read the equip and save plumbing, or are big and wait for a quiet tree.

### Equip and save follow-ups
- Source: docs/todo/ui.md:16; docs/todo/classes.md:17; docs/todo/systems.md:477 (?143); docs/plans/hud-markers.md:44; docs/todo/world.md:29
- Scope: Settings > Gameplay toggle for auto-equip; unequipping a slot-granting skill removes its slots (skills and all); save plumbing for lent item skills and the HUD marker picker's setting; the stash and outfit saved if `x-save` left them out.
- Read: docs/plans/item-skills.md, docs/plans/hud-markers.md
- Files: Scripts/Settings.gd, Scripts/Unit.gd, Scripts/Save.gd (as built), Scripts/HUD.gd
- Model: sonnet/high
- Collides with: x-equip and x-save branches' areas

### Test tidy and `_expose` rename
- Source: docs/todo/systems.md:136,494-496 (?144)
- Scope: `hud_test`'s stale-count check covers every role's wheel, not only the Adventurer; `KeyBinds.SAVE` no longer a shared const so runs can't collide; the sweep covers behaviours that crash on a missing precondition (Emergency Exit, Retrieve); rename `Battle._expose()` to say what it does and fix the Glossary and Effect text ("its holder's grip"). Does not touch ?144 Option A/B.
- Read: docs/plans/consolidation.md, docs/plans/checks.md
- Files: Tests/hud_test.gd, Tests/sweep_test.gd, Scripts/KeyBinds.gd, Scripts/Battle.gd, Scripts/Glossary.gd
- Model: sonnet/medium
- Collides with: Forced-unshape card (Battle.gd)

### Item icons: card and spoils
- Source: docs/todo/world.md:127,129 (?135)
- Scope: the card's third icon no longer touches the word under the portrait; the post-battle Spoils and any loot list draw item icons.
- Read: docs/plans/item-icons.md
- Files: Scripts/HUD.gd, Scripts/Loot.gd
- Model: sonnet/medium
- Collides with: HUD glow bundle, Reserve HUD bundle

### Pace: hurry and a one-line log
- Source: docs/plans/ui-v2.md:91; docs/plans/pace.md:60
- Scope: a spent unit hands over to the next; a held key hurries the turn change and the AI; the log collapses to its last line; floating numbers hurry with the rest.
- Read: docs/plans/pace.md, docs/plans/ui-v2.md
- Files: Scripts/HUD.gd, Scripts/Overlay.gd, Scripts/Battle.gd
- Model: sonnet/high
- Collides with: HUD cards in all waves

### Bio text on the sheet and the Guide
- Source: docs/todo/systems.md:152 (?91)
- Scope: the character sheet and the Guide show a unit's bio (behaviour, appearance, adjectives) text; no new tempers.
- Read: docs/plans/ui-small.md
- Files: Scripts/HUD.gd, Scripts/Guide.gd, Scripts/Bio.gd
- Model: sonnet/medium
- Collides with: HUD cards

### Unbounded maps, camera and spawning
- Source: docs/todo/systems.md:46; docs/plan.md Phase 7 item 27
- Scope: a map that streams chunks, a camera that pans and follows units, spawning out of view (`Battle.summon()` is the start); Infernal Meadows' 30-kill portal stays a later battle.
- Read: docs/plans/route.md, docs/plans/path.md
- Files: Scripts/Battle.gd, Scripts/Overlay.gd, Scripts/Camera*.gd, Scenes/
- Model: opus/medium
- Collides with: nearly every Battle and Overlay card; run alone

## Needs the user (not queued)
- Test stubs, Option A or B: ?144.
- Winded's meaning: ?126. Burnout: burnt max, out-of-combat, other gains: ?121. A Life tree: ?121, ?122, ?124.
- Price table or computed prices: ?131. The 27 concrete skills: ?133. Retuning colours: ?125.
- `Unit.guard` on helpless: ?127. 0-AP actions while tapped: ?119. Merchant tree for Drone: ?119.
- Item rank-up and enchant rank, lent skills as prerequisites, sources for the Habergeon family: ?118, ?143.
- Snapped forms (Gallantry, Final Act): ?140. A flank or rear rider skill: ?142.
- Gods and classes not designed: Divinity trees for Ramut, Urlo, Drael, Vetruvis, Survival skills, Paladin leadership Flex, burn tier cap (?122, ?81); Wizard and Mage real trees (?70); Martial and Specialist roots (?15); more Rogue, Bard, Luun, Elmon and Hogel skills; the cut-off Demon / Warlock / Dark Magic skill; Skill Slot +1, Trade Skills, Grind (?2, ?3, ?11).
- Inspire, Sundering, Silent Strike and Sunder (?13); Charm (?14); Discipline's initiative half and the Pike unit (?80, ?82, ?120).
- Energize and Power Transfer (siphon-sorcerer plan: named, not defined); Commitment to the bit (a Cultist tree); clout earned in play and more tempers (?91, ?93); more resources (Rage, Hype, Clout, Gold) and shops; round and initiative lines using the arrow (ui.md:8); Astral Envoy tuning (?29).
