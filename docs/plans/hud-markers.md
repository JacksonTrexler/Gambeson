# HUD markers (branch `n-hud`)

Six open HUD todos. Tests: `Tests/hud_markers_test.gd` (5 tests, 23 checks). Frames in `scratchpad/shot_n-hud/`.

## Readings

- `Battle.cast()` asks every behaviour's `fits()` (Resuscitate: only a Downed target); `HUD.why_not()` (what the
  hover, `intent()`, `targets()` and `skill_glow()` all ask) didn't, so Resuscitate was offered on any ally in reach.
- Borrowed Time had log lines and a float only. Downed had a card chip, log and float only.
- The reserve bars: "only the largest reserve" is no longer true. After the two-bar work the map draws the Energy bar
  (when held), the main reserve and a second reserve (`second_bar`); the card lists every held reserve. What was still
  missing: a third. Stamina, Focus and Sweet Nothings together drew only two.
- The allied glow (`look_of()`, pale mint at the plain strength x 0.55 alpha) read as a haze on grass.

## Calls

1. **Gating** in `why_not()`, before the reach check (an out-of-reach non-target neither walks nor glows). Same check as
   Battle.cast(), no extra rule. New `Behaviour.unfit()` gives the reason when `fits()` says no ("Not for that one";
   Resuscitate: "Only the Downed"), so a later limiting behaviour overrides one method. It asks the true state for any
   visible unit, as cast() does; a Downed unit is visibly down to everyone, but a future `fits()` reading hidden state
   would leak through the hover. Left for when one exists.
2. **Borrowed Time chip**: "Borrowed time: N rounds left" (gold; red at the last) and "N harms to replay" (red) while
   `deferred > 0`, in the Downed chips' place (`_heart_chips`), the existing chip style.
3. **Switch marker**: `SkillSlot.switching` while the unit's channel is a switch on that slot's skill: a turning gold arc
   round the toggle's dot, a pulsing gold rim and a tooltip line ("Switching to Energy: takes effect as the channel
   ends"). Set from `_refresh_bar()`; clears when the channel ends.
4. **Downed on the map**: the sprite lies on its side (about 77 degrees, the side chosen by the tile's parity so
   neighbours differ), 3px lower, and keeps 55% of its colour on top of whatever the HUD asks (`Unit._lie()`, on
   `dbno_changed`; `set_saturation` multiplies). Every observer sees it: it is how the unit looks, not what is known.
   Bars stay where they are. Borrowed time (deferred death) is not drawn differently.
5. **Reserves**: `Unit.more_bars`: a third reserve and any further get a 1px sliver each (stacked between Energy and the
   second bar), made on demand. The Overlay's drain segments (the forecast) still only map the first two bars; I left
   that code alone (it is `m-slayer`'s), so a spend from a third reserve shows on the card row only.
6. **Allied glow**: x1.7 alpha on a tinted (other-faction ally) glow (`ALLY_BOOST`), and a Settings picker "Allied glow:
   Mint / White / Sky / Gold" (built in code beside the contrast toggle; not saved between runs, like the other toggles).
   Mint stays the default; on grass, White and Sky read better than Mint at any strength (frame `ally_picks.png`).
   Question for the designer: change the default to Sky or White?

## As built

- `Scripts/HUD.gd` (why_not, `_heart_chips`, `_refresh_bar`, `_apply_look`, picker), `Scripts/Unit.gd` (`_lie`,
  `more_bars`), `Scripts/SkillSlot.gd` (`switching`), `Scripts/Behaviour.gd`, `Behaviours/resuscitate.gd` (`unfit`).
- No existing test changed. Suite: 42639 checks, 0 failed (653 tests); it began at 42616 (648).
- Not done: Overlay drain on a third reserve; the AI offers nothing new; no Settings persistence for the picker.
