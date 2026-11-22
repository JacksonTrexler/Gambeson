extends Behaviour

# Snapping Turtle: when its holder uses an offensive skill on a foe, up to rank of its other defensive
# passives that react are snapped: asked to react as to its attack (Battle.react_with(), the trigger
# &"snap"), top to bottom of its hotbar, counting those that do. What each does snapped is its own
# (Interject: its check against the target; passing, the attack can't be turned aside). Defensive passives
# that don't react (Turtle Tactics) are always on: there's nothing to snap.


func react(r: Reaction, holder: Unit, rank: int) -> bool:
	if r.trigger != &"attacked" or r.by != holder or r.cast == null or &"offensive" not in holder.skill_tags(r.cast.skill):
		return false
	var me := r.skill
	var subject := r.subject
	var left := holder_rank(holder, rank)
	r.trigger = &"snap"
	r.subject = holder
	r.by = subject
	for x in Battle.reactions_of(holder):
		if left <= 0:
			break
		if x.skill != me and &"defensive" in x.skill.tags and r.battle.react_with(r, holder, x):
			left -= 1
	r.by = holder
	r.subject = subject
	r.trigger = &"attacked"
	r.skill = me
	r.rolled = []
	return left < holder_rank(holder, rank)


# Its terms: rank snaps more passives (impact).
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "passives snapped")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "Using an {x:offensive} skill on a foe, it also sets off up to {r:%d} of its other {x:defensive} {k:reaction|reactions}, top to bottom." % c.impact_rank()
