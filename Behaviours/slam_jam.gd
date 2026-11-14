extends "res://Behaviours/jam.gd"

# Slam Jam: Jam's heavy form. Landing, a contest - d20 + its str check mod + rank against the foe's con
# save - and won, it interrupts the foe and leaves it Jammed, as Jam does (jam.gd). A hit also gives back
# 1 / (rank + 2) of its AP and cost (Unit.refund()): a hit costs (rank + 1) / (rank + 2) of its price.
# Not Jam's drain on Focus.


func apply(c: Cast) -> void:
	if not c.foe:
		return
	c.caster.refund(c.skill, 1.0 / (c.rank + 2))
	if not c.target.is_alive():
		return
	var b := c.battle
	var vs := b.beats(Check.side(c.caster.check_mod(&"strength", &"offensive", c.tags) + c.impact_rank()),
			Check.side(c.target.check_mod(&"constitution", &"defensive", c.skill.tags), Check.Kind.SAVE))
	b.contested.emit(c.caster, c.target, vs.mine.total, vs.theirs.total)
	c.bag[&"slammed"] = vs.won
	if vs.won:
		super.apply(c)


func dealt(_c: Cast, _n: int) -> void:
	pass


# Its terms: + rank on its interrupting contest, the interrupt impactful.
func terms(t: SkillTerms) -> void:
	t.check = true
	t.hit_per_rank += 1.0
	t.add(&"rank_impact", "contest")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return "A hit: a %s, {o:str mod} + {r:%d} vs the foe's {d:con mod}; won, it interrupts it and leaves it %s, as Jam does. A hit gives back 1/%d of its AP and cost" % [
			Glossary.term(&"contest"), rank, Glossary.term(&"jammed", "Jammed"), rank + 2]
