# w3-strike: skill uses, Glancing Strike per use, Heavy Strike on any use, Chaser

The user's words: `docs/agents/answers-2026-11-18b.md`, items 2 and 3 (Glancing Strike "per skill use: units can
make many strike attack rolls at once"; Heavy Strike "acts on a single skill *use*", an automatic repeat is
consecutive, a manual re-target and re-use is a separate hit; Rogue t8 "Chaser"). Prior: ?186, ?189.

## Readings and calls (for review)

1. **One generic scope, the skill use** (`Battle.use_of(u)`, payload `Behaviour.Volley`, now "a skill use"):
   opened by a caster's outermost `cast()`/`cast_at()` and holding everything inside it (all its attack rolls,
   Strike!'s restrike, Jugular's recast, an auto skill's spread), closed when that returns. Each use has an
   `id`; every attack roll carries it (`Check.Roll.use`). No per-skill counter. A use chosen afresh (aimed
   again by hand, or picked in an interrupt) is a new one. Another unit's reaction inside it is not part of it.
2. **Glancing Strike (a)**: `opening_rolls` now counts within a use: `Unit.rolls_made` is zeroed as a use opens
   (was: per battle). The glance reading (lower die misses, higher would land) was already as the user said.
   Effect text: "+N to hit on each of its first N attacks each time it uses a skill".
3. **Heavy Strike (b)** works on any skill's use: every attack that lands (each Strike hit, and now any
   attacking skill's blow in `cast()`) goes through `striking()` at stage `hit`; the `end` stage moved from
   `_chain` to the use's close (`Battle._end_use`), once per unit the use landed on. Calls:
   - pools are **per target** (an auto skill hitting three foes makes three blows, each behind its own last roll);
   - a multi-hit skill (`hits_per_rank`) counts each blow from its one roll as a success;
   - the pooled blow lands after `used` is emitted (it's at the use's close), through `_blow()`: Starblade's
     refill, the ground, a kill counted;
   - **changed**: a missed last roll now loses only the pooled damage; the Strike no longer counts as missed
     for its behaviours (`_miss`) or Perfect (Strike has no behaviours, so this is only Perfect at 36 hits);
   - Heavy Strike stays a Strike form (exclusive, renames Strike), though it now also pools other skills.
4. **Chaser (c)**, the user's name (`--human`, no ??), passive, tags martial + reaction, on the Rogue's Blade
   root after Backstab with Backstab as its prereq (roots have no tiers, so "t8" is not set; prereq is my call).
   - Trigger: a new reaction trigger `&"crit"` (`Battle.roll_attack()`, subject the target, by the roller),
     fired on a rolled critical hit, so any passive can react to dealing or taking one. Jugular's forced
     critical (a hit made a crit after the roll) does not fire it.
   - The follow-up is the existing interrupt (`grant_interrupt`, as Final Act's): one action, free AP as any
     interrupt, the player picks in the HUD (`directed`), the AI through `AI.interrupt()`. It opens after the
     critting use is over, so it is a separate use (Heavy Strike pools it apart).
   - `grant_interrupt(u, actions, only)`: new optional `only` (Skill -> highest rank), set on the unit as
     `Unit.allowed` while the interrupt is open: `Unit.actives` is just those, `Unit.rank()` caps them. HUD
     and AI read actives, so they follow without changes.
   - "Within rank actives of the rightmost": the rightmost `rank` usable actives on the hotbar (rank I: the
     rightmost alone); passives and unusable (disabled) actives aren't counted.
   - Rank cap = Chaser's rank through its holder's modifiers (`holder_rank`); its reach uses the same.
   - Once per skill use (a Strike's many crits chase once); a use made inside an interrupt (a chase, Final
     Act's action) sets off no chase - without it a high crit range chains chases indefinitely (seen in a
     mutation: 80+ chases).
5. Not balanced; Chaser's price is the calculator's.

## As built

- `Scripts/Battle.gd`: `_uses`, `use_of()`, `_begin_use()`, `_strike_hit()`, `_end_use()`, `_blow()`; `cast()`/`cast_at()`
  open/close uses; `roll_attack()` tags the roll and fires `&"crit"`; `_chain()` lost its own Volley and end
  stage; `cast()`'s damage loop goes through `_strike_hit()`; `grant_interrupt(..., only)`.
- `Scripts/Behaviour.gd` (Volley: `id`, `struck`; docs), `Scripts/Check.gd` (`Roll.use`), `Scripts/Unit.gd`
  (`rolls_made` per use, `allowed`, `actives`, `rank()`), `Scripts/Effect.gd` (opening_rolls text).
- `Behaviours/heavy_strike.gd` (per-target pools over a use), `Behaviours/chaser.gd`, `Skills/chaser.tres`,
  `Roles/rogue.tres`, `Icons/Skills/chaser.png`.
- Tests: `check_test.test_glancing_and_opening` (a real Strike: one use, rolls counted 1-3, next Strike new),
  `check_test.test_crit_range_glances` (was "80 rolls counted a battle", now 80 uses), `heavy_strike_test`
  (new `test_any_use`; `test_last_roll` sets defense before the hits), `chaser_test` (new: reach, cap, once
  per use, no chain, AI picks within reach), `hud_test.test_tabbed_skills_screen` (Chaser on the Blade root).
- Mutation spot-checks (each failed, reverted): no reset per use; non-Strike hits not pooled; use never
  closes; chase not once per use; no rank cap; leftmost instead of rightmost; no restriction; chase chains.
- Not done: the HUD isn't visually checked during a Chaser interrupt (it reads `actives`; HUD is a sibling's area).
