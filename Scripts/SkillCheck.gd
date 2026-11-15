class_name SkillCheck
extends Resource

# The check a skill makes against a foe, declared as data (Skill.check; docs/plans/checks.md): the
# caster's d20 + its check mod in `stat` against the foe's in `against`, through the one helper
# (Battle.check(); Battle.skill_opts() reads this). Used on a foe, it stands in place of the attack roll:
# lost, the skill misses. With `suspicion`, it's rolled only on a foe suspicious of the caster instead.

@export var stat := &""  # the caster's stat; empty: the skill's own (Skill.stat())
@export var against := &""  # the foe's; empty: the same as the caster's
@export var save := false  # the foe saves (a Save; Haluca), rather than a Contest (Drown)
@export var ranked := false  # + the skill's rank (rank impact) on the caster's side (the saves)
@export var edge := 0  # the caster's advantage (+1) or disadvantage (-1) on it
@export var range_penalty := 0  # off the caster's side a tile - tiles dragged, else past the first between them - less 1 a rank past I (Drown: 1)
@export var tags: Array[StringName] = []  # check tags it carries beside the skill's own (check effects tagged so count on it)
@export var drags_to := &""  # won, it drags the foe to the nearest ground with this tag the caster could walk to, and both into it (Drown: water; Battle.drag_spot())
@export var suspicion := false  # not in place of a roll: rolled only on a foe suspicious of the caster, and won, takes a stack of suspicion off; the skill moves only the enraptured (Sing's draw: Behaviours/displace.gd, Battle.lured())


# The caster's stat in it, for skill s.
func mine(s: Skill) -> StringName:
	return stat if stat else s.stat()


# The foe's.
func theirs(s: Skill) -> StringName:
	return against if against else mine(s)


# The range penalty at rank r over n tiles.
func penalty(r: int, n: int) -> int:
	return maxi(range_penalty - (r - 1), 0) * n if range_penalty > 0 else 0
