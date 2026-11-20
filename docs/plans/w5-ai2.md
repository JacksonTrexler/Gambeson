# w5-ai2: plating on the card and in the AI, friction on the HUD, the Coyote set's loot and the AI (2026-11-19)

Cards (docs/queue.md Wave 5): "Armor plating: the unit card, the AI and `lapsed()`" (?200), "Friction on the HUD and the AI" (?202), "Coyote set: loot and AI" (?201).
Read `w3-armor.md`, `w4-friction.md`, `w4-coyote.md`, `w5-ai1.md`. No names made up (no ??): Armor, Power Armor, Scrap Plating, friction, Coyote items are the user's; the new
names are a field (`Unit.pack`), a hook (`slot_toll`), a static (`postponing_in`), constants (`DELAY`) and a Roll field (`friction`). Baseline suite: 10225 checks, 0 failed (966 tests).

## Card 1: plating
1. **The unit card** (`HUD.trims`) lists the armor in each plate slot after the three item slots, named for its slot ("Bulwark (Power Armor)"), worn or not working.
2. **`lapsed()`**: `plates()` already read it through `passives` (`on_passives` leaves out a lapsed skill), so the todo was stale; now explicit: `Unit.plate_works(skill)` (the passive works and its
   `slot_works()`), commented, and pinned by `plating_test.test_lapsed` (a lapsed slot: Defense off, armor stays worn and on the card). Mutation: `not lapsed` dropped from `on_passives` fails it.
3. **The AI has no stash**, so "equips armor into a plate slot" needs armor to draw on: new `@export Unit.pack: Array[Item]` (armor a unit carries; not worn, so it counts for nothing). No unit has
   one yet (content is yours; a scene sets it). Call: a generic carry list, not plating-only.
4. **`AI._dress()`**: picks the (slot, armor) pair adding most Defense over what is worn there, by the slot's own rules (`Unit.plate_defense(skill, item)`, new, shared with `plated_defense()`: Scrap
   Plating's cap and Power Armor's gate are read, not guessed); only slots that work now; one a turn through `Battle.equip` (so AP is paid: armor is ~10 - dex mod); what it takes off goes back in the
   pack. When: at the start of a self-directed turn if there is no blow to strike from where it stands (`_could_strike`), and with what is left at the end of one. Calls: a unit fighting never stops
   to dress (it dresses when it is idle or the AP is left); drag and weight are not weighed against the Defense (Defense gain alone).
5. **The blocks**: new hook `Behaviour.slot_toll(holder, rank, power) -> int` (what a block takes off its holder's Power; default 0; Power Armor's `slot_blocked` now calls it; in `skill.py` HOOKS).
   `AI._blocks()`: for a foe whose armor shows (`Read.defense` read) and wears plates, per plate the extra chance the blow would have hit without it (hit chance with Defense less the plate's,
   minus with it) x the toll x `POINT`, added to a skill's score (an attack that is not a save/contest/level-down). Scrap Plating's toll is 0, so nothing. Calls: valued at POINT (0.5 HP a Power
   point); a foe's plates are read from the true unit once its Defense is read; the AI does not (yet) fear its own plate's tolls, or the slot switching off when Power runs down.
6. Sim (`Tests/sims/ai_sim.gd plate`, n=8): before / after
   | | before | after |
   |---|---|---|
   | dress, foe far (defense after 3 rounds, dressed, strikes) | 2.00, 0, 8.00 | 3.00, 8, 6.00 |
   | dress, foe in reach | 2.00, 0, 9.00 | same (it strikes) |
   | two foes of Defense 20, Power Armor listed second: struck first, Power drained | 0/8, 0.00 | 8/8, 3.00 |
   Every other scenario's SIM line is identical before and after (no unit has a pack or plates).

## Card 2: friction on the HUD
7. **`Check.Roll.friction`** (Unit.friction when it was rolled, set in `Battle.roll_attack`), carried by the HUD's `_roll` to `_on_used`: the log line gets " (friction: disadvantage, -N)" and a
   "Friction -N" float rises over the caster (when seen). No per-skill case: any roll made under `Unit.friction`.
8. **The AI's forecast**: w5-ai1's `friction_ahead()` / `attack_odds()` / `_use_ratio()` already count friction for a chase's first roll and a Strike's later rolls. Left, and not built: the
   crit-triggered loops themselves (a Chaser's chase, Jugular's recast) as an expected extra on a use. They are worth about the crit chance (5% plus crit range) of one more use, at disadvantage
   and friction, and the forecast cannot name the friction of a use not yet begun without carrying a chain state into it; so not priced.

## Card 3: the Coyote set
9. **Loot**: both in `Loot/astral_princess.tres` (the strongest unit, a loot table of Hearts and trinkets; Alabaster's table is emblems, Icor's one blade), weight 1 each, so epic pulls them to
   2% each. `item.py` has no "add an existing item" verb; I called its `add_to_loot()` directly (same writes). `items_test.test_loot`'s describe line updated to the new table.
10. **The AI** (`AI._held()`): a disable (`Skill.disables`) against a target `r` reads as postponing (`Unit.postponing_in(r.effects)`, any status with the postpone stat, not the Coyote's) is
    worth `DELAY` 0.5 of itself, divided by 1 + the disablings it already holds (`Unit.postponed`); applied to the cc price (Brainfog) and to the flat +1 where the disable is all the skill does.
    Calls: DELAY is a guess; the status is read at recon 3 as any status; held disablings are read from the true unit (what the AI's side cast into the wait). A curse debuff that does not tick
    is not priced (it only helps the caster).

## Tests
New: `plating_test.test_lapsed`, `plating_test.test_ai`, `hud_test.test_friction_named`, `coyote_charm_test.test_ai_weighs_a_postponed_disable`. Changed to the new rule: `items_test.test_loot`
(the table's description). Mutations (each failed, reverted): lapsed dropped from `on_passives`; dress ignoring `_could_strike`; `_blocks` off; dress taking the first not the best;
`hit.friction` not set; `_held` off.

## As built
Scripts/HUD.gd, Scripts/Unit.gd (`pack`, `plate_works`, `plate_defense`, `postponing_in`), Scripts/AI.gd (`_dress`, `_blocks`, `_held`, `DELAY`), Scripts/Behaviour.gd (`slot_toll`), Scripts/Check.gd,
Scripts/Battle.gd, Behaviours/power_armor.gd, Util/skill.py (HOOKS), Loot/astral_princess.tres, Tests/{plating,hud,coyote_charm,items}_test.gd, Tests/sims/ai_sim.gd.
Not done: no unit carries a pack; AI ignores its own plates' tolls; Abjuration/Smith placement; crit-loop forecast.
