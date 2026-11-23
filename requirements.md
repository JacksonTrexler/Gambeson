# Gambeson: project requirements

The short list of decided rules and principles, one per line, that a host or builder reads first. Last refreshed 2026-11-19 (questions to ?204). `docs/done/rules.md` holds each rule with its worked numbers; `completed.md` indexes what is built; `todo.md` holds only open questions. Do not delete either.
Format: `(?N)` the question it came from; `[user]` the user's own wording or answer, `[call]` a builder's call the user has seen and not objected to ("kept as built").

## Standing principles
- Skills are data first (`Skills/*.tres`); anything new a skill does is a `Behaviours/*.gd` hook with `apply()` and `describe()` together, never a new `Skill.gd` flag. [user, CLAUDE.md]
- Composable over sandboxed: shared tags and generic hooks, no "hoagie token only hoagie skills use"; unintended interactions beat tightly coupled systems; do not over-abstract. [user 2026-11-12]
- Unit, Battle and HUD stay loosely coupled: a unit emits a signal, Battle dispatches to behaviours; no Battle reference handed to a Unit. [user]
- Any tag or element can be a modifier on any eligible skill; a new eligible tag works with no further code; a skill too concrete to take modifiers should be parameterized, not exempted. (?131) [user]
- A skill that does not scale well is a signal to parameterize it on rank and stats, not to hand-tune a number. (?152) [user]
- No balancing for now; if a skill is underpowered, tweak its check difficulty. Effects that stop a unit taking useful actions on its turn are precious and priced high. (?152) [user]
- 20/80 everything: ship the useful 20%, build the framework that keeps work correct and quick. (?144, 2026-11-16) [user]
- Lean tests: consolidate 20/80; data-driven table tests over a file per skill; functionally identical skills with different flavour are covered by tests of the core skill or mechanic (Option A: only a skill with a `Behaviours/*.gd` gets its own test file). (?144) [user]
- Test hardware assumption: M3 Mac is about 4x the target device; prefer big sims (10 rangers vs 10 hiders) to many small tests; busy fights wanted. Budgets: 200 ms a unit turn (raised 2026-11-23: players must not wait on large factions, so a unit plans in its own frame under the walks), 1000 ms an `end_turn` and a side's player stare at M3 x 4. (?183, ?257) [user + call]
- Every name an AI makes up gets " ??" (skills `ai = true`) until a person reviews it; a name the user gave goes in as given. [user, CLAUDE.md]
- Terms: "Arcalís" for arcane/magic broadly; preferred terms in docs/g-dictionary.md, lore in docs/g-glossary.md. (?180) [user]
- Art is a placeholder PNG at a fixed path until real art replaces it. (?95) [user]
- Choose sensible numbers where none are given; every number stays exposed in the editor. [user]

