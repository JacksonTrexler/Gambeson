# w22-shots: visual check of Wave 22
Goal: frames of Starbuilding tab, Starchitect bar swap, Starpower/Mana Resonance, star map, signal/arc/lock HUD. Driver S/driver_w22shots.gd (not in repo). Frames S/shot_w22-shots/<mode>/.
## Calls
- Fix only tiny obvious visual bugs; list the rest below.
## Findings
(see below)
- BUG (fixed): skills screen grid tabs (all but the Adventurer wheel) showed a blank tree: w21-vscroll put the Column in a VScroll, so TreeScroll (no min height, Body expand has no spare room) got 0 px. Fix: TreeScroll custom_minimum_size (0,176) = the wheel's. Test hud_test.test_adventurer_skills_screen (+1 check; fails without the fix). The screen is 264 tall so the detail/foot now sit below the fold (scroll), as the wheel tab already did.
## Seen (S/shot_w22-shots/, driver S/driver_w22shots.gd, modes tab|bar|pool|map)
- 1 Starbuilding tab (teal): Startile, Starpanel, Starbridge, Starpower Generator, Starway, Manifest Starchitecture drawn; Starnest (T9) sits above the fold at open (scrolls).
- 2 Wizard bar: regular (Strike, Mana, ...) -> Manifest on -> Startile/Starbridge/Starpanel/Generator -> off -> regular. OK.
- 3 Starpower + Mana Resonance: teal "SP 10/13" bar, teal star and blue-star-on-yellow icons. OK.
- 4 Map: startiles, generator (orange), starpanes, Starway pair, Stardust with half arc and "Repairing: 1/2, Signal: 3" pane line, "Signal: 1" on a startile, "LK locked 40" row, hatched sealed segment on the leader's map bar (visible, 4b).
## Open (not fixed)
- Wizard is not on the entry screen (Adventurer only); driver adds it to the picker.
- Hotbar names clip ("Mana Reson", "Starpower G"): existing 5-slot width.
- Skills grid: horizontal scrollbar overlaps the T1 row's bottom edge; Starnest (T9) off-screen at open.
- Startile hover pane: "Starpower source, 0% full" on a plain startile (charge 0).
- cast_at of Startile (range 5) at 2 tiles failed after the first cast in the driver (cause not found: fits_at true, price ok); tiles laid with Battle.lay_star instead.
