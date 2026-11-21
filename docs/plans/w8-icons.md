# w8-icons (?223)

The user (2026-11-20): skill icons should be coloured or white-and-tinted, but expected to be icons / thumbnails.

## Readings
- The hotbar (SkillSlot) multiplied every icon by a near-white and its brightness; the skills screen's tree views (SkillGrid, SkillWheel) multiplied by a tag-tone ink per state. The spellbook list (SkillEntry) draws no icon, only a tag-coloured stripe, so it needed nothing.
- w7-art made no coloured-or-not helper.

## Calls
1. One helper in Skill.gd: `is_coloured(tex)` scans the texture once, cached by path. Coloured = any solid pixel (alpha >= 0.78) that is not near white (min channel < 0.78). Placeholders (white letters, translucent black edge at alpha 150) never trip it. Today 38 of 272 skill icons are coloured art, 234 white.
2. `icon_ink(tex, ink, dim, alpha)`: a placeholder returns the tint it had; coloured art returns grey `dim` at `alpha`, never a tag tint.
3. States on coloured art: tree views learned 1.0, open 0.85, locked 0.4 at 0.55 opacity, stub 0.5/0.5, learned-but-unworn x0.8; hotbar uses its existing brightness() as alpha. Dimmed, not framed (the node's own edge already carries the tag colour).
4. Not desaturated: modulate can only darken; a shader per slot was over-abstract.

## As built
Files: Scripts/Skill.gd, SkillSlot.gd (1 line), SkillGrid.gd, SkillWheel.gd, Tests/skills_test.gd (`test_icon_ink_tints_placeholders_not_coloured_art`, mutation-checked: threshold set to 0 fails 2 of 3 checks).
Screenshots: scratchpad shot_w8-icons (hotbar, skills screen). Seen: coloured Strike/Mana on the bar, coloured Mana/Mage Armor learned, Clairvoyance/Forage open, a locked one dim, "So"/"Na" placeholders still tinted.
Undone: no screenshot of a white-placeholder skill on the hotbar (the mage's bar holds only coloured ones), nor the hotbar's lit state (captured during allies' turn, so dimmed).
