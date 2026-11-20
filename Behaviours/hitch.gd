extends Behaviour

# Hitch: a light blow that hooks on. Landing, a grapple: d20 + its str check mod + rank against d20 + the
# better of the foe's str and dex check mods (the foe wins ties). Won, the foe is held (a grip:
# Battle._break_free()) and Hitched: the caster's moves this turn tow it rank tiles the same way (the
# tow stat: Battle.travel()). The grip ends as the caster's turn does.

const HITCHED: Effect = preload("res://Effects/hitched.tres")
const HELD := 0.5  # the share of a foe's turn a grip takes (it can't walk off; it can strike): what the AI counts (Behaviour.foresee() `afflicts`)
const FOE_STATS: Array[StringName] = [&"strength", &"dexterity"]  # the foe rolls the better of them


func apply(c: Cast) -> void:
	if not c.foe or not c.target.is_alive():
		return
	var b := c.battle
	var t := c.target
	var vs := b.check(c.caster, &"strength", t, FOE_STATS, grapple(c))
	b.contested.emit(c.caster, t, vs.mine.total, vs.theirs.total)
	c.bag[&"hitched"] = vs.won
	if vs.won:
		c.put(HITCHED, 1).lasting = true


# The grapple's helper options (apply() rolls them, foresee() weighs them): + rank, the caster's tags on its
# side and the skill's on the foe's; the foe wins ties.
static func grapple(c: Cast) -> Dictionary:
	return {bonus = c.impact_rank() + c.check_shift(), tags = c.tags, their_tags = c.skill.tags, ties = false}


# What a hit would bring: the chance the grapple holds the foe (Battle.odds(), the roll apply() makes).
func foresee(c: Cast) -> Dictionary:
	if not c.foe:
		return {}
	var p := Battle.odds(c.caster, &"strength", c.target, FOE_STATS, grapple(c))
	return {notes = ["Holds it (%d%%)" % roundi(p * 100.0)] as Array[String], riders = 0.0, afflicts = p * HELD}


# Its terms: + rank on its grapple contest (a check), the tow an impactful effect.
func terms(t: SkillTerms) -> void:
	t.check = true
	t.hit_per_rank += 1.0
	t.add(&"rank_impact", "grapple")
	t.impact = &"impactful"


func describe(rank: int) -> String:
	return describe_as(Cast.at(rank))


func describe_as(c: Cast) -> String:
	return "A hit grapples: a %s, {o:str mod} + {r:%d} vs the better of {d:str mod} and {d:dex mod}. Won, it holds the foe, and its moves this turn tow it {r:%d} tile%s the same way. The grip ends with its turn" % [
			Glossary.term(&"contest"), c.impact_rank(), c.impact_rank(), "" if c.impact_rank() == 1 else "s"]
