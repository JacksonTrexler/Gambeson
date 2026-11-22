# Item icons: card and spoils (z-icons, 2026-11-15)

Read: docs/plans/item-icons.md (call 8: the card's third icon touched the class word).

## Calls
1. **Card trims leave the portrait.** They were anchored over the portrait's foot, 10px, so a third one reached the name block. Now an HFlowContainer row of its own under the head (UnitCard.trims): 16px icon with its banner beside it (the corner-overlay branch of trim_mark is gone), wrapping, so nothing can overlap however many items. Costs about 30px of card height.
2. **Spoils**: a wrapping row of icons with banners (`UnitCard.item_row()`, reusable for any loot list) under the Over panel's text, tooltips carry the name. The text line "Spoils: a, b" stays: the log and Save read OverText, and it names what icons cannot.
3. Other lists: the sheet's stash already shows icons (q-icons); Loot.gd draws nothing (a Resource), so no change there.

## Tests
`item_icons.test_card_icons_never_overlap_and_spoils_show_them` (9 trims, rects do not intersect the head or each other; the spoils row has an icon each, none without). Mutation: h_separation -12 fails it.

## As built
Scripts/UnitCard.gd, Scripts/HUD.gd (`_show_spoils`), Tests/item_icons_test.gd. Captures: scratchpad shot_z-icons/ (before b.png, a_card.png, a_spoils.png).
