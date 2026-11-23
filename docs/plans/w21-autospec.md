# w21-autospec: units spend skill points by their bio
Goal (user): AI picks skills by bio (tags/types; exploratory / training / remedial), else class tree. Player units never
auto-spec except a long-press "Spec Automatically" on the skill screen; under enforced auto (Disturbed) points are spent,
refunded as control returns ("level down"). "Hard" settings toggle: units spec automatically.

## Reading
- Spend code before: Unit.take_path() (w18-monster-ai: Monster traits, cheapest raise first); take_flex() (w18-flex-ai)
  only picks trees, spends nothing. No w19-monster-ai / w19-flex-ai plans exist. Non-Monster NPCs never spent points.
- NPC = bio or path_auto (w18). Player units have no bio (bio isn't saved); none marked as the player's.
- "Level down": Unit.unranked() undoes `purchases` newest first while a level curse lasts. No refund of points exists.
- Enforced auto: Unit.disturbed() (HUD.autopilot() reads it for the starter), Unit.uncontrolled.
- No scene sets skill_points: NPC spending only shows at level_up (and Monsters' owed points at ready).

## Calls
1. Bio data: `Bio.prefers: Array[StringName]` (plain words: skill tags, postures offensive/supportive/defensive, kinds
   active/passive/toggle; an item can append) + `Bio.spec` (one of Bio.SPECS: exploratory, training, remedial; "" default).
   Written by `unit.py new --prefers fire,passive --spec training`; `unit.py check` validates spec. Word match: `Skill.fits()`.
2. One routine `Unit.auto_spec()`: a purchase at a time, best affordable; score = 10 per preference met (PREFER_WEIGHT)
   + 5 for the mode's leaning (SPEC_WEIGHT: exploratory = an unlock, training = a raise, remedial = a skill in the
   posture/passive bucket its own ranks hold fewest of); ties cheapest, then order (raises in _own order, then options()).
   Never hoards: training with too few points for a rank-up unlocks instead. Leftover only if nothing is affordable.
3. Pool: class skills (Role.offered()) always; general trees / species / knowledge only when a preference matches.
   No bio preference and no mode = class tree, cheapest first (so unlocks before raises). Flex trees count as non-class.
4. Unified: take_path() now only picks the path and sets owed points; auto_spec() spends (Monster default = class
   pool = path traits, cheapest first: w18 behaviour unchanged, its tests pass untouched). take_flex() picks only.
   Non-Monster NPCs now spend too (at ready if they have points, and each level_up).
5. Player's unit: new `Unit.player_unit` (set by from_dict() and Battle.starter()). npc() = (bio or path_auto) and not
   player_unit, so a player's unit with a bio never auto-specs.
6. Enforced auto = disturbed() or uncontrolled (unit-level; a leader-down autopilot doesn't count). Points spent then are
   counted in `auto_spent`; refund = `unspend()` newest purchase first (the Level Down order of unranked(), but for good),
   at the start of its side's turn once not enforced (Battle.turn setter), and at Phase.OVER. A save written mid-fight
   while still Disturbed keeps the auto-spent skills (undone).
7. Hard: Settings CheckButton "Hard" (Prefs "hard", `Unit.hard` static, as auto_equip). Every unit auto-specs at
   level_up; a player's unit's spend isn't refunded. Not at battle start (only "at level-up").
8. "Spec Automatically": button in the skills footer (left), visible when the player may spend, disabled at 0 points;
   fires on release after PersonaPanel.HOLD_MS (500 ms), as PersonaPanel's Clear. Logs the purchases.

## As built
Files: Scripts/Bio.gd, Skill.gd (fits), Unit.gd (npc, enforced, spec_due, auto_spec, spec_options, _make_up, _thinnest,
unspend, refund_auto, player_unit, auto_spent, hard; take_path/take_flex gates), Battle.gd (starter flag, refund hooks),
HUD.gd (Hard pref, _on_auto_spec), SkillTree.gd (AutoSpec hold), Scenes/UI/hud.tscn (Hard, AutoSpec), Util/unit.py.
Tests: new Tests/autospec_test.gd: test_modes (table: plain/exploratory/training/remedial/prefers; NPC vs player level_up),
test_refund (Disturbed round trip + Hard), test_button (click vs hold, Hard toggle present). Existing tests changed: none.
Mutations (each fails autospec_test): training leaning off; Battle turn refund hook off (3); hold check off; class-pool
gate off; player_unit gate off in npc(); hard off in spec_due.
Suite: start 11544 checks, 0 failed (1078); end 11564, 0 failed (1081). Shots: S/shot_w21-autospec/ (footer button, Hard toggle).
AI turn cost: spending is in level_up/_ready only; the turn setter adds one int compare per unit.
