# Follow-up worksheet (2026-11-23)

Answer inline after each `Answer:` (a word is enough: "ok" takes the best guess; "skip" leaves it as built), then say **continue**. Where you leave one blank, the best guess is what gets built and recorded as a numbered call. Ids: `?NNN` is an existing question in `todo.md` (detail in `docs/todo/*.md`, `docs/plans/*.md`); `F1` to `F30` are new, from your 2026-11-23c answers (`docs/agents/answers-2026-11-23c.md`, wave 18). Already answered and left out: ?278 (clean up leaks), ?279 (camera, now wave 18), ?276's old form, delete the merged branches, the Nexus void and generators (now F-items), ?255, ?256, ?216, ?218, ?220, ?222, ?223, ?214. Everything still open in `todo.md` that nothing waits on is batched under "Standing calls" in each group: "ok" keeps it as built.

Blocking order inside each group: first items hold up the most wave 18 cards (A hscroll, B camera, C leaks, D nexus, E starmen, F fog, G flex, H jester, I monster, J theseus).

---

## 1. Items and dungeons (wave 18 D, E)

**F1. Pane and tile: which is which, and what does "x" and "base power" count?** Your rule: `pane * base power, tile * x, (Gen), tile * x, pane * base power`, rows and columns alike, diagonals panes, "the generators should basically be in a wired circuit". Two readings: (a) a run of that many cells; (b) a weight. Your 2026-11-23b spec had startiles forming the grid round each generator and starpanes filling the gaps, which puts tiles beside the Gen (the wire) and panes outside, and that matches the rule as written.
Best guess: as written. Along a row or column from a Gen: `x` startiles, then panes up to the next Gen's tiles; `x` = 2, "pane * base power" = a run of 2 panes (base power = a constant, not a unit's reserve); diagonals always panes. Record the reading in `docs/plans/w18-nexus.md`.
Ref: `Scripts/AstralNexus.gd:9-14,53-70` (now `REACH` 4 square, `BROKEN` 0.25, `VOIDED` 0.15, startile on every even offset); tiles `Terrain/startile.tres`, `starpane.tres`, `cracked_startile.tres`, `starpower_generator.tres` (`passes`, `source`).
Answer: ____

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

---

## 4. HUD and UX (wave 18 A, B)

**F20. Horizontal scroll: the shared container (blocks A).** "On the parent menu so it can be used for any nonbreaking horizontal list." Name and inputs?
Best guess: a `HScroller` Control in `Scripts/` (one scene node you drop under any menu): wheel and shift-wheel, trackpad two-finger pan, click-drag, edge arrow buttons; first user is the class picker in `Scenes/entry.tscn`; the selected item scrolls into view with the arrow keys.
Ref: `Scenes/entry.tscn`, `Scripts/HUD.gd` (band / bar rows are the other long lists).
Answer: ____

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
