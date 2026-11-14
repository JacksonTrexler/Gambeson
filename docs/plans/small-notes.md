# Small pieces (?57, ?60, ?63, ?68, ?80, ?82)

Six small changes the user asked for in the 2026-11 answers. Each section: what was read, the calls
made, then what was built.

## 57 Meditation: a trade between core stats

User: "meditation to only permit units to tweak core stats, they may decrease -> increase one stat
point per rank per use".

Meditate existed (`Skills/meditate.tres`, `respecs = true`): after it, each core stat could shift up
to rank *from where it was born*, independently (a free +2 everywhere was allowed at rank II).

Calls:
- "decrease -> increase" read as a trade: the points taken out pay for the points put in exactly
  (the changes sum to 0). Up to rank points moved a use (rank II: str +2, cha -2; or str +2, dex -1,
  wis -1).
- The limit is per use, not a lifetime band around birth stats: meditating again moves rank more.
  `Unit.respec` still records the running shift from birth.
- No stat goes below 1.
- Kept the earlier self-knowledge gate (a use moves no more than the unit knew itself before it,
  so Self-reflection still opens the first one). The user didn't mention it; dropping it would leave
  Self-reflection with nothing to do.

As built: `Unit.respec_by()` (zero-sum, moved <= limit, nothing below 1, all or nothing),
`Battle.respec()` unchanged but its comment, the skill's description (`Skill.markup()`), and the HUD
panel (`HUD._respec_window()`): each stat steps within room of where it is now, and Shift stays
disabled until the points balance. Tests updated: `actualization_test` (test_meditate,
test_self_reflection_first), `derived_test.test_respec`.

## 63 Magnitudes: severe, not extreme

User: "intense 2.5, severe 3". The 3 x rank word renamed from `extreme` to `severe` everywhere:
`Difficulty.MAGNITUDE`, `Glossary.TERMS` ("Severe"), `Skill.dice_scale`'s comment, Wildfire's data,
`difficulty_test`. Intense stays 2.5. No call made.

## 60 Telepathy and Word to the Wise

User: "arcane skill 'Telepathy' makes it easier to command a single unit each turn by removing cha
restrictions entirely. 'Telepathy' ranks replace cha mod when ordering this unit, but it can only be
used on one unit per turn within rank range." and "Specialist passive skill: word to the wise: when
commanding, unit may use their wisdom mod instead of charisma mod. wis as replacement mod bounded by
lower of the two units wis mod + rank".

Command's limits all went by one leader-wide number (`Command.cha_of()`). Both skills need a number
per ally, so one hook sits beside it: `Command.cha_for(u)` = the leader's charisma as it commands
(`cha()`, Grand Design included) or, if better, the best stand-in a switched-on passive offers for u
through a new Behaviour hook, `command_mod(command, holder, rank, u)`, with Grand Design added on top.
A second hook, `ordered(command, holder, rank, u)`, tells passives an order went out (from
`Command.order()`). Anything later that commands by another stat (a bard's song, a pack bond, an item)
is one behaviour on that hook. `Util/skill.py`'s HOOKS list knows both.

What goes by cha_for(u): that ally's reach (`in_range()`, through `reach_for(u)`), orders a turn
(`order_cap(u)`), and hotbar slots (`slots(u)`, `slot_open`, `may_use`), plus the HUD's per-ally
texts (`_why_locked(u)`, the "Ordered n/m" chip, `basis(bonus, u)` "..., +3 for this ally") and
`HUD.uses_intents()` (slots(u)). Not changed: allies a turn (`ally_cap()`), party size and reach, and
`could_order()` (the a-tap builder's ground).

Calls:
- "arcane": no such tag; Telepathy is tagged magical, supportive (no element - pure arcane, as
  Arcana reads it). General Caster tree, tier 3 (Strategist and Tactician's tier on the Specialist
  tree). Word to the Wise: specialist, supportive, wis; General Specialist tree, tier 3, beside
  Tactician. Both passives, both names the user's (`--human`).
- Telepathy is a passive, not a cast: until it carries an order, every ally within rank tiles counts
  rank in place of cha; the first ally given an order while rank beats the leader's cha mod is bound
  for the turn (`Command.linked`, freed by `new_turn()`); the rest fall back. So the player picks the
  one by ordering it first.
- "removing cha restrictions entirely" read as the per-ally limits (reach, orders, slots). The linked
  ally still counts toward allies a turn (`ally_cap()`), which stays leader-wide.
- Word to the Wise's bound read as min(leader wis, min(leader wis, ally wis) + rank), which is
  min(leader wis mod, ally wis mod + rank).
- Grand Design (+1 to cha as it commands, a rank) adds to a stand-in mod too.
- `HUD.uses_intents()`'s low-wisdom half still reads the leader's raw wis mod.

Tests: `Tests/telepathy_test.gd`, `Tests/word_to_the_wise_test.gd`; `command_test` passes unchanged.

## 68 Bumping into a concealed unit

User: "physically contacting a concealed unit and being unable to proceed because of them grants 1
recon in itself".

Read: `Battle.walk()` stops a walk short of units (they can be passed, not stood on) and where it
can't pay to pass one (`pass_cost()`); `_contact()` (investigating on contact) is separate and stays.

Built: `walk()` now also returns `blocker`, the unit that stopped it short (the last occupied tile it
backed off, or a unit whose pass cost it couldn't pay when the ground alone fit). `travel()`: if the
walker couldn't place the blocker (`read().located()` false) before the bump, it gains a recon level
on it through a new generic store, `Battle.noticed` (unit -> {unit or tile -> levels}), read in
`_read()` beside `studied`, written by `Battle.note(o, k, n)` - any later "one unit learns about
another" can use it. Signal `Battle.bumped(u, into)`; the HUD logs "X bumps into something unseen".
It counts even when the walk goes nowhere (the first tile is the hider's).

Calls:
- "concealed" read as "the walker couldn't place it": a unit it had located is no surprise.
- Each bump adds 1 more, cumulatively, while it still can't place the unit; the recon is the
  walker's own (not its side's, unlike preparation's study) and lasts the battle.
- Only walks (`travel()`): pushes and teleports don't bump.

Test: `moves_test.test_bump`.
