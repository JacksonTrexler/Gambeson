extends Behaviour

# Illusionist: opens a school of spellcasting (school: the tab of a choice on its holder's class whose
# `by` is this skill - the Rogue's Illusion), to pick on its class's own tab. Its spells are a guest
# tree's, ranking at the choice's Affinity penalty - but the first `rank` of them its holder learns
# (in the order learned) rank and cost as its own: no penalty (Unit.guest_affinity()).

@export var school := "Illusion"


func affinity(holder: Unit, rank: int, s: Skill, t: SkillTab, a: int) -> int:
	if a >= 0 or t.name != school:
		return a
	var learned: Array = holder.slots.filter(func(x: Slot): return x.rank > 0 and t.offers(x.skill)).map(func(x: Slot): return x.skill)
	var i := learned.find(s)
	var n := holder_rank(holder, rank)  # how many, through its modifiers
	return 0 if (i >= 0 and i < n) or (i < 0 and learned.size() < n) else a


# Its terms: how many spells rank as its own grows with rank (impact); a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "spells without penalty")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return ("Opens the %s school of spellcasting, to pick on your class's own tab. The first {r:%d} of its spells you learn "
			+ "rank as your own: none of a guest tree's Affinity penalty") % [school, rank]
