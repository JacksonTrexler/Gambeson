# Consolidation: tests and one-off logic, 20/80 (survey and plan, 2026-11-15)

Branch `v-survey`, off `f5bf7a1`. Survey only: nothing is refactored here. Builders start after
`u-checks`, `u-facing` and `u-itemskills` land (overlaps are listed per task).

Starting suite: **45664 checks, 0 failed (816 tests)**, 154 `Tests/*_test.gd` files, 15,479 lines.

## Readings: measured

### Runtime

- A full run took **150 s wall** (sum of per-test times 148 s; median test **129 ms**). Other Godot runs
  were going on the machine at the same time. CLAUDE.md says about 30 s and run.gd says about 10 min:
  both are out of date.
- A trivial test (forage, blur, stage_presence) costs **115-200 ms**, almost all of it in
  `root.add_child(museum)`. In a bare loop the same add takes 30 ms.
- **The cause is resource unloading between tests.** `run.gd` does `load(MUSEUM).instantiate()` and
  keeps no reference. After `scene.free()` nothing holds `museum.tscn` / `Roles/wizard.tres`, so they
  leave the ResourceCache. The next test reloads them. Icor's `Unit._ready()` then calls `_layout_bars()`,
  which calls `pools()`, which calls `picks()`, which calls `TreeChoice.all()`. Its `_found` cache is
  fresh again, so it `load()`s every Role in `Roles/`, with its trees and skills: **150-180 ms, every test**.
- **Measured fix:** one line in run.gd, `var museum: PackedScene = load(MUSEUM)`, held for the whole run.
  Result: **70 s wall, median 31 ms, the same 45664 checks, 0 real failures.** The only failure was
  skill.py nagging about the temp file's missing `.uid`. That cuts runtime by 53% at no coverage cost.
- **combat_test takes 23.8 s of the 68 s after the fix (35%).** `test_battles` runs 30 seeds of the same
  museum fight (21.1 s). The results are lopsided: "Lancin 27, Nemes 3 | turns 10-19". `test_replay`
  runs three more full fights (2.6 s).
- hud_test is the next biggest at 9.1 s for 44 tests. Everything else is under 2 s a file.
- The tests still at 100 ms or more after the fix: 74 tests, 41.5 s, of which combat is 23.8 s.
  `Tests/slow.txt` (27 entries, picked at the 100 ms cutoff) needs regenerating once the fix lands.
- **Flake:** concurrent runs share `user://settings_test.cfg`. `ui_small_test.test_prefs` failed while
  two runs overlapped.

### Where the 45k checks come from

- `combat_test.test_battles` has **34,413 checks** and `test_replay` has **4,326**. Together that is
  **38,739 of 45,664 (85%)**: `check()` runs about 6 invariants per unit per unit-turn for 30 battles.
  The other 814 tests make **about 6,900 checks**.
- What the 38k buy: HP/Energy in range, movement spent within the peak, AP never negative, on the board
  iff alive, board and positions agree, over exactly when one side is left, only the turn's side moves,
  and the same seed gives the same log.
  - These are real invariants and worth keeping.
  - Running 30 seeds of one map pays for repetition, not coverage. The same AI branches fire, and seeds
    8-30 add no new map, roster or tempers.
  - Counting every evaluation as a "check" inflates the headline number.

### Duplication in the tests

| Pattern | Count | Notes |
|---|---|---|
| One file per skill (`Tests/<skill id>_test.gd`) | **58 files, 3,046 lines, 168 tests** | `Util/skill.py new` stubs one per skill (`TEST_STUB`), so growth is built into the tool |
| ...of which "learn, stage, cast, the stat moved by amount x rank" | 12 files, 163 lines | blur, disguise_self, invisibility, double_bluff, mirror_image, stage_presence, flourish, phantasm, phantasmal_force, showstopper, prestidigitation, vanishing_act |
| ...near-identical capstone files (same body, different ids) | 5 files, 145 lines | quarry, survivalist, wildcaller (character-for-character the same shape), acceptance, bargaining: all `Behaviours/efficiency.gd` |
| Effect-stat stub files (`mechanic.py`) | 4 files, 73 lines | foresight, hale, regain, forage (a stub pin) |
| Per-unit pin files (re-assert .tscn data) | blinthe, pike (+ meadows, undine are behaviour tests: keep) | `unit.py check` already guards the wiring |
| Same stage line | `stage(lancin, {v(1): (4,3), v(3): (5,3)})` **51x**; the 6 most common shapes about 120x | 559 `stage(` calls in all |
| `learned.append(slot(...))` | 320 | always followed by `stage` |
| HUD fixture (instantiate, battle, auto=false, pace=0, add, await) | **22 copies in 21 files** | 5 named `start()` / `hud()` helpers already |
| `func sk(n)` = `load("res://Skills/%s.tres")` | **14 files** | plus `unit()` 4, `siren()` 6, `icor()` 5, `shrike()` 4 |
| Rigging stats to force an outcome | 72 `stat = 40+`, 20 `stat = 1`, 95 `max_hp = N` | a sure save fail / sure hit / soak, written out by hand each time |
| Save seam re-tested through content | 8 files rig `wisdom = 1` vs a big caster stat | phantasm, phantasmal_force, showstopper, brainfog, ... |
| `describe(...)` contains a word | 105 | partly covered by `skills_test.test_flags_described` (every set field changes the markup) |
| Tests pinning list literals of tree / tab / name content | 52 `== [...]` lines | e.g. `casters_test` `titles(wizard.trees()) == [...]`: change-detectors on data |
| Literal counts the tool must patch | `skill.py COUNTS` rewrites `hud_test` `w.skills().size() == N` | a test that a tool must edit is pinning data |

