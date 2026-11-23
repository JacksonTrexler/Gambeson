# w13-invest: rebuild the investigation layer lost in 4fe2c05 (sirens) merge

## Reading (what main already covers)
Orig `Scripts/Investigation.gd` (dc/run/succeed/lead) is superseded on main by Battle: `inspect()` (tiles, hidden units), `doubt()` (tricksters), `suspect()`+`spread()`, `_first_look()`/`_inspect_first()`, `_watch()`/`survey()`, `_look_harder()`.
- new in range: `_first_look()` after travel()/place() — covered.
- held still at turn end: `_watch()` at every turn end, + `rested_turns` widens/boosts — covered (superset; orig only if not acted).
- free when attacked by unseen: hit by a *deceiver* -> `doubt()` (3 sites) — covered; hit by a *hidden/unplaced* one -> only `_lose_cover` + `_note_attack` clue, NO check — GAP.
- pass earns suspicion: inspect/doubt -> `suspect()` 1 stack — covered (orig max(1, wis mod - dist) stacks; kept main's 1).
- cha mod shares: `spread()` (WORD + cha mod tiles, every awake ally) — covered for units; tiles don't spread (orig did) — left, question.
- Detective (stat `detective`, recon marks on target): missing — GAP. Main's `Battle.note()` is the "marks" equivalent (own recon on k).
- Ambush (ap 2, `watch`): missing; `Skill.watch` gone — GAP. Orig intent clear: watch up to rank tiles within an offensive skill's reach until caster's next turn; a foe (as read) stepping on one is struck and stopped; tile used up.
- Opportunist, Sing, Rake, Drown, Coordinate (now link), boon: rebuilt elsewhere (w9-siren, reactions) — siren_test parts covered by suspicion/reaction/drown tests; not ported.

## Plan / calls
1. Unseen-attack check: lift the 3 `doubt(target, caster)` hurt sites into `Battle._hurt_by(t, by)`: deceived -> doubt; else can't make it out (net < 0) -> free `inspect(t, by.cell)`. Kept main's "hurt" gate (orig: any attack incl. miss). CALL.
2. Detective: Effect stat `detective` (mechanic.py); `suspect()` on an own pass (n > 0, not told_of) adds `note(o, t, detective)` recon on what it saw through (unit and tile). Data-only skill Detective (--human), passive per_rank. Dropped orig "Detective also observes unconcealed things" (main's Study/Evaluate prep cover reading). CALL.
3. Ambush: reuse tile Marks (lay_mark), not a new Watch class. Generic: `Mark.halts` (a walk it triggers on stops there, like a trap) + `Mark.skill` -> new Behaviour hook `tripped(b, mark, u)` called from `_trigger()`. Behaviours/ambush.gd: cast_at a cell -> hidden mark (concealment = caster's?) on that cell + up to rank-1 nearest within reach of its first hostile active, who=foes, halts, turns 1, uses 1; tripped -> `grant_interrupt(by, 1, {s: rank}, {}, u)` like Opportunist. Marks are concealed, so inspect()/suspicious() find ambushes: investigation synergy. CALL (guess on cell shape/concealment).

## Tests
Extend Tests/suspicion_test.gd: unseen hit check, Detective, Ambush. Mutation spot-checks listed below.

## Done
