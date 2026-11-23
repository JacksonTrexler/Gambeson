# w21-vscroll: menus scroll vertically where the screen is short
Goal (user): "menus should have vertical scrolling as needed. e.g. demo start screen doesnt fit by default in landscape".
Start: 11461 checks, 0 failed (1071 tests).

## Reading
- Screen: 480x270 design, stretch canvas_items/expand: the visible height is NEVER below 270 (a short landscape window only widens it: 1000x420 -> 642x270). So "short" = 270.
- Entry Form is 324 tall (360 with Continue/Party/Delete): ran off top and bottom even at 16:9 (screenshot, before). Skills screen min 330 (wheel tab). Party 260 with 13 classes (grows). Sheet 183, Settings 220, Spellbook 256 (own scrolls), portal menu ~209: fit. HUD side panels (prep) 264/267: fit, left alone.

## Calls
1. Twin, not a generalised HScroll: new `Scripts/VScroll.gd` (class_name VScroll, a ScrollContainer, vertical only). HScroll's arrows/drag/sideways-wheel are row things; a column has room for a bar and the wheel/pan are native. Shared idea only: "ask for the content's size, no more than the screen's" (HScroll.max_width, VScroll.reserve).
2. VScroll asks its parent for min(content height, screen height - `reserve`) (default 16: margins around it). Full-rect page: no effect; inside a centred panel: the panel stops at the screen's edge and content scrolls. Refits on content min change, visibility, viewport resize. `VScroll.wrap(content, keep)` for code-built menus; `reserve` set after build = the rest of the menu's height + 16 (Party, portal menu).
3. Applied: entry page (whole Center in `Scroll`: Title..Delete reachable; the class row stays an HScroll within), Party screen (grid only: title/count/Done stay put), skills screen (whole Column: Close/title at top, footer reached by scroll; a wheel tab at 270 needs ~60px scroll; chose it over scrolling only the Body since the wheel needs its 176px and the head/tabs/detail leave ~100), portal menu in GamutsTower (text body only, Enter/Back stay). Not touched: HUD side panels (battle HUD, w21-hudpanels, fit 267/270), sheet, settings, spellbook (fit / own scrolls).
4. HScroll: `max_width` 440 -> 420 so the page's bar (8px) doesn't clip the form's 476 against 480; and a row with nowhere to scroll (arrows hidden) no longer eats the wheel, so over Side/Scenario the page scrolls.
5. No mouse-drag scroll on VScroll (HScroll has it): wheel, trackpad pan, bar, keyboard focus follow. Scrolled Skills footer: picking a skill does not auto-scroll to the Unlock button (undone, small).
6. Movie capture is always 1440x810 (stretched for non-16:9), so short-window shots are distorted; layout checked numerically (VP 642x270) and at 1440x810.

## Tests
`Tests/vscroll_test.gd`: test_rule (clamp, wrap placement, reserve refit, follows content, no bar when it fits), test_menus (test window pinned to 480x270: entry form taller than screen, page scrolls over all of it and Play reachable; Party with a 17-member roster stays on screen; skills screen with a tall tree stays on screen). `hscroll_test` extended: a row with no room leaves the wheel unhandled, a scrolling row keeps it.
Mutations: VScroll clamp removed -> 4 fail; PartyPanel reserve removed -> party check fails; HScroll `and left.visible` removed -> hscroll check fails.
Existing tests changed: none (only added checks).
