# w22-shots: visual check of Wave 22
Goal: frames of Starbuilding tab, Starchitect bar swap, Starpower/Mana Resonance, star map, signal/arc/lock HUD. Driver S/driver_w22shots.gd (not in repo). Frames S/shot_w22-shots/<mode>/.
## Calls
- Fix only tiny obvious visual bugs; list the rest below.
## Findings
(see below)
- BUG (fixed): skills screen grid tabs (all but the Adventurer wheel) showed a blank tree: w21-vscroll put the Column in a VScroll, so TreeScroll (no min height, Body expand has no spare room) got 0 px. Fix: TreeScroll custom_minimum_size (0,176) = the wheel's. Test hud_test.test_adventurer_skills_screen (+1 check; fails without the fix). The screen is 264 tall so the detail/foot now sit below the fold (scroll), as the wheel tab already did.
