# w18-monster: Monster class, one path at level 1 (starmen, Sirens, skeletons)

User: "Monsters are a unique class. At level 1 a singular path must be selected or will already be pre-selected. We'll start with three paths: starmen, Sirens, skeletons. Monsters get their traits for free, and may rank them up with skill points."

## Readings (follow-up.md F16, no Answer filled: best guess used)
- Playable and NPC. A path = one tab (kind Path) over a root `Trees/monster_<path>.tres`; its traits granted at rank I when the path is taken.
- Other skills: the unit's own (scene / learned), not the path's. Siren, Skeleton, Starman scenes untouched (no role).
- Starting screen: Monster on it; the path is picked on the skills screen's existing choice box (picking is free, at level 1).

## Plan
- Role monster (role.py new, --human), choice "Path" (role.py tab --choice Path) x3 tabs Starmen / Sirens / Skeletons.
- Generic: `TreeChoice.free`: picking a tree of it learns its opening skills (root branches with nothing before them) at rank I, no points; ranks past I cost raise_cost() as any skill.
- Pre-selection = the pick machinery: `Unit.picked` exported (a scene or helper lists "Path/Sirens"); picks() fallback (learned a skill on the tree) already reads a unit authored with a path's trait.
- Helper `Unit.monster(path, level, faction)` for Thesis of Theseus.

## Calls
(filled as built)