## Core rules and rolls
- Rolls: attack = d20 + stat mod vs Defense (meet it to hit); a skill may declare its own check (stat vs stat, contest, save); every d20 goes through one Check resolver and the HUD and AI forecast from it. (?5, ?141)
- Checks first: a passed check almost always does something. Hostile skills without damage roll too; effects land on a hit. (?5) [call, kept as built]
- Defense is armor's, raised or lowered by effects; mitigation is a separate % cut capped at blocking 100%. (?47)
- Damage floor: attacker-side effects cannot take a hit below 1. (?1) [call]
- Luck: divisions round down, up for positive luck; luck rounds level/4 up into a clover slot, untyped. (?6) [call]
- Level is a plain stat in XP: (BST + level)/7, requirements 20 x n log2 n, cap 20; XP shared among nearby standing units, two shares to the killer. (?78, ?79)
- HP: class units start from a base of 5. (?61) Power reads as fullness % / 20. (?62)
- Last stand = d20 + average stat mod (whole-unit defensive check); Level Down and Death roll against it. Execute: defender's roll is scaled by HP left / max HP / rank.
- Effects last that many of their side's turns; the current turn does not count if applied on that side's turn. Easy-to-remove effects take several ranks to cleanse (Level Down 2, Level Up 4).
- Facing: a unit faces along its last intentional move (start to finish) or last aim, whichever is latest; only a unit's own intentional actions turn it: being hit, pushed, pulled, warped or teleported does not; fear and entrance are the unit's own move, so they turn it and cost movement AP. Rear attacks need 1 less. (?142, ?188, ?192) [user 2026-11-18]
- Critical hit on a miss becomes a `glance`: half regular damage, but a hit regardless. [user 2026-11-18]
- Downed: a unit on its last life lives on at 0 HP; hearts and a Red Spinel Ring go first; helpless means no acting but still hit, healed and targeted; Downed units are tapped (the berserker variant acts as normal on Borrowed Time). (?85, ?119)
- Tapped is derived from sources (out of AP, ordered to cap, helpless), never cleansed; Stunned is a tapping `wound`, easy to cleanse (rank halved), healed by an active heal. (?119) [user]
- Wounds are cleared by a heal of equal or higher rank. Heals and Energy grants report through one signal. (?121)
- Execute-style and tap-style effect checks get the Intervention bonus whether or not the developer knows the skill (a generic hook). (?85) [user]
- Contact with a concealed unit that blocks a move gives 1 recon. (?68) [user]
- Allies never fight each other, win together, are commanded only by their own leader; allied factions glow a distinct colour (default green), not grey. (?83) [user]
- Command limits: at most cha mod (min 1) allies a turn and as many orders each; effects do not raise them; Telepathy and Word to the Wise substitute rank and wis. (?60, ?86, ?120) [user]
- Water: depth in unit sizes; submerged when deeper than size; drowning only held and submerged. (?72)

