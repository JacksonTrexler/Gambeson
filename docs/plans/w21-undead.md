# w21-undead: Undead rank effect, the user's rule
User: rank added to any check defending against instant death; incoming healing tagged Dark or Undead +rank*5%.
Replaces the guessed pierce Defense per rank (w18-undead-rank).
## Calls
- Death half: no code. Skills/undead.tres Effect stat=check kind=defensive tags=[execute] per_rank +1: Unit.check_bonus() already feeds Battle.stand_bonus() (the shared last-stand/Death check) execute-tagged effects. Luun's Smite execute is a HP threshold, not a check: untouched.
- Heal half: new Effect stat `healed` (mechanic.py stat), Effect tags=[dark, undead] amount .05 per_rank; read in Unit.heal() (new `tags` param, only when heard) as h*(1+stat). Battle.mend() passes tags; Battle.cast passes caster.skill_tags(skill). Untagged heals (items, pulse, regen) are unboosted. Boost applied before being_healed listeners (Molothrus cuts the boosted amount).
- Tags dark, undead, execute already exist; no tag added.
- Skill has no hand-written description; Effect text is generated.
## Tests
- monster_test.test_undead_rank rewritten (was pierce Defense per rank): stand_bonus(execute) +rank, plain unmoved; dark/undead/fire heals; mend() carries tags.
- Mutations: execute tag dropped -> rank II/III fail; heal tags ignored -> heal and mend checks fail. Both reverted.
