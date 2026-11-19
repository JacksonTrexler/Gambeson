# w4-coyote: Coyote Charm and Coyote Scepter

The user's words: docs/agents/answers-2026-11-18b.md item 8, the Coyote paragraphs. Names (Coyote Charm, Coyote
Scepter, Curse of the Coyote, the curse tag) are the user's: `--human`, no ??.

## Readings
- "Skills are disabled" = `Unit.disable()` (Brainfog's slot disabling, the `disabled` dict). Stuns, sleep and
  Traits Suppressed are cc statuses, not disabled skills: the Charm doesn't react to them.
- "Instant death" = dies with HP left: Death and Luun's Smite set `hp = 0` directly. Borrowed Time already exists
  (the `defer` stat, `Unit.defer()`, `Battle._borrowed()`); the enchanted Charm reuses it.

## Calls
1. Two generic hooks, no item flags. `Unit.disable(s, turns, curse, by)` emits `disabling(u, d)` (mutable d:
   skills, turns, curse, by); Battle asks the disabler's passives, then the target's (`Behaviour.disabling()`).
   New `Unit.slay()`, the one place an instant death happens, emits `slaying(u, d)`; the victim's passives may
   set `d.defer` (`Behaviour.slain()`), and it goes on borrowed time through `Unit.defer(n)`. Death and Luun's
   Smite call `slay()`. skill.py's HOOKS list knows both.
2. Defer-disable is a status, not the item: new Effect stat `postpone` ("Disablings postponed ??"). While a
   unit has one, disablings go to `Unit.postponed` (not counting down) and its curse debuffs (statuses bearing
   `curse`) don't tick - any curse, not only the Coyote's (composable; it cuts both ways). As the last postpone
   goes (tick or a dispel), what was held lands for its full turns (`Unit.release()`). Held disablings aren't
   shown on the hotbar (only the buff and curse statuses show); disable_order() skips them.
3. "Must be overcome" is a stat, `overcome` ("To be overcome ??", harmful): cleansing takes its ranks before
   any other debuff's (leftover ranks go on); a heal (`Battle.mend()`: skills, regen, Lovely Caster,
   Resuscitate) only wears max(power, 1) of its ranks away and does nothing else. Plain `heal()` (potions) and
   dispels aren't stopped. A Downed unit's Resuscitate can be eaten by it - harsh, left as the rule says.
4. The Charm buff and the Curse last rank turns (+1 in the unit's own side's turn), both at the lending skill's
   rank; the curse is put on last, so it is rightmost in the status list. A buff already up isn't renewed, so
   repeated disablings can't stall forever; later ones join the held pile.
5. The Charm's enchanted effect: its behaviour owns the enchantment (like Armor: not ranked up), and an instant
   death on its last life (no hearts, not Downed) puts it on Borrowed Time for rank rounds. Any enchantment
   counts (the tag or Pray's).
6. Scepter: disablings its wielder causes get + rank turns and the target the buff and curse at the Scepter's
   rank (same helper as the Charm). Net: the disable waits rank turns, then lasts rank longer.
7. Items: Coyote Charm, epic trinket, tags magical, lends skill Coyote Charm; Coyote Scepter, epic weapon,
   blunt, tags magical, lends skill Coyote Scepter. Lent skills tagged magical, curse. No loot table yet.

## As built
- Scripts: Unit.gd (signals, disable/postponing/release/tick, defer(n), slay), Battle.gd (_on_disabling,
  _on_slaying, _strip, mend, Death/Luun -> slay, Downed clears postponed), Behaviour.gd (two hooks),
  Effect.gd (stats, titles, text). Behaviours/coyote_charm.gd, coyote_scepter.gd. Effects/coyote_charm.tres,
  curse_of_the_coyote.tres. Skills and Items coyote_charm, coyote_scepter (+ icons). Util/skill.py HOOKS.
- Tests/coyote_charm_test.gd: one test per seam (postpone, overcome, scepter, instant death). Mutation
  spot-checks, each failing the test: postpone off; curses ticking while held; mend ignoring the curse; cleanse
  order; slay ignoring d.defer; Scepter not adding turns.
