extends Behaviour

# Coyote Scepter (lent by the Coyote Scepter, an epic weapon): skills its holder disables last rank turns longer (rank impact),
# and their unit gets the Coyote Charm buff and the Curse of the Coyote at that rank (coyote_charm.gd: lend()): the
# disabling waits rank turns, then lands for its full, longer turns - the curse barring cleanses and heals.

const Charm := preload("res://Behaviours/coyote_charm.gd")


func disabling(b: Battle, holder: Unit, rank: int, u: Unit, d: Dictionary) -> void:
	if holder == d.by and holder != u:
		var n := holder_rank(holder, rank)
		d.turns += n
		Charm.lend(b, u, n)


# Its terms: the turns it adds and the Charm's rank on the foe are rank impact; a tame effect.
func terms(t: SkillTerms) -> void:
	t.add(&"rank_impact", "turns, charm")
	t.impact = &"tame"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	var rank := c.impact_rank()
	return "Skills it %s last %d turns longer, and their unit gets the Coyote Charm and the Curse of the Coyote %s: the disabling waits %d turns first" % [
			Glossary.term(&"disabled", "disables"), rank, Skill.roman(rank), rank]
