# Silhouettes and the four strengths of glow

Branch `r-visuals`. Tests: `Tests/hud_test.gd` (`test_silhouette`, `test_skill_glow`, `test_command_glow`).

## The rules as built

**Black shape.** A unit draws black only when it might be a monster in the brush: the viewer has
placed it, can't tell its side, and something stands between them (`Read.silhouette()`). "Something
between them" (`Read.concealed`, set in `Perception`) is any of:
- concealment left over after the viewer's own senses: darkness, fog, brush, or the unit hiding;
- sight is limited and the unit is too far to make out;
- the viewer holds suspicion of the unit or of its tile.

A unit in plain view that the viewer only isn't clever enough to identify keeps its own colours with a
neutral grey glow. The viewer's own faction never draws black. An ally of another faction draws black
only when it really is hidden or in the dark. The card's portrait goes black with the unit.

**Colour.** Own units drain colour with AP as before. One that is only out of command reach stays in
colour (new command state `far`); grey is for every other reason (no AP, past the limits, asleep,
locked). `Command.can_order` = `could_order` (everything but distance) and `in_range`.

**Glow.** One abstraction: `Unit.Intensity { BARELY, SOMEWHAT, MOSTLY, FULLY }` and
`Unit.set_glow(level, contrast)`; the HUD asks `glow_of(unit)` for every unit on screen (-1 = plain).
- Skill armed (`skill_glow`): each unit the skill could be used on glows
  - fully: in range now;
  - mostly: a sure walk brings the caster into range; a click walks there and uses the skill;
  - somewhat: only an unsure walk gets there; a click does not walk;
  - barely: can't be reached this turn.
  Units the skill isn't for keep their plain glow. Area skills light no units.
- No skill armed (`command_glow`): the player's own units glow
  - fully: ready for orders (in command reach, AP left);
  - mostly: out of reach, and the leader's walk straight toward it gets into reach, surely;
  - somewhat: the same walk gets there but isn't sure;
  - barely: no walk this turn gets there, or the unit is spent (grey).

**Unsure walk** (`HUD._sure_walk`): the walker is held (breaking free is a contest), or the walk
crosses ground the player's side can't vouch for (the same test as the `?` on a move cost), or it
steps on a known trap.

**Walk and use.** The Strike charge (`HUD._charge`) now takes any unit-target skill: clicking a
"mostly" target walks to the cheapest sure tile and uses the skill as one order. Hovering it shows the
walk and "Click: walk N, then use: ...".

## Calls made on judgement (question 84)

1. Suspicion alone makes a black shape, even in daylight (the designer's "suspicious hiders").
2. Too far to make out under limited sight counts as concealment.
3. Strengths are 0.3 / 0.65 / 1.25 / 1.6 of the plain glow, sizes 0.8 / 0.9 / 1.15 / 1.3; the plain
   glow sits between somewhat and mostly.
4. With a skill armed the command glow gives way to the skill's.
5. A spent unit glows barely (and is grey); a far one in colour can also glow barely.
6. The command glow judges one walk of the leader straight toward the unit, not every tile it could
   reach (cheap; can under-report "mostly" when only a roundabout walk is sure).
7. Clicking a "somewhat" target doesn't walk: the note says "Out of reach".
8. High contrast lifts the glow of the own side and of any unit with a level.
9. `Unit.command_look` is gone; `set_glow` and `set_saturation` replace it.

## Left to do

- "Somewhat" could offer the unsure walk on a forced click (as Strike's forced charge does); not built.
- Area skills give no glow; tiles in range are still the overlay's job.
- Command glow follows the leader only; a party member with its own reach isn't walked.
- The reach map is now computed while a skill is armed (it was skipped); watch the cost on big maps.

## Revised 2026-11-10: suspicion in plain view

Branch `v-suspicion`; tests `hud_test.test_silhouette`, `hud_test.test_suspicion_marks`. Replaces call 1 above.

- Suspicion no longer counts as concealment (`Read.concealed`). A black shape is a concealed unit (dark,
  fog, hiding, too far) whose side can't be told, or whose shown side the viewer suspects is a lie.
- A **trick** (`Read.trick`) is one that would fool the viewer but for its suspicion (trickery, a front,
  Conspire). Suspected (`Read.doubted`) in plain view, `Read.mark()` gives:
  - DOUBT, still fooled or side unreadable: a white "?" pops and fades (~1 s, `Unit.MARK_TIME`); it shows as
    if unaffiliated (own colours, neutral glow and bar trim; card chip "Suspected");
  - CAUGHT, the suspicion has seen through it (the read no longer deceived, its true side shows): a "!" in
    its true side's primary pops and fades; it wears that side again.
- Discovery uses the existing mechanic (each stack takes a rank off trickery) rather than a new threshold.
- `HUD._pop` remembers the last mark per unit (`HUD.marks`): a pop plays only on a change, from the
  observer's read (the leader's, as `view()`), so only suspicion the player's side holds shows.
- A plain unit merely suspected (no trick) gets no mark and keeps the ordinary look.
- Ruled 2026-11-11 ("unit card should just read ? / suspicion tracked by unit not just leader, while
  commanding unit player sees through their eyes"); branch `w-sight`, test `hud_test.test_sight_by_unit`:
  - The card chip reads just "?" (was "Suspected").
  - `HUD.eyes()`: while the player commands a unit (`HUD.commanding()`: selected, alive, of its side, in
    the TURNS phase on its side's turn, not autopilot; whether it can take another order doesn't matter,
    so the view holds as orders are spent) the map's units, shapes, marks, glow, card reads, suspect
    tiles and tile reads follow that unit's read; otherwise `observer()` (the leader, else any ally).
    The viewer's own card still reads as the leader sees it. `observer()` itself is unchanged (camera,
    spellbook fallback).
  - `HUD.marks` is kept per viewer. A viewer's first look (new eyes) notes its marks without popping;
    after that a mark pops only when that viewer's read of the unit changes, so switching units pops
    nothing by itself (returning to a viewer whose read changed while away does pop, once).
  - Cost: a selection already redraws (`select()` -> `_mark()`); no per-frame work was added.
