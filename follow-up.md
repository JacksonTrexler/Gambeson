# Follow-up worksheet (2026-11-23)

Answer inline after each `Answer:` (a word is enough: "ok" takes the best guess; "skip" leaves it as built), then say **continue**. Where you leave one blank, the best guess is what gets built and recorded as a numbered call. Ids: `?NNN` is an existing question in `todo.md` (detail in `docs/todo/*.md`, `docs/plans/*.md`); `F1` to `F30` are new, from your 2026-11-23c answers (`docs/agents/answers-2026-11-23c.md`, wave 18). Already answered and left out: ?278 (clean up leaks), ?279 (camera, now wave 18), ?276's old form, delete the merged branches, the Nexus void and generators (now F-items), ?255, ?256, ?216, ?218, ?220, ?222, ?223, ?214. Everything still open in `todo.md` that nothing waits on is batched under "Standing calls" in each group: "ok" keeps it as built.

Blocking order inside each group: first items hold up the most wave 18 cards (A hscroll, B camera, C leaks, D nexus, E starmen, F fog, G flex, H jester, I monster, J theseus).

---

## 1. Items and dungeons (wave 18 D, E)

**F1. Pane and tile: which is which, and what does "x" and "base power" count?** Your rule: `pane * base power, tile * x, (Gen), tile * x, pane * base power`, rows and columns alike, diagonals panes, "the generators should basically be in a wired circuit". Two readings: (a) a run of that many cells; (b) a weight. Your 2026-11-23b spec had startiles forming the grid round each generator and starpanes filling the gaps, which puts tiles beside the Gen (the wire) and panes outside, and that matches the rule as written.
Best guess: as written. Along a row or column from a Gen: `x` startiles, then panes up to the next Gen's tiles; `x` = 2, "pane * base power" = a run of 2 panes (base power = a constant, not a unit's reserve); diagonals always panes. Record the reading in `docs/plans/w18-nexus.md`.
Ref: `Scripts/AstralNexus.gd:9-14,53-70` (now `REACH` 4 square, `BROKEN` 0.25, `VOIDED` 0.15, startile on every even offset); tiles `Terrain/startile.tres`, `starpane.tres`, `cracked_startile.tres`, `starpower_generator.tres` (`passes`, `source`).
Answer: **x is radiating power from sources. signal decays by "1" each discrete tile away (diagonals count for two, one horizontal, one vertical). These signals interact with powered effect tiles, as well as with starpanes and startiles to create latticies / surfaces in the astral. every 20% power produces 1 tile of signal traveling along generators and wiring, which is needed for star flooring to exist, build out, and maintain itself.
If I recall: Starpanels carry power current and emit signal, generators collect and distribute power to nearby tiles and units, and Startiles are somewhat fragile but otherwise reliable flooring that self-regenerate when powered.
New tile type: Stardust: linger after startiles are broken. If powered they'll eventually regenerate into a startile. It takes y turns, with y being the signal distance from the nearest power source.

give generators in nexus / starnests rank 5, and starpanels rank 1: starpanels create and maintain walkways with generator power. generators have larger platforms they exist on.

Wizard, astral mage t3: Starpower: Mana is Power: now called Starpower. It regenerates like Power and can be used like Power **only for power exclusive skills**: cannot be used as energy. +Rank Starpower. `Starpower` is greenish teal
Wizard, mage: Mana Resonance: Unit energy is now mana. Abilities that use energy consume AP instead. Exhaustion penalty, base + base* (1/rank)
*icon is blue star with yellow circle behind*

Astral skills for Wizards, Mages, Sorcerers, adventurers.
these require Power
t1: Startile: place a startile within rank range. Seals 1 power until tile is destroyed. It lasts for rank rounds unpowered.
t2: Starbridge: Connect two powered tiles with rank columns of Startile. Each tile seals 1 power.
t2: Starpanel: Place starpanels in a line, up to casting mod + rank tiles away. They each seal 1 power until destroyed.
t3: Starpower Geneerator: Startile but it's a starpower generator. It shares rank with skill. Seals 1 + 10% * rank power until destroyed.
t6: Starway: On a percieved Startile, create a pair of Starway tiles. When powered they have entrance effect: relocate unit to paired tile. Has mod stat total + rank range.


t7 Manifest Starchitecture. Cheap. Unit may configure and utilize Starchitect hotbar to create. `pillar`. Dismissing and returning to regular hotbar is free. Divide cost of first rank casts cost by rank, aside from power `seal` effects.

t9 Starnest: Creates rank generators, linked horizontally or vertically by starpanes, which support new startiles layered on top of existing tiles. (Use procedural generation rules for starnest setpieces). Seals 20% * rank power. can go negative as reserve debt.

`Negative Energy`: some skills and effects allow for negative energy gain past 0. In these circumstances the debt must be paid before new energy can be gained. There is a % energy gain penalty based on the overage (-100% of energy means 0.5 efficiency gains, -50% means 0.75 efficiency etc.)



**F2. "Live circuit" for Power Siphon.** Which tiles count as live?
Best guess: every startile connected to a generator by an unbroken run of startiles (4-neighbour; a cracked or missing startile cuts it); a generator's own tile is live; panes never are. A unit on a cut-off startile gets nothing.
Ref: `Scripts/AstralNexus.gd:102 _connect()`; `Terrain/starpower_generator.tres`.
Answer: ____

**F3. Power Siphon's numbers.** "Draining 5% health on turn end to gain 5% power, from each unit standing on the live circuit." 5% of max or current HP? Allies and the foe both? Can it kill? What is "power" for a unit with no Power reserve (Energy share)?
Best guess: 5% of max HP (at least 1), floor at 1 HP so it never kills; every unit on the circuit, either side; gains 5% of max Power if it has the reserve, else nothing (still drained: a trap, as built for pits). Runs in the owning side's turn-end, once per unit a turn.
Ref: new hook beside `Terrain.gd` tile effects; `?267` says generators are inert today; Power reserve in `Scenes/starman.tscn`.
Answer: ____

**F4. How much larger is "a little larger"?** Today 23 x 13 with 3 generators.
Best guess: 31 x 17, 5 generators sprinkled (not in a line), `START` on the left edge; 4 to 6 starmen as now.
Ref: `Scripts/AstralNexus.gd:9-11` (`WIDTH`, `HEIGHT`, `GENERATORS`), `Scenes/astral_nexus_play.tscn`.
Answer: ____

**F5. Astral void is impassable, but a pit you can jump.** Does a unit that jumps onto a void tile fall, or only across it? Do flyers and floaters stay up on it? Do hostile NPCs with no Jump treat it as a wall for pathing?
Best guess: a jump must land on non-void; "floating or flying" (a `float` / `flight` tag) ignore it; void is a wall in `AI` paths and the Path overlay (enter cost 99 today stays as the "impassable" for walkers, ?267).
Ref: `Terrain/astral_void.tres`; grep found no `jump` code in `Scripts/Unit.gd` or `Battle.gd`, so Jump is new, build on the push / teleport movement.
Answer: ____

