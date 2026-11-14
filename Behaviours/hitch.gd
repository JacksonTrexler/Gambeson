extends Behaviour

# Hitch: a light blow that hooks on. Landing, a grapple: d20 + its str check mod + rank against d20 + the
# better of the foe's str and dex check mods (the foe wins ties). Won, the foe is held (a grip:
# Battle._break_free()) and Hitched: the caster's moves this turn tow it rank tiles the same way (the
# tow stat: Battle.travel()). The grip ends as the caster's turn does.

const HITCHED: Effect = preload("res://Effects/hitched.tres")


func apply(c: Cast) -> void:
	if not c.foe or not c.target.is_alive():
		return
	var b := c.battle
	var t := c.target
	var vs := b.beats(Check.side(c.caster.check_mod(&"strength", &"offensive", c.tags) + c.impact_rank()),
			Check.side(maxi(t.check_mod(&"strength", &"defensive", c.skill.tags), t.check_mod(&"dexterity", &"defensive", c.skill.tags))), false)
	b.contested.emit(c.caster, t, vs.mine.total, vs.theirs.total)
	c.bag[&"hitched"] = vs.won
	if vs.won:
		c.put(HITCHED, 1).lasting = true


# Its terms: + rank on its grapple contest (a check), the tow an impactful effect.
func terms(t: SkillTerms) -> void:
	t.check = true
	t.hit_per_rank += 1.0
	t.add(&"rank_impact", "grapple")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return "A hit grapples: a %s, {o:str mod} + {r:%d} vs the better of {d:str mod} and {d:dex mod}. Won, it holds the foe, and its moves this turn tow it {r:%d} tile%s the same way. The grip ends with its turn" % [
			Glossary.term(&"contest"), rank, rank, "" if rank == 1 else "s"]
