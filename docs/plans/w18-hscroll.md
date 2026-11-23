# w18-hscroll: horizontal scroll for the class picker, reusable
Goal: a non-wrapping sideways list container: wheel, shift-wheel, trackpad pan, drag, edge arrows; used by Choice (the entry screen's class row).
Start: 11088 checks, 0 failed (1047 tests).

## Calls
1. New `Scripts/HScroll.gd` (class_name HScroll, an HBoxContainer: `<` ScrollContainer `>`), not a ScrollContainer subclass: arrows can't be children of a ScrollContainer (it lays out all Control children as content). Scene children are moved into the strip in _ready, so any scene can use it by parenting a row to an HScroll node.
2. "Parent menu" = `Choice` (the shared one-of-many menu; entry's Side/Role/Scenario all use it). choice.tscn: Options now under `Scroll` (HScroll), found by `%Options`. Side/Scenario fit and show no arrows; only a row wider than `max_width` (440 of the 480 screen) scrolls.
3. The scroll rule is one static `HScroll.amount(event, width)`: wheel up/down/left/right all go sideways (row has no vertical), `factor` scales a notch (STEP 48 px), pan goes by larger axis x width/8 (as Godot's own), left-held motion = -relative.x. Tested as a table.
4. Input via `_input` + rect test (a Button STOPs bubbling, so `_gui_input` on the strip would miss wheel over a button; and mouse drag starts on a button). Drag has a 4 px slop; past it the focused button inside releases focus (cancels its press), and the release is swallowed so the drag doesn't click what it ends over.
5. Arrows: both shown while the row scrolls at all, the one at the end disabled (not hidden: the strip doesn't resize as one comes and goes). Click pages by strip width - STEP.
6. `Choice.pick()` scrolls the picked button into view (deferred); `follow_focus` on, so keyboard focus moves follow too.
7. Strip's scrollbar hidden (SHOW_NEVER): arrows say it.
8. Changed existing test: champions_test.test_entry looked up `get_node("Options")` -> `get_node("%Options")` (moved under Scroll).

## Tests
Tests/hscroll_test.gd: test_rule (amount table: every input kind), test_strip (live row: arrows, wheel in/out of rect, slop vs drag, end clamp, entry's last class picked scrolls into view). Mutations: flipped wheel-down sign -> test_rule fails 3; removed rect test -> "and off it does nothing" fails.
