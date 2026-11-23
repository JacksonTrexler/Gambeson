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
- Step 1 (unseen hit): `Battle._hurt_by()` replaces 3 doubt sites (cast x2, _grip). Test `suspicion_test.test_unseen_hit`; mutation (elif false) fails it. Updated `stealth_test.test_attacker_exposed`: clears v(1)'s suspicion after the hit (its free look may now pass; rule under test is exposure). Full suite before: 10972 checks, 1 failed (that one) -> fixed.
- Step 2 (Detective): stat `detective` (mechanic.py, describe line); `Battle.suspect()`: own pass (n > 0, not told_of) -> `note(o, t, detective)`. Skills/detective.tres via skill.py (--human, passive, wis, per_rank) on Trees/general_specialist after Inquisitor (orig was unwired; placement CALL). Data-only: no test file. Test `suspicion_test.test_detective`; mutations: rule off (`if false`) fails; told_of ignored fails.
- Step 3 (Ambush): generic `Battle.Mark.halts` (walk() stops on it; `Mark.harms()` counts it, so a known one is dreaded) + `Mark.skill` -> new hook `Behaviour.tripped(b, m, u)` from `_trigger()`. `Behaviours/ambush.gd`: tile cast; up to rank (impact) empty tiles in its weapon's reach (first hostile non-tile active), nearest the aimed tile; hidden marks (concealment = rank: inspect() finds them like traps), who=foes, uses 1, TURNS 2 (its side's turn ends: lasts through the foes' turn); tripped -> `grant_interrupt(by, 1, {w: rank}, {}, u)` (Opportunist's free aimed use) unless the caster reads the walker as ally/ignore/unknown (orig "spares beloved"). Skills/ambush.tres via skill.py --human: ap 2 hand-priced, cost 0 (orig), radius 6 (aim), hostile false, tags dex + `defensive` (posture tag: AI._defend casts it at the nearest foe with no AI.gd change). Placed on Roles/ranger after Snare (orig unwired; CALL). Coordinate's support-watch half not rebuilt (Coordinate is now a link skill on main). `turns` field dropped: skills_test.test_flags_described wants it in the text; lifetime is a const.
- Tests: Ambush's rule in its stub `Tests/ambush_test.gd` (2 tests, behaviour's own file per house rule) rather than suspicion_test. Mutations: halts off, tripped off, friend gate off: each fails a check.
- Suite: 10997 checks, 0 failed (1036 tests), 112 s; origin/main baseline 10969/1032 at 112 s: no time growth.
- Launch check: only "8 resources still in use at exit". skill.py check, mechanic.py check: ok.

## Questions for the user
1. Unseen hit: free inspect only when hurt (main's doubt gate); orig gave it on any attack, miss included.
2. Suspicion per pass: main's 1 stack kept (orig max(1, wis mod - distance)).
3. Word of suspicion (spread) stays units-only; orig also shared tile suspicion (cha mod allies within cha mod tiles).
4. Detective: recon on what it sees through only; orig also let it investigate unconcealed things it couldn't fully read. Placed on General Specialist after Inquisitor.
5. Ambush: marks reuse (not a Watch class); tiles chosen nearest the aimed tile within weapon reach (orig: player picks up to rank tiles); concealment = rank; lasts to its side's next turn end; on Ranger after Snare; tag `defensive` so the AI uses it via _defend. Coordinate's support watch not rebuilt.
6. New generic fields: `Battle.Mark.halts`, `Battle.Mark.skill`, hook `Behaviour.tripped()` (no Skill.gd field; no ceiling raised).

## Undone
- Detective "observes the unconcealed"; tile word-of-suspicion; Coordinate support watch; AI weighing of where to Ambush beyond _defend; no visual check (marks draw through Overlay's generic mark path).