**F6. Same tiles as the astral envoy encounter.** Reuse the envoy's tile resources (`Scenes/astral_envoy.tscn`) in the Nexus. Does the envoy fight pick up the generators and Power Siphon too, or only share art?
Best guess: share the resources only; the envoy encounter stays as it is (its tuning is ?29).
Ref: `Scenes/astral_envoy.tscn`, `Dungeons/astral_nexus.tres`.
Answer: ____

**?267 (rest). Power Star.** Win reward at 15% a rank, charge lost on save, starmen on the unaligned faction. Still right now that the starmen are Vindictive towards hostile astral creatures (F8)?
Best guess: keep; the Envoy and Princess stay on a hostile faction, starmen "unaligned" so Vindictive has someone to hunt; no loot change.
Ref: `Dungeons/astral_nexus.tres`, `Items/power_star.tres`, `docs/plans/w16-nexus.md`.
Answer: ____

**Standing calls (items):** ?118 item rank-up and the Habergeon sources; ?212 Send Off's ward on a foe sent away; ?213 `Unit.pack`, `POINT`, `DELAY`, Astral Princess loot (`Loot/astral_princess.tres`); ?228 free lends, Hollow Bones' flight and defense, the plain lend free for Broadsword, Hobnail Boots; ?249 are all item icons committed. Best guess: keep all as built, say so below.
Answer: ____

---

## 2. AI and behaviours (wave 18 E, F)

**F7. Fog radius in tiles (blocks F).** "Units can only see others within full wis range; tiles outside are in the fog of war." Sight already exists: a unit's reading range is its wisdom total in tiles, shared by its side, with appearances only inside half of it. So is the fog the full range, per unit or per side, and is it the same number?
Best guess: reuse the existing number (wisdom total, one tile per point, the full ring, not the half); the fog is the union over the player's side (any ally sees), drawn dimmed over unseen tiles, terrain remembered once seen, units there hidden; the AI uses the same `in_range`, so no new cost.
Ref: `Scripts/Battle.gd:219` (`sight`), `:4973 in_range()`, `:4719 beyond_sight()`, `Scripts/Perception.gd:492 _range()`.
Answer: ____

**F8. Vindictive (starmen) against the existing vindictive temper (blocks E).** The temper exists: `Bio.BEHAVIOURS` vindictive "goes after whoever hurt it or its own", grudges by name, class, race or tag (`Unit.wrongs`, `AI._grudge`). Your starmen Vindictive: "singlemindedly prioritize hostile astral creatures in combat if not otherwise aggressed". One rule or two?
Best guess: one rule. A starman's Bio carries `behaviour = vindictive` with `grudges = ["astral"]` (a tag), so it starts with a standing grudge on any hostile unit tagged astral; being struck by anyone else adds that attacker's side (existing weights, 2 a blow, cap 3) and "otherwise aggressed" = the new grudge outweighs the standing one.
Ref: `Scripts/Bio.gd:9,18,39`, `Scripts/AI.gd:846 _grudge()`, `Scripts/Unit.gd:170 wrongs`, `docs/plans/w16-tempers.md`.
Answer: ____

**F9. Flippant: what is "a significant amount of damage"?** Skirts evasively or aimlessly until punished.
Best guess: 25% of max HP lost in one fight (any source), then it switches to `aggressive` for the rest of the fight; aimless = a random walk to tiles out of foes' reach, cheap (no scoring), so the turn budget is untouched.
Ref: `Scripts/Bio.gd:18`, a new branch in `Scripts/AI.gd` beside `_recover` / `_escape`.
Answer: ____

**F10. Power Hungry.** Moves beside the target with the most Power (else Energy, else other reserves) and transfers energy, also from neutrals. Does that count as a hostile act (neutrals turn hostile)? Which skill does it use?
Best guess: not hostile (neutrals stay neutral), uses the existing Energy Transfer (`Skills/energy_transfer.tres`, `Behaviours/energy_transfer.gd`) as its only skill, "high" = largest share of its max, it won't drain below 25% of the target's.
Ref: `Behaviours/energy_transfer.gd`, `Behaviours/energize.gd` (named, not defined), `Scripts/AI.gd` `_strike`.
Answer: ____

**?270. Ramut's Ire: does it need a cost? (still unanswered).** Built with none, on its holder, tier 2 after Pray.
Best guess: no cost (it is a reaction to being wronged and "lands on its holder"); keep tier 2.
Ref: `Skills/ramuts_ire.tres`, `Trees/ramut.tres:7-11`, `docs/plans/w16-ire.md`.
Answer: ____

**?257, ?243, ?260, ?266. The AI's time budgets.** Unit turn 200 ms, a side's end_turn 1000 ms on the target (M3 x 4); the 30-a-side stare p95 ~950 to 2050 ms with a ~5% margin. Acceptable, or keep cutting?
Best guess: acceptable ("raise the budget provided players don't actually spend time waiting"); no more cuts unless a swarm gets slow. Optional micro-cuts stay unbuilt: `end_turn` stat reads, a path round a unit's own column (?266), Opportunist on `_recover` / `_escape` / `_hunt` (?263), `Battle._enter` (?265).
Ref: `Tests/sims/busy_fight.gd:25-26`, `docs/plans/w13-aifast.md`.
Answer: ____

**?271, ?272. Tempers and herds, as built.** "Grudge" pop-up shares the Grudge skill's name; weight 2 a blow cap 3; flirty cut cha 14; `SIGN_HOLD` 0.3 s; "skilled leader" = tag `leader` or cha 14 (no unit has the tag, no Glossary entry); herd size 3, `COHESION` 3 tiles, herd members in a fight take full turns; no test for the soft strike.
Best guess: keep; add a `leader` Glossary tag and one soft-strike test when next in the file.
Ref: `Scripts/AI.gd:87`, `Scripts/HUD.gd:2181`, `Scripts/Command.gd:63`, `Scripts/Battle.gd:1873 first_time()`.
Answer: ____

**?269. Ambush as built.** Stretch = since its side's turn began, a miss uses it up, Sally 20% a rank, Fusillade's rank extra rolls, the Ambush skill a flat melee dex blow. Spelling: you typed "Fussilade", built as "Fusillade".
Best guess: keep all; keep "Fusillade".
Ref: `Scripts/Unit.gd:392 ambush_rolls`, `docs/plans/w16-ambush.md`.
Answer: ____