## Skills and costs
- Skill cost is part of identity (AP-heavy, resource-heavy, a preferred resource); a baseline algorithm reads tags and how far parameters scale (rank may scale cost a lot); "high mana cost, low ap cost" should be trivial to configure. Hand-set costs are kept. (?131) [user]
- Cost model: damage intensity is the base; added for rank bonuses and unique effects; tapered by activation restrictions; reduced by penalties and for adjacent; rank range neutral; extremes grow exponentially, penalties reduce flat. (?131) [user]
- Modifier symbols (rho, sigma, lambda) and the rank-scaling factor RSC on sigils, crests, badges, insignia. (?131) [user; exact readings in docs/todo/systems.md]
- Rank: no cap; unlock 1 point; rank r to r+1 costs 1 + r^2; efficiency (+/-) from traits, skills and debuffs must matter to how many points a unit can invest, through one uniform cost system. (?58, ?97) [user]
- Tiers: a skill needs (its tier - 1) learned skills; start-of-game skills are tier 0; tiers set by tree shape.
- Magnitude tags scale by rank: faint .5, mild 1, moderate 1.5, strong 2, intense 2.5, severe 3, overwhelming 4. (?63) [user]
- Higher ranks do more with AP, scalable with stats or rank, with depreciating then linear returns (Discipline). (?80) [user]
- Exhaustion: mild until the 2nd use of one skill, the 3rd caster skill in a row or the 4th different skill in a turn; +0.5 of base cost per use, half-weight for the rest of a broad kind, counts fall by 1 per side turn, resting adds con mod; kind by tree beats tag; every `int` skill also takes Burnout (harsher on Mana). (?87, ?98, ?195) [user 2026-11-18]
- Channels: one rule for all; held only if the unit spent no AP and did not walk; free recasts, 0-AP actions and reactions do not break one. (?97)
- Reactions: one hook, contests won by the reactor on ties, an interrupt turn is one free skill use. (?140)
- Resources: Mana, Stamina, Focus, Overcharge, Energy follow the rules in docs/done/rules.md and docs/todo/systems.md "Resources". (?98, ?100, ?116, ?117)
- Forced moves: pushes do no damage on impact but a stopped push slams (SLAM 2 blunt per tile unspent); teleports spring traps, no trail; executes cut saves and drags, not Defense. (?68, ?146)
- Summoned units spend all but rank + cast mod AP on spawning. (?181, ?197) [user 2026-11-18]
- Parameterized means the skill declares its channels and every read goes through the holder's modifiers; the skills screen shows base values. (?133, ?134)
- Strike rules apply only to skills tagged `strike` (Strike, Waterstrike, Silent Strike; also a chained Strike, to its component): Backstab (rank crit ease), Glancing Strike (first rank rolls of a use at disadvantage, both-not-miss hits as glance), Heavy Strike (a use's blows pooled), Chaser (procs rank times); the `friction` tag gives rolls past a looping skill's first rank disadvantage and a growing -1. Per skill use, not per chain. (?186, ?193, ?202) [user 2026-11-18, 2026-11-19]
- Striking Features / Striking Intellect: cha / int may be the strike mod. (?189) [user 2026-11-18]
- `shove` only on skills whose force moves a unit; `cc` on anything that impairs acting. (?146, ?192) [user 2026-11-18]
- Density, Diluted and Cram: a skill is eligible if it has rank impact and something to trade (range, a check, a slot a foe can disable, a penalty); dense scales harder with shorter range and harder checks for its user (easier for foes), diluted the reverse; as few skills as possible are ineligible, each with a declared `no_density` reason; slot counts double under Density and Cram's penalties scale. (?185 to ?191, ?198, ?203) [user 2026-11-19]
- Balance knobs: an optional scaling coefficient on Impact, Range or Modified (`Skill.scaling`), and the `β` and `d` (Cohen) tags, tweak an obviously dominant or weak skill without asking; not applied defensively, kept in the back pocket; β and d show only to a viewer with `very high` int; one skill each carries one to test, then left alone. (?204) [user 2026-11-19]

## Wave 5 rules (2026-11-19)

- Student is Mage-only; others reach it through a flex tree choice or an adventure. Journeyman is an optional Martial/Specialist tree (Physical Intelligence: Int mod to Str checks; Muscle Memory: Wis mod; up to rank). Armor is an equipment skill, never a hotbar skill. (?199, ?196, ?208)
- Burnout is Exhaustion functionally (one count). (?195, ?209)
- "High", "very high" and the like are synonyms on one check-difficulty table (`Difficulty.WORDS`), used everywhere a difficulty is set. (?204, ?211)
- The no-new-flags rule is relaxed: restrict creep, confirm new flags. (?203, ?210)

## Wave 6 rules (2026-11-20)

- Equipment links: `optional` and `innate` are flags on an item's link to a skill, not on the skill; armor lends Armor innate. (?196, ?214)
- Multi-slot skills: 1 slot by default; a rarity takes Rare 2, Epic / Very Rare 3, Legendary 4, Mythic 5; an explicit slots property overrides. (?215)
- Party size is max(base cha mod, 0) + max(level / 4, 1); size 1 is solo (a unit with nothing to market goes alone); the player's units persist in a roster. (?216, ?226) [user]

## Wave 7 rules (2026-11-20)

- Facing shows only to a viewer with "high" wisdom, as a subtly stronger glow on the facing side, not an arrow. (?218)
- On level up a unit's glow flashes to 2x; a higher level is a subtly larger glow, a lower one smaller, unless the glow is showing targeting. (?221)
- Preparation uses (Study, Surveys, Evaluates, Inquisitions) share one table; the top box lists them. (?219, ?222)
- Bard: String Theory, Conductor, Symphony (First Chair); `impact` is a Glossary term. (?220)
- Placeholder art comes from `/Users/jtrex/assets/utumno` where a name fits. (?223)
- Passives show muted until they act; an acting passive signs itself (a slot lighting or a floater, "Name +amount", in the tag colour), with nothing measurable added to a fight; rounding shows italic (down) or bold (up). (?224)
- The hotbar wraps into columns on wide windows; a description has one lead per "On <who>" line. (?225)
- Skill names are unique (`skill.py check` holds it); a ?? goes on an AI-invented tag's shown name only, never its id, and never on the user's words. (?227) [user]
- A skill an item lends is free by default (no slot, equipped while worn); `optional` is the link that costs a slot and is slotted by choice; the band under the hotbar holds slotless skills, activatable ones first on the next number keys. (?228) [user]
- Skill icons are coloured art or white placeholders; placeholders are tinted by state, coloured art is only dimmed. (?229)
- A band's names show whole and a multi-slot skill is one tall button kept whole across a column break. (?230)

## Equipping and traits
- Every skill, active or passive, does nothing unless equipped (and toggled where relevant): auto-equipped on learn when a slot is free, manually when the bar is full; AI included. (?163) [user]
- Slots: 4 + level/4, typed (martial, magic, specialist) or untyped; passives take the last slots; losing a slot depends on why. (?3) [call]
- Traits are special: always on the hotbar, never count against slotted skills, kept at the far right, cannot be disabled like skills, do not change disable order or enchant ranking. Suppressing traits stays possible for utility (e.g. "disable unit traits for rank rounds"). (?163) [user 2026-11-18]
- Skill Slot +1 is a hotbar trait; always-on passives show no on/off indication; traits are declared through the tools, not inferred. (?3, ?165, ?194) [user 2026-11-18]
- Disabling takes slots from the right; pillar skills resist; enchant ranks leftmost skills. (?163)
- A worn item's lent skills sit on the bar while worn and are never ranked; the rank comes from the item; an item's enchant enchants its lent skills (+1 rank unless a skill has its own enchant effect); armor's Defense is the `equipment` skill it lends; lent skills count as prerequisites, and a skill learned on one lapses with it. (?143, ?196) [user 2026-11-18]
- Item rank: rarity multiplies rank cost in one table; `enchanted` and `honed` are exclusive +1 rank tags; everything scaling by item rank reads `ranked()`. (?118) [call]
- Emblem symbols: sigil leftmost eligible, insignia all, crest actives, badge passives; the emblem's rank sets efficiency. (?131) [user]
- Equipping drag, auto-equip toggle (global), saved set. (?163, ?145)

## Units and perception
- Persona (what a unit shows) can differ from the unit; dissonance measures how far a lie is by distance in natures; clout adds to persona rank. (?93, ?152) [call]
- A unit is a silhouette when it knows something is there but not what (fog, dark, murky water); silhouettes are targetable; suspicion alone is enough; four glow strengths. (?84) [user]
- Attacking a concealed friendly: a hidden wis check; passing prevents the attack, grants recon, interrupts like a jam. (?84) [user]
- Suspicion is tracked per unit; while commanding a unit the player sees through its eyes. (?96, ?99) [user]
- Tempers drive the AI: timid craven, brave and aggressive charge, helpful walks to the wounded, stoic holds. (?91)
- Sight is shared across a side but reads stay each unit's own; sides remember foes and hunt where last seen. (?77)
- In the Meadows a tile beyond perception cannot look suspicious. (?175) [call]
- Stat points: Meditate trades up to rank points a use between core stats only. (?57, ?120) [user]
- Specialisation: guest trees of Ranger/Druid/Paladin/Warlock come from capstones and gods; one god system; choosing a god grants its domain and unique trees. (?65, ?81, ?122) [user]

## AI
- The AI reads the same hit chances and forecasts the player sees; no AI-only knowledge of a skill beyond its generic hooks. (?138, ?170)
- AI weights are guesses kept in constants, tuned by sims, not by hand per skill; tuning is secondary to rules. (?162, ?177)
- AI acts through the equipped set only. (?163)
- AI is not given a special case for any skill; it reads `restores()`, `neutralized`, `wearing`, `foils`, `strides` and the like. (?130, ?182)
- Units act together in batches; each still decides in turn. (?104)
- **A unit's behaviour should be inferable from the unit itself** (the user, 2026-11-22, a rule of thumb): prideful, pitiful, pragmatic, capable; reads as plain targeting, going for downs, squaring up, hedging. Player units and those they command have behaviour too (autobattle if ever built; control stripped by cognitive disruption). `docs/agents/answers-2026-11-22.md`.

## UI
- No static hints on screen; dynamic info only (tooltips after 1 s, forecasts, status lines). (?83)
- Bars show estimated consumption (a plan's AP, a known trap's hits) with as little text as possible; a unit predicts only int mod expenditures. (?90) [user]
- Suspicion marks: "?" first suspicion, "!" seen through, faction colours as unaffiliated until revealed; the card reads "?". (?84, ?96) [user]
- Glow: only for faction and attention; most units show normal colour. (?83) [user]
- Terms in place of dice in the Guide; the Guide stays in sync with rebinding. (?136, ?168)
- Pace: spent unit passes focus on the player's turn; hold the Hurry key for x4. (?129)
- Entry: preparation, level box 1-20, Continue and New game. (?105, ?145)

## World
- Gamut's Tower: three floors, six portals; the Astral Envoy and lattice; items from bosses, commanders and scenarios; the Center and Lancin lore lives in g-glossary.md. (?77, ?180)
- Properties tag their unit and carry resist/weak numbers (Aquatic, Energized, Radiant, Rotting). (?92)

## Tooling and tests
- New content goes through its tool and process in `.claude/skills/` (skill.py, tile.py, role.py, unit.py, item.py, mechanic.py); run each `check` you touched and `skill.py check` before committing. [user, CLAUDE.md]
- Tests: `godot --headless --path . -s Tests/run.gd -- [words]`; a compile error hangs it; sims live outside the suite. (?144, ?183)
- Large `.gd` files: grep and read ranges, never whole. [CLAUDE.md]
- Delegation: a host splits work into builder tasks on cheaper models in worktrees, wakes about twice a prompt for under 2 minutes, a floater runs merges/verify/docs; calls recorded as numbered questions. [user 2026-11-16]
- Saves: progress only (JSON, `user://save.json`); settings stay in Prefs. (?145)
- AI 20/80: shortcuts that cut processing time are welcome; a calm follower of a skilled leader (`Command.skilled`: tag `leader` or cha 14) drills without its preferences unless hurt, cc'd, betrayed or its leader is lost. (?256, ?271) [user 2026-11-23]
- Tests are not overly concrete: relations to the data over pinned content, 20/80, consolidated but not too far; `busy_fight` checks outcomes, not a digest. (?257, ?258) [user 2026-11-23]
- The investigation system (trickery, persona, concealment, suspicion) must exist: lost parts are recovered or rebuilt. (?255) [user 2026-11-23]
- Wait length scales with interest: the more worth watching an enemy's turn, the longer it may take; surprising decisions and first-time consequences pop up like skill activations. (?257) [user 2026-11-23]
- Ambush is the first attack roll out of concealment, usually only the first attack; Sally: +20% damage a rank on an ambush; Ambush Fusillade: ambush and its triggered effects proc on rank more rolls. (?269) [user 2026-11-23]
- Tests: audit what 20/80 lost, mark what carries regression risk, run by segment (`t.sh <wt> <segment>`, `risk`). (?268) [user 2026-11-23]
- Astral Nexus (tower): generators, a broken startile grid, starpanes, astral void, 4 to 6 hostile starmen; the Power Star (Power-only energy potion, overflow Power at rank x 15%) drops. (?267) [user 2026-11-23]
- Ire sits on Ramut's tree. (?270) [user 2026-11-23]
- Vindictive units focus those who landed blows on them or an ally (2 a blow, cap 3) or whom their Bio names; flirty units give support first to, and soft skills toward, those they fancy (Bio words, else cha 14); first-time "Grudge" and "Smitten" pop up like skill activations; the HUD holds 0.3 s a sign, 0.9 s at most. (?271) [user 2026-11-23]
- Cheap macro decisions: 3 or more like units (side, class, race) share one plan a side turn and stay within 3 tiles; target superlatives (HP, physical, magical Defense) kept sorted per side. (?272) [user 2026-11-23]
