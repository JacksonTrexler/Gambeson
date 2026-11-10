# Battle UI v2: hover to plan, click to do

Combat should read at a glance and move at the player's pace. The map shows what will happen; text
and numbers appear only when the unit actually knows them. This is a plan; nothing here is built.

## What's in the way today (`Scripts/HUD.gd`, `Scripts/Overlay.gd`)

1. **Four places decide what a click means**: `click()`, `_replan()`, `_tip_text()` / `_charge_line()`
   and `use_slot()` each work it out again, so the preview and the action can disagree.
2. **Arming a skill is a mode.** While armed, the move plan and reach shading switch off; the player
   backs out to walk.
3. **Only slot 1 gets walk-and-use**, and only on foes (`_primary()`, `_charge()`).
4. **Self and auto skills fire on the key press**, with no preview.
5. **The tooltip gives instructions and sums**: "Click: walk 3, then Strike II / 3 AP · 65% to hit ·
   4-9 damage", "Ctrl-click to strike at whatever may be here", "?%" when Defense isn't known.
6. **Refusals are sentences** on the hint line (`_say()`, `_nag()`), read after the fact.
7. **Focus can be lost.** The leader is selected as the turn opens, but a right click or a click on
   empty ground selects nothing, and no slot is ever selected by default.

## The model

The player's unit is always the focus. One slot is always selected (the first, or the last used: a
Settings toggle). Hovering shows the plan; left click does exactly that; right click steps back once.

| Hovering | Shows | Click |
| --- | --- | --- |
| A tile | The walk as the unit expects it, from tiles it can see; uncertain steps dashed | Walk |
| A foe | Walk into range and use the selected slot, or the first offensive skill to its right | Walk and use |
| An ally | In reach: select it for orders. Out of reach: the leader's walk into command range | Select, or walk |
| Itself, before acting | Rest, or keep channeling | Rest / continue |
| Itself, self skill selected | What the skill will do | Use |

Selecting a support or defensive skill that takes an ally turns the map to the support view: allies
glow by how reachable they are, foes fall back, and hovering an ally plans the walk into range.

## How it's built

1. **One `Intent`**: `HUD.intent(cell) -> {kind, unit, skill, target, walk, access}`. The overlay draws
   it, the tooltip words it, `click()` runs it. The four deciders above are deleted. No behaviour
   change in this step; `hud_test.gd` pins it.
2. **Focus and the selected slot**: `select(null)` becomes "back to my unit"; `armed` becomes `slot`,
   always set, and no longer blocks walking. `_primary()` becomes "first offensive from the slot".
3. **The hover table**, one row at a time, each a new `Intent.kind`: ally walk-to-command, rest and
   continue-channel on self, support view, self preview.
4. **One visual language**: the four glow strengths from `docs/plans/silhouettes-glow.md` (now, after
   a sure walk, after an unsure walk, not this turn) mark targets in every view.

## Saying it without words

- **Costs on the bars.** The AP, movement and resource a plan would spend flashes on the unit's own
  bars; an exhausted skill's slot shows its raised cost as pips, not "exhausted x2".
- **Damage on the target.** A known HP bar shows the span a hit would take. When HP isn't known the
  target keeps its read ("Bloodied", "Menacing, cold") and no number is invented.
- **Odds by feel.** Target brackets are solid, broken or faint for likely, even or unlikely; when
  Defense can't be made out they waver, in place of "?%". The exact figure stays on the unit card.
- **Reach as shape.** A target just out of range shows the gap as two rings (already a todo item)
  in place of "Out of reach of Strike".
- **No as motion.** A refused order shakes the unit and floats one word ("Spent", "Too far"); the full
  reason is on its card.
- **Uncertainty looks uncertain.** Dashed paths, silhouettes and wavering marks carry what "?" and
  "Something" carry now.
- The tooltip shrinks to a name and a read; instructions ("Click to...", "Ctrl-click...") move to the Guide.

## Pace

- After an action the same unit and slot stay selected; a spent unit hands over to the next one that
  can act (a toggle).
- The turn change (`TRANSITION`, 1 s) and the AI's moves can be hurried by holding a key, never blocking input longer than the animation.
- The log stays, collapsed to its last line; floating numbers on units carry the moment.

## Order and size

1 (M, refactor) → 2 (S) → 3 (M) → words-to-cues, one bullet at a time (S each) → pace (S). Each step
ships on its own and is checked with a capture.

## To settle (?90)

- Does resting by clicking yourself end the whole side's turn, or only that unit's?
- "First offensive skill from the selected slot": search rightward only, or wrap around?
- Odds as three bands, or keep the percentage when Defense is known?
- A self skill: confirm with a second key press, a click on yourself, or both?
