# w18-flex-ai: NPCs take flex trees
Calls: NPC = unit with a `bio` and a role. `Unit.take_flex()` on _ready and level_up, only if no "Flex Tree/" in picked (authored pick stands): (1) flex slot due -> first of flex_options(); (2) else on an inverted page -> first invert_options() tree some stat pays for, cheapest stat above floor 6 (lowest value; FLEX_PAY order ties); one tree per run of it. Authored "Flex Tree/<t>" in picked already works (general_trees reads it): tested.
Files: Scripts/Unit.gd, Tests/general_test.gd test_flex_npcs.
As built: suite 11339 checks, 0 failed (1065 tests; start count not measured, base 1064). Test: general_test.test_flex_npcs (7-row table + at-floor jester + level_up). Mutations (no bio gate, dearest stat, no level_up hook, no already-picked gate): each fails 1.
Jester picks Student first (tree order) when a stat pays; at floor for caster payers it falls through to Scout via cha.
