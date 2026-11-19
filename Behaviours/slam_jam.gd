extends "res://Behaviours/jam.gd"

# Slam Jam: Jam's heavy form. Landing, a contest - d20 + its str check mod + rank against the foe's con
# save - and won, it interrupts the foe and leaves it Jammed, as Jam does (jam.gd). A hit also gives back
# 1 / (rank + 2) of its AP and cost (Unit.refund()): a hit costs (rank + 1) / (rank + 2) of its price.
# Not Jam's drain on Focus.


func apply(c: Cast) -> void:
	if not c.foe:
		return
	c.caster.refund(c.skill, rebate(c).y)
	if not c.target.is_alive():
		return
	var b := c.battle
	var vs := b.check(c.caster, &"strength", c.target, &"constitution", contest(c))
	b.contested.emit(c.caster, c.target, vs.mine.total, vs.theirs.total)
	c.bag[&"slammed"] = vs.won
	if vs.won:
		super.apply(c)


# The contest's helper options (apply() rolls them, foresee() weighs them): + rank, the caster's tags on its
# side and the skill's on the foe's, rolled as a save.
static func contest(c: Cast) -> Dictionary:
	return {bonus = c.impact_rank() + c.check_shift(), tags = c.tags, their_tags = c.skill.tags, kind = Check.Kind.SAVE}


# Its contest's odds (as apply() rolls it): the interrupt is a rider that lands that often.
func foresee(c: Cast) -> Dictionary:
	if not c.foe:
		return {}
	var p := Battle.odds(c.caster, &"strength", c.target, &"constitution", contest(c))
	return {notes = ["Interrupts it, Jammed (%d%%)" % roundi(p * 100.0)] as Array[String], riders = p}


func rebate(c: Cast) -> Vector2:  # on a hit only: a refund after paying
	return Vector2(0.0, 1.0 / (c.rank + 2))


func dealt(_c: Cast, _n: int) -> void:
	pass


# Its terms: + rank on its interrupting contest, the interrupt impactful.
func terms(t: SkillTerms) -> void:
	t.check = true
	t.hit_per_rank += 1.0
	t.add(&"rank_impact", "contest")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "A hit: a %s, {o:str mod} + {r:%d} vs the foe's {d:con mod}; won, it interrupts it and leaves it %s, as Jam does. A hit gives back 1/%d of its AP and cost" % [
			Glossary.term(&"contest"), c.impact_rank(), Glossary.term(&"jammed", "Jammed"), c.rank + 2]
