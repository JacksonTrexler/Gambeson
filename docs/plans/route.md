# Routing the engine through the modifier reader (r-route, 2026-11-14)

Task: finish what docs/plans/skill-modifiers.md listed as "not routed", so a modifier changes a skill
everywhere it shows or acts: mechanics, requirements on every outcome path, descriptions as held, the AI,
behaviours on every path. Then (after r-param landed) the six skills it deferred and UNSAID.

## Readings and calls (for review)

1. **Which channel each read is.** Rank as a *distance or how many it reaches* is rank_range; rank as
   *what it does* (a bonus, a DC, turns, hits, a count of effects) is rank_impact. As built:
   - rank_range: aura reach and Flamecharm's split count, Flamewall's width, Solar's cone (+15 a rank),
     Send Off's + rank tiles, Sing's (auto) count of targets, Emergency Exit's ally reach, Waltz's radius,
     Metea's blast (AI too).
   - rank_impact: a save's + rank, an execute's / rank (every contest that cuts by it), Wildfire's
     imposed DC, hits_per_rank and Strike's chain (hits and tier), Level Down's rolls, Death's last stand,
     Brainfog's sqrt(rank) slots, trap concealment/dice/level, Well Up depth and turns, zone levels,
     Observe, boost + rank, clears(rank), carry, Shackles' rank and DCs, Elemental Strike's uses,
     Meditate's points, investigation's + rank, Humble, Pray, Smite's god riders (Vetruvis's radius
     included - one rank goes in, a call), Flamewall's burn turns, Exit's turns, Waltz's concealment,
     Beastshape's form rank and turns, Burning Bag's item rank, Eros heal's overheal.
   - stat_range: Send Off's mod, Waltz's dex/cha mod, Coordinate's cha-mod reach.
   - stat_impact: boost_mod, Relay's str mod (now `per_mod = strength` on its Effect, so the existing
     passive path scales it; `_relay()` just reads the stat).
   SkillTerms declares each, so eligibility and Pricing follow (`skill.py modifiers`: 51 -> 27 with
   r-param). Pricing's `rank_term` counts them; hand-priced skills only scale by a ratio, so no price
   changes without modifiers.
2. **Requirements on every outcome path.** One payoff set, read wherever the skill has the outcome:
   `hit` (+ to whatever check it makes: attack, Strike's chain rolls, save, drag/engulf contests, Level
   Down's rolls, Death's check), `edge` (on that check), `damage` (+ to damage on every damage path incl.
   chain, Wildfire, Metea's blast; + HP on a heal and Eros's Smite heal; + AP on a boost). New fields
   `turns` (+ to the turns its effects and disabled slots last) and `strength` (its effects x (1 + s)
   via Applied.scale). Lambda pays turns like hit; strength x potency. Pricing: a turn counts 0.5, +100%
   strength 2. `requirement()` now returns 5 entries. A requirement is now described
   (`Requirement.markup()`: share and payoff through lambda).
3. **Descriptions as held.** `Skill.markup(rank, with_spec, u)` / `describe(rank, u)` / `spec(u, rank)`:
   with a holder, every number above reads through `u.mods()`, a scaled stat shows as
   "{o:1.75 x int mod}" (0 x when nullified), range through `reach_markup(m)`, and AP/cost are what u
   pays (`Pricing.ap_at/cost_at` x Exhaustion) - closes "Static skill descriptions show base costs only"
   for the spellbook and hotbar. Holder-aware: hotbar tooltip (SkillSlot.holder), spellbook entries
   and their summary line, the spellbook's detail. **Base** (call): the skills screen (SkillGrid,
   SkillWheel tooltips, SkillDetail when it offers a purchase) - it is where ranks are bought, so it
   shows the skill itself; it adds "Base values: ρ↑ changes them (...)" when the unit's modifiers do.
   There is no unit card with skill text (UnitCard shows none).
4. **Behaviours' descriptions**: new hook `Behaviour.describe_as(c: Cast)` (holder, rank, mods; no
   battle), default `describe(c.rank)`. Behaviours that read `c.impact_rank()` should override it to
   show modified numbers; none do yet (behaviours are r-param's ground).
5. **AI and HUD**: one estimator, `Battle.damage_range(u, s, t, b)` (tier/dice/hits at rank impact, stat
   at stat impact, weapon bonus, requirement damage) for `AI.score` and `HUD._hurt`; `hit_chance` adds
   the requirement's hit and edge and uses the hit's tags (modifier tags) for Defense. AI's Metea blast,
   Observe look and wound clears read through the reader.
6. **Behaviours on every path** (`Battle._land()`): apply() now runs on every path that lands - Beastshape,
   the aura/retrieve/humble/fog/exit/boost/imbue branch, Eros's heal, Level Down (if a level was taken),
   Death (if it killed), Strike's chain (once, if any hit landed, with `dealt()` after; guard, edge and
   bonus() apply to each chain roll). Paths that **can't**: a lost save or contest is a miss, as a
   missed attack roll is, and runs none (there is no "missed" hook to call); a channel stopped by using
   it again (`recast_stops()`) lands nothing; tile skills (`cast_at`) have no Cast (it needs a target
   unit). Comment in `_cast()`.
7. Checks in `_level_down`, `_death`, `_flamewall`, `_chain`'s stat reads now use the skill's tags as its
   caster has them (modifier tags reach them).
8. **UNSAID emptied**: markup lines for Beastshape, Coordinate's links, Alluring's adjectives and
   nouns ("It may go by ..."), Personify's AP (a hybrid passive's spec shows AP), Pray's range (shown
   since a prayer to Drael lands in range). `Skill.cinders` was dead (its Effect does the work, and was
   already described): removed from Skill.gd and cindering.tres, FLAG_CEILING 129 -> 128.

## Not routed (left)
- Behaviours/*.gd describe() lines (describe_as hook added for them).
- Rift turns, reserves/opens/Downed rules' text, Look's dissonance rank, Dabblings, waives (build-time).
- Strike passives' per-hit extras (steady, featured, brutal) read effect stats, already through effects.

## As built
- Scripts: Battle.gd (cast paths, `_land`, `damage_range`, helpers), Skill.gd (markup/spec/describe with
  holder, `cone_at`, `base_note`, `_mod`), Requirement.gd (turns, strength, markup), Pricing.gd (ap_at,
  cost_at, payoffs), SkillTerms.gd, Behaviour.gd (describe_as), AI.gd, HUD.gd, SkillSlot/SkillEntry/
  SkillDetail/SkillGrid/SkillWheel/Spellbook.gd. Skills/relay.tres (per_mod), Skills/cindering.tres.
  Util/skill.py (FLAG_CEILING).
- Tests: new Tests/route_test.gd (10 tests). Changed: modifiers_test.test_requirement compares the
  first three payoff entries (the array grew); skills_test UNSAID -> [].
