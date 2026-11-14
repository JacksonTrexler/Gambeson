# Parameterizing skills for modifiers; Clairvoyance's pings; UNSAID (r-param, 2026-11-14)

The user (2026-11-14): "if the skill doesn't have the tags / mechanics needed for the automated system to
work on it, it is ineligible / if a skill is genuinely too concrete and totally *could* be compatible with
the system if properly tagged / polymorphized / abstracted / parameterized it should be."
Builds on docs/plans/skill-modifiers.md (SkillTerms, Modifiers, Behaviour.terms(), Cast.impact_rank()).

## Readings and calls (for review)

1. **Parameterized** = the skill declares its channels (a behaviour's `terms()`, or SkillTerms reading
   a field) *and* every read of that rank or stat goes through its holder's modifiers, so a modifier
   that is eligible also acts. A channel is declared only where the read is routed: no skill is made
   eligible for a modifier that would do nothing.
2. **"Add the missing tags"** read as the terms' kind flags and channels a skill failed to declare
   (Manifest's per_stat effect was already scaled by Modifiers.effect() but SkillTerms didn't count it).
   No Skill.tags were added: none of these skills' checks or damage would read a tag modifier, so a tag
   would make them eligible for something that does nothing (call).
3. **Passive hooks** (affinity, lets_word, hurt, healing, command_mod, step_cost) get the holder and a
   rank, not a Cast: `Behaviour.mods_on(holder)` finds the passive the behaviour is on and returns
   `holder.mods()` of it (NONE without emblems, cheap); `holder_rank()` reads a rank through it. Peel
   now uses it too.
