# Battle UI v2 as built (branch a-ui)

Plan: `docs/ui-ux-v2.md`. Its four open points, as the user answered them: (1) clicking yourself to
rest ends only that unit's turn; (2) the hover search for an offensive skill wraps around the hotbar;
(3) odds show as bands on the map (solid / broken / wavering bracket), and the exact % only with a held
modifier or on the expanded card once Defense is known; (4) a self skill confirms on a second key
press or a click on yourself, either one.

## Readings and calls

1. **One intent.** `HUD.intent(cell, mods)` returns `{kind, unit, skill, target, cell, walk, dest, access, why}`.
   `click()` runs it (`_run()`), the overlay draws it (`hud.plan`, `hud.charge` are now read from it)
   and the tooltip names it. `_replan()`, `_charge_line()` and the armed branch of `_tip_text()` are gone.
2. **The selected slot is always set.** `slot` (an index) replaces the `armed` mode. `armed` stays
   as a read-only getter for the selected slot's skill, so the slot highlight and the tests still read it.
   Walking is never blocked by it. A Settings toggle, `keep_slot` (default off), keeps the last used
   slot. Off, a turn and each new selection start on slot 1.
3. **Area and trap-laying skills still aim** (call): pressing their key sets `aim`, tile clicks then cast,
   and a right click or the key again steps back. Without this, every tile click with an area skill
   selected would be a cast, so walking would need a mode anyway. Aim clears after the cast.
4. **Self skills**: the first press selects the slot and previews the cost on the bars. A second press,
   or a click on the unit itself, uses the skill. Auto skills (Sing) work the same way.
5. **Clicking yourself** with no self skill selected: `rest` (still idle, no channel), `continue`
   (idle, holding a channel) or `done` (it has already acted). Each one locks only that unit for the
   rest of the turn (`Command.lock`). The leader can be locked too, which greys it.
6. **Foe hover**: the first offensive, unit-target skill from the selected slot rightward, wrapping
   around (a slot allies are barred from is skipped). Shift still selects (inspects) instead.
7. **Ally hover**: in command reach, `select`. Out of reach, the leader walks into command range
   (`command_walk`), planned as the command glow's straight walk. A support skill selected
   (`for_allies` and not `for_foes`) makes it `use` (walk into range, then use) instead.
8. **Glow and saturation read through one function**, `HUD.look_of(u) -> {glow, sat, tint}`.
   `_show_units()` applies it. a-tap's `tapped` state and saturation tiers slot in there.
   In the support view, foes glow barely ("fall back").
9. **Allied factions glow green** (`HUD.ally_glow`, default `FRIEND`, a Settings colour later). Their
   bar trim keeps their faction's colour and their sprite keeps full colour. `Unit.set_glow()` takes
   an optional tint.
10. **"Will consume" overlay**: `HUD.drain()` gives `{hp, energy, <Reserve>: n, ap, move, unsure: [keys]}`
    from the hovered intent: the walk's move points and known-trap damage (the dice average plus
    bonus, before mitigation), or the skill's AP and cost after exhaustion. It shows as a pulsing
    segment at the end of the unit's own map bars and the card's rows. A key in `unsure` gets a muted,
    flashing "?" after its number on the card and beside its map bar instead of a segment.
11. **Foresight** (predictions): a unit makes `int mod` hazard estimates a turn (`HUD.foresight()`),
    kept in the HUD per unit and cleared when the player's turn opens. Only hazard estimates count:
    plain move points and a skill's own cost always show. A prediction is spent when an action whose
    plan showed an estimate is actually taken. With none left, or at +0, a known hazard gives "?".
    Below 0 there is no "?" either, no trap line, and the walk counts as sure. The path itself is
    still Battle's (call: "plans as if safe" is read as the display, not the pathing).
12. **Words cut**: the tooltip shrinks to the name and read (unit), or nothing for a walk (the bars
    and the plan carry it). Instructions ("Click: ...", "Ctrl-click ...") are gone from it. Refusals
    shake the unit and float one word (`_refuse()`: "Spent", "Too far", "No AP", "No"), and the hint
    line still keeps the full reason.
13. **Odds**: the target bracket is solid (>= 65%), broken (35-65%) or faint (< 35%). It wavers
    (pulsing jitter) when Defense can't be made out. Holding Alt shows the exact % in the tip once
    Defense is known.
14. **Reach as shape**: a target out of reach shows two rings, the skill's range around the caster and
    a small ring at the target.
15. **Exhausted cost as pips**: an exhausted skill's slot draws its multiplier as pips (one per extra
    use), and the slot tooltip no longer opens with "Exhausted x2: ...".
