# w21-anim: unit animation convention, Util/anim.py, state animations

## Goal
User convention (requirements.md "Animation"): `X.png` / `X-neutral.png` base pose; `X-left.png`, `X-right.png` lean poses; `X1.png`, `X-1.png`... idle cycle. Tool builds a SpriteFrames per sprite with per-state animations; units play them by state, paced by statuses.

## Readings
- Unit sprite: `Unit.look` (Texture2D; role's if none) -> `Unit._show_look()` builds a 1-frame SpriteFrames `default`. HUD / `_stack()` / `_show_face()` read `sprite_frames.get_frame_texture(&"default", 0)`: `default` must stay the base pose.
- Sprites: `Units/<Name>.png` (unit.py / role.py / icon.py). Prefabs = `Formations/*.tres` (units: Array[PackedScene]).
- Statuses: Haste = `Unit.HASTE` (stat movement, +); fear = an effect with stat `fear` (Battle.DRIVES); wound = Glossary condition (`bears` wound); no slow status as such.

## Calls
1. Frames live beside the sprite: `Units/<Name>.tres` (SpriteFrames), found by path from `look` at `_show_look()`; no scene/role field. No .tres: today's 1-frame `default`, unchanged.
2. Pose -> state mapping (tool `STATES`): attacking = left, right (rear, strike; one-shot); hit = left (one-shot); investigating = right (one-shot); waiting = numbered cycle, else neutral (loops). `default` = neutral, always first frame. A missing pose falls back to neutral.
3. Frame rates: default 5, waiting 4, attacking 6 (2 frames = 0.33 s), hit 6, investigating 3 (0.33 s).
4. A one-shot returns to waiting when it ends (`animation_finished`).
5. Triggers: attacking = Battle `_done_casting()` on a finished outermost cast (any skill, not only hostile); hit = `Unit.hit()` taking > 0 damage; investigating = Battle `inspect()` / `investigate()` (the looker); waiting = default.
6. Moods -> pace (`Unit.ANIM_PACE`, multiplied): wounded 0.6 (HP under half, or a status bearing `wound`), slowed 0.6 (a status lowering movement or initiative), hasted 1.5 (raising movement or initiative), frightened 1.5 (a `fear` status). Pace re-read on each animate() and each loop.
7. Base names may be any case / hyphenated (sortme style `starman-left.png`); a pose with an extra suffix (`-left-raise`) is listed by `show` as an unused variant, not played.
8. `setup --all` writes only sprites with poses beyond the base (no 27 identical .tres); a named target always gets one. No real posed art in Units/ yet: none written.
9. A lone base image: `_show_look()` as before (1-frame `default`), no `animation_looped` hook (no per-loop cost); `animate()` falls back to `default`.
10. Numbered frames: `X1.png`, `X-1.png`, `X_1.png` all count, sorted by number; `-neutral` counts as base when no plain `X.png`.

## As built
- `Util/anim.py`: `setup <targets|--all> [--dry-run]` (Units/<Name>, Roles/, Scenes/, Formations/ ids; follows scene -> role, formation -> scenes), `show`, `check` (each Units/*.tres current with its poses; posed sprite without .tres; Unit.ANIMS names all made by STATES).
- `Scripts/Unit.gd`: `ANIMS`, `ANIM_PACE`, `PACED`; `_show_look()` loads `Units/<Name>.tres` if there; `animate(state)`, `anim_pace()`, `moods()`; `hit()` plays hit.
- `Scripts/Battle.gd`: `_done_casting()` caster attacking; `inspect()` (past its early return) and `investigate()` the looker investigating.
- `Tests/anim_test.gd` (2 tests, 13 checks). Mutations: drop waiting fallback -> fails; hasted 0.6 -> fails; no hit animate -> fails.
- Tool trial: temp Units/Zz poses (from sortme/starman) -> .tres loads in Godot (5 anims, right frames, loops); stale detection works; temp files removed.
- CLAUDE.md tool line, `.claude/skills/new-unit` mention.
- Suite: 11461 checks, 0 failed (1071 tests) -> 11474, 0 failed (1073 tests).

## Next
- Posed art into Units/ (sibling w21-sprites / Util/sprites.py), then `python3 Util/anim.py setup --all`.
- No visual capture (no posed art in Units/ to show).