**Standing calls (AI):** ?130 a unit with one toggle and no pool holding enough stays put; ?233 `AI.LOST` 0.35 (`Scripts/AI.gd:43`); ?244 `AI.BLOCKS` 3 (`:75`); ?252 `AI.STRUCK` 0.5 (`:79`); ?253 a striker counts only if it can fund its skill, AP not asked; ?246 Opportunist's "ran into" = a walk ending beside it, first active, faction not read; ?250 the react filter by the `reaction` tag; ?206 cc priced `BLOW` 5, `CC` 0.5 (`:74,76`); ?260 `HUNT_FAR` 2.0 (`:84`); ?264 `SUSPECT_TILES` 3 and stacks 3 (`Scripts/Battle.gd:244-245`); ?261 Detective observes inside `survey()`; ?217 Skeleton's AI numbers; ?238 the Disturbed soft cap leaves a low-int caster no summons; ?262 and ?255 closed by ?269. Best guess: keep all as built.
Answer: ____

**F31. Void, jumps and Hop as built (wave 18 E; see ?288).** A jump lands only where its jumper can stand (never on void unless it floats or flies); walkers keep void as enter 99; units with a jump skill leap on their approach when it brings them nearer. Hop is an innate active (1 AP, 1 Power, radius 2) rather than a trait, because a trait is always-on.
Best guess: keep as built.
Ref: `docs/plans/w18-starmen.md`, `Scripts/Battle.gd` `footing`, `Behaviours/jump.gd`, `Skills/hop.tres`.
Answer: ____

**F32. Starmen tempers: weights and thresholds as built (wave 18 E; see ?290, ?291).** Several tempers a unit (`Bio.also`); the astral grudge is weight 5 (a standing grudge) against 2 a blow cap 3 = 6, so a foe that strikes it three times outweighs the astral grudge; Flippant turns aggressive at 25% HP lost, Power Hungry skips targets under 25% of their reserve, and takes from neutrals without making them hostile.
Best guess: keep as built (no balancing now).
Ref: `Scripts/Bio.gd`, `Scripts/AI.gd` `_feed`, `_richest`, `_skirt`.
Answer: ____

**F37. Fog of war as built (wave 18 F; see ?297, ?298).** The fog radius is the unit's sight (wisdom total, the full ring), union over your side; clear in sight, dimmed (0.45) where seen before, darker (0.75) never seen, terrain faintly visible; "remembered" is only the dim shade, not a frozen copy of the ground. The AI needed no change (already sight-gated), though it does not yet path by explored ground.
Best guess: keep as built; frozen look and AI pathing are later cards.
Ref: `docs/plans/w18-fog.md`, `Scripts/Overlay.gd` `fog_of_war`, `Scripts/Battle.gd` `sight_cells`.
Answer: ____

**F42. The AI and Power Siphon as built (wave 18 follow-ups; see ?310 to ?312).** The AI prices the siphon as turn-end HP on a live-circuit tile (through `Battle.hazard`, so the HUD forecast shows it too); the Power it gives is not weighed, generators do not recharge from it, and the price reads the true circuit.
Best guess: keep as built; weighing the gain and the recharge are later cards.
Ref: `Scripts/Battle.gd` `hazard`, `_owe_wound`, `docs/plans/w18-ai-siphon.md`.
Answer: ____

**F44. The AI and the fog (wave 18 follow-ups; see ?315, ?316, ?319, ?326).**
Best guess: keep as built. The AI reads `explored` (never-seen ground by the unknown-terrain rule), filled lazily from the disc it plans from, so ground walked past but never planned from stays unmarked (card w18-fog-seen); the fog freezes terrain only, not ground effects, and not timed (card w18-fog-effects).
Ref: `Battle.known_ground`, `_mark_seen`, `Overlay.memory`, `docs/plans/w18-fog-ai.md`, `docs/plans/w18-fog-frozen.md`.
Answer: ____

**F45. A cornered Flippant starman holds still (wave 18 follow-ups; see ?325, ?326).**
Best guess: keep; Floaty never stalls, and a Flippant starman with every tile unsafe holds 3 to 4 turns until struck.
Ref: `Tests/stars_test.gd` `test_floaty_no_stall`, `docs/plans/w18-flip-test.md`.
Answer: ____

**F49. Generators recharging from siphoned Power (wave 18 follow-ups; see ?311).** The card w18-siphon-recharge (a starpower generator recharging from the Power siphoned on its circuit) was not built; you never asked for it, and it adds a mechanic.
Best guess: do not build.
Ref: `Scripts/Battle.gd` `_owe_wound`, `docs/plans/w18-ai-siphon.md`.
Answer: ____

**F50. The AI weighs a siphon's Power gain at 0.5 HP a Power (wave 20; see ?327, ?328).** A powered unit's siphon price drops by `SIPHON_POWER_HP` (0.5) HP for each Power it gains, never below 0 (a gain over the loss is a free tile, not a lure); Energy units unchanged. The 0.5 is a guess.
Best guess: keep as built.
Ref: `Scripts/Battle.gd` `_owe_wound`, `docs/plans/w20-siphon-gain.md`.
Answer: ____

**F51. The fog hides what is laid out of sight (wave 20; see ?331 to ?333).** Layers and marks laid on a tile out of sight, or never seen, are now hidden (they used to show live through the fog); a fire lit in the dark is not seen until the tile is seen again. Layers, trodden ground and marks freeze to their last-seen look; the lattice, debris and traps do not. No screenshot has been taken.
Best guess: keep as built.
Ref: `Scripts/Overlay.gd` `_ghost`, `_sighted`, `docs/plans/w20-fog-effects.md`.
Answer: ____

---

## 3. Skills and classes (wave 18 G, H, I, J)

**F11. Flex trees: the prerequisites (blocks G, H).** "Flex trees have prereqs, slackened for Rogues and Bards (`generalist`), none for Adventurers and Jesters (`jack`)". What is a prerequisite here?
Best guess: a flex tree needs one skill from the class's own root tree (or a minimum level / one rank in the tree's tier-1 skill), set per flex tree in its `.tres`; `generalist` halves it (rank 1 of any skill in the tab), `jack` skips it. Cadence as you said: one flex tree per 10 levels (Rogue, Bard 5; Adventurer 3).
Ref: `Scripts/Unit.gd:757` (flex slots, `burned()`), `:3031 grant_tree()`, `Scripts/Role.gd`, `Trees/general_student.tres`, `general_journeyman.tres`; the flex picker is still missing (?208).
Answer: ____

**F12. Scout flex tree: who and what.** "Ranger General, Scout Martial; Rogues, Paladins have Scout Martial as a flex option." Is Scout the Ranger's general tab itself, or a new martial flex tree the Ranger gets free while Rogue and Paladin choose it?
Best guess: a new martial flex tree `Trees/scout.tres`, free on the Ranger's General tab, a flex option for Rogue and Paladin; seed it with Perception-flavoured skills only (a stub like Student started, ?199).
Ref: `Trees/general_martial.tres`, `Roles/ranger.tres`, `Util/role.py include`.
Answer: ____

