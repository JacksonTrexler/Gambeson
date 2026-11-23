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
1. One generic flag, `TreeChoice.free`: picking a tree of it learns its opening skills (root branches with no `after`/`needs`) at rank I for nothing (`Unit.take_free()`, run on pick and on ready; idempotent). Not a purchase: a level curse doesn't take it back. Ranks past I: `raise()` as any skill (II costs 2). A later skill on a path with a prereq costs points as usual.
2. One-path choice = existing TreeChoice "Path" (picks 1) on the Monster's own tab; tabs kind "Path" (existing kind colour) named Starmen, Sirens, Skeletons (--human). Roots `Trees/monster_{starmen,sirens,skeletons}.tres`, tag martial (the class's focus).
3. Pre-selection, no second system: (a) `Unit.picked` now `@export` (a scene can list "Path/Sirens"; duplicated on ready); (b) `Unit.monster()` sets it; (c) existing `picks()` fallback: a monster made with a path's skill (Floaty) reads that path as picked, and the rest (Hop) comes free.
4. Path contents: Starmen = Floaty, Hop (Hop an active, the user's pair); Sirens = the Siren's innate traits Alluring, Seaborn ??, Opportunist (not Oceanic: a learned toggle drawback; not Rake/Drown/Sing/Tonefoolery: "other skills from the unit's own"). Skeletons: the Skeleton had no trait skill (only unit tags undead, summon), so a new trait **Undead ??** (`Skills/undead.tres`, tag `undead`, data only) carries the tag (has_tag reads learned skills). Ranking it changes nothing yet (no per-rank effect): open.
5. Monster class: focus martial (str 14 dex 11 con 14 int 8 wis 10 cha 9), noun "Monster", tends pragmatic, gambeson + dagger, race human (tool default), colour #7a9a6a, placeholder sprite; general martial. Its own tab holds only the Path box; skills beyond the path come from the unit (scene) or its general trees.
6. Playable: on the starting screen (entry.tscn); the path is picked on the skills screen's existing choice box at level 1 (picking free). The skills badge lights while a free choice is unpicked (`Unit.free_due()`, HUD badge line). Not forced: a Monster can enter battle unpicked (no traits).
7. Siren, Skeleton, Starman scenes untouched (roleless, their innate traits as before).
8. Helper `Unit.monster(f, path, at := 1, nick := "")` (static; `Battle.from_role` + level + skill points level-1 + pick); null for an unknown path. Thesis of Theseus: `Unit.monster(caster.faction, path, rank)` then add to Units.
9. UI fixes: SkillGrid drew nothing on a tab with choices but no skills (early return on empty `_boxes`): now draws when entries exist. SkillDetail adds "Its first skills come free, at rank I; skill points rank them up" for a free choice.

## As built
Files: Roles/monster.tres, Trees/monster_{starmen,sirens,skeletons}.tres, Skills/undead.tres + Icons/Skills/undead.png, Units/Monster.png, Scenes/entry.tscn, Scripts/{TreeChoice (free), Unit (MONSTER, picked @export, take_free, free_due, monster), SkillTab (Monster colour), HUD (badge line), SkillGrid (_draw guard), SkillDetail (free line)}.gd.
Tests: new Tests/monster_test.gd (test_paths: 3-path table at level 3 via Unit.monster: traits free rank I, 2 points kept, one path only, others refused + shut, raise II costs 2, save/load no doubling, unknown path null; test_pick: unpicked owes 1, pick Sirens free at L1, traits on; made with Floaty -> Starmen + Hop). Changed: champions_test.test_entry (+Monster), equip_test.test_traits (+undead).
Mutations (each failed monster_test): no take_free on ready (10); none on pick (2); not idempotent (3); free costs a point (10); picks 2 (14).
Visual: S/shot_w18-monster (m00000090: Class Monster tab, "PATH · PICK UP TO 1" box St Si Sk, footer free line; m00000145: Path · Sirens tab, Alluring, Sb, Op at I).
Suite: start 11255 checks, 0 failed (1058 tests); end 11288, 0 failed (1060 tests). role/skill/unit check ok; launch clean (8 resources at exit only).

## Undone
- Thesis of Theseus skill itself (next card). AI never picks a path for an unpicked Monster (helper/scene pre-select instead).
- Undead ?? has no per-rank effect; Skeletons path is thin (one trait).
- Monster race human (tool default); no monster-specific sprite.
