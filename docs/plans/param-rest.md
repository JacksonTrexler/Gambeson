# Param rest: the text of reserves, opens and Downed rules (z-paramrest, 2026-11-15)

Card: "Param rest" (docs/queue.md). Read: param-tail.md, route.md.

## Readings and calls (for review)
1. **Already routed, text still base.** `Unit.pools()`, `opened()` and `Downed.takes()` already read mods (param.md); only `Skill.markup()` showed raw `rank` and the raw `Glossary.mod(reserve_mod)` for them. Now they read `ri` (rank impact) and `_mod(reserve_mod, stat_impact, m)`: a reserve's size ("(cha mod) x {r:3}", or "{o:1.5 x cha mod}" under sigma), the tier a skill opens ("up to T3"), the Downed rule (`downed.markup(ri)`: rounds, HP limit, actions).
2. **Rates: the mechanic is routed too (call).** The resting rate (`Unit.giver_rank()`, Stamina's and Mana's "N more on a turn it rests") and a switch's carry (`Unit.carry()`, "10% x rank a turn held") read the raw slot rank, while pools and tiers read the modifiers' rank: a Density emblem on Stamina grew the pool but not its rate, and the text would have had to lie one way or the other. Both now read `mods(skill).irank(rank, rank_impact)`, as SkillTerms already declared for "reserve" and "tiers opened"; the text follows. Focus is the same Skill/Reserve path (a passive with `reserve_mod`), so it is covered by the reserve line, not special-cased.
3. **Stays concrete (build-time gates, no change):** `waives` (Generalist, Martialist, Thaumaturgist: the tier of general-tree skills one may learn), Dabblings' picks (`studies`), and the guest-tree rank caps (divinity, mastery, symphony, witchery). They gate what is *learned*; an emblem coming off would strand picks.
4. **`missed()`: no first user, nothing added.** Grepped docs/todo, docs/plans, docs/done and Skills for "on a miss", "if it misses", "whiff", "refund": no skill's recorded design wants a rider on a miss. Poach and Slam Jam's refunds are on a *hit* (`rebate`). Grudge counts an attack "hit or miss" as a melee attack, which is a rule over any use, not a rider. "Commitment to the bit" is the posing whiff, a path `missed()` is documented not to run on. Strike Out ("a miss among them doesn't end the attacks") is about the chain, not a rider. Inventing a skill to exercise the hook would be content nobody asked for.

## As built
- Scripts/Skill.gd (markup), Scripts/Unit.gd (`giver_rank`, `carry`).
- Test: `route_test.test_reserve_text` (one seam, no new file): Sweet Nothings size and text under Density and Concentrated, Stamina's rate, Mana's tier and carry, Tenacity's rule text.
- Mutation spot-checks (each failed the test, reverted): reserve text on raw rank; raw mod in the reserve text; `_comes_back` on raw rank; opens text raw; carry text raw; Downed text raw; `opened()` raw; `giver_rank()` raw; `carry()` raw.