What already sweeps all content: `skills_test.test_flags_described` (a property test), `test_wiring`
(skill.py check), `tooling_test` (icons, tool checks), `tag_colors_test.test_every_tag_coloured`,
`glossary_test.test_no_dice_in_skills` / `test_spec`. **No test casts every skill.** 12 built skills are
never named in any test: the 7 bracings, brutal/decisive_mastery, oceanic, specialist_slot, thaumaturgist,
ramuts_ire (except via lure_test's Ire). All but ramuts_ire are passives with plain effects. A passive
sweep would cover them.

Sweep-ready populations (built, not stubs, no behaviours, not tile skills):
- **39 active skills with `effects`** (astera ... wauaw)
- **67 passives with `effects`**

### Logic: one-off code

- `Skill.gd` has **130 `@export` fields**:
  - by data users: **7 with 0**, **66 with exactly 1**, 15 with 2, 42 with 3 or more
  - `FLAG_CEILING` is 128. `u-checks` takes it to 126 (removes `save`, `resisted`, `drags_to`; adds `check`).
  - **Dead fields** (no .tres sets them): `push` (Battle 967, SkillTerms 183; Kick calls `b.push()`
    itself), `grip` (Battle 3620), `beast` (Unit 646). Also `intensity`, `penalty`, `requires`,
    `rank_growth`: Terms-group / tooling fields, which are fine.
- `Battle._cast()` is **325 lines (710-1034)** and reads **59 distinct `skill.*` fields**. Most are
  single-user branches:
  - **Self / utility early return (797-814):** `exits`, `fog`, `elements`, `aura` (+`splits`),
    `retrieves`, `humbles`, `boost_pool` (+`boost_mod`); `shapes` just above (792). These are 11 fields
    and 8 skills (Emergency Exit, Waltz of Vapors, Elemental Strike, Flamecharm/Flamedance, Burning Bag,
    Humble, Igna/Aetha/Prestidigitation, Beastshape). Each is `do X; _land(acts); used.emit; return`,
    which is exactly a Behaviour's `apply()`.
  - **Forced movement (965-970):** `pull` (Sing), `push` (dead), `sends` (Send Off). The functions
    `pull` / `push` / `send` (4090-4128) and `drag` / `drag_spot` (4156-4190) are 5 hand-rolled line-walks.
  - **Outcome riders:** `levels_down`, `kills`, `prays`, `links`, `binds`, `respecs`, `disables`,
    `recast_on_crit`, `sure_crit`, `god_tag` + `carry` (Smite), `hits_per_rank` + `chain` (Strike).
- `Battle._cast_at()` (2030-2076) is a **10-branch elif chain** on single-user flags:
  - the flags: `flamewall`, `cone` + `evadable` (Wildfire vs Solar), `channel`, `observes`, `guards`,
    `wells`, `rifts`, `lays`, else `zone`
  - their bodies: `_flamewall` 25, `_wildfire` 29, `_solar` 18, `observe` 8, `_guard` 12, `well_up` 11 +
    `flood` 22, `open_rift` 27 + `close_rift` 14 + `can_rift` 6, `lay` 40
- The single-skill Battle functions I measured come to **811 lines**. Moving them into `Behaviours/`
  shrinks Battle.gd and the flag bag more than it cuts total lines. Be honest about that in reports.
- `AI.gd` (940 lines) is mostly generic already. Per-flag routines: `x.observes` (415), `x.fog` (501),
  `x.wells` (521), `x.auto and x.pull` (534, 663), `x.drags_to` (385, 544), `x.channel` (742),
  `s.guards` (275). The filter `for_foes() and not on_tile() and not auto and can_afford` is copied
  **4 times** (244, 378, 887, 904).
- `HUD.gd` has few per-skill branches (`hybrid`, `elements`, `lays`, `channel`, `auto`; about 10 lines).
  It is not a priority.
- No skill is hard-coded by path except `Battle.IRE` (ramuts_ire).

## Calls (judgement, for the coordinator)

1. **The runner fix comes first and alone.** It is the biggest win (53%) and changes no test.
   - Risk: with resources now cached across tests, a test that mutates a shared `Skill` / `Role` /
     `Item` resource in memory leaks into later tests. Today each test gets fresh copies by accident.
   - The measured run shows no leak now. Add a `reverse` runner word (file order reversed) and run both
     orders in acceptance, to catch future order-dependence.
2. **Fewer combat seeds, not fewer invariants.** Run 8 seeds by default and all 30 under a new `soak` word.
   - Each invariant becomes one `ok()` per battle, failing with the first seed / turn / unit that broke it.
   - The check count drops from about 45.7k to about 7k. **That drop is cosmetic. Say so in the report so
     nobody reads it as lost coverage.**
   - `test_replay` should compare two runs of one battle capped at 5 turns, not three full fights.
   - Spend part of the saved time on one `astral_envoy` or `meadows` battle for roster variety.
3. **Sweeps replace per-skill effect tests; seam tests stay.** A table or property test over `Skills/*.tres`
   replaces files whose whole body is "the effect landed at amount x rank". Files that test a behaviour's
   own rule (hitch's tow, spike's AP, sutemi's lunge) stay, folded per seam only where they share fixtures.
   Behaviour tests are the documentation of a rule. Don't delete them for line count.
4. **Content-pin tests become data checks or go.** A test that restates a .tres / .tscn (blinthe's bio,
   forage's tree, Wizard's tab list) protects against nothing a tool `check` doesn't. Move the wiring
   asserts into `Util/*.py check` where they aren't already, and delete the restatement.
   - Keep pins that encode a rule (e.g. "nothing picked: own tab and the World").
   - Delete pins that encode a list.
5. **Tool stubs (needs the user):** `skill.py new` / `unit.py new` / `mechanic.py` write
   `Tests/<id>_test.gd` per item. CLAUDE.md and `.claude/skills/` document that, and builders may not
   edit those. Two choices:
   - **Option A:** stub a row into a seam file (`Tests/skill_cases.gd`) for data-only skills, and a file
     only when `--behaviour` is given.
   - **Option B:** keep files, but have the stub call the shared helpers (`duel()`, `sweep` coverage) so
     it's 3 lines.

   I recommend A. **This needs a user decision.** Until then, builders keep the tools as they are.
6. **Logic lifts follow "migrate on touch", but two clusters earn a deliberate pass.** The `_cast` self /
   utility block and the `_cast_at` elif chain are single-user flags shaped exactly like
   `Behaviour.apply()`. Lifting them takes about 19 fields off Skill.gd and turns two dispatch chains
   into `_land()`.
   - **Don't lift:** `channel` (32 Battle + 13 AI + 9 HUD refs: a real mechanic), Strike's `chain`
     (core), the Look group (`stance` / `shows_*`: a persona system with one user so far), the Terms
     group, or heal fields (3 users).
   - **Don't add a Behaviour hook per skill.** Add at most one new hook: `apply_at(c: Cast, cell)` for
     tile skills.
7. **Forced movement becomes one behaviour, not three flags.** `Behaviours/displace.gd` (class name
   `Displace`, a code name, so no `??`) takes `toward: bool`, `teleport: bool`, `tiles: int`
   (x rank impact) and `stat: StringName` (+ caster's mod).
   - Battle keeps one primitive, `Battle.displace(t, from_cell, dir_sign, n, teleport) -> int`, which
     `pull` / `push` / `send` become thin calls to. Kick and Sutemi already call `b.push`, and keep working.
   - Composability: any skill (or item skill, after u-itemskills) can knock back or draw in, with no flag.

## Ranked: tests (20/80)

| # | Change | Lines | Runtime | Coverage |
|---|---|---|---|---|
| T1 | run.gd holds the museum (+`reverse` word, per-process `Prefs.SAVE`) | +5 | **-80 s (150 → 70 s)** | same; adds an order-dependence check |
| T2 | combat 30 → 8 seeds (+`soak`), one ok per invariant per battle, short replay | -0 / +20 | **-17 s** (24 → about 7 s) | same invariants, 8 seeds; check count 45.7k → about 7k (cosmetic) |
| T3 | `Tests/sweep_test.gd`: passive-effect sweep (67 skills), active-effect sweep (39), every-active-casts smoke (all built actives), behaviour describe sweep (every `Behaviours/*.gd` at ranks 1-3: non-empty, no `%`, no `STUB`) | +about 150 | +about 1 s | **raises it**: 12 unnamed skills covered; every new data skill covered with no new file |
| T4 | Delete the 12 effect-only per-skill files and the 4 effect-stat stubs (fold the 3 real effect-stat rules into one `effect_stats_test.gd`) | **-236 + 73 → about 60** | -2 s | kept by T3, plus one rule test each for save-fail and investigate (below) |
| T5 | `Test` helpers: `duel(s, r, foe := true) -> Unit` (learn + the 51x stage), `sure_save_fail(caster, target)`, `soak(u, hp := 999)`, `hud(leader) -> HUD`, `sk(id)` | +about 40, **about -350** across files | about 0 | none |
| T6 | Table test for TreeChoice capstones (`efficiency.gd` openers): one loop over every Skill that is some `TreeChoice.by` | **-145 → about 35** | -0.4 s | same five, plus any future capstone automatically |
| T7 | Content pins out: blinthe / pike data asserts → `unit.py check`; tree-list literals in casters / berserker / general reduced to rule asserts; drop `skill.py COUNTS` and the `hud_test` count | about -120 | small | wiring moves to the tool checks, which run in `tooling_test` |

T1 + T2 are about 97 s of 150 s. T3 + T4 + T6 cut file count by about 22 (154 → about 132) and lines by
about 450 while covering more skills. T5 is the readability multiplier for whatever remains.

### How to prove nothing important is lost (mutation spot-checks)

Each builder runs each mutation against the **old** suite and the **new** suite, records "old fails / new
fails" in their plan doc, then reverts. Every row must fail in the new suite.

| Mutation (revert after) | Guards | Expected to catch it in the new suite |
|---|---|---|
| `Battle._cast` line 936: pass `r` for both branches (ignore `e.per_rank`) | effect strength by rank | active-effect sweep |
| `Unit.afflict`: drop the `amount * rank` scaling | passive / active amounts | both effect sweeps |
| `Skill.lasts()`: return `turns` only (ignore `turns_per_rank`) | durations | active-effect sweep (asserts `timed[e].total == s.lasts(r)`) |
| save block: invert `if not vs.won` (post u-checks: in `Battle.check` / `skill_opts`) | saves | `duel` + `sure_save_fail` rule test in check_test |
| `Behaviours/efficiency.gd`: affinity +1 → +0 | capstone stacks | T6 table |
| `investigate()`: early `return` | disguises / hiding | stealth / perception tests (kept) |
| `Unit.hit`: skip the clamp at 0 | HP invariant | combat (8 seeds) |
| `Battle.travel`: allow off-turn moves | turn rule | combat |
| a behaviour's `describe()` returns "" | descriptions | behaviour describe sweep |
| `TreeChoice.all()`: skip borrowed classes | Dabblings | casters_test rule asserts (kept) |

## Ranked: logic (20/80)

| # | Lift | Fields off Skill.gd | Battle.gd | Future content |
|---|---|---|---|---|
| L1 | `_cast` self / utility block → behaviours: `beastshape.gd`, `emergency_exit.gd`, `waltz.gd`, `imbue.gd`, `aura.gd` (with `splits` as its option), `retrieve.gd`, `humble.gd`, `boost.gd` (`pool`, `mod`); the block (792-814) becomes `_land(acts)` | **11** (`shapes`, `exits`, `fog`, `elements`, `aura`, `splits`, `retrieves`, `humbles`, `boost_pool`, `boost_mod`; plus `opening` stays) | -25 in `_cast`, about 170 moved out | an item or modifier can grant any of these by adding a behaviour |
| L2 | `_cast_at` chain → one `Behaviour.apply_at(c, cell)` hook; `flamewall.gd`, `cone.gd` (Solar; `evadable` option = Wildfire), `observe.gd`, `guard.gd`, `well_up.gd`, `zone.gd` | **7** (`flamewall`, `cone`, `evadable`, `observes`, `guards`, `wells`, `zone`) | about -30 dispatch, about 140 moved | new ground skills are a behaviour, not a branch |
| L3 | `Displace` behaviour + `Battle.displace()` under pull / push / send; delete the dead fields | **5** (`pull`, `push`, `sends`, `grip`, `beast`) | about -25 | knock-back / draw-in on any skill, item or reaction |
| L4 | AI: `Unit.foe_actives()` for the 4 copied filters; AI routines ask `s.has(BehaviourClass)` where they read lifted flags | 0 | AI about -15 | AI keeps working with the lifted skills |
| (later) | outcome riders (`levels_down`, `kills`, `prays`, `links`, `binds`, `respecs`) → behaviours on touch | 6 | about 130 moved | migrate-on-touch; not this pass |

L1 + L2 + L3 take **23 fields** off Skill.gd (130 → about 107; after u-checks, 127 → about 104). Lower
`FLAG_CEILING` to match **after** the builders merge. Builders don't edit it: removing fields can't trip
the check.

Not worth it: `rifts` / `lays` (Rift's channel ties and Snare's HUD / Overlay / Terrain readers make the
lift bigger than the gain), `channel`, Strike, Smite's `god_tag` / `carry`, and heals.

## Builder tasks (parallel after u-checks, u-facing, u-itemskills land)

File ownership is disjoint except for **Skill.gd's `@export` block** (L-builders each delete only their
own lines; a merge conflict there is mechanical) and `Tests/test.gd` (B2 only).

### B1: runner and soak (small; land first if possible, since everyone's runs get 2x faster)
- **Scope:** T1 + T2.
- **Files:** `Tests/run.gd`, `Tests/combat_test.gd`, `Tests/slow.txt` (regenerate from `-- times`, same
  100 ms rule), and the run.gd header comment (real times).
- **Work:**
  - hold `load(MUSEUM)`
  - add the `reverse` and `soak` words
  - set `Prefs.SAVE` to `user://settings_test_%d.cfg % OS.get_process_id()`, deleted at exit
  - combat: 8 seeds, all 30 under `soak`; aggregate invariants; replay capped at 5 turns; one
    `astral_envoy` battle if it fits in 2 s
- **Expected:** a full run of about 55 s or less on this machine (back-to-back with a baseline run),
  checks about 7k.
- **Risks:** order-dependent leaks once resources are cached. Acceptance runs forward **and** `reverse`.
  Also: someone reading the check-count drop as lost coverage. Put the before / after numbers in the
  plan doc.
- **Acceptance:** both orders end at 0 failed; `soak` passes 30 seeds; the mutations `Unit.hit` clamp
  and off-turn travel still fail combat_test.
- **Overlap:** none with the three in-flight branches (u-facing touches test.gd's `stage`, not run.gd).

### B2: helpers, sweeps and the effect files
- **Scope:** T3, T4, T5 (helpers, and their use in files B3 doesn't own).
- **Files:**
  - `Tests/test.gd`: add `duel`, `ally_duel`, `sure_save_fail`, `soak`, `hud`, `sk`
  - new `Tests/sweep_test.gd`
  - new `Tests/effect_stats_test.gd`
  - delete the 12 effect files + `foresight` / `hale` / `regain` / `forage`
  - swap the HUD fixture in the 21 files that have one, except any on B3's list
  - drop local `sk()` from the 14 files, except B3's
- **Sweeps:**
  - passives: learn at r = 2, then `stat(e.stat)` moved by `e.amount * 2` (per_rank) or `e.amount`
  - actives: `duel` / `ally_duel` by `for_foes()`, with `sure_save_fail` / sure hit, cast at r = 2; each
    effect is in `target.timed` with `total == s.lasts(2, caster)`; skip `dual` foes and `grants`, with
    the skip list explicit and **shrink-only**, like `UNSAID`
  - smoke: every built active casts on a valid staged target (or `cast_at` a valid cell) and returns
    true, with no script error (t.sh kills on SCRIPT ERROR)
  - behaviour describes
- **Expected:** about -400 lines net, -16 files.
- **Risks:**
  - a sweep too generic to fail. Run the mutation table rows 1-3 and 9.
  - skills needing odd preconditions (Resuscitate: a Downed target; Coalescing: a mist). Use
    `Behaviour.fits()` / an explicit, commented skip list rather than special-casing in the sweep.
- **Acceptance:** 0 failed; the mutation rows fail; skill.py check ok; the 12 previously unnamed skills
  appear in the sweep's coverage print.
- **Overlap:** u-facing adds `facing = ZERO` to `stage()`, so build on top of it. u-itemskills adds item
  skills: the smoke test should include item-granted actives through a worn item, which is cheap once
  they land. u-checks changes the save path that `sure_save_fail` rigs: rig via stats, not internals.

### B3: tables and pins
- **Scope:** T6, T7.
- **Files:**
  - `Tests/quarry_test.gd`, `survivalist_test.gd`, `wildcaller_test.gd`, `acceptance_test.gd`,
    `bargaining_test.gd` → one `Tests/capstones_test.gd`
  - `blinthe_test.gd` + `pike_test.gd` data asserts → `Util/unit.py check` (keep pike's water-cost and
    read-level asserts as a short `aquatic_test` addition)
  - `casters_test.gd`, `berserker_test.gd`, `general_test.gd`: tree-list literals become rule asserts
  - `Util/skill.py`: drop `COUNTS`; `hud_test.gd`'s count line becomes a rule assert (**B3 owns that one
    line only**; B2 owns the rest of hud_test, so coordinate on the merge)
- **Expected:** about -250 lines, -6 files.
- **Risks:**
  - losing a guard on a wiring mistake (a capstone opening the wrong choice). The table asserts
    `choice.by == cap` and that the tree it opens contains a skill of tier 1.
  - the tools' check getting slower. Keep it plain text.
- **Acceptance:** 0 failed; mutation row 5 fails; `python3 Util/unit.py check` and `skill.py check` ok.
- **Overlap:** none with the in-flight branches.

### B4: tile skills onto behaviours (L2)
- **Scope:** `Behaviour.apply_at(c: Cast, cell: Vector2i)` (and `describe` as usual).
- **Files:**
  - `Scripts/Battle.gd` `_cast_at` (2030-2076) plus `_flamewall` / `_wildfire` / `_solar` (4630-4785),
    `observe`, `_guard`, `well_up` / `flood`, zone laying
  - `Scripts/Behaviour.gd`
  - new `Behaviours/{flamewall,cone,observe,guard,well_up,zone}.gd`
  - the six skills' .tres (`flamewall`, `solar`, `wildfire`, `observe`, `shields_up`, `well_up`, `darkstone`)
  - Skill.gd fields: `flamewall`, `cone`, `evadable`, `observes`, `guards`, `wells`, `zone`
  - SkillTerms.gd readers
  - AI.gd 275 / 415 / 521
- **Expected:** 7 fields off; Battle about -170 (moved), the chain 10 branches → 3 (`channel`, `rifts`,
  `lays` stay).
- **Risks:**
  - Pricing / SkillTerms read these fields for cost and terms. Each behaviour fills `terms()`.
  - `test_flags_described` must still pass: the behaviour's describe now carries the line.
  - Tests reading `.cone` (route_test) and `.observes` (evidence_test) need updating to the new shape.
    Update them; never weaken them.
- **Acceptance:** 0 failed, with **no other test edits** beyond those two; skill.py check ok; a
  forecast / Overlay screenshot of Wildfire's cone unchanged (visual check).
- **Overlap:** **u-checks moves Flamewall's dodge onto `Battle.check`**, so start from it.

### B5: self / utility and forced movement (L1, L3, L4)
- **Files:**
  - `Scripts/Battle.gd` `_cast` 792-814 and 965-970, plus `beastshape`, `emergency_exit`, `waltz`,
    `imbue`, `_aura`, `_retrieve`, `_humble`, and `pull` / `push` / `send` (4090-4128) under one
    `displace()`
  - new `Behaviours/{beastshape,emergency_exit,waltz,imbue,aura,retrieve,humble,boost,displace}.gd`
  - those skills' .tres
  - Skill.gd fields: `shapes`, `exits`, `fog`, `elements`, `aura`, `splits`, `retrieves`, `humbles`,
    `boost_pool`, `boost_mod`, `pull`, `push`, `sends`, `grip`, `beast`
  - `AI.gd` (501, 534, 663; `foe_actives()` at 244 / 378 / 887 / 904)
  - `Unit.gd` 646 (`beast`)
  - `HUD.gd` 538 / 896 (`elements`)
- **Expected:** 16 fields off; `_cast` about -40 lines; Battle about -200 (moved).
- **Risks:**
  - `aura` is also read by Perception / Bio / AI as a **unit's** aura, a different field with the same
    name. Grep `skill.aura` / `s.aura` only.
  - Sing's pull is gated by u-checks' `SkillCheck.suspicion`. `Displace` must run inside the landed path.
  - Burning Bag retrieves an Item, and u-itemskills changed Item.gd.
  - lure_test reads `.pull` and moves_test reads `.push`: update them to the behaviour.
- **Acceptance:**
  - 0 failed
  - a new composability test: a plain damage skill with a `Displace` behaviour added in-test knocks
    back, proving it's not Sing-only
  - mutation: `displace()` with n = 0 fails lure / kick / send-off tests
  - skill.py check ok
- **Overlap:** u-checks (`resisted` / `drags_to` removal, the contest block above line 860); u-itemskills
  (Item.gd, AI.gd 11 lines, Battle.gd).

### Order and merge notes

- B1 is about an hour. Merging it first halves everyone else's test loop, but it is independent.
- B2 and B3 split hud_test (B3 one line) and the `sk()` removals (each in its own files). Merge B2 first.
- B4 and B5 conflict only in Skill.gd's `@export` lines and maybe AI.gd lines more than 100 apart.
  Merge in either order.
- After all five: the coordinator lowers `FLAG_CEILING` to the new count and updates CLAUDE.md's "~30 s".
- Expected end state: about 55 s a run, about 125 files, about 14.5k test lines, Skill.gd about 104
  fields; every data-only skill and passive covered by sweeps with no file of its own.


## B2 as built (branch `c-sweeps`)

Built: `Tests/test.gd` helpers (`sk`, `duel`, `sure_save_fail`, `soak`, `hud`), `Tests/sweep_test.gd`,
`Tests/effect_stats_test.gd`; 13 files deleted; HUD fixture and `sk()` deduped. Calls, for the coordinator:

1. **Helpers.** `duel(s, r, foe := true)` returns the target; **`ally_duel` dropped** (`duel(s, r, false)` is the
   same line, and nothing would call the alias). `sure_save_fail(caster, s, t)` rigs through stats alone
   (caster's check stat 60, the foe's 1; `s.stat()` without a declared check), so it survives u-checks.
   `hud(leader := null, pace := 0.0)` is a coroutine (`await hud(v(1))`); it replaced 22 fixtures and 4 local
   `start()` / `hud()` helpers. `clock_test` and `vanish_test` now wait the frame the others did.
2. **T5's "about -350 lines" was not met.** The HUD fixture, `sk()` and 66 `max_hp = N` / `hp = N` pairs (now
   `soak`) came to about -230; `duel()` has 9 uses, because only 9 tests have the two lines side by side (the
   51 stage lines mostly sit among rigging). Tests that rig a save with a retry loop (brainfog, haluca) were left:
   making them `sure_save_fail` would change what they test. Files B3 owns (general, casters, berserker, the
   five capstones) were not touched.
3. **The sweep** (`sweep_test.gd`, 4 tests, about 1.3 s with four museum setups, about 0.7 s over the empty-test
   cost): `test_passives` learns all 99 built passives at rank 2 and weighs 84 stats (amount x rank, per_stat,
   per_mod, min_rank, above_hp, unless_on understood; a multiplier, an armored or skill-listed effect is skipped);
   `test_actives` casts 92 built actives at rank 2 on one reused battle (each skill re-poses the same units;
   `stage()`, timed cleared, HP, AP, Energy topped up; a spare foe stays far off so a kill can't end the battle)
   with its check and attack roll rigged to land, and asserts: the cast returns true, each effect is on the
   target, `total` is the turns, `rank` is the cast rank, the stat moved by amount x rank x strength, and a
   damaging skill costs the foe HP, Energy or a reserve. Ramut's Ire (not castable) is applied through
   `Battle.IRE`. `test_item_skills` casts what Broadsword (Strike: vacuous, villagers already have it) and
   Hobnail Boots (Kick) lend. `test_describes` runs every Behaviour at ranks 1-3.
4. **Skip lists, in the file with reasons, shrink-only:** `NOT_CAST` (beastshape: needs a biome; resuscitate:
   needs a Downed ally; ramuts_ire: applied instead) and `EFFECTS_UNWEIGHED` (level_down: its own rank rolls;
   sing: lands on the nearest in range, not on its user). A test asserts every built active is cast or named.
   Coalescing, Gank, Wildfire etc. needed only a pose (mist, an ally beside the foe, the right target), not a skip.
5. **Duration oracle.** The plan's row 3 asserts `total == s.lasts(2, caster)`; that cannot catch a broken
   `Skill.lasts()` (both sides use it). The sweep spells it out: `turns + turns_per_rank x rank (+ turns_mod)`.
6. **The "no `%`" describe rule** is narrowed to unfilled format specifiers (`%s`, `%d`, `%f`): seven behaviours
   legitimately write "20%".
7. **Kept, against the plan's 12 (Call 3: a rule stays):** `vanishing_act_test` (the vanished signal, the assumed
   faction, a lie that still fools), `prestidigitation_test` (the only test of the move-pool boost; Igna's skill
   pool is in sol_test), and `double_bluff_test` trimmed to its one rule (embellish puts on a front,
   `Perception.fronts`). Flourish's "its user alone" is `self_only`, covered in route_test. Showstopper's
   "Dazzled ??" name pin went with it (a data pin: Call 4).
8. **Deleted (13):** blur, disguise_self, invisibility, mirror_image, stage_presence, flourish, phantasm,
   phantasmal_force, showstopper, foresight, hale, regain, forage (+ `.uid`). `effect_stats_test.gd` takes
   foresight, hale and regain verbatim (3 rule tests, one file). forage's two asserts restated tree / stub data.

### Mutation spot-checks (old = the 16 files the plan names, plus those kept; new = the sweep or the named kept test)

| Mutation (reverted) | Old fails | New fails |
|---|---|---|
| `Battle._cast`: effect rank `ri if e.per_rank else r` -> `1 if e.per_rank else r` (the plan's row 1, "pass r for both", changes nothing without modifiers) | 8 | sweep 31 |
| `Unit.stat`: drop `* (pair[1] if e.per_rank else 1)` | 10 | sweep, both tests |
| `Skill.lasts()`: ignore `turns_per_rank` | **0** | sweep 23 (Sola, wauaw...) |
| skill check block `if not vs.won` inverted (Battle.gd, `# the caster wins ties`) | 4 | sweep 5 (Phantasm, Showstopper, Phantasmal Force's damage) |
| `Battle.investigate()`: early return | moves_test (kept) | moves_test, same 3 |
| `Unit.hp` setter: drop the floor clamp | (combat) | combat_test.test_battles fails |
| `Battle.travel()`: drop the `_acting` check | (combat) | combat_test.test_battles fails ("only the turn's faction moves") |
| `Behaviours/kick.gd` `describe()` returns "" | skills_test.test_flags_described | that, and sweep test_describes (3 ranks) |
| `TreeChoice.all()`: skip borrowed classes | casters_test (kept) | casters_test, same |
| `Behaviours/efficiency.gd` affinity +1 -> +0 | B3's table | not run here |

Not done: `skill.py new` still stubs a per-skill test file (CLAUDE.md, pending the user's Call 5). The sweep
is 734 ms in `test_actives`; `Tests/slow.txt` (c-runner's) uses a 100 ms cutoff, so that test belongs on it.

## B4 as built (branch `c-tiles`)

Starting suite 45995 checks, 0 failed (838 tests); ending 46001 checks, 0 failed (840 tests) (two tests added, below).

- **Hook:** `Behaviour.apply_at(c: Cast, cell: Vector2i)`, run by `_land(c, cell)` (an optional second argument:
  given a tile, `_land()` calls `apply_at()` instead of `apply()`). `_cast_at`'s chain is now `channel` / `rifts` /
  `lays` / else `_land(cast_of(caster, skill, null, rank, skill.hostile), c)`.
- **Behaviours:** `flamewall.gd`, `cone.gd` (`degrees`, `evadable`: Solar plain, Wildfire evadable; `width(rank, m)`
  replaces `Skill.cone_at()`), `observe.gd` (static `reach()`, which `AI._search()` now reads instead of its copy of
  the formula), `guard.gd`, `well_up.gd`, `zone.gd` (`kind`). `Battle._flamewall/_wildfire/_solar/_guard`,
  `observe()` and `well_up()` moved out; `flood()`, `evade()`, `in_cone()`, `zone_levels()` stay as Battle primitives.
- **Fields off Skill.gd (7):** `flamewall`, `cone`, `evadable`, `observes`, `guards`, `wells`, `zone`.
  `@export` count 126 -> **119**. FLAG_CEILING untouched (126).
- **Data:** the seven .tres moved by `S/b4_migrate.py` (scratchpad), through `Util/tres.py`'s `sections` /
  `ext_id_for` / `add_ext`; no ids by hand.
- **Lines:** Battle.gd +18 -132, Skill.gd +13 -36, SkillTerms.gd +6 -9, AI.gd +6 -5; 287 lines in the six behaviours.
  As predicted: Battle and the flag bag shrink more than the total does.

### Calls (B4)

1. **A second, pure query beside the hook:** `Behaviour.tile_target() -> StringName` (&"tile", &"area", or empty).
   `Skill.on_tile()` and `Skill.target()` need to know a skill is aimed at a tile before it's cast, and a hook
   can't be asked without running it. It's the `fits()` / `unfit()` pattern, not a hook per skill.
2. **`Skill.behaviour(file: StringName) -> Behaviour`** (by the script's file name: `&"guard"`, `&"observe"`), for
   readers that act on one kind: Overlay (Observe's ring), `AI._search()` / the Well Up routine, `Battle.interrupt()`
   (a guard's effects end), `Battle.attempt()` (no zone skill on thin air). File names rather than class names: no
   global names, no preload cycles. **Merge note:** B5 may add `Skill.has(BehaviourClass)` for the same need;
   keep one of the two.
3. **`AI._defend()` reads `s.on_tile()` instead of `s.guards`:** any defensive skill aimed at a tile is aimed at the
   nearest foe. Only Shields Up! qualifies today, so nothing moves; before, any other such skill would have failed
   `cast()` on itself.
4. **Impact:** `SkillTerms._derived_impact()` counted any behaviour as a rider (tame). A tile behaviour now says
   its own (Flamewall and Zone set tame in `terms()`, as their old fields did); Solar, Wildfire, Observe and
   Well Up stay "" as before. Every terms line of the seven skills is the same, except below.
5. **Observe gains a `rank_impact` term ("observe"):** its rank was always read through rank impact, but no term
   said so. `skill.py modifiers`: unchanged overall; Observe now also fits rho_up (eligibility better, nothing lost).
6. **Flamewall's check** stays on the helper, `Battle.check(u, dex, caster, wis, ties = false)`, as u-checks left
   it. It is not a `Skill.check` (SkillCheck): that declares a check in place of an attack roll on a target, and
   Flamewall has none. `evade()` (Wildfire's DC dodge) is a check against a number, not a contest, so it stays too.
7. **Private Battle helpers:** `_flame()` renamed `flame()` (behaviours call it). `cone.gd` calls `b._expose()`
   rather than renaming it, because 16 callers, most of them in `_cast`, sit beside B5's lines. Rename it after both branches merge.
8. **Description order:** the lifted lines now come after the effect lines (behaviour lines come last in
   `Skill.markup()`). Shields Up!'s facing line is now below its effects. No test read the order.
9. `Util/skill.py` HOOKS gains `apply_at`; `Util/tres.py` FLOATS drops `cone`.

### Tests (B4)

- Updated for data shape only: `route_test.test_area` (`solar.cone_at()` / `.cone` -> the cone behaviour's
  `width()` / `degrees`); `evidence_test.test_ai_follows_it` (`s.observes` -> `s.behaviour(&"observe")`).
- Added: `sol_test.test_flamewall_catches` (one standing where the wall goes up makes the check and burns at
  once) and `watch_test.test_observe_looks` (it looks there, within reach). Both pass on the old code too.
  The suite had no test for either rule: the mutation spot-checks found the gaps.

### Mutation spot-checks (B4; each reverted)

| Mutation | Fails |
|---|---|
| flamewall.gd: never burns a unit that loses the check | sol_test.test_flamewall_catches (new; nothing failed before) |
| flamewall.gd: width 0 | sol_test.test_flamewall, route_test.test_flamewall |
| cone.gd: Wildfire's dodge ignored (share 1) | difficulty_test.test_wildfire_dodged |
| cone.gd: Solar's width ignores modifiers | route_test.test_area |
| observe.gd: early return | watch_test.test_observe_looks (new); before, test_observe only crashed with a SCRIPT ERROR, which the runner doesn't count as failed |
| guard.gd: guard not raised | facing_test.test_shields_up (4) |
| well_up.gd: centre a rank shallower | undine_test.test_well_up |
| zone.gd: lays nothing | perception_test.test_tonefoolery_doubles; zone describe "" -> skills_test.test_flags_described |

Survivors (equivalent mutants, or not covered; recorded, not fixed): Solar's cone at width 0 passes `test_solar`,
whose units stand on the aim line. Observe's +rank bonus at 0 passes, because `test_observe`'s roll bounds are loose.
`guard.gd` describe "" passes, because removing the behaviour also changes the spec line, so `test_flags_described`
can't see it. B2's describe sweep should catch it.

Visual: Wildfire's and Observe's targeting overlay (armed, hovered) captured before and after (`S/driver_b4.gd`,
`S/shot_b4_*`): the two look the same. The pixel diffs are the overlay's real-time pulse.

## B3 as built (`c-tables`)

- **Capstones:** `quarry`, `survivalist`, `wildcaller`, `acceptance`, `bargaining` tests (5 files, 145 lines) became
  `Tests/capstones_test.gd`. The table loops every Role's `choices` whose `by` carries an efficiency behaviour
  and asserts: it waits on its root, it unlocks once the lower-tier skills of the role's roots are learned, a guest
  tree with a tier 1 skill picks, that skill's affinity is `choice.affinity + 1`, `describe` says "tier". The three
  Ranger rows come from the data. Call: Acceptance and Bargaining are not `TreeChoice.by` openers (they reach
  Patron trees), so their rule tests (Flex `after` / `burns`, the stacks) stay as two plain tests in the same file.
  Call: the old per-skill probe skill (jugular, forage, stonegift) is now "the first tier 1 skill of the first
  offered guest tree", so a data change there can't break the table.
- **Unit pins:** `blinthe_test.gd` deleted; `pike_test.gd` deleted, its water-cost and read-level asserts are
  `aquatic_test.test_pike`. `Util/unit.py check` now checks, for every unit scene: every `res://` path it names
  exists, a Bio'd unit has a faction, look, bio, behaviour and appearance, and each clout key is a `Factions/` file.
  Call: level, role, clout numbers, bio text and skill ranks are values, not rules, and are no longer pinned.
- **Tree lists:** casters / berserker / general literals are rule asserts (a role's trees are its own tab, then what
  its choices offer; a choice by a study is -1 except a school; every class gets the base general tree plus one per
  declared category, for every Role). Dropped the root-name list asserts.
- **COUNTS:** `skill.py COUNTS`, `check_counts` and `wheel_count` removed. `hud_test` line 917 now asserts every
  skill of the wheel's tab (centre, core, roots) has a spot on the wheel.
- **Spot-checks** (old suite fails by construction for the deleted files: they asserted the same):
  efficiency `a + 1` to `a + 0`: capstones table fails (9); `TreeChoice.all()` skipping borrowed trees: casters fail (8);
  `general_trees()` ignoring `role.general`: `trees_by_class` fails; `_cost` ignoring aquatic: `aquatic.test_pike` fails;
  `SkillWheel._put` dropping a skill: the hud wheel rule fails; blinthe.tscn with an empty appearance / a missing
  faction file / clout keyed to a Role: `unit.py check` reports each. All reverted.
