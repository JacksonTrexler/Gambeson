# Studies UX (w7-studies, 2026-11-20)

The user (docs/agents/answers-2026-11-20b.md, "UX nits"): cut "No foe or tile studies left..." to "No studies left" and only on click;
hovering a studyable tile or unit shows a magnifying glass next to the mouse, grayed out if no studies are left. Task adds: the
preparation banner becomes a top box, "Preparing" over a smaller "Study: X", generic so Surveys, Evaluates and Inquisitions can add lines.

## Readings and calls

1. **The message** was already only a click's `_say()`; its text is now "No studies left" (one string for ally and foe/tile). "Already
   studied" is unchanged.
2. **The top box is `PhaseBox`** (`Scripts/PhaseBox.gd`, a `Tip`-styled panel at top centre): `show_lines(title, sublines)` lays out a gold
   title and a smaller line per entry; an empty title hides it. It knows nothing about studies.
3. **The API for later uses: `HUD.prep_uses`**, a `Dictionary[StringName, Callable]` in insertion order; each Callable returns its
   subline (`""` leaves it out). `_refresh_phase_box()` runs on every refresh; in PREP it titles the box "Preparing" and calls each use.
   A Survey/Evaluate/Inquisition builder does `prep_uses[&"survey"] = _survey_line` and edits no layout. Other phases show no box (the
   title argument is the hook for giving them one).
4. **Study line wording**: "Study: 1 ally, 2 foes or tiles" (zero parts left out; "Study: none left" when both are 0). The bottom hint line
   says nothing in preparation now (the box replaces "Preparing. Studies left..."; "Begin when ready" is the button's own label).
5. **The cursor is a sprite following the pointer**, not an OS cursor (it greys by modulate and shows beside the system arrow, up and to the
   right so the unit tooltip at +10,+10 isn't covered). Placeholder art `Icons/UI/study.png` (11x11 magnifier, white on clear), drawn by a
   new `python3 Util/icon.py glyph study --shape magnifier` (a `glyph` command for small HUD marks; shape lives in `SHAPES`).
6. **When it shows, and greys**: `HUD.study_state(cell)` is `&"open"`, `&"spent"` or `&""`. Shown over any on-map tile or unit but the
   leader (the leader can't study itself) while preparing. Grey (`spent`) when no study of that kind is left (ally by cha, foe/tile by
   wis) **or the thing is already studied** (call: the same dead end the click reports as "Already studied", so it greys too). It
   follows the hovered cell, so it hides over panels (hover is cleared there).

## Tests (Tests/prep_test.gd, `test_hud` extended; no new file)

Checks at the seams: the box's title and lines (and a second use added through `prep_uses`), `study_state` over ally, foe, tile, leader,
nothing; the cursor's visibility and grey; "No studies left" set on a click and not by hovering; box and cursor gone once begun.
Mutation spot-checks (each failed the test, then reverted): dropping the studies-left test in `study_state`; skipping `use.call()`;
cursor always visible; reverting the message text.
Suite: starting 10352 checks, 0 failed (979 tests); final 10363 checks, 0 failed (979 tests). `study_state` guards a freed battle (the HUD outlives it in some tests).