**F13. Which trees count as martial, specialist, caster flex?** Needed for the Jester's costs (F14). Student, Journeyman, Scout: which type each?
Best guess: Scout martial; Journeyman specialist (it sits on the martial and specialist tabs); Student caster.
Ref: `Trees/general_*.tres`.
Answer: ____

**F14. Jester's inverted page: cost size.** Unlock a flex tree by spending base stats: martial costs a chosen mental stat, specialist str or int, caster a chosen physical stat. How many points, permanent, and can a stat fall below a floor?
Best guess: 1 point of the stat per flex tree, permanent, floor 6 (below 6 refused); the tree still follows its normal cadence, `jack` (no prerequisites). The inverted page is its own tab mirroring the class page.
Ref: `Util/role.py`, `Scripts/Role.gd`; no `Jester` anywhere in the repo yet (grep).
Answer: ____

**F15. Jovia, the new warlock patron.** "Allows warlocks to use the inverted Jester tree." Does the warlock pay stats too, and what is Jovia's flavour (domain, tag)?
Best guess: yes, same stat costs; Jovia a trickster patron with `suit` neutral, tag `jest`; she burns one flex slot of the patron tree (like the other patrons).
Ref: `Gods/`, `Util/role.py god --patron`, `Roles/warlock.tres`.
Answer: ____

