# w22-bar-reshoot
Goal: re-shoot Wizard bar swap with new name font (SkillSlot.name_font 7 -> min 4).
Driver: S/driver_w23bar.gd (bar mode); frames S/shot_w23-bar/ (bar_all.png = regular | Manifest on | off).
Seen (3x, 1440x810):
- regular: Strike, Mana, Startile, Starbridge; all names full size, no clip.
- Manifest on: Startile, Starbridge, Starpanel, Starpower Generator; Generator shrinks to 4px, fits whole in slot, no clip, legible but small (grey dimmed slot as unaffordable/idle). Others 7px.
- off: back to regular (shot mid enemy turn, dimmed).
- "Mana Resonance" / "Manifest Starchitecture" are not on the Wizard bar here (spellbook/tree only); not shot.
Call: no code change; 4px at 3x is small but readable and unclipped. Wrap to two lines would be next option if user finds it too small.
Tests: none run (no code change).
