# w9-icons
Goal: disabled icon sat .25/val .70, untoggled sat .15/val .85; disabling declares why + badge; non-colour cue; locked coloured icons on skills screen use the rule.
Files: Skill.gd (LOOK_*, mute, muted_tex, draw_icon), Unit.gd (disabled_by, disable(src)), Battle.gd (passes skill), SkillSlot.gd (icon_look, off_by), HUD.gd, SkillGrid/Wheel.gd.
Decisions: colour maths = Skill.mute(); look zero = old behaviour. Cue: slash (disabled/locked), hollow ring (untoggled). Hook: Unit.disable(..., src: Skill) -> disabled_by[skill]; slot shows src.mark() first char as badge + "Disabled by X" tooltip; any skill calling disable with src does it. Curse (Brainfog) is the one example. Postponed disablings carry no src. Grid/wheel: coloured art only (locked=disabled look+slash, unworn=untoggled look+ring); placeholders unchanged. Opacity 1 with a look (colour carries the state, text still dims).
Done: code in. Next: tests, shots.
