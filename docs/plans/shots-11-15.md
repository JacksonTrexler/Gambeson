# Screenshot checks (y-shots)

Driver: `S/driver_shots.gd` (phases clair, spec, facing, flank, items, warcry), frames in `S/shot_y-shots/<phase>/`
(movie frames lag the driver by tens of frames; the turn banner covers the first ~100). No code changed: nothing was
plainly broken and small.

## 1. Clairvoyance pings (Wizard, rank 3, wisdom 8, foes concealed)
Black silhouettes at each pinged foe's tile, the tile tinted lightly; hovering one gives the circle, the label "Something"
and the tile tooltip "Something may be here: sensed". Reads clearly, in keeping with the other black shapes; overlaps nothing.
After End turn (round 2) the pings stay and move with the foes. Not seen: the suspicion stacks. They are not drawn on
the tile or in its tooltip (the "?" gold mark at one tile is plain ground suspicion, not the pings). Follow-up: show the
stack count on a sensed tile (`HUD._tile_text`/tooltip near `dubious[r.cell] = "sensed"`, HUD.gd ~1996; `Overlay._suspect_mark`).

## 2. Specialist tree (Rogue, General . Specialist tab)
T2: Synergy, DS; T3: four skills (Ds, St, Ta, Ww), not three; T4: SF, Rs. T1 empty, T0 empty (floor labels only).
Tier rows, the green tab and the detail line ("T2 . Needs a T2+ specialist class skill") read clearly. All greyed (no
points). One oddity: the tree opens scrolled to the top-of-tree (T4 at the top edge, row cut off by the scroll
frame) with an empty T1/T0 under it. Minor; belongs to x-equip (SkillGrid): open it scrolled to the lowest filled tier.

## 3. Facing chevrons (Fighter walking, `facing` phase)
A small grey triangle on the unit's facing side, mid-height, on every unit (player and foes). It reads, but it is
low-contrast and about 4 px at 1x, drawn over the sprite's arm/weapon (Fighter's axe arm), so easy to miss.
Follow-up: a larger or side-coloured chevron placed outside the sprite box (`Unit.gd` facing tick draw, `facing` setter).
Rear/flank tags: the HUD shows no label at all for them (confirmed by facing.md "Not done"); the hover line only has
"N% to hit". In my flank scene the foe stood in concealment (black shape), so no forecast showed. Follow-up: show
"Rear"/"Flank" next to the odds (`HUD._hover_text`, HUD.gd ~2790), x-polish's forecast territory.

## 4. Item-lent rings and emblem diamonds (hotbar)
Kick lent by the boots: a pale blue ring at the slot's lower right, under the rank pip. Strike with a Sigil: a gold
diamond at the slot's upper right, above the pip. Both clear, small, in the HUD's palette, no overlap with name or key.
The ring sits a little lower than the pip, so the two do not line up on one baseline; cosmetic (SkillSlot, x-equip).

## 5. Warcry marks
Charge! tiles are orange with a pulsing centre square, Routed! tiles blue with a pulsing square, both inside a faint
outline; hovering gives "Routed! (you...)" in the tile tooltip. Readable. The Routed! blue is close to the blue
movement-range outline and to water tiles, so on a busy board it blends; there is no on-tile text, so the player
must hover to learn which is which. Follow-up for x-gaps (marks HUD): a distinct hue or a glyph per mark kind
(`Overlay.gd` ~434, the swell/fall-in drawing).
