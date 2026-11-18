# Summoned AP and Wake and Rake (branch w3-skeleton)

The user (answers 2026-11-18b item 9, ?181): summoned units "spend all but up to rank + cast mod ap on spawning."
Caster general: Wake and Rake: "Add rank to AP `summon` units keep on spawning."

## Calls

1. **Keep rule** in `Behaviours/summon_per_rank.gd` `keeps()`: rank impact + the cast's stat mod (the skill's stat, through
   the caster's modifiers: Skeleton is int) + passives' `summon_ap`, never below 0, never more than the unit had.
   Spent first-pool-last: the keep is taken from the pools in order. "Cast mod" read as the casting stat's mod.
2. **Generic hook** `Behaviour.summon_ap(holder, rank, who) -> int` (default 0), asked of every equipped passive the summoner
   has; Battle.summon is untouched. Added to `skill.py` HOOKS so the check accepts it.
3. **Tag `summon`** (the user's, no ??; kind target, colour #8fb0c8 a placeholder) on Skeleton's unit. Declared via
   `mechanic.py tag`, whose ?? on the term I removed by hand. Wake and Rake reads the tag, not Skeleton.
4. **Wake and Rake** (`--human`): passive, magical+int, Caster general tree, tier 4 (a guess, beside Drone), hand price
   left to the calculator (2 AP, cost 1). Its rank goes through holder_rank (rank impact), so modifiers raise it.
5. Skeleton's description now says the AP kept.

## Tests
- `summon_test` extended: kept AP = rank + mod, then a second cast with Wake and Rake III keeps 3 more; describe says rank.
- Stub `wake_and_rake_test.gd` deleted (sweep covers it).
- Mutations (each fails summon_test, reverted): summon_ap not added; rank dropped from the keep.
