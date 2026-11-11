# Resources: what a unit runs on

The user (verbatim, the parts built here):

> Let's make it special to have two types of resource at the same time:
> Mana is efficient for spellcasting and has a more even keel regenerating: it gets half the resting
> bonus even on turns a unit doesn't rest. there are skills that boost it specifically
> However: mana can *only* be used for caster skills.
> Mana is now a toggle passive that defaults "on": while it's on unit can't use active skills with
> energy requirements.
> similar with stamina: it can only be used with specialist and martial skills: can't pay resource costs
> for spells while it's active. Stamina recovers quickly while resting.
> Toggling an energy replacement skill is channeled, of their current resource reserves, unit keeps up
> to 10% of their max resource per rank per turn channeled.

Builds on `docs/plans/stamina.md`, `docs/plans/focus.md`, `docs/plans/channels-jam.md`, and sits beside
`docs/plans/siphon-sorcerer.md` (Overcharge, Energy Transfer).

## Readings and calls (written before building)

1. **One resource at a time.** Mana and Stamina are "energy replacement" toggles: on as learned, the
   unit *runs on* that reserve instead of Energy (`Unit.runs_on()`). *Call:* "replacement" is read
   literally: running on Mana or Stamina, the unit's own Energy is emptied as the battle starts and
   doesn't come back (like Power). That is the lock-out: a Mana user can't use Energy-cost actives
   because it has no Energy, not because Energy is forbidden.
2. **Energy got some other way pays.** "Ways for Mana users to get regular energy without toggling"
   says they can spend it: Energy from Energy Transfer (`grant_energy()`), a potion, or an Overcharge
   buffer pays for anything, non-caster skills included. The rule reads the toggle (the toggle empties
   Energy and stops its recovery), not which reserves are held.
3. **What pays.** Mana: only magical skills (by tag or tree, `Skill.tagged()`). Stamina: martial,
   specialist and general. *Call - departure:* general is kept (and `physical` dropped), because with
   Energy gone a Stamina user couldn't otherwise pay for Move ??, the skill built for Stamina.
   Running on Stamina, nothing pays for a spell that costs anything (`Reserve.bars`), Focus and
   Overcharge included; a spell costing nothing (Waterstrike) is still used.
4. **Focus** keeps its rules (first for a ranged attack, else after Energy). It is a second resource
   reached through a specific skill, so it sits beside either toggle - except that the Stamina spell
   ban covers it.
5. **Regen.** Mana now comes back as Energy does (rest rate, half light, none busy) plus Mana's rank on a
   resting turn and half that on any other turn, busy included (`Reserve.steady` 0.5). Stamina: the
   resting bonus doubles, 2 x rank (`Reserve.rest_rank` 2). A reserve switched off doesn't recover.
6. **One on.** A unit with both toggles keeps the first on its bar on, the other off.
7. **The switch is a channel** (`Unit.toggle()`, `Channel.switch`). *Call:* it takes effect at the
   channel's end: meanwhile the unit runs on the old resource. Each of its side's turn ends it holds
   idle (the toggle's own turn included, if it spent nothing) counts one turn. When it ends - toggled
   again, broken by acting, interrupted (Jam), or once the carry would take everything - what it leaves
   goes to 0, and floor(10% of that one's max x the toggle's rank x turns held), no more than it had,
   comes into the new one. Holding another channel, it can't switch.
8. **AI** never toggles. A Wizard or Mage under the AI simply runs on Mana.

## As built

As planned. Details:

- `Reserve.gd`: `replaces`, `bars`, `rest_rank`, `steady`. `Reserves/mana.tres`: `with_energy`,
  `replaces`, `steady` 0.5. `Reserves/stamina.tres`: `only` martial, specialist, general; `replaces`,
  `bars` magical, `rest_rank` 2. `Skills/mana.tres`, `Skills/stamina.tres`: `toggle`.
- `Unit.gd`: `replacer()`, `runs_on()`, `switching()`, `carry()`, `_switched()`, `channel_held()`,
  `_one_replacer()`; `channel` has a setter, so however a switch's channel ends, the switch completes.
  `spends()` (Mana off pays nothing), `funding()` (the spell ban, before Overcharge's look), `recover()`
  (no Energy back running on a reserve), `_recover_reserves()`, `giver_rank()` (Mana opens its reserve).
- `Battle.end_turn()`: a held channel calls `Unit.channel_held()`.
- **Bars:** drawn in `Unit.gd` (not StatusBar). `held_reserves()`: what it runs on first, then every
  other reserve it spends from. A second reserve gets its own 2px bar (`second_bar`, made on demand);
  the Energy bar shows only when it holds Energy (`holds_energy()`). The unit card (`HUD._info()`)
  lists each held reserve, then EN/PW if held, then Overcharge's "OC +n".
- **Player:** Mana and Stamina now sit on the hotbar as toggles. Pressing one starts the switch (log:
  "switching to Energy, channeled"); pressing it again finishes.
- Skill descriptions say what Mana and Stamina pay for, their regen, the run-on rule and the switch.
- Tests: `Tests/resources_test.gd` (new). Updated to the new rules: `adventurer_test.test_mana_casting`,
  `champions_test` (`test_icor`, `test_hex_iii`, `test_mana_rules`, `test_bars`), `command_test`
  (`test_default_bar`, `test_bar_place`: Mana is on the bar), `hud_test` (`test_toggle_from_bar`,
  `test_spellbook_and_bar`), `stamina_test` (`test_pays`, `test_recovers`), `focus_test.test_pays`.

## Left open

- Learned mid-battle, a toggle starts running at once, but the Energy the unit had stays until spent.
- A Druid holds Mana from its Astral tab before learning Mana, and Icor-like units without the skill
  would hold both. With no toggle, both pay as before.
- Wizards and Mages now start every battle with no Energy. Strike costs nothing so still works. Their
  non-magical costed skills need Energy Transfer, Overcharge or a switch.
- The hotbar doesn't mark a switch in progress beyond the log line.
- The todo docs aren't updated (out of bounds). The calls above want question numbers when merged.
