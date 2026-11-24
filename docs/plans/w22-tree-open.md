# w22-tree-open
Goal: grid tab opens at highest learned tier, or at top if none learned.
Calls: "unlocked" = learned (state_of == learned, incl. item-lent). Highest learned tier's row bottom sits at view bottom (above BAR), so the next tiers up show. None learned -> scroll 0 (top, highest tier). floor_y() removed (unused). TreeScroll 176px and BAR kept.
Built: SkillGrid.open_y() (-1 = none), SkillTree._scroll_to_open(). Test: hud_test.test_adventurer_skills_screen (top when none; learned -> formula).
Mutation: top->bottom scroll fails "opens at the top". Reverted.
