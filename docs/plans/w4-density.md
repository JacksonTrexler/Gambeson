# Density eligibility and its bargain (branch w4-density, 2026-11-19)

The user's words: `docs/agents/answers-2026-11-19.md`, the "185-191" block. Built on skill-modifiers.md, param.md,
param-tail.md, param-rest.md, w2-param.md, w3-cram.md. Baseline suite: 10019 checks, 0 failed (951 tests).

## Readings

1. **"Dramatically more difficult checks to pass / easier to overcome for enemies"** is read from the caster's side:
   a dense skill is harder for its user to land (its attack rolls, the saves and contests it imposes) and easier for
   foes to resist; Diluted the reverse ("easier checks, harder checks to overcome for enemies"). One number does both:
   a shift on the caster's side of every check the skill makes.
2. **"Scaling component ... and a penalty component"** is read as AND, both ways (Density and Diluted share one rule):
   rank impact to boost (Density) or tamp down (Diluted), and something that makes the skill harder or easier to land.
   A skill without rank impact is ineligible for Diluted too: Diluted would cost nothing (Clairvoyance, Solar, Peel,
   Send Off used to fit Diluted through rank range alone; they no longer do).
3. **"Range scaling buff"** for Diluted is read literally: rank range x (1 + f), as before. **"Vastly reduced range"**
   for Density: rank range nullified (as before) *and* the whole range / (1 + f), never below the tiles beside it.

## Calls (for the coordinator to number)

1. **The penalty component** ("trades", `SkillTerms.trades()`): a **range** (an active reaching past its neighbours, or
   any rank range), a **check** (an attack roll, save, contest, or a behaviour's declared check), a **slot a foe can
   disable** (every skill but a trait: dense skills are easier to disable, `Unit.slot_weight()`), or a **penalty** (the
   Terms group's, derived or declared: Cram's wear). The disable trade is my reading of "easier to overcome for enemies"
   for passives; without it ~95 more passives (Favour, the slot passives, Mana...) were ineligible. It makes the rule
   mostly "has rank impact, isn't a trait": ask whether passives deserve a stronger cost.
2. **Check shift knobs:** `Modifiers.DENSE_CHECK = 5`, `DILUTE_CHECK = 3`, x f (a rank I Sigil: -4 / +2). The tuning
   point the user asked for ("tune by check difficulty"); first cut, untuned.
3. **One read for the shift:** `Battle.requirement()`'s + hit carries it, so attack rolls, Strike's chain, saves and
   contests (`skill_opts`), engulfs, Level Down, Last Stand and the forecast (`hit_chance`) all get it with no new
   call sites in the attack roll (w4-friction's ground). Behaviour checks: `Cast.check_shift()` (Hitch, Slam Jam, Stun's
   DC, Wildfire's dodge DC) and Gallantry's bonus (`mods_on(holder).check`).
4. **Declared reasons:** `Skill.no_density` (Terms group, FLAG_CEILING 103 -> 104: a field every skill shares, as
   `penalty`). `skill.py check` runs `Util/terms.gd density-check` (headless, ~2 s): a skill the rule finds ineligible
   must say why; one that says why but fits is flagged too. `skill.py density` lists them. `skill.py terms <id>` prints
   what a skill trades. New skills: `skill.py new --set no_density="..."`. Quiet in skills_test (a design note).
5. **Parameterized (rank I unchanged), 10:** Stun (DC rank and turns: rank impact, `describe_as`), Power Armor (Power
   share and blow cut), Scrap Plating (Defense cap), and seven uncapped single-tier blows given `dice_per_rank`
   (their rank did nothing): Crushing Blow ??, Rake, Savage Swing ??, Waterstrike, Energy Missile, Gank, Sutemi. The
   blows' rank II+ is new scaling (2 dice at II), not a balance pass: tune by the knob or a later d tag.
6. **Wildfire's reach_scale range** is not cut by Density's reach (only its rank range, as before): `span()`'s
   reach_scale branch returns early. Small; left.
7. **Cram:** unchanged; eligible (rank impact, a slot, a pillar). param_test's concrete table gains a Cram row (slots
   granted: I 2, II 3, Density reads I as II); its converted slots and wear under Density stay equip_test.test_cram's.

## Ineligible (`skill.py density`: 140 under the bare rule -> 45 with the disable trade -> 35)

| Skills | Declared reason | Question |
|---|---|---|
| alluring, starkind, skill_slot | a trait: no slot, range, check or cost: Density would be all gain | a trait-wide cost? |
| arcanist, physical_intelligence, everyman, field_experience, working_knowledge, decisive_strike, decisive_mastery, powerful, synergy, striking_intellect, elemental_mastery | a switch / selector / gate: nothing scales | - |
| generalist, journeyman, martialist, thaumaturgist, divinity, mastery, symphony, witchery | a build gate: an emblem off would strand picks | - |
| clairvoyance, peel, send_off, solar | rank buys only reach | give each a rank-impact term (Solar's damage, Send Off's turns)? |
| mage_armor, manifest, relay | stat impact only: rank adds nothing yet | `per_rank` on the effect? |
| coalescing, stoneskin | a fixed roll / share: rank would need new tiers | new tiers? |
| armor | Defense by the item, not ranked | - |
| oceanic, reckless_abandon, vaporize | a drawback only / an inherent trait / a toggled form | - |

## As built

- `Scripts/SkillTerms.gd`: `reach`, `slotted`, `trades()`, `density_why()` (the one rule). `Scripts/Modifiers.gd`:
  rho_up/rho_down set `reach` and `check`; `why_not()` asks `density_why()` for both. `Scripts/Skill.gd`: `span()` x
  `m.reach`; `no_density`. `Scripts/Battle.gd`: `requirement()`'s shift. `Scripts/Unit.gd`: `slot_weight()`.
  `Scripts/Behaviour.gd`: `Cast.check_shift()`. Behaviours: stun, cone, hitch, slam_jam, gallantry, power_armor,
  scrap_plating. `Util/terms.gd` (density, density-check, terms line), `Util/skill.py` (check_density, density).
- Skills: 7 blows (`dice_per_rank`), 35 `no_density`.
- Tests: new `param_test.test_density` (range, attack, forecast, slot weight both ways; Stun's DC; trait vs slotted;
  Clairvoyance). Updated to the new rule: modifiers_test.test_symbols (Density range / 1.75), route_test.test_save_rank
  and test_area (less the shift; Solar given a rank impact in the test), test_aura (Glow given turns_per_rank),
  test_rift_look (the look slotted, not a trait), param_test.test_move, test_clairvoyance (Diluted no longer fits),
  test_concrete_scaled (Gallantry's rank part; + Cram row), skills_test QUIET (+ no_density).
- Mutation spot-checks (each failed test_density, reverted): requirement() without the shift; slot_weight() without
  it; span() ignoring reach; Stun's DC on raw rank; no disable trade. `skill.py check` caught a dropped reason and a
  stale one.