**F16. Monster class (blocks I, J).** Level-1 path chosen or preselected: starmen, Sirens, skeletons. "Monsters get their traits for free and may rank them up with skill points." Are these player-selectable, or NPC-only, and where do their other skills come from?
Best guess: playable and NPC; a path is one `Trees/monster_<path>.tres` whose traits are granted at level 1 (Floaty and Hop for starmen; the Siren's `Starkind` etc., existing traits ?185); other skills from the unit's own skills; the Siren, Skeleton and Starman scenes keep working unchanged.
Ref: `Scenes/starman.tscn`, `Scenes/siren.tscn`, `Scenes/skeleton.tscn`, `Util/role.py`.
Answer: ____

**F17. Floaty and Hop numbers.** "Floaty": Jump distance x (rank + 1), movement / (rank + 1). "Hop": an active movement skill, a small Power cost, performs a Jump. Whose rank, and which numbers?
Best guess: the trait's own rank (a starman has rank 1, so Jump x2, move /2, rounded up, at least 1); Hop costs 1 Power, 1 AP, Jump base distance 2, so a starman hops 4 tiles and walks half as far. Hop is the only Jump source until a Jump skill exists.
Ref: new traits next to `Skills/` trait files (`skill.py new --trait`); `Scripts/Unit.gd` movement.
Answer: ____

**F18. Thesis of Theseus: which classes (blocks J).** "Wizards, warlocks, dark mages, dark clerics": there are no dark mage or dark cleric classes (no `dark` tree; `Roles/` has wizard, warlock, mage, cleric). Where does it go, and what is "rank level"?
Best guess: a t6 skill (tags `dark`, `nature`) on the Wizard and Warlock trees only; "dark mage" and "dark cleric" read as a Mage or Cleric who took the Necromancy / death route (a tree not yet made, see ?240's death-cleric tree) so it waits; "rank level" = the summoned Monster's level equals the skill's rank; it uses the summon soft cap (?238).
Ref: `Roles/wizard.tres`, `Roles/warlock.tres`, `Skills/skeleton.tres`.
Answer: ____

**F19. Thesis of Theseus: the design step.** "Designing" a monster: just pick a path, or also choose its traits?
Best guess: pick a path only (starman, Siren, skeleton), the AI picks its own by what it lacks; the summon lasts the fight, uses summon AP rules (?197).
Ref: `Behaviours/` summon hook `summon_ap`.
Answer: ____

**Standing calls (skills):** ?185 more traits, whether `insignia` / `badge` reach a trait; ?186 tier placement of Backstab, Glancing, Heavy Strike and the natural-20 reading; ?189 Striking Intellect's placement and `attack_stat`; ?190 the 26 flat-rank profiles, 38 hand prices; ?191 the 22 concrete skills and Gallantry's check; ?192 to ?197 (cc audit edges, Chaser tier, Skill Slot +1 gating, exhaustion numbers, Wake and Rake); ?198 to ?201 (Cram, Defense adds, `postpone` / `overcome`); ?202 to ?204, ?206, ?208 (Journeyman tier 2 and max rank 5; the flex picker now rides F11); ?209 recoveries add Exhaustion uses; ?215 and ?216 roster, a fallen member; ?240 a death-cleric tree for Grave Aura (rides F18). Best guess: keep as built; ?209 no.
Answer: ____

**Design wanted (batch):** Divinity trees for Urlo, Drael, Vetruvis, Survival, Paladin leadership flex, burn tier cap (?122, ?81); Wizard and Mage real trees (?70); Martial and Specialist roots (?15); a Life tree (?121, ?122, ?124); Merchant tree for Drone (?119); Trade Skills and Grind (?2, ?11); more Rogue, Bard, Luun, Elmon, Hogel skills; the cut-off Demon / Warlock / Dark Magic skill; Inspire, Sundering, Silent Strike, Sunder (?13); Charm (?14); Commitment to the bit; Energize and Power Transfer. Best guess: nothing is built until you design it; the Suit system (F27) is the frame for the next trees.
Answer: ____

**Smaller calls (batch):** Winded (?126), Burnout's burnt max (?121), `Unit.guard` on helpless (?127), 0-AP actions while tapped (?119), snapped forms (?140), a flank / rear rider skill (?142), unshaping skills (?126, ?153), Discipline's initiative half and the Pike (?80, ?82, ?120), clout and tempers (?91, ?93), Jam's Focus hit (?97, ?100). Best guess: leave as built.
Answer: ____

**F33. Floaty: movement stays fractional (wave 18 E; see ?289).** Movement /(rank + 1) at rank 1 on 5 is 2.5, left unrounded, and Jump x2 makes Hop 4 tiles.
Best guess: keep fractional; round only if a unit stalls.
Ref: `docs/plans/w18-starmen.md`, `Scripts/Effect.gd` ops `scale`, `divide`.
Answer: ____

**F34. Jester's inverted page: the stat lists and the skills (wave 18 H; see ?292, ?293).** Mental stats read as int, wis, cha; physical as str, dex, con. 1 point per tree, permanent, floor 6. The Jester's seven skills are data only (Jape, Heckle, Tumble, Juggle, Read the Room, Fool's Luck, Pratfall), all `??`.
Best guess: keep; behaviours for the skills are a later card once you pick the names.
Ref: `docs/plans/w18-jester.md`, `Scripts/Unit.gd` `FLEX_PAY`, `buy_flex`.
Answer: ____

**F35. Jovia and `flex_kind` (wave 18 H; see ?294, ?295).** Jovia's tree is the Jester's Inverted root itself; the warlock pays the same stat costs and must meet each tree's prereq floors (checked before paying). Types: Scout martial, Journeyman specialist, Student caster. No `jest` tag, no suit yet.
Best guess: keep as built.
Ref: `Gods/jovia.tres`, `Trees/inverted.tres`, `Scripts/SkillTab.gd`.
Answer: ____

**F38. Monster paths and class as built (wave 18 I; see ?299 to ?301).** Playable and on the starting screen; the path is picked free on the skills screen at level 1 (a Monster may enter battle unpicked, no traits); Starmen = Floaty, Hop; Sirens = Alluring, Seaborn ??, Opportunist; Skeletons = a new invented trait Undead ?? (no effect per rank yet). Class stats str 14 dex 11 con 14 int 8 wis 10 cha 9, human, gambeson and dagger.
Best guess: keep as built; Undead ?? keeps its `??` and gets a per-rank effect on a later card.
Ref: `docs/plans/w18-monster.md`, `Roles/monster.tres`, `Skills/undead.tres`, `Trees/monster_*.tres`.
Answer: ____
Answered 2026-11-23d: the Undead rank effect is now the user's rule: the rank is added to any check defending against instant death, and healing tagged `dark` or `undead` is boosted rank * 5% (built, ?347, ?348; `Undead ??` keeps its `??`).

**F39. Thesis of Theseus: where it sits and who casts it (wave 18 J; see ?302).** Placed on the Wizard's Transgression root and on Elmon (the Warlock's patron tree), both at t6. Not placed: a dark mage (Mortis Arcalis holds 2 skills, no t6) and a dark cleric (no death-cleric tree, ?240).
Best guess: keep; place it when those trees grow.
Ref: `docs/plans/w18-theseus.md`, `Roles/wizard.tres`, `Trees/elmon.tres`.
Answer: ____

**F40. Thesis of Theseus: level, design, price (wave 18 J; see ?303 to ?305).** The Monster's level is the cast's rank, one a cast; "design" is picking a path (its level - 1 skill points stay unspent); 4 AP and 3 cost at every rank; the AI picks the path fewest on its side and values a level L Monster as L + 1 Skeletons.
Best guess: keep as built; trait-level design waits for your word.
Ref: `docs/plans/w18-theseus.md`, `Behaviours/theseus.gd`.
Answer: ____

**F46. NPC flex trees (wave 18 follow-ups; see ?317, ?318).**
Best guess: keep as built. An NPC (has a bio) takes the first offered flex tree when a slot is due, an authored pick stands, and a Jester pays with its lowest stat above floor 6.
Ref: `Unit.take_flex`, `docs/plans/w18-flex-ai.md`.
Answer: ____

**F47. Monster AI spends points, reversing ?303 (wave 18 follow-ups; see ?320 to ?322).**
Best guess: keep as built. An NPC or summoned Monster picks the path fewest on its side and spends its level - 1 points on that path's traits, cheapest first, so a Theseus Monster arrives with them spent (?303 said unspent). A player's Monster is left alone (card w18-monster-ai-player). Undead ?? is +1 pierce Defense a rank, a guess.
Ref: `Unit.take_path`, `fewest_path`, `path_auto`, `Skills/undead.tres`, `docs/plans/w18-monster-ai.md`, `docs/plans/w18-undead-rank.md`.
Answer: ____
Answered 2026-11-23d: the user's "AI should pick skills when they have points to spend based on their bio, otherwise sticking to their class tree" generalises this: every NPC now spends through one `Unit.auto_spec()`, a Monster's default pool being its path traits as before (built, ?354, ?355).
Answered 2026-11-23d: the +1 pierce Defense a rank guess is replaced by the user's rule (rank added to checks against instant death; dark or undead healing +rank * 5%); built, ?347, ?348.

**F52. Auto-playing a player's Monster (wave 18 follow-ups; see ?320).** The card w18-monster-ai-player (a player-side Monster left on auto picking its path and spending its points) was not built: it takes the choice away from the player.
Best guess: do not build.
Ref: `Unit.take_path`, `path_auto`, `docs/plans/w18-monster-ai.md`.
Answer: ____
Answered 2026-11-23d: "Player auto AI doesn't spec on their behalf": a player's unit never auto-specs unless the player long-presses Spec Automatically or Hard is on (built, ?355, ?357); the best guess stands.

---

## 4. HUD and UX (wave 18 A, B)

**F20. Horizontal scroll: the shared container (blocks A).** "On the parent menu so it can be used for any nonbreaking horizontal list." Name and inputs?
Best guess: a `HScroller` Control in `Scripts/` (one scene node you drop under any menu): wheel and shift-wheel, trackpad two-finger pan, click-drag, edge arrow buttons; first user is the class picker in `Scenes/entry.tscn`; the selected item scrolls into view with the arrow keys.
Ref: `Scenes/entry.tscn`, `Scripts/HUD.gd` (band / bar rows are the other long lists).
Answer: ____
Answered 2026-11-23d: menus also scroll vertically as needed (the demo start screen did not fit in landscape): built as `VScroll`, a twin of the HScroll container (?334 to ?336).

**F21. Camera: multitouch.** "Allow scrolling using multitouch." A trackpad two-finger pan, or touchscreen drag too?
Best guess: both: `InputEventPanGesture` (macOS trackpad) and a one-finger drag on touch, speed follows the gesture's speed; the existing middle-drag and arrow keys stay.
Ref: `Scripts/BattleCamera.gd:17,49` (`edge_pan`, the edge branch), `PAN := 360`.
Answer: ____

**F22. Camera: the edge zone's shape and speed.** "Rectangular elliptical (rounded) pan radius; same total velocity at top-middle and top-right; adjust dead zones; speed from distance to edge, tempered by map size."
Best guess: normalise the push vector so the corner is not faster than the middle (|v| capped at 1, direction from the cursor's depth into a rounded rectangle, corner radius = 1/4 of the short side); depth = 0 at an inner edge ~48 px, 1 at the edge (the `EDGE` 3 px band becomes this); max speed scaled by sqrt(map width in screens), at most 2x; the HUD side panels still block it.
Ref: `Scripts/BattleCamera.gd:19 EDGE`, `:49`.
Answer: ____

**F23. Camera: edge pause out of full screen.** "At the very edge outside full screen, pause: it's likely outside the screen."
Best guess: pause when the cursor is within 1 px of the window edge and the window is not fullscreen; also stop on `NOTIFICATION_WM_MOUSE_EXIT` / window focus loss (the better signal where the OS sends it), resume on `MOUSE_ENTER`.
Ref: `Scripts/BattleCamera.gd:49`, `Scripts/HUD.gd` where `edge_pan` is set from Prefs.
Answer: ____

**F24. The camera's null `hud.selected` guard (?279).** The camera is being rewritten (F21 to F23); fold the guard in.
Best guess: yes, no separate card.
Ref: `Scripts/BattleCamera.gd` `hud` group lookup; `docs/plans/w17-reverse.md`.
Answer: ____

**?241. The band at level 20 on 16:9.** Whole band names or whole bar names.
Best guess: whole bar names (a long row scrolls via F20 if it must).
Ref: `Scripts/HUD.gd`, `docs/plans/w9-band.md`.
Answer: ____

**Standing calls (HUD):** ?221 command readiness and the glow's size; ?222 do intel-only uses roll, tier 2 for "low"; ?224, ?225 passive signs, held rounding pieces, wrap rather than scale, merged "On <who>" lines; ?247 the Restless Dead chip not a rename, the boon a note, a screenshot; ?97 and ?100 a HUD showing more than the largest reserve; round and initiative lines using the arrow (`docs/todo/ui.md:8`); more resources (Rage, Hype, Clout, Gold) and shops; ?125 retuning colours (now with red, black, blue, purple from F27). Best guess: keep as built.
Answer: ____

**F43. HUD chips for the further tempers (wave 18 follow-ups; see ?313, ?314).** A starman's `Bio.also` tempers (Flippant, Vindictive, Power Hungry) show as chips on the leader's card only; a foe's card shows none, as it shows no behaviour chip today.
Best guess: keep; a foe's tempers stay unshown until you want them read.
Ref: `Scripts/HUD.gd` `_info`, `docs/plans/w18-hud-also.md`.
Answer: ____

**F48. One HUD picker for any skill with choices (wave 18 follow-ups; see ?323, ?324).**
Best guess: keep. Any non-tile skill whose behaviour has `choices` asks through the one HUD picker and casts at once; Elemental Strike migrated, and `Battle.cast` takes a `chose` argument.
Ref: `Scripts/HUD.gd` `_pick_choice`, `docs/plans/w18-picker-es.md`.
Answer: ____

---

## 5. Tests and tooling (wave 18 C)

**F25. ?276: "probably keep a rolling window?"** The question was whether to keep the bar-keyed drop of the held-effects cache while the hotbar fills. Reading: keep it, but as a small rolling window of recent bar states rather than drop-all on any change?
Best guess: keep and bound it: a last-2-hashes window (a tiny LRU) in place of the single `_fx_bar`; no behaviour change (nothing tests it today), one test that feeds it a changing bar. If you meant a rolling window of something else (e.g. the leak list), say.
Ref: `Scripts/Unit.gd:1889-1896` (`_filling`), `:4075 _fx_bar`, `:4080 _held_fx()`, `docs/plans/w17-equip.md`.
Answer: ____

**F26. The leak list (blocks C).** Each swept leak is appended to a running list "solved in batches later".
Best guess: `Tests/leaks.txt`, committed, one line per `test | node class | path`, deduped, sorted; kept even after a clean run (it only grows until a batch fix empties it); never fails the run. The same list also gets orphan nodes counted at exit if Godot reports them.
Ref: `Tests/run.gd:62,119-131` (the sweep, `leaked`).
Answer: ____

**?275, ?274, ?277. Equip follow-ups.** The mechanical 545-line test diff (each test calls `sync_bar()` after handing skills); the fill-order quirk kept (Icor's bar order, Mana before Hex, ?259); the gain was ~4%, the refit / `_take_looks` setup not pursued.
Best guess: all fine as built.
Ref: `Scripts/Unit.gd:1366 sync_bar()`, `docs/plans/w17-equip.md`.
Answer: ____

**?268. Test segments and the risk tier.** Anything of terrible importance lost under the 20/80 audit? Is the risk list right?
Best guess: nothing lost; keep the segments as built (`Tests/run.gd` words: quick, reverse, soak).
Ref: `docs/plans/w16-testaudit.md`, `Tests/run.gd:17`.
Answer: ____

**?203, ?204, ?210. Flags to confirm.** `no_density` and `scaling` (`FLAG_CEILING` 105 in `Util/skill.py`).
Best guess: both stay.
Answer: ____

**Standing calls (tooling):** ?258 the looser tests; ?239 expand typing (the 27 declarations, ?248) only for safety; ?251 and ?249 `test_icons` and the icon files; ?183 sims and budgets (see ?257 above). Best guess: keep.
Answer: ____

**F41. `skill.py` fix as built (wave 18 follow-ups; see ?307 to ?309).** `new` now writes `intensity` only with an explicit `--tier`, `check` fails a skill with a field `Skill.gd` does not declare (`check_declared`), and a stray `description` left `Skills/undead.tres`. Default-valued fields are not checked.
Best guess: keep as built.
Ref: `Util/skill.py`, `docs/plans/w18-skillpy.md`. This closes F36.
Answer: ____

---

## 6. Naming and docs (`??`)

**F27. Suit system, recorded as your words (wave 18 K).** diamond = non-divine, non-natural magic, magical, evoker; heart = divine / natural, spiritual, invoker; red = caster colour; spade = offensive, martial; club = defensive, specialist; black = physical colour; invokers (clerics, druids, warlocks, sometimes wizards, paladins, rangers) blue; evokers (mages, sorcerers, sometimes wizards, monsters) purple. Your text says "Suite system"; I write "Suit".
Best guess: record verbatim under a "Suit system" heading in `requirements.md`, no code or tags yet; wizards (and a Ranger / Paladin) are "sometimes" so no fixed suit on their `.tres`.
Ref: `requirements.md`, `docs/g-glossary.md` (a Glossary entry each).
Answer: ____

**F28. Are suits tags later?** Will `diamond`, `heart`, `spade`, `club` become skill tags (like `magical`, `strike`)?
Best guess: yes eventually, on skills and trees; not now.
Answer: ____

**F29. Names taken as given.** Scout, Jester, Jovia, Floaty, Hop, Jump, Flippant, Vindictive, Power Hungry, Power Siphon, Thesis of Theseus, Monster, starpower generator, astral void, startile, starpane. None carries `??`. Any collide with an existing name? (grep found no skill, tree or class called Scout, Jester, Jovia, Jump, Hop or Floaty; `Monster` is a tag word already used on units.)
Best guess: no `??` on any.
Answer: ____

**F30. Pane and tile in the code.** You wrote "pane" and "tile"; the files are `startile` and `starpane`. Rename?
Best guess: keep the file names, say "pane" and "tile" in comments and the Glossary as the short words.
Ref: `Terrain/startile.tres`, `starpane.tres`.
Answer: ____

**?237. Seaborn ?? and betrayal ??; `shows_boon`.** Keep the `??` markers, and is `shows_boon` the home of the shows_* look family?
Best guess: keep the `??` until you approve each; `shows_boon` is the home.
Answer: ____

**?180. Glossary readings of Lancin, Lancela, Lancin Proper.** Builder's own reading, "delete if wrong".
Best guess: keep. Answer: ____

**Names to review (batch).** `Traits Suppressed ??`, `Crit range ??`, `Glancing ??`, `Opening attacks ??`, `Attack stat ??`, `Reserve.burns ??`, `Disablings postponed ??`, `To be overcome ??`, `no_density ??`; and unmarked: `ambush_rolls`, `fusillade`, `Sally`, `starpower_generator`, `astral_void`, `power_star`, `soaks`, `held`, `wrongs`, `grudges`, `fancies`, `first_time`, `skilled`, `Trees/ramut.tres`. Best guess: all stay; the `??` ones keep their mark until you strike it.
Answer: ____

**F36. The `skill.py` `intensity` line (wave 18 H; see ?296).** `skill.py` wrote `intensity = &"faint"` on Juggle, a field no other skill has; the builder removed it. Fix the tool?
Best guess: yes, a tooling card (w18-skillpy) stops it writing the field unless set.
Ref: `Util/skill.py`, `docs/plans/w18-jester.md`.
Answer: ____

---

## 7. Wave 21 batch 1 (from your 2026-11-23d answers, `docs/agents/answers-2026-11-23d.md`)

Note: you suggested "a .py script for class authoring". `Util/role.py` already does that (`new`, `tree`, `tab`, `include`, `god`; skill `new-class`), so no new script was built. Say if you want something it lacks.

**F53. Vertical scroll: a twin class, `reserve` 16, the menus covered (wave 21; see ?334 to ?336).** `VScroll` is a separate ScrollContainer, not a generalised HScroll; it asks for min(content, screen - 16), the screen never being under 270 tall. Applied to the entry page, Party grid, the whole skills screen and the portal menu body; the battle HUD's side panels, sheet, settings and spellbook fit and were left. No drag scroll, no scroll-to-Unlock. HScroll `max_width` 440 to 420, and an idle row passes the wheel.
Best guess: keep as built.
Ref: `Scripts/VScroll.gd`, `docs/plans/w21-vscroll.md`.
Answer: ____

**F54. Sprite extractor as built (wave 21; see ?337 to ?339).** One folder per sheet in `Assets/sorted/<sheet-stem>/`; alpha above 0 counts as sprite, so 48 one-pixel specks among the 718 PNGs (275, 147, 296) were kept (default `--min-size 1`; `--min-size 2` would cut them); colour word is the nearest of 12 by redmean, so light grays read pink or white; clashes `-2`, `-3`.
Best guess: keep; delete the 48 specks and default `--min-size` to 2 if they are clutter.
Ref: `Util/sprites.py`, `docs/plans/w21-sprites.md`.
Answer: ____
Built 2026-11-23 (not an answer; your "update follow-up.md as needed"): the default `--min-size` is now 4 and the 104 specks under 4 px (48 one-pixel, 56 of 2 or 3) were deleted; survivors kept their names, so `-n` suffixes have gaps (?358, F67).

**F55. Animation: pose to state mapping, frame rates, triggers (wave 21; see ?340 to ?343).** attacking = left then right, hit = left, investigating = right, waiting = the numbered cycle else neutral; rates 6, 6, 3 and 4 a second; attacking fires on any finished outermost cast, hit on damage over 0, investigating on `inspect` / `investigate`; frames in `Units/<Name>.tres` beside the sprite. No posed art exists yet, so none of it has been seen in play.
Best guess: keep as built.
Ref: `Util/anim.py`, `Unit.ANIMS`, `docs/plans/w21-anim.md`.
Answer: ____

**F56. Animation pace multipliers (wave 21; see ?342).** Wounded (HP under half, or a `wound` status) and slowed (a status lowering movement or initiative) play at 0.6; hasted (raising either) and frightened (a `fear` status) at 1.5; all multiply. The numbers and the half-HP line are guesses.
Best guess: keep as built.
Ref: `Unit.ANIM_PACE`, `docs/plans/w21-anim.md`.
Answer: ____

**F57. Objective panel (wave 21; see ?344, ?345).** Top left of the visible map; "Foes left: N", or `?` ("? (3 seen)") with the fog on, dropped when a foe side is `lasting`; a map adds its own lines (Meadows: demons slain, the portal clock; its old tally label is gone). Hidden under menus and after victory; it does not fade.
Best guess: keep as built.
Ref: `Battle.objectives`, `HUD.objective_lines`, `docs/plans/w21-hudpanels.md`.
Answer: ____

**F58. Tile pane (wave 21; see ?346).** Always up at the map's top right; with the pointer off the map it keeps the last tile (before any, the selected unit's or leader's); it fades to 0.2 while the view moves and returns once still for 0.25 s. Speeds 6 and 2.5 a second are guesses.
Best guess: keep as built.
Ref: `HUD.pane_cell`, `fade_step`, `docs/plans/w21-hudpanels.md`.
Answer: ____

**F59. Undead rank rule as built (wave 21; see ?347, ?348).** The rank adds to every check against instant death through an `execute`-tagged defensive check effect (the shared last-stand and Death check); Luun's Smite execute is a HP threshold and is untouched. Healing tagged `dark` or `undead` is boosted rank * 5% by a new Effect stat `healed`; untagged heals (items, pulse, regen) are not; the boost lands before `being_healed` listeners.
Best guess: keep as built.
Ref: `Skills/undead.tres`, `Unit.heal`, `docs/plans/w21-undead.md`.
Answer: ____


**F60. Focus state and the pointer hold-off (wave 21; see ?349, ?350).** A left click or tap on a tile waits 0.2 s before it targets; a second click, a double tap or a right click in that time focuses the tile (the card and tile pane show it, white brackets), without changing the selected unit or the armed skill. No wait when the tile is already focused, when Ctrl, Meta, Shift or Alt is held, in preparation, or off the map; every tile waits, walks too.
Best guess: keep as built (0.2 s, under your 0.25).
Ref: `HUD.TARGET_HOLD`, `focus_cell`, `docs/plans/w21-focus.md`.
Answer: ____

**F61. Right click focuses before it disarms (wave 21; see ?351).** A right click on a tile not yet focused focuses it, also while aiming; only a right click on the focused tile or off the map cancels as before. So disarming a skill by right click now takes two clicks over the map. Esc is unchanged.
Best guess: keep; if the extra click annoys, make the right click cancel while a skill is armed and focus only when none is.
Ref: `HUD.right_click`, `docs/plans/w21-focus.md`.
Answer: ____

**F62. AI foresight: horizon, projection and margin (wave 21; see ?352).** A unit with wis mod above 0 looks wis mod turns ahead (cap 4) with a cheap projection (each located foe walks to it, then deals its read blow each turn), and misjudges by up to clamp(0.3 - 0.1 x int mod, 0.05, 0.6) + 0.3 x the share of foes whose blows it can only guess, from a deterministic local RNG. Energy is projected with no error. It runs on self-directed full turns only; villagers (wis under 12) never use it, and no cost was measurable.
Best guess: keep as built; the 0.3 base, the guess share and the cap 4 are guesses.
Ref: `AI.horizon`, `margin`, `_foresee`, `docs/plans/w21-foresight.md`.
Answer: ____

**F63. Foresight: pleas, orders, and Energy pleas that never fire (wave 21; see ?353).** A unit that a heal would keep alive longer heals itself, else pleads (`PLEA` 2.0 to a healer that reaches it); its skilled leader's plea adds `ORDER` 2.0 ("command healers"). No skill restores an ally's Energy, so an Energy plea can never be answered and none is raised; the answer code waits for the first such skill. No HUD sign (log lines only). The 30-a-side unit turn p95 is 258 ms at M3 x 4, over 200 before this branch too.
Best guess: keep as built; design an ally-Energize skill when you want Energy pleas.
Ref: `AI._aid`, `_answer`, `docs/plans/w21-foresight.md`.
Answer: ____

**F64. Autospec by bio: scoring and the pool (wave 21; see ?354, ?355).** Bio gains `prefers` (tags, postures, kinds) and `spec` (exploratory, training, remedial). A purchase scores 10 per preference met plus 5 for the mode (unlock, raise, or the thinnest bucket); class skills are always in the pool, other trees only when a preference matches; with neither, the class tree cheapest first. Every non-player NPC now spends at ready and each level-up (before, only Monsters). A player's unit with a bio never auto-specs by itself.
Best guess: keep as built; the 10 and 5 weights are guesses.
Ref: `Unit.auto_spec`, `Bio.prefers`, `docs/plans/w21-autospec.md`.
Answer: ____

**F65. Autospec refund under enforced auto (wave 21; see ?356).** Points spent while a unit is Disturbed or uncontrolled are refunded newest first at its side's next turn once control returns, and at battle end. A save written mid-fight while it is still Disturbed keeps the auto-spent skills (not fixed; card w21-autospec-save).
Best guess: keep; the save card fixes the gap.
Ref: `Unit.unspend`, `refund_auto`, `docs/plans/w21-autospec.md`.
Answer: ____

**F66. Hard toggle and Spec Automatically (wave 21; see ?357).** Hard (a settings check button) makes every unit, the player's too, auto-spec at level-up (not at battle start) and never refunds the player's. Spec Automatically is a button at the left of the skills footer, 500 ms long press, disabled at 0 points.
Best guess: keep as built.
Ref: `Unit.hard`, `HUD._on_auto_spec`, `docs/plans/w21-autospec.md`.
Answer: ____

**F67. Sprite specks removed, `--min-size` 4 (wave 21; see ?358).** The extractor now skips islands under 4 px and 104 specks (48 of 1 px, 56 of 2 to 3 px) were deleted from `Assets/sorted`; survivors keep their names, so `-n` suffixes have gaps in two sheets (astral, rough). Re-running would rename them.
Best guess: keep; leave the gaps.
Ref: `Util/sprites.py`, `docs/plans/w21-minsize.md`.
Answer: ____

**F68. Books: Read, consumed pass or fail (wave 21; see ?359, ?360).** Four common books (Applied Charizzmatics, Sensible Approaches, Life by the Gavel, Dungeoneer Delicacies) drop from the Meadows champion's table at weight 1. Read costs 1 AP and rolls a medium charisma and a medium intelligence check (flat DC 12), both always; the book is gone whether or not the reader passes; on a pass the player picks one tweak or none. Life by the Gavel offers two tweaks (you gave it no preference+). Books cannot be read between battles. The bio is now saved with the unit (an optional save key).
Best guess: keep as built; say if a failed read should keep the book.
Ref: `Battle.study`, `HUD._read`, `Item.blurb`, `docs/plans/w21-books.md`.
Answer: ____

**F69. Deity+ is a guess (wave 21; see ?362).** Bio gains `favours`, gods it holds dear. A godless unit with a favoured god can Pray to the first one; autospec leans toward the favoured god's domain tag (Eros love, Urlo energy, Ramut physical, Drael water). A class god is unchanged. `Bio.line` shows favours nowhere.
Best guess: keep; say what a favoured deity should do.
Ref: `Bio.favours`, `Unit.deity`, `docs/plans/w21-books.md`.
Answer: ____

**F70. Pragmatic: what do you mean? (wave 21; see ?364).** I mapped the temper `pragmatic` to the existing heal style (skip heals wasted on a nearly whole ally, weigh level). Your wider idea ("hate", aura blindness, "bad person is good") is NOT implemented; I had no definition. Does Pragmatic need more than the heal style, and what is the "bad person" rule?
Best guess: leave as the heal style until you define it.
Ref: `AI._heal`, `Bio.BEHAVIOURS`, `docs/plans/w21-books.md`.
Answer: ____

**F71. Compliant and Hungry as built (wave 21; see ?365, ?366).** Compliant: the aim of the leader it follows is worth ORDERED 4.0 (half for a foe within 2 tiles of an aimless leader); no leader, 0. Hungry: a skill tagged `siphon` or `drain` is worth + 0.5 x hit chance x min(average damage, what the target has); only in the strike pick. No lifesteal skill exists yet. No HUD sign for either.
Best guess: keep as built.
Ref: `AI._orders`, `_hungry`, `docs/plans/w21-books.md`.
Answer: ____

**F72. AI units never read books yet (wave 21; see ?363).** The AI's tweak pick (`Unit.fancy`) exists, but no AI turn uses an item, so only the player reads books. Card w21-books-ai is queued.
Best guess: build the card: an AI unit with a readable book reads it on a calm turn.
Ref: `Unit.fancy`, `Battle.study`, `docs/plans/w21-books.md`.
Answer: ____

**F73. Mid-fight save writes the refunded state (wave 21; see ?367, F65).** A save written while a unit is Disturbed shows it as if its auto-spent points were refunded; the live unit is untouched. Saved learned rows now use `points_in()`.
Best guess: keep as built.
Ref: `Unit.to_dict`, `_lowered`, `docs/plans/w21-autospec-save.md`.
Answer: ____

**F74. AI units read books on calm turns (wave 21; see ?368, F72).** The first readable book in `Unit.pack` is read at the nothing-to-strike branch or the start of a prowl; consumed pass or fail. Not read in the `_dress` tail or `_drill`. No scene gives any NPC a book, so it never fires in play yet.
Best guess: a later scene gives one named NPC (a scholar or a champion) a book to show it.
Ref: `AI._study`, `docs/plans/w21-books-ai.md`.
Answer: ____

**F75. AI pack is not saved (wave 21; see ?368).** A book an NPC carries is lost on a save and load, since `pack` is not written for AI units.
Best guess: save `pack` for NPCs once a scene gives them books.
Ref: `Unit.to_dict`, `docs/plans/w21-books-ai.md`.
Answer: ____
