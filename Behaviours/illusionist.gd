extends Behaviour

# Illusionist: opens a school of spellcasting (school: the tab of a choice on its holder's class whose
# `by` is this skill - the Rogue's Illusion), to pick on its class's own tab. Its spells are a guest
# tree's, ranking at the choice's Affinity penalty - but the first `rank` of them its holder learns
# (in the order learned) rank and cost as its own: no penalty (Unit.guest_affinity()).

@export var school := "Illusion"


func affinity(holder: Unit, rank: int, s: Skill, t: Resource, a: int) -> int:
	if a >= 0 or t.name != school:
		return a
	var learned: Array = holder.slots.filter(func(x: Slot): return x.rank > 0 and t.offers(x.skill)).map(func(x: Slot): return x.skill)
	var i := learned.find(s)
	return 0 if (i >= 0 and i < rank) or (i < 0 and learned.size() < rank) else a


func describe(rank: int) -> String:
	return ("Opens the %s school of spellcasting, to pick on your class's own tab. The first {r:%d} of its spells you learn "
			+ "rank as your own: none of a guest tree's Affinity penalty") % [school, rank]
