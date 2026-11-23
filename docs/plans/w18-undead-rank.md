# w18-undead-rank: Undead ?? per-rank effect
Call: the Skeleton unit gets nothing but tag undead + stats, so nothing to lift; bones turn piercing: Effect defense +1/rank tagged pierce (existing Effect fields, no Skill.gd change). Name kept. Rank I = +1.
Test: monster_test.test_undead_rank (ranks I-III pierce Defense steps, blunt flat, still undead). Mutation: per_rank off -> rank II, III fail.
Suite: 11350 checks, 0 failed (1067 tests).