4. **Rank where a behaviour reads it as a quantity of effect** is rank_impact (Move's tiles, Energize's
   pairs, Telepathy's "commands as rank"); as a distance it is rank_range (Molothrus's and Telepathy's
   reach, Clairvoyance's reach). Wisdom *score* in Clairvoyance's reach is stat_range.
5. **Build-time gates left concrete**: Dabblings (`studies`) and the general-tree waivers (`waives`) set
   what can be picked or learned; an emblem coming off would strand picks. Efficiency and Illusionist
   (Affinity) were parameterized: they only discount, nothing is stranded.
6. **Battle.gd reads deferred**: six skills whose rank/stat reads live in Battle.gd's cast paths
   (r-route's ground this round) are parameterizable but left for after r-route merges.
7. **Hand prices kept**; no rebalancing (no per_rank added to flat passives like Favour).
8. **Pings -> behaviour**: `Behaviours/clairvoyance.gd`. Three Behaviour hooks, generic: `recast_stops()`
   (used again while channeling it: stop, free - before payment), `held(b, holder)` (its channel held
   through its side's turn end), `senses()` (the AI's scry, and it doesn't hold still for it). Battle keeps
   the perception side as `ping(u, reach)` (was clairvoy(); registers the seer) and `pinged()`;
   `clairvoyance_reach()` moved to the behaviour as `reach(u)` (clairvoyance_test calls it there).
   Its reach is through the reader: wisdom score (stat range) + channel rank (rank range).
   FLAG_CEILING 130 -> 129. `held` added to skill.py's HOOKS.
9. **UNSAID**: Sweet Nothings' two were already said (dropped from the list). Coalescing's and Drown's
   `grapples` were dead (holds() is already true by `drowns`): removed from their .tres; water_test now
   asserts `holds()` instead of the field. The other seven need Skill.markup lines (Beastshape.shapes,
   Cindering.cinders, Coordinate.links, Alluring.shows_*) or are live but hidden by design (Personify.ap,
   a hybrid; Pray.radius_per_rank, its rank-tile area): left, as markup is r-route's this round.

## The 54 (`skill.py modifiers`: 54 -> 33)

| Skill | Call | How / why |
|---|---|---|
| acceptance, bargaining, quarry, survivalist, wildcaller | parameterized | Efficiency: tier reached = rank impact, via holder_rank |
| bandwagon | parameterized | DC rank and doubters cap: rank impact; cha mod in DC: stat impact |
| illusionist | parameterized | spells without penalty = rank impact |
| molothrus | parameterized | fooled within rank tiles: rank range; siphon/shield shares: rank impact |
| telepathy | parameterized | ally reach: rank range; commands as rank: rank impact |
| word_to_the_wise | parameterized | own wis mod: stat impact; + rank cap: rank impact |
| energize | parameterized | pairs, Overcharge cap and turns: c.impact_rank() |
| heal, megaheal | parameterized | dice and + rank: rank impact; caster mod: c.stat_mod() |
| move | parameterized | tiles: rank impact |
| resuscitate | parameterized | HP share: rank impact |
| clairvoyance | parameterized | new behaviour; reach: rank range + stat range |
| manifest | parameterized | per_stat effect counted as stat impact (already scaled) |
| sweet_nothings | parameterized | Unit.pools(): mod stat impact, x rank rank impact (every reserve passive) |
| mana | parameterized | Unit.opened(): tier = rank impact (every `opens` passive) |
| grudge, tenacity | parameterized | Downed.gd: the rule's rank through mods (rounds, limit, actions) |
| beastshape, burning_bag, elemental_strike, emergency_exit, waltz_of_vapors | deferred | reads in Battle.gd (beastshape(r), _retrieve(r), imbue(r), emergency_exit, waltz's mods) - r-route's file |
| relay | deferred | str mod read in Battle.gd:2303 (relay x str mod); flat in rank |
| arcanist, physical_intelligence | concrete | a stat stand-in: on or off, nothing scales |
| everyman, field_experience, working_knowledge | concrete | energy counts as a kind: binary, max rank I |
| decisive_mastery, decisive_strike, elemental_mastery | concrete | a Strike form switch, max rank I |
| powerful, synergy | concrete | a binary trait, max rank I |
| hazard_expert | concrete | flat x2 word range; rank adds nothing |
| magic_slot, martial_slot, specialist_slot, move_plus_one | concrete | flat +1, max rank I |
| favour | concrete | flat +1 luck, 1% mitigation; rank adds nothing (making it per rank would rebalance) |
| oceanic | concrete | a penalty contingency only; lambda acts on beneficial ones |
| reckless_abandon | concrete | inherent trait: flat Affinity by posture |
| vaporize | concrete | a toggled form with flat mitigations |
| divinity, mastery, symphony, witchery | concrete (build gate) | rank caps guest-tree picks; an emblem off would strand picks |
| generalist, journeyman, martialist, thaumaturgist | concrete (build gate) | rank opens general-tree tiers to learn |

Counts: 21 parameterized, 6 deferred (Battle.gd), 27 left concrete.

## As built
- `Scripts/Behaviour.gd`: `mods_on()`, `holder_rank()`, `recast_stops()`, `held()`, `senses()`.
- `terms()` and routed reads in Behaviours: efficiency, illusionist, bandwagon (`dc(holder, rank, m)`),
  molothrus, telepathy, word_to_the_wise, energize, heal, move, resuscitate, peel (mods_on), clairvoyance (new).
- `Scripts/SkillTerms.gd`: passive reserve (rank impact; reserve_mod stat impact), opens and downed (rank
  impact), per_stat effects (stat impact).
- `Scripts/Unit.gd`: pools() and opened() through `mods()`. `Scripts/Downed.gd`: the rule's rank through mods.
- `Scripts/Battle.gd`: pings code out (recast stop, channel start, turn-end update are the behaviour's);
  `clairvoy()` -> generic `ping(u, reach)`; `clairvoyance_reach()` removed. `Scripts/AI.gd`: `senses()`.
  `Scripts/Skill.gd`: `pings` and its markup line removed (the behaviour's describe() says the same).
- Drift (`skill.py drift`): 77 hand-priced skills differ, before and after. Computed points moved for
  clairvoyance 1 -> 2, heal and megaheal 2 -> 2.5 (their new terms); computed AP/cost unchanged.
- Tests: `Tests/param_test.gd` (5: all 21 eligible; Move under Density; Heal under Concentrated;
  Clairvoyance under Diluted and an ineligible Density; Word to the Wise, Sweet Nothings and Mana under
  badges). Changed: clairvoyance_test calls `reach()` on the behaviour; water_test asserts `holds()`;
  skills_test UNSAID shrunk.

## Not done
- The 6 deferred Battle.gd skills; Strike/elemental reads; markup for the 7 UNSAID entries.
