# Pace (Battle UI v2, last section) - branch n-pace

Plan: the Pace section of `docs/ui-ux-v2.md` (?90, ?123). Built on top of v2 as `docs/plans/ui-v2.md`
describes it (one intent, an always-selected slot, clicking yourself to rest locks only that unit),
beside the turn clock (?103) and moving together (?104). Standing guidance: the less text to read, the better.

## Readings and calls

1. **"The same unit and slot stay selected."** The unit already stays. The slot is the user's answered
   Settings toggle `keep_slot` (off: back to slot 1 after an action, on: the slot just used). Left as the
   user set it; Pace adds nothing there.
2. **Spent** = the unit can no longer take an order this turn (`HUD._orders()` false: tapped by AP,
   order caps, a lock - rest, hold, a wasted intent - or helpless). A unit that has walked but still
   has AP is not spent.
3. **Handover order**: the next unit after the spent one in the side's order (`Battle.members()`, the
   order Tab already walks), wrapping; the first one that hasn't acted this turn wins, else the first that
   can still act. The leader is in the rotation like anyone. None left: the focus stays on the spent unit.
4. **When**: after any order goes through - a skill, a walk (it may hit the order caps), resting /
   standing down by clicking yourself, Hold. Only on the player's own turn, and only if the spent unit
   is the one selected (so a click elsewhere isn't overridden).
5. **The toggle**: Settings "Next unit when one is spent" (`HUD.hand_over`), on by default.
6. **The held key**: a new bindable action `hurry` (Settings > Keys "Hurry"), default **F**. Not Space
   (End turn), so pressing to end the turn and holding to hurry don't fight over one key.
7. **Hurry = x4** (`HUD.HURRY`): while the key is held every paced wait runs four times as fast: the turn
   change band (`TRANSITION`), the wait between units acting alone (when `together` is off), the end of
   their turn and the walks they animate. It's read every frame, so letting go mid-turn slows back down.
   Waits are counted in hurried time (`HUD._wait()`), and the AI turn ends when the last (hurried) walk
   is done, so input is never blocked longer than what's on screen.
8. **The player's own turn**: the turn change was already not blocking input (the curtain ignores the
   mouse); hurrying it just clears the band sooner. The clock keeps its full second for the band either
   way, so hurrying never costs time.
9. **What isn't hurried**: floating numbers and refusal shakes (they carry the moment, and don't block),
   and the opening initiative roll (any key already skips it).
10. **The log**: collapsed by default to its last entry (the whole entry, wrapped, not just its last
    visual line), sitting at the foot of the right column above End Turn. Clicking the line or the LOG
    title opens the whole log; clicking the title again collapses it. The full log keeps every line
    while collapsed.
11. **Words**: no new text on screen beyond the toggle and key names; the LOG title shows a small
    arrow (▸ collapsed, ▾ open).

12. **The Guide** gets two sentences (handover; hold F to hurry, click LOG for the whole log). It names
    F as a fixed word, like the Guide's other keys, so a rebind leaves it stale.

## As built

- `Scripts/HUD.gd`: `hand_over`, `_hand_over()` (called from `_done()`, `_move()` and `hold()`), `next_able()`;
  `HURRY`, `speed()`, `_wait()` (replaces the three `create_timer` waits in `_act_alone()`), `_hurry()` (each
  frame: the turn-change tween and the walks); `log_open`, `show_log()`, `_log()` also sets the last line.
  `end_turn()` and the AI's choices are untouched.
- `Scripts/Overlay.gd`: walks run at a speed (`hurry()`); `walking_left()` reads the walk tweens (hurried time)
  instead of a wall-clock end.
- `Scenes/UI/hud.tscn`: `LogGap`, `LogLine`, `LogTitle` clickable; Settings `HandOver` toggle.
- `project.godot` / `Scripts/KeyBinds.gd`: the `hurry` action (F), "Hurry (hold)" in Settings > Keys.
- `Scripts/Guide.gd`: the two sentences.
- Tests: new `Tests/pace_test.gd` (hand_over, hurry, log). No existing test changed.
- Captures (`shot_n-pace/` in the scratchpad, frame 150; hurry 133): the collapsed log, the open log, Villager1
  resting and the focus passing to Vex, the Nemes band hurried. End Turn to the player's next turn on the
  museum: 60 frames plain, 17 held (30 fps).

## Left open

- Pace's "same slot stays selected" is left to `keep_slot` (call 1); if the user meant it to override the
  toggle, it's a one-line change in `_done()`.
- The floating numbers aren't hurried; with many AI units hurried, they can stack more.
