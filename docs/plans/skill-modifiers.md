# Skill modifiers, skill terms, the cost calculator, emblems (m-core, 2026-11-14)

The user's request (2026-11-14): make skills parameterized so modifiers can act on them; tags such as
execute and elements such as fire applicable to any skill by modifier, later tags working out of the
box; a cost calculator; the six symbol modifiers (rho, sigma, lambda, up and down); emblem items
(Sigil / Insignia / Crest / Badge); !RSC; ineligible skills listed, too-concrete ones parameterized.

## Readings and calls (for review)

1. **"claude-skill"** = `.claude/skills/new-skill/` and `Util/skill.py` (coordinator's reading).
2. **One place.** `Scripts/SkillTerms.gd` (class SkillTerms) reads what a skill does and how it scales
   from its existing fields (no edits to existing .tres). `Scripts/Modifiers.gd` (class Modifiers) is
   the set of modifiers on one unit's use of one skill, and the reader every per-rank / per-stat value
   goes through. `Scripts/Pricing.gd` (class Pricing) is the cost calculator and its one tuning table.
   `Unit.mods(s)` builds a Modifiers from what the unit wears; base + modifiers is computed only there.
3. **Four channels**, derived from fields:
   - rank -> range: radius_per_rank, reach_scale, blast;
   - rank -> impact: more than one Tier (dice by rank), roll_per_rank, dice_per_rank, dice_scale,
     turns_per_rank, push, pull, per_wound, restores, effects with per_rank (actives as put on; passives
     in Unit._gather_effects());
   - stat -> range: radius_mod, radius_stat;
   - stat -> impact: a Tier's stat, heal_mods, turns_mod, effects with per_mod / by_mod.
   Behaviours declare their own with `Behaviour.terms(t: SkillTerms)` and read scaled values through
   `Cast.impact_rank()` / `Cast.range_rank()` (Kick's push routed as the example).
4. **Effective rank.** A channel's factor k multiplies rank where that channel reads it: rank' = rank x k.
   *Nullify* means "as at rank I" (rank' = 1), not zero, so a skill whose whole effect is "x rank" (a
   per-rank effect, dice_per_rank, push) still does its rank-I thing; integer uses round, at least 1.
   Stat terms: mod' = mod x k, nullify = 0 (the stat adds nothing).
5. **!RSC** (coordinator's reading): factor 1 + f(r), r the emblem's rank: f = (2+r)/(3+r) on one skill
   (Sigil), (1+r)/(2+r) on a subset (Crest: actives, Badge: passives), r/(1+r) on all (Insignia). The
   user's "rank *" prefix is read as dropped (with it the factor runs past x2, against "approaches x2").
   Boost = multiply by 1 + f; drawback = nullify (rho, sigma) or a root (lambda down). Several emblems on
   one skill multiply. `Modifiers.rsc(rank, scope)`.
6. **Symbols.** rho up (Density): rank range nullified, rank impact x (1+f). rho down (Diluted): rank
   impact nullified, rank range x (1+f). sigma down (Concentrated): stat range nullified, stat impact
   x (1+f). sigma up (Dispersed): stat impact nullified, stat range x (1+f). Symbol ids rho_up,
   rho_down, sigma_up, sigma_down, lambda_up, lambda_down; shown as the Greek symbol and arrow.
7. **Lambda** (coordinator's reading of the 80% -> ~95% example): a requirement's permissive share p
   (the slice of its range that meets it) becomes p^(1+f) under lambda up (Restrictive; f -> 1: p
   squared, 80% energy -> 96%) and p^(1/(1+f)) under lambda down (Unrestrictive; -> sqrt). The
   contingent payoff: lambda up multiplies it by 1 + f; lambda down takes its (1+f)-th root (-> sqrt),
   rounded, at least 1 where it was. Tile requirements ("within rank tiles of an ally") normalize tiles
   over a span of 12 into a share and back. Binary ones (from concealment) keep their test; only the
   payoff changes. Lambda acts only on beneficial contingencies (the user: "for beneficial contingent
   effects"); a penalty contingency makes a skill no more eligible.
8. **Contingencies.** Existing: `Effect.above_hp` (Stoneskin: 0.85, share 0.15) is a requirement, routed
   through Modifiers so lambda acts on it (makes those passives eligible for free). New, declarative:
   `Skill.requires: Requirement` (Scripts/Requirement.gd): test (hp_below, hp_above, energy_above,
   energy_below, target_hp_below, target_hp_above, ally_within, concealed), share, and the payoff while
   met: hit, damage, edge (advantage +1 / disadvantage -1). Read by Battle.cast's attack roll and damage.
9. **Intensity**: the user's low / moderate low / moderate / high / extreme map onto Difficulty.MAGNITUDE
   words faint / mild / moderate / strong / severe (extreme was renamed severe before; intense and
   overwhelming sit between and past). `Skill.intensity` names it for new skills (skill.py writes the
   Tier from it); otherwise it is derived from the tier's average damage at rank I.
10. **Effect impact**: `Skill.impact` &"" | tame | impactful, for the unique effect beyond damage; derived
    when empty (effects, grants, behaviours, holds, contests: tame; disables, kills, levels_down, binds,
    shapes, rifts, exits: impactful). **Penalties**: derived (disadvantage, negative roll_bonus, a
    penalty requirement); `Skill.penalty` minor | major | severe for new ones.
11. **Pricing** (Pricing.TABLE): points = intensity points (exponential: 1, 2, 3, 5, 7, 10, 16 up the
    MAGNITUDE ladder) + per-rank hit and damage x rank + effect impact (tame 1, impactful 3) tapered by
    its requirement's share (x 0.4 + 0.6 share) - penalties (flat 1 / 2 / 3, flat even at the extreme) -
    adjacent (range at most 1.5 with no range scaling: -1); rank range costs nothing. AP and Energy come
    from points by the table. Existing skills keep hand-set ap/cost unless `priced = true`; their cost
    under modifiers is scaled by computed(modded) / computed(base), so modifiers change every price.
    New skills from skill.py are priced. `skill.py drift` lists hand-set vs computed (info, not check).
12. **Tag modifiers**: eligibility by the tag's kind - Glossary.TERMS kind, and Glossary.ELEMENTS
    count as damage. damage -> the skill deals damage (tiers); check -> it has a check (attack roll,
    save or contest); condition -> it puts effects on; ground -> it is aimed at a tile; target -> never.
    A tag unknown to the Glossary is ineligible. Added tags reach: Unit.has_tag (via its skills'
    tags), Battle.hit_tags (damage tags, bane, mitigation, Defense), Battle.executed (execute), stun's
    taps check (Cast.tags), Unit.mod/check_mod calls in cast with the skill's tags.
13. **Eligibility of symbols**: rho up needs rank impact, rho down rank range, sigma down stat impact,
    sigma up stat range (the channel it boosts must exist, so an emblem never only takes away); lambda
    needs a beneficial contingency.
14. **Emblems**: `Item.emblem` (a symbol id or a tag) and `Item.scope` (sigil, insignia, crest, badge);
    slot trinket (one at a time, so emblems compete with Heart Up and rings). Sigil: the leftmost skill
    on the hotbar the modifier is eligible for. Made by hand as .tres (no Util/item.py exists), names
    "<Word> Sigil" etc. in the user's pattern, so no ??. In loot: astral_princess and icor tables.
15. **HUD**: the skill tooltip adds one line of the applied modifiers as symbols and tags ("ρ↑ σ↓ fire").
16. **Colours**: TODO for m-colors - the six symbols want colours in `Tags.color()`; not added here.

## Not routed (listed for later)
Filled in as built.

## As built
Filled in as built.
