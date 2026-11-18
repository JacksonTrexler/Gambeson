# Parameterize the concrete skills (?133, w2-param, 2026-11-18)

The user: "if in doubt for a skill that isn't properly parameterized with difficulty, scaling / it's overly
concrete, that's a signal that it needs to be parameterized or scaled better on rank and stats"; "any
underpowered skill should be easy to tweak using check difficulty"; "don't focus on balance at present".
Read: param.md (its 27 concrete), param-rest.md, param-tail.md, w2-cost.md (costs untouched).

## Readings and calls (for review)
1. **Count.** `skill.py modifiers` listed **29** skills eligible for no modifier (the 27 of param.md plus
   Final Act and Striking Intellect, added since) and 5 "tags only" (eligible for a tag, nothing scales).
   After: **22** and 4. Costs unchanged: no AP / cost / profile touched.
2. **The rule for "can be parameterized"**: it holds a number (a count, a bonus, a duration, a size) that
   can read rank through the declared channels with rank I exactly the old value. Rank I is always as it
   was; rank II+ is new scaling, which is what the user asked for ("scaled better on rank"), not a rebalance
   of rank I. Where a passive is capped at max_rank 1 it still scales: a Density emblem reads rank I as II
   (that is what the modifier is for; Efficiency, Move and Mana were done the same way in param.md).
3. **Parameterized (8 of the 29, 1 tags-only, 1 more):**
   - **Favour**: luck +1 and mitigation 1% are now `per_rank` effects (data only). Reverses param.md's
     "making it per rank would rebalance" call: the user's later words say concrete is the signal to scale.
   - **Hazard Expert** (trap word x(1 + rank)), **Move +1** (movement +rank): `per_rank` on the effect (data only).
   - **Basic Magic / Martial / Specialist Skill Slot +1**: `per_rank`; the slots a passive grants now read
     its rank through its holder's modifiers (`Unit._grants()`, rank impact), as `_gather_effects` does for
     every other passive effect. Call: slots are a count, so a Density emblem on one gives 2.
   - **Final Act**: its free actions are its rank (rank impact, `holder_rank()`), 1 at rank I; the AI's
     `reprisal()` weighs that many strikes. Text via `describe_as`.
   - **Gallantry** (tags-only before): its cha check gets +1 a rank past I (`CHECK_PER_RANK`, a named constant
     in the behaviour; 0 at I), rank impact. To carry it, `Reaction.contest()` / `odds()` take an optional
     `bonus` (default 0; one generic hook any reaction's check can use: Interject's dex check can too).
     Call: the check difficulty stays a behaviour constant rather than a `Skill.check` on a passive
     (`ranked` would add +1 at rank I, and `Skill.check` on a passive would make AI/HUD read it as a cast).
   - **Stonegift** (tags-only before): `turns = 2, turns_per_rank = 1` (3 turns at I as before, +1 a rank);
     hand price untouched.
4. **Stays concrete (22), with the reason:**
   - *Binary stat / form / kind switches, nothing to scale:* arcanist, physical_intelligence (a stat stands
     in for another), everyman, field_experience, working_knowledge (energy counts as a kind),
     decisive_strike, decisive_mastery (a Strike form switch), powerful (Energy is Power), synergy (shared
     reads while in party reach: a gate), striking_intellect (which stat an attack reads: a selector, and the
     attack roll code is off limits this round).
   - *Elemental Mastery*: a switch whose number (the highest mental mod on Strike's first hit) already scales
     through Strike's own stat_impact `element` term (param-tail.md); there is no second read to declare.
   - *Penalties and traits:* oceanic (-4 str/dex/con off water: a drawback, rank would only punish learning
     it; lambda acts on beneficial contingencies), reckless_abandon (an inherent trait: flat Affinity by
     posture), vaporize (a toggled form: 75% / 50% mitigations; rank past 100% makes no sense, no rank-curve
     mitigation exists).
   - *Build-time gates* (unchanged from param.md, call kept): generalist, journeyman, martialist,
     thaumaturgist (`waives`: the tier of general skills one may learn) and divinity, mastery, symphony,
     witchery (`studies`: the rank caps guest-tree picks). An emblem coming off would strand picks.
   - *Not touched, tags-only:* coalescing, energy_missile, stoneskin (a single fixed tier / threshold; rank
     would need new content: tiers, not a re-reading of an existing number).
5. **Check difficulty.** None of the 29 had a `SkillCheck` to tune; the only checks among them are Gallantry's
   (above) and Striking Intellect's (the attack roll: left alone). For tunability the numbers are now data
   (`per_rank`, `turns_per_rank`) or one named constant; `skill.py terms <id>` shows each channel.

## As built
- Skills: favour, hazard_expert, move_plus_one, magic_slot, martial_slot, specialist_slot (`per_rank`); stonegift (turns).
- Scripts: `Unit._grants()` (slot rank through mods), `Behaviour.Reaction.contest()/odds()` (`bonus`).
- Behaviours: `final_act.gd` (free actions, text, reprisal), `gallantry.gd` (`check_bonus()`, text).
- Test: `Tests/param_test.gd`: PARAMETERIZED gains nine; `test_concrete_scaled` is one table (rank I as it was, rank II
  more, Density reads I as II, for each), plus Favour's mitigation, Reaction bonus, Gallantry's text. No new files.
- Mutation spot-checks (each failed, reverted): slot rank raw in `_grants()`; Final Act's grant on raw rank;
  Gallantry's bonus on raw rank; `Reaction.odds` dropping `bonus`.
- `skill.py modifiers`: 29 -> 22 ineligible (tags-only 5 -> 4). `skill.py check`: ok.

## Not done
- Interject / Snapping Turtle's checks don't take a bonus yet (the hook is there).
- Coalescing, Energy Missile, Stoneskin (tags-only) and the 22 above stay.
